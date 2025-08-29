import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:rxdart/rxdart.dart';

import '../controllers/session_manager.dart';
import '../models/asset_model.dart' as models;
import 'api_service.dart';

// ----------------------------------------------------------------------------
// PUBLIC TYPES
// ----------------------------------------------------------------------------

/// FE sections that map to VM filters (Notes/Watchlist intentionally excluded)
enum Section {
  overview,       // header + price + chart + perf basics
  summary,        // fundamentals + technicals (+ chart data as per VM contract)
  news,           // news list
  marketDepth,    // expandable tile
  shareholding,   // expandable tile
  fundamentals,   // expandable tile (metrics)
  financials,     // expandable tile (charts)
  portfolio,
}

const List<String> supportedPeriods = ['1D', '1W', '1M', '1Y', '5Y', 'ALL'];

// lightweight search result item
class AssetMini {
  final String id;
  final String name;
  const AssetMini(this.id, this.name);
}

// failures
sealed class AssetFailure implements Exception {
  final String message;
  const AssetFailure(this.message);
  factory AssetFailure.timeout([String m = "Request timed out"]) => _Timeout(m);
  factory AssetFailure.server(String m) => _Server(m);
  factory AssetFailure.badPayload(String m) => _BadPayload(m);
  factory AssetFailure.unknown(String m) => _Unknown(m);
  @override
  String toString() => message;
}
class _Timeout extends AssetFailure { const _Timeout(super.message); }
class _Server extends AssetFailure { const _Server(super.message); }
class _BadPayload extends AssetFailure { const _BadPayload(super.message); }
class _Unknown extends AssetFailure { const _Unknown(super.message); }

class AssetViewState {
  final bool loading;
  final models.AssetData? data;
  final AssetFailure? error;
  final String activePeriod;                 // '1D' | '1W' | '1M' | '1Y' | '5Y' | 'ALL' | '<n>Y'
  final List<models.ChartPoint> currentChart;

  const AssetViewState._({
    required this.loading,
    required this.data,
    required this.error,
    required this.activePeriod,
    required this.currentChart,
  });

  factory AssetViewState.loading([String period = 'ALL']) =>
      AssetViewState._(
        loading: true,
        data: null,
        error: null,
        activePeriod: period,
        currentChart: const [],
      );

  factory AssetViewState.data({
    required models.AssetData data,
    required String period,
    required List<models.ChartPoint> chart,
  }) => AssetViewState._(
    loading: false,
    data: data,
    error: null,
    activePeriod: period,
    currentChart: chart,
  );

  factory AssetViewState.error(AssetFailure e, [String period = 'ALL']) =>
      AssetViewState._(
        loading: false,
        data: null,
        error: e,
        activePeriod: period,
        currentChart: const [],
      );
}

// ----------------------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------------------

class AssetService {
  AssetService({EndPointService? api}) : _api = api ?? EndPointService() {
    // debounced, distinct search → POST /assets/search via EndPointService
    _searchResults$ = _searchQuery$
        .debounceTime(const Duration(milliseconds: 250))
        .distinct()
        .switchMap((q) => _doSearch(q).asStream().onErrorReturnWith((e, _) {
      // swallow search errors into empty results
      return const <AssetMini>[];
    }))
        .shareReplay(maxSize: 1);
  }

  // ---- IO via EndPointService ----
  final EndPointService _api;

  // ---- Public state stream ----
  final BehaviorSubject<AssetViewState> _state$ =
  BehaviorSubject.seeded(AssetViewState.loading());
  Stream<AssetViewState> get state => _state$.stream;
  AssetViewState get snapshot => _state$.value;

  // ---- Search stream ----
  final BehaviorSubject<String> _searchQuery$ = BehaviorSubject.seeded('');
  late final Stream<List<AssetMini>> _searchResults$;
  Stream<List<AssetMini>> get searchResults => _searchResults$;
  void setSearchQuery(String q) => _searchQuery$.add(q);

  // ---- Current asset context & cache ----
  String _assetId = '';
  String _period = 'ALL';
  Map<String, dynamic>? _rawJson; // merged source-of-truth (deep-merged)
  models.AssetData? _rawData;

  // Dynamic long chip label, e.g. "3Y"
  String _longPeriodLabel = '5Y';
  String get longPeriodLabel => _longPeriodLabel;

  final Map<String, Map<String, dynamic>> _cacheJsonByAsset = {};
  final Map<String, Set<Section>> _loadedByAsset = {};

  int _fetchSeq = 0;
  bool _disposed = false;

  /// Default sections for first load (NO Notes/Watchlist in filters)
  static const Set<Section> _defaultSections = {
    Section.overview,
    Section.summary,
    Section.news,
    Section.marketDepth,
    Section.shareholding,
    Section.fundamentals,
    Section.financials,
    Section.portfolio
  };

  // ----------------------------------------------------------------------------
  // PUBLIC API
  // ----------------------------------------------------------------------------

  /// Initialize (or reload) the service for an asset and perform the first fetch.
  Future<void> init({
    required String assetId,
    Set<Section> sections = _defaultSections,
    String initialPeriod = 'ALL',
  }) async {
    if (_disposed) return;
    _assetId = assetId;
    _period = _validatePeriod(initialPeriod);
    await _fetchAndPublish(
      assetId: assetId,
      sections: sections,
      period: _period,
      force: true,
      incremental: false,
    );
  }

  /// Alias; can be used for subsequent loads.
  Future<void> load({
    required String assetId,
    Set<Section>? sections,
    String? initialPeriod,
  }) async {
    if (_disposed) return;
    _assetId = assetId;
    _period = _validatePeriod(initialPeriod ?? _period);
    await _fetchAndPublish(
      assetId: assetId,
      sections: sections ?? _defaultSections,
      period: _period,
      force: true,
      incremental: false,
    );
  }

  /// Pull-to-refresh or retry. Keeps current period.
  Future<void> refresh([Set<Section>? sections]) async {
    if (_disposed || _assetId.isEmpty) return;
    await _fetchAndPublish(
      assetId: _assetId,
      sections: sections ?? _loadedByAsset[_assetId] ?? _defaultSections,
      period: _period,
      force: true,
      incremental: false,
    );
  }

  /// Ask for additional sections (incremental fetch) - merges into existing.
  Future<void> requestSections(Set<Section> more) async {
    if (_disposed || _assetId.isEmpty) return;
    final loaded = _loadedByAsset[_assetId] ?? <Section>{};
    final missing = more.difference(loaded);
    if (missing.isEmpty) return;

    await _fetchAndPublish(
      assetId: _assetId,
      sections: loaded.union(missing), // union; VM trims anyway
      period: _period,
      force: false,
      incremental: true,
    );
  }

  /// Change active chart period; derive data from available series or 'ALL'.
  void setPeriod(String period) {
    if (_disposed) return;
    final p = _validatePeriod(period);
    _period = p;
    if (_rawData == null) return;
    final chart = _buildChartForPeriod(_rawData!, _period);
    _state$.add(AssetViewState.data(data: _rawData!, period: _period, chart: chart));
  }

  /// Special: dynamic long chip (e.g., "3Y") sliced from ALL.
  void setLongPeriod() {
    if (_disposed || _rawData == null) return;
    final all = _rawData!.chartData.getDataForPeriod('ALL') ?? const <models.ChartPoint>[];
    if (all.isEmpty) return;

    final y = int.tryParse(_longPeriodLabel.replaceAll('Y', '')) ?? 5;
    final cutoff = all.last.timestamp.subtract(Duration(days: 365 * y));
    final sliced = all.where((p) =>
    p.timestamp.isAfter(cutoff) || p.timestamp.isAtSameMomentAs(cutoff)).toList();

    final densified = _densify(sliced, target: 120);
    _period = _longPeriodLabel; // publish as active
    _state$.add(AssetViewState.data(data: _rawData!, period: _period, chart: densified));
  }



  /// Calculate available periods based on ALL data span
  /// Calculate available periods based on actual data availability
  /// Calculate available periods based on actual data availability
  List<String> getAvailablePeriods() {
    final ts = _rawData?.chartData.timeSeriesData ?? const <String, List<models.ChartPoint>>{};

    // Helper function to check if a period has actual usable data
    bool hasUsableData(String period) {
      final data = ts[period] ?? const <models.ChartPoint>[];
      return data.isNotEmpty && data.length >= 2;
    }

    final out = <String>[];

    // Check standard periods in order of preference
    final standardPeriods = ['1D', '1W', '1M', '1Y', '5Y'];

    for (final period in standardPeriods) {
      if (hasUsableData(period)) {
        out.add(period);
      }
    }

    // Add ALL if it has data
    if (hasUsableData('ALL')) {
      out.add('ALL');
    }

    // If no periods are available, return a minimal set
    if (out.isEmpty) {
      return ['1W', '1M', 'ALL'];
    }

    //print("📊 Available periods: $out");
    return out;
  }


  // --------- Optional local optimistic mutations (no server yet) ---------

  void addNote(models.UserNote note) {
    if (_disposed || _rawData == null) return;
    final ad = _rawData!.additionalData;
    final updated = models.AdditionalData(
      dataFreshness: ad?.dataFreshness,
      marketStatus: ad?.marketStatus ?? "CLOSED",
      currencySymbol: ad?.currencySymbol ?? "₹",
      timezone: ad?.timezone ?? "Asia/Kolkata",
      userNotes: [...(ad?.userNotes ?? const []), note],
      userWatchlisted: ad?.userWatchlisted ?? false,
      watchlistStocks: ad?.watchlistStocks ?? const [],
    );
    _applyAdditional(updated);
  }

  void updateNote(models.UserNote note) {
    if (_disposed || _rawData == null) return;
    final ad = _rawData!.additionalData;
    final list = (ad?.userNotes ?? const []);
    final updatedList = [
      for (final n in list) if (n.id == note.id) note else n,
    ];
    final updated = models.AdditionalData(
      dataFreshness: ad?.dataFreshness,
      marketStatus: ad?.marketStatus ?? "CLOSED",
      currencySymbol: ad?.currencySymbol ?? "₹",
      timezone: ad?.timezone ?? "Asia/Kolkata",
      userNotes: updatedList,
      userWatchlisted: ad?.userWatchlisted ?? false,
      watchlistStocks: ad?.watchlistStocks ?? const [],
    );
    _applyAdditional(updated);
  }

  void deleteNote(String noteId) {
    if (_disposed || _rawData == null) return;
    final ad = _rawData!.additionalData;
    final updatedList = (ad?.userNotes ?? const [])
        .where((n) => n.id != noteId)
        .toList();
    final updated = models.AdditionalData(
      dataFreshness: ad?.dataFreshness,
      marketStatus: ad?.marketStatus ?? "CLOSED",
      currencySymbol: ad?.currencySymbol ?? "₹",
      timezone: ad?.timezone ?? "Asia/Kolkata",
      userNotes: updatedList,
      userWatchlisted: ad?.userWatchlisted ?? false,
      watchlistStocks: ad?.watchlistStocks ?? const [],
    );
    _applyAdditional(updated);
  }

  void toggleWatchlist() {
    if (_disposed || _rawData == null) return;
    final ad = _rawData!.additionalData;
    final updated = models.AdditionalData(
      dataFreshness: ad?.dataFreshness,
      marketStatus: ad?.marketStatus ?? "CLOSED",
      currencySymbol: ad?.currencySymbol ?? "₹",
      timezone: ad?.timezone ?? "Asia/Kolkata",
      userNotes: ad?.userNotes ?? const [],
      userWatchlisted: !(ad?.userWatchlisted ?? false),
      watchlistStocks: ad?.watchlistStocks ?? const [],
    );
    _applyAdditional(updated);
  }

  /// Dispose everything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state$.close();
    _searchQuery$.close();
  }

  // ----------------------------------------------------------------------------
  // INTERNALS
  // ----------------------------------------------------------------------------

  Future<void> _fetchAndPublish({
    required String assetId,
    required Set<Section> sections,
    required String period,
    required bool force,
    required bool incremental,
  }) async {
    if (_disposed) return;

    _state$.add(AssetViewState.loading(period));

    // Cache hit (superset already loaded) and not forcing
    final loaded = _loadedByAsset[assetId] ?? <Section>{};
    final hasSuperset = loaded.containsAll(sections);
    if (!force && hasSuperset) {
      final cachedJson = _cacheJsonByAsset[assetId];
      if (cachedJson != null) {
        _rawJson = Map<String, dynamic>.from(cachedJson);
        _rawData = models.AssetData.fromJson(_rawJson!);
        _computeLongPeriodLabel();
        final chart = _buildChartForPeriod(_rawData!, period);
        _state$.add(AssetViewState.data(data: _rawData!, period: period, chart: chart));
        return;
      }
    }

    // VM filters
    final filters = _filtersFromSections(sections);

    // De-dup stale responses
    final seq = ++_fetchSeq;

    try {
      final freshJson = await _callFetchApi(assetId: assetId, filters: filters);
      if (_disposed || seq != _fetchSeq) return; // drop stale

      if (incremental && _rawJson != null) {
        _rawJson = _deepMerge(Map<String, dynamic>.from(_rawJson!), freshJson);
      } else if (!incremental && _cacheJsonByAsset[assetId] != null) {
        // non-incremental but we had cache → keep previous sections by merging
        _rawJson = _deepMerge(
          Map<String, dynamic>.from(_cacheJsonByAsset[assetId]!),
          freshJson,
        );
      } else {
        _rawJson = freshJson;
      }

      _rawData = models.AssetData.fromJson(_rawJson!);
      _cacheJsonByAsset[assetId] = Map<String, dynamic>.from(_rawJson!);
      _loadedByAsset[assetId] =
          (_loadedByAsset[assetId] ?? <Section>{}).union(sections);

      _computeLongPeriodLabel();
      final chart = _buildChartForPeriod(_rawData!, period);
      _state$.add(AssetViewState.data(data: _rawData!, period: period, chart: chart));
    } catch (e) {
      final msg = handleApiError(e); // from EndPointService
      if (e is ApiException) {
        _state$.add(AssetViewState.error(AssetFailure.server(msg), period));
      } else {
        _state$.add(AssetViewState.error(AssetFailure.unknown(msg), period));
      }
    }
  }

  // --- HTTP: Fetch asset via EndPointService ---
  Future<Map<String, dynamic>> _callFetchApi({
    required String assetId,
    required List<String> filters,
  }) async {
    final uidFromToken = SessionManager.uid;
    final resp = await _api.post(
      endpoint: "/assets/fetch",
      body: {
        "asset_id": assetId,
        if (filters.isNotEmpty) "filters": filters,
        "uid": uidFromToken
      },
    );

    if (resp is Map<String, dynamic>) return resp;

    if (resp is String) {
      try {
        final decoded = jsonDecode(resp);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      throw AssetFailure.badPayload("VM returned non-object response");
    }

    throw AssetFailure.badPayload("Unexpected response type from VM");
  }

  // --- HTTP: Search assets (debounced) via EndPointService ---
  Future<List<AssetMini>> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return const <AssetMini>[];

    try {
      final resp = await _api.post(
        endpoint: "/assets/search",
        body: {"keyword": query},
      );

      final List<dynamic> list = resp is List
          ? resp
          : (resp is String ? (jsonDecode(resp) as List<dynamic>) : const []);

      final out = <AssetMini>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final id = (item["_id"] ?? "").toString();
          final name = (item["name"] ?? "").toString();
          if (id.isNotEmpty && name.isNotEmpty) out.add(AssetMini(id, name));
        }
      }
      return out;
    } catch (_) {
      // search errors → empty list
      return const <AssetMini>[];
    }
  }

  // --- Filters mapping (FE Sections -> VM filter display names) ---
  List<String> _filtersFromSections(Set<Section> sections) {
    final set = <String>{}; // de-dupe

    for (final s in sections) {
      switch (s) {
        case Section.overview:
          set.add("Overview");
          break;

        case Section.summary:
        // "summary mein saara and chart data"
          set..add("Summary")..add("Overview");
          break;

        case Section.news:
          set.add("News");
          break;

        case Section.marketDepth:
          set.add("Market Depth");
          break;

        case Section.portfolio:
          set.add("Portfolio");
          break;

        case Section.shareholding:
          set.add("Shareholding");
          break;

        case Section.fundamentals:
          set.add("Fundamentals");
          break;

        case Section.financials:
          set.add("Financials");
          break;
      }
    }

    return set.toList();
  }

  // --- Chart helpers ---
  List<models.ChartPoint> _buildChartForPeriod(models.AssetData data, String period) {
    print("🔍 Building chart for period: $period");

    // First, try to get data for the specific period requested
    List<models.ChartPoint>? requestedData = data.chartData.getDataForPeriod(period);
    print("📊 Requested period '$period' data points: ${requestedData?.length ?? 0}");

    if (requestedData != null && requestedData.isNotEmpty) {
      final sanitized = _sanitizeAndSort(requestedData);
      if (sanitized.length >= 2) {
        print("✅ Using requested period data: ${sanitized.length} points");
        return _densify(sanitized, target: 120);
      }
    }

    // If requested period is empty, try to find the best available data
    List<models.ChartPoint>? fallbackData;

    // Priority order for fallback data
    final fallbackPriorities = ['1Y', '1M', '1W', '5Y', 'ALL'];

    for (final fallbackPeriod in fallbackPriorities) {
      if (fallbackPeriod == period) continue; // Skip the one we already tried

      fallbackData = data.chartData.getDataForPeriod(fallbackPeriod);
      print("📊 Trying fallback period '$fallbackPeriod': ${fallbackData?.length ?? 0} points");

      if (fallbackData != null && fallbackData.isNotEmpty) {
        final sanitized = _sanitizeAndSort(fallbackData);
        if (sanitized.length >= 2) {
          print("✅ Using fallback data from '$fallbackPeriod': ${sanitized.length} points");

          // If we have good fallback data, slice it to match the requested period
          if (period != 'ALL') {
            final sliced = _sliceDataForPeriod(sanitized, period);
            if (sliced.length >= 2) {
              return _densify(sliced, target: 120);
            }
          }

          return _densify(sanitized, target: 120);
        }
      }
    }

    print("❌ No usable chart data found for any period");
    return const <models.ChartPoint>[];
  }


  List<models.ChartPoint> _sliceDataForPeriod(List<models.ChartPoint> data, String period) {
    if (data.isEmpty || period == 'ALL') return data;

    final anchor = _parseTimestamp(data.last.timestamp);
    final cutoff = _calculateCutoffDate(anchor, period);

    final filtered = data.where((p) {
      final pointTime = _parseTimestamp(p.timestamp);
      return pointTime.isAfter(cutoff) || pointTime.isAtSameMomentAs(cutoff);
    }).toList();

    print("🔍 Sliced ${data.length} points to ${filtered.length} for period $period");
    return filtered;
  }

  // ADD THIS NEW METHOD to AssetService:
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp).toUtc();
      } catch (e) {
        print("❌ Error parsing timestamp: $timestamp");
        return DateTime.now().toUtc();
      }
    }
    return DateTime.now().toUtc();
  }

  /// Sort, drop duplicate timestamps (keep last)
  List<models.ChartPoint> _sanitizeAndSort(List<models.ChartPoint> pts) {
    if (pts.isEmpty) return pts;
    final list = List<models.ChartPoint>.from(pts)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final seen = <int, models.ChartPoint>{};
    for (final p in list) {
      seen[p.timestamp.millisecondsSinceEpoch] = p;
    }
    final unique = seen.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return unique;
  }

  /// Choose the series with the largest time span if ALL is missing
  List<models.ChartPoint>? _longestSeries(Map<String, List<models.ChartPoint>> ts) {
    List<models.ChartPoint>? best;
    int bestSpan = -1;
    ts.forEach((_, series) {
      if (series.length < 2) return;
      final s = _sanitizeAndSort(series);
      final span = s.last.timestamp.millisecondsSinceEpoch -
          s.first.timestamp.millisecondsSinceEpoch;
      if (span > bestSpan) {
        bestSpan = span;
        best = s;
      }
    });
    return best;
  }

  /// Does a provided series *actually* fit the named period?
  bool _seriesFitsPeriod(List<models.ChartPoint> s, String period) {
    if (s.length < 2) return false;
    if (period == 'ALL') return true;

    final sorted = _sanitizeAndSort(s);
    final spanDays = sorted.last.timestamp.difference(sorted.first.timestamp).inDays;

    int maxDays;
    if (period == '1D') {
      maxDays = 2;       // allow some drift
    } else if (period == '1W') {
      maxDays = 10;
    } else if (period == '1M') {
      maxDays = 45;
    } else if (period == '1Y') {
      maxDays = 400;
    } else if (period.endsWith('Y')) {
      final years = int.tryParse(period.replaceAll('Y', '')) ?? 5;
      maxDays = (years * 370);
    } else {
      maxDays = 400; // safe default
    }

    return spanDays <= maxDays;
  }


  /// Generate realistic data for short periods when source data is sparse
  List<models.ChartPoint> _generateRealisticDataForPeriod(
      List<models.ChartPoint> allData,
      String period,
      DateTime anchor
      ) {
    if (allData.isEmpty) return const [];

    // Get the latest price as starting point
    final latestPrice = allData.last.price;
    final latestVolume = allData.last.volume ?? 0;

    // Calculate how many points we need based on period
    int pointCount;
    Duration interval;

    switch (period) {
      case '1D':
        pointCount = 24; // hourly data
        interval = const Duration(hours: 1);
        break;
      case '1W':
        pointCount = 14; // twice daily
        interval = const Duration(hours: 12);
        break;
      case '1M':
        pointCount = 30; // daily data
        interval = const Duration(days: 1);
        break;
      default:
        pointCount = 20;
        interval = const Duration(days: 1);
    }

    // Generate realistic price movement (small variations around latest price)
    final random = _createSeededRandom(latestPrice.toInt());
    final points = <models.ChartPoint>[];

    for (int i = 0; i < pointCount; i++) {
      // Create timestamps going backwards from anchor
      final timestamp = anchor.subtract(interval * (pointCount - 1 - i));

      // Generate realistic price variations (±2% from latest)
      final variation = (random.nextDouble() - 0.5) * 0.04; // ±2%
      final price = latestPrice * (1 + variation * (i / pointCount)); // gradual trend

      // Generate volume variations
      final volumeVariation = (random.nextDouble() - 0.5) * 0.3; // ±15%
      final volume = latestVolume * (1 + volumeVariation);

      points.add(models.ChartPoint(
        timestamp: timestamp,
        price: price,
        volume: volume,
        high: null,
        low: null,
        open: null,
      ));
    }

    return points;
  }

  /// Enhance sparse period data with interpolated points
  List<models.ChartPoint> _enhanceSparsePeriodData(
      List<models.ChartPoint> filtered,
      List<models.ChartPoint> allData,
      String period
      ) {
    if (filtered.length < 2) return filtered;

    // Sort by timestamp
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final enhanced = <models.ChartPoint>[];

    for (int i = 0; i < filtered.length - 1; i++) {
      final current = filtered[i];
      final next = filtered[i + 1];

      enhanced.add(current);

      // Add interpolated points between sparse data
      final timeDiff = next.timestamp.difference(current.timestamp);
      final priceDiff = next.price - current.price;

      // Determine how many intermediate points to add
      int intermediatePoints = 0;
      switch (period) {
        case '1D':
          intermediatePoints = timeDiff.inDays > 0 ? (timeDiff.inDays * 4) : 2;
          break;
        case '1W':
          intermediatePoints = timeDiff.inDays > 7 ? (timeDiff.inDays ~/ 2) : 3;
          break;
        case '1M':
          intermediatePoints = timeDiff.inDays > 30 ? (timeDiff.inDays ~/ 7) : 4;
          break;
        default:
          intermediatePoints = 2;
      }

      // Add interpolated points with some realistic variation
      final random = _createSeededRandom(current.price.toInt());
      for (int j = 1; j <= intermediatePoints; j++) {
        final fraction = j / (intermediatePoints + 1);
        final interpolatedTime = current.timestamp.add(
            Duration(milliseconds: (timeDiff.inMilliseconds * fraction).round())
        );

        // Linear interpolation with small random variations
        final basePrice = current.price + (priceDiff * fraction);
        final variation = (random.nextDouble() - 0.5) * 0.01; // ±0.5%
        final interpolatedPrice = basePrice * (1 + variation);

        final interpolatedVolume = current.volume ?? 0;

        enhanced.add(models.ChartPoint(
          timestamp: interpolatedTime,
          price: interpolatedPrice,
          volume: interpolatedVolume,
          high: null,
          low: null,
          open: null,
        ));
      }
    }

    // Add the last point
    enhanced.add(filtered.last);

    return enhanced;
  }

  /// Create a seeded random generator for consistent results
  math.Random _createSeededRandom(int seed) {
    return math.Random(seed);
  }


  DateTime _calculateCutoffDate(DateTime anchor, String period) {
    switch (period) {
      case '1D':
      // For 1D, we want the last trading day's data
        return anchor.subtract(const Duration(days: 1));

      case '1W':
        return anchor.subtract(const Duration(days: 7));

      case '1M':
        return anchor.subtract(const Duration(days: 30));

      case '1Y':
        return anchor.subtract(const Duration(days: 365));

      default:
      // Handle dynamic periods like "3Y", "5Y"
        if (period.endsWith('Y')) {
          final yearStr = period.replaceAll('Y', '');
          final years = int.tryParse(yearStr) ?? 5;
          return anchor.subtract(Duration(days: 365 * years));
        }
        return anchor.subtract(const Duration(days: 365 * 5)); // fallback to 5Y
    }
  }



  // Linear interpolation → target number of points for a smooth curve
  List<models.ChartPoint> _densify(List<models.ChartPoint> pts, {int target = 120}) {
    if (pts.length >= target || pts.length < 2) return pts;

    // Sort points by timestamp to ensure proper interpolation
    pts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final start = pts.first.timestamp.millisecondsSinceEpoch.toDouble();
    final end = pts.last.timestamp.millisecondsSinceEpoch.toDouble();
    if (end <= start) return pts;

    final out = <models.ChartPoint>[];

    for (int i = 0; i < target; i++) {
      final t = i / (target - 1);
      final ts = start + (end - start) * t;

      // Find surrounding points for interpolation
      int leftIdx = 0;
      while (leftIdx < pts.length - 1 &&
          pts[leftIdx + 1].timestamp.millisecondsSinceEpoch.toDouble() <= ts) {
        leftIdx++;
      }

      if (leftIdx >= pts.length - 1) {
        out.add(pts.last);
        continue;
      }

      final leftPoint = pts[leftIdx];
      final rightPoint = pts[leftIdx + 1];

      final leftTime = leftPoint.timestamp.millisecondsSinceEpoch.toDouble();
      final rightTime = rightPoint.timestamp.millisecondsSinceEpoch.toDouble();

      // Linear interpolation
      final fraction = (ts - leftTime) / (rightTime - leftTime);
      final interpolatedPrice = leftPoint.price + (rightPoint.price - leftPoint.price) * fraction;
      final interpolatedVolume = (leftPoint.volume ?? 0) +
          ((rightPoint.volume ?? 0) - (leftPoint.volume ?? 0)) * fraction;

      out.add(models.ChartPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts.toInt()),
        price: interpolatedPrice,
        volume: interpolatedVolume,
        high: null,
        low: null,
        open: null,
      ));
    }

    return out;
  }



  String _validatePeriod(String period) {
    final available = getAvailablePeriods();
    return available.contains(period) ? period : (available.isNotEmpty ? available.first : 'ALL');
  }





  String getDefaultPeriod() {
    final available = getAvailablePeriods();

    // Prefer periods with actual data, in this order
    final preferredOrder = ['1W', '1M', '1Y', '5Y', 'ALL'];

    for (final period in preferredOrder) {
      if (available.contains(period)) {
        return period;
      }
    }

    // Fallback to first available or 1W
    return available.isNotEmpty ? available.first : '1W';
  }




/// Enhanced long period computation
  void _computeLongPeriodLabel() {
    final all = _rawData?.chartData.getDataForPeriod('ALL');
    if (all == null || all.length < 2) {
      _longPeriodLabel = 'ALL'; // Changed from '5Y' to 'ALL' when no data
      return;
    }

    final totalDays = all.last.timestamp.difference(all.first.timestamp).inDays;
    final years = (totalDays / 365).clamp(1, 50).round();

    // Set dynamic label based on actual data span
    if (years == 1) {
      _longPeriodLabel = '1Y';
    } else if (years < 50) {
      _longPeriodLabel = '${years}Y';
    } else {
      _longPeriodLabel = 'ALL';
    }
  }

  // --- Deep merge maps for incremental fetches ---
  Map<String, dynamic> _deepMerge(Map<String, dynamic> base, Map<String, dynamic> fresh) {
    fresh.forEach((key, freshVal) {
      if (freshVal is Map && base[key] is Map) {
        base[key] = _deepMerge(
          Map<String, dynamic>.from(base[key] as Map),
          Map<String, dynamic>.from(freshVal),
        );
      } else {
        base[key] = freshVal; // replace scalars and lists directly
      }
    });
    return base;
  }

  // --- Apply updated AdditionalData after optimistic changes ---
  void _applyAdditional(models.AdditionalData newAdditional) {
    if (_rawData == null || _rawJson == null) return;

    final d = _rawData!;
    final updated = models.AssetData(
      assetId: d.assetId,
      basicInfo: d.basicInfo,
      priceData: d.priceData,
      chartData: d.chartData,
      portfolioData: d.portfolioData,
      performanceData: d.performanceData,
      fundamentals: d.fundamentals,
      technicals: d.technicals,
      news: d.news,
      events: d.events,
      futuresOptions: d.futuresOptions,
      additionalData: newAdditional,

      // ✅ keep existing tiles returned by VM
      expandableTiles: d.expandableTiles,
    );

    _rawData = updated;

    // keep additional_data in the backing JSON too (as you do)
    _rawJson!['additional_data'] = _additionalToJson(newAdditional);

    _cacheJsonByAsset[_assetId] = Map<String, dynamic>.from(_rawJson!);

    final chart = _buildChartForPeriod(updated, _period);
    _state$.add(AssetViewState.data(data: updated, period: _period, chart: chart));
  }


  Map<String, dynamic> _additionalToJson(models.AdditionalData a) {
    return {
      if (a.dataFreshness != null) 'data_freshness': a.dataFreshness!.toUtc().toIso8601String(),
      'market_status': a.marketStatus,
      'currency_symbol': a.currencySymbol,
      'timezone': a.timezone,
      'user_notes': [
        for (final n in a.userNotes)
          {
            'id': n.id,
            'title': n.title,
            'content': n.content,
            'created_at': n.createdAt.toUtc().toIso8601String(),
          }
      ],
      'user_watchlisted': a.userWatchlisted,
      'watchlist_stocks': [
        for (final s in a.watchlistStocks)
          {
            'symbol': s.symbol,
            'name': s.name,
            if (s.logoUrl != null) 'logo_url': s.logoUrl,
            'current_price': s.currentPrice,
            'change_percent': s.changePercent,
            'is_positive': s.isPositive,
          }
      ],
    };
  }
}
