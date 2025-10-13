// watchlist_models.dart
import 'package:meta/meta.dart';

import '../services/asset_service.dart';

/// Type aliases so code self-documenting rahe
typedef WatchlistId = String;
typedef AssetId = String;

/// Lightweight list-row item (Watchlist listing screen)
@immutable
class WatchlistSummary {
  final WatchlistId id;
  final String name;
  final int stocksCount;

  const WatchlistSummary({
    required this.id,
    required this.name,
    required this.stocksCount,
  });

  WatchlistSummary copyWith({
    String? name,
    int? stocksCount,
  }) {
    return WatchlistSummary(
      id: id,
      name: name ?? this.name,
      stocksCount: stocksCount ?? this.stocksCount,
    );
  }

  // ------ JSON ------
  factory WatchlistSummary.fromJson(Map<String, dynamic> j) {
    return WatchlistSummary(
      id: j['id'] as String,
      name: j['name'] as String,
      // allow both `stocksCount` or `assets` array from APIs
      stocksCount: j['stocksCount'] is int
          ? j['stocksCount'] as int
          : (j['assets'] is List ? (j['assets'] as List).length : 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stocksCount': stocksCount,
  };

  // ------ Equality (no external deps) ------
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WatchlistSummary &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              stocksCount == other.stocksCount;

  @override
  int get hashCode => Object.hash(id, name, stocksCount);
}

/// Detail object (single watchlist + its assets)
@immutable
class WatchlistDetail {
  final WatchlistId id;
  final String name;
  final List<AssetId> assetIds;

  const WatchlistDetail({
    required this.id,
    required this.name,
    required this.assetIds,
  });

  int get stocksCount => assetIds.length;

  WatchlistDetail copyWith({
    String? name,
    List<AssetId>? assetIds,
  }) {
    return WatchlistDetail(
      id: id,
      name: name ?? this.name,
      assetIds: assetIds ?? this.assetIds,
    );
  }

  // ------ JSON ------
  factory WatchlistDetail.fromJson(Map<String, dynamic> j) {
    return WatchlistDetail(
      id: j['id'] as String,
      name: j['name'] as String,
      assetIds: (j['assets'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assets': assetIds,
  };

  // ------ Equality ------
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WatchlistDetail &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              _listEquals(assetIds, other.assetIds);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(assetIds));
}

// Small helper to avoid importing collection package
bool _listEquals<E>(List<E> a, List<E> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}




class WatchlistStockData {
  final AssetId assetId;
  final String symbol;
  final String name;
  final String? logoUrl;
  final double currentPrice;
  final double changeAmount;
  final double changePercent;
  final bool isPositive;
  final List<String> tags;

  const WatchlistStockData({
    required this.assetId,
    required this.symbol,
    required this.name,
    this.logoUrl,
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.isPositive,
    required this.tags,
  });

  // ✅ REAL API IMPLEMENTATION using AssetService
  static Future<WatchlistStockData?> fetchFromApi(AssetId assetId) async {
    try {
      print('🔍 Fetching data for: $assetId');
      final assetService = AssetService();

      await assetService.init(
        assetId: assetId,
        sections: {Section.overview},
        initialPeriod: '1D',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final state = assetService.snapshot;

      if (state.data != null) {
        final data = state.data!;
        final basicInfo = data.basicInfo;
        final priceData = data.priceData;

        print('✅ API Success for $assetId: ${basicInfo?.name ?? "No name"}');

        // Dispose service after use
        assetService.dispose();

        return WatchlistStockData(
          assetId: assetId,
          symbol: basicInfo?.symbol ?? assetId,
          name: basicInfo?.name ?? assetId,
          logoUrl: basicInfo?.logoUrl,
          currentPrice: priceData?.currentPrice ?? 0.0,
          changeAmount: priceData?.changeAmount ?? 0.0,
          changePercent: priceData?.changePercent ?? 0.0,
          isPositive: priceData?.isPositive ?? true,
          tags: _generateTagsFromData(basicInfo, priceData),
        );
      } else {
        print('⚠️ No data in state for $assetId');
      }

      // Dispose if no data
      assetService.dispose();
    } catch (e, stackTrace) {
      print('❌ Error fetching stock data for $assetId: $e');
      print('Stack trace: $stackTrace');
    }

    print('📦 Using fallback mock data for $assetId');

    // Fallback to mock data (inline)
    final mockData = {
      'HDFCBANK': ('HDFC Bank', 1821.45, 21.45, 1.19),
      'ICICIBANK': ('ICICI Bank', 1821.45, -14.45, -1.06),
      'TCS': ('Tata Consultancy Services', 3421.50, 45.20, 1.34),
      'INFY': ('Infosys', 1456.30, -12.50, -0.85),
      'RELIANCE': ('Reliance Industries', 2456.75, 32.10, 1.32),
      'NFLX': ('Netflix', 455.80, 8.20, 1.83),
      'GOOGL': ('Alphabet Inc', 138.45, -2.15, -1.53),
      'MSFT': ('Microsoft Corporation', 378.85, 5.60, 1.50),
      'TATASTEEL': ('Tata Steel', 123.45, 2.15, 1.77),
      'DIS': ('Walt Disney Co', 91.23, -0.56, -0.61),
    };

    // If not in mock data, use assetId as display name
    final data = mockData[assetId] ?? (assetId, 1000.00, 10.00, 1.00);
    final isPositive = data.$3 >= 0;

    return WatchlistStockData(
      assetId: assetId,
      symbol: assetId,
      name: data.$1, // Will be assetId if not in mockData
      logoUrl: null,
      currentPrice: data.$2,
      changeAmount: data.$3,
      changePercent: data.$4,
      isPositive: isPositive,
      tags: _generateMockTags(assetId),
    );
  }

  // Generate tags based on actual data
  static List<String> _generateTagsFromData(dynamic basicInfo, dynamic priceData) {
    final tags = <String>[];

    try {
      // Try to add sector/industry if available
      if (basicInfo?.sector != null && basicInfo.sector.toString().isNotEmpty) {
        tags.add(basicInfo.sector.toString());
      }

      // Try to add exchange if available
      if (basicInfo?.exchange != null && basicInfo.exchange.toString().isNotEmpty) {
        final exchange = basicInfo.exchange.toString();
        if (exchange == 'NSE' || exchange == 'BSE') {
          tags.add(exchange);
        }
      }

      // Add based on price range (simple categorization)
      if (priceData?.currentPrice != null) {
        final price = priceData.currentPrice as num;
        if (price > 2000) {
          tags.add('High Value');
        } else if (price > 500) {
          tags.add('Mid Value');
        }
      }
    } catch (e) {
      print('Error generating tags: $e');
    }

    // If no tags generated, add default
    if (tags.isEmpty) {
      tags.add('Stock');
    }

    return tags;
  }

  static List<String> _generateMockTags(AssetId assetId) {
    final tagMap = {
      'HDFCBANK': ['Banking', 'Large Cap'],
      'ICICIBANK': ['Banking', 'Large Cap'],
      'TCS': ['IT Services', 'Large Cap'],
      'INFY': ['IT Services', 'Large Cap'],
      'RELIANCE': ['Conglomerate', 'Large Cap'],
      'NFLX': ['Entertainment', 'Large Cap'],
      'GOOGL': ['Technology', 'Large Cap'],
      'MSFT': ['Technology', 'Large Cap'],
      'TATASTEEL': ['Steel', 'Large Cap'],
      'DIS': ['Entertainment', 'Large Cap'],
    };

    return tagMap[assetId] ?? ['Stock'];
  }
}