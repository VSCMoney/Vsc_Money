// watchlist_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watchlist_modal.dart';
import 'api_service.dart';



class WatchlistService {


  WatchlistService({
    EndPointService? api,
    bool localMode = true,
  })  : _api = api ?? EndPointService(),
        _localMode = localMode {
    //_seedLocalIfEmpty();  // ✅ Uncommented
  }

  final EndPointService _api;

  bool _localMode;

  // ---------------- In-Memory Store ----------------
  final Map<WatchlistId, WatchlistDetail> _store = {};

  // ---------------- Streams ----------------
  final _watchlists$ = BehaviorSubject<List<WatchlistSummary>>.seeded(const []);
  final _detail$ = BehaviorSubject<WatchlistDetail?>.seeded(null);
  final _busy$ = BehaviorSubject<bool>.seeded(false);
  final _error$ = BehaviorSubject<String?>.seeded(null);

  // Public streams
  Stream<List<WatchlistSummary>> get watchlistsStream => _watchlists$.stream;
  Stream<WatchlistDetail?> get detailStream => _detail$.stream;
  Stream<bool> get isBusyStream => _busy$.stream;
  Stream<String?> get errorStream => _error$.stream;

  // Sync getters (optional)
  List<WatchlistSummary> get watchlists => _watchlists$.value;
  WatchlistDetail? get activeDetail => _detail$.valueOrNull;

  // ---------------- Endpoints (future) ----------------
  static const _epList   = '/watchlist/list';
  static const _epCreate = '/watchlist/create';
  static const _epEdit   = '/watchlist/edit';
  static const _epDelete = '/watchlist/delete';
  static const _epDetail = '/watchlist/detail';
  static const _epAdd    = '/watchlist/add-assets';
  static const _epRemove = '/watchlist/remove-assets';

  // ===================================================
  // Lifecycle
  // ===================================================



  void enableLocalMode([bool v = true]) => _localMode = v;
  bool get isLocalMode => _localMode;



  static const _storeKey = 'watchlist_store';

  // Load from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storeKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _store.clear();
        decoded.forEach((key, value) {
          _store[key] = WatchlistDetail.fromJson(value);
        });
        print('✅ Loaded ${_store.length} watchlists from storage');
      } else {
        // ✅ First time - seed with sample data
        print('📦 First time launch - seeding data');
        _seedLocalIfEmpty();
        await _saveToStorage(); // ✅ Save seeded data immediately
      }
    } catch (e) {
      print('⚠️ Error loading from storage: $e');
      _seedLocalIfEmpty();
      await _saveToStorage(); // ✅ Save after error recovery
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      _store.forEach((key, value) {
        toSave[key] = value.toJson();
      });
      final jsonString = jsonEncode(toSave);
      await prefs.setString(_storeKey, jsonString);
      print('💾 Saved ${_store.length} watchlists to storage');
    } catch (e) {
      print('⚠️ Error saving to storage: $e');
    }
  }

  // ✅ Bootstrap - MUST be called on app start
  Future<void> bootstrap() async {
    print('🚀 Bootstrapping WatchlistService...');
    await _loadFromStorage();  // ← Load saved data first
    await refreshList();       // ← Then refresh UI
    print('✅ WatchlistService ready');
  }

  // ✅ FIX: Add save to reorderWatchlistAssets
  Future<WatchlistDetail?> reorderWatchlistAssets({
    required WatchlistId id,
    required List<AssetId> orderedAssetIds,
  }) async {
    try {
      _busy$.add(true);
      _error$.add(null);

      WatchlistDetail updated;

      if (_localMode) {
        final cur = _store[id];
        if (cur == null) throw StateError('Watchlist not found');

        // Validate that all assets exist
        final curSet = cur.assetIds.toSet();
        final newSet = orderedAssetIds.toSet();
        if (!curSet.containsAll(newSet) || curSet.length != newSet.length) {
          throw StateError('Asset list mismatch');
        }

        updated = cur.copyWith(assetIds: orderedAssetIds);
        _store[id] = updated;
        await _saveToStorage(); // ✅ ADDED: Save to storage!
      } else {
        final res = await _api.post(
          endpoint: '/watchlist/reorder',
          body: {'id': id, 'assets': orderedAssetIds},
        );
        updated = WatchlistDetail.fromJson(res as Map<String, dynamic>);
      }

      _detail$.add(updated);
      await refreshList();
      return updated;
    } catch (e) {
      _error$.add(handleApiError(e));
      return null;
    } finally {
      _busy$.add(false);
    }
  }


  void dispose() {
    _watchlists$.close();
    _detail$.close();
    _busy$.close();
    _error$.close();
  }

  // ===================================================
  // Local seed
  // ===================================================

  void _seedLocalIfEmpty() {
    if (_store.isNotEmpty) return;
    _store['w1'] = const WatchlistDetail(
      id: 'w1',
      name: 'My Watchlist',
      assetIds: ['NFLX', 'GOOGL', 'MSFT', 'TCS'],
    );
    _store['w2'] = const WatchlistDetail(
      id: 'w2',
      name: 'Entertainment',
      assetIds: ['NFLX', 'DIS', 'SONY', 'WBD', 'AMZN', 'SPOT', 'RBLX', 'EA', 'TTWO', 'UBI'],
    );
    _store['w3'] = const WatchlistDetail(
      id: 'w3',
      name: 'My Fav Watchlist',
      assetIds: [],
    );
  }

  // ===================================================
  // Queries
  // ===================================================

  Future<void> refreshList() async {
    try {
      _busy$.add(true);
      _error$.add(null);

      if (_localMode) {
        final list = _store.values
            .map((e) => WatchlistSummary(id: e.id, name: e.name, stocksCount: e.stocksCount))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _watchlists$.add(list);
      } else {
        final res = await _api.get(endpoint: _epList); // -> List<Map>
        final list = (res as List)
            .map((j) => WatchlistSummary.fromJson(j as Map<String, dynamic>))
            .toList();
        _watchlists$.add(list);
      }
    } catch (e) {
      _error$.add(handleApiError(e));
    } finally {
      _busy$.add(false);
    }
  }

  Future<void> openDetail(WatchlistId id) async {
    try {
      _busy$.add(true);
      _error$.add(null);

      if (_localMode) {
        final d = _store[id];
        if (d == null) throw StateError('Watchlist not found');
        _detail$.add(d);
      } else {
        final res = await _api.get(endpoint: _epDetail, query: {'id': id});
        _detail$.add(WatchlistDetail.fromJson(res as Map<String, dynamic>));
      }
    } catch (e) {
      _error$.add(handleApiError(e));
    } finally {
      _busy$.add(false);
    }
  }

  // ===================================================
  // Mutations
  // ===================================================

  Future<WatchlistDetail?> createWatchlist(String name) async {
    if (name.trim().isEmpty) {
      _error$.add('Name required');
      return null;
    }

    try {
      _busy$.add(true);
      _error$.add(null);

      WatchlistDetail created;

      if (_localMode) {
        final id = _nextLocalId();
        created = WatchlistDetail(id: id, name: name.trim(), assetIds: const []);
        _store[id] = created;
        await _saveToStorage();
      } else {
        final res = await _api.post(endpoint: _epCreate, body: {'name': name.trim()});
        created = WatchlistDetail.fromJson(res as Map<String, dynamic>);
      }

      await refreshList();
      _detail$.add(created);
      return created;
    } catch (e) {
      _error$.add(handleApiError(e));
      return null;
    } finally {
      _busy$.add(false);
    }
  }

  Future<WatchlistDetail?> editWatchlist({
    required WatchlistId id,
    required String name,
  }) async {
    try {
      _busy$.add(true);
      _error$.add(null);

      WatchlistDetail updated;

      if (_localMode) {
        final old = _store[id];
        if (old == null) throw StateError('Watchlist not found');
        updated = old.copyWith(name: name.trim().isEmpty ? old.name : name.trim());
        _store[id] = updated;
        await _saveToStorage();
      } else {
        final res = await _api.post(endpoint: _epEdit, body: {'id': id, 'name': name});
        updated = WatchlistDetail.fromJson(res as Map<String, dynamic>);
      }

      await refreshList();
      if (_detail$.valueOrNull?.id == id) _detail$.add(updated);
      return updated;
    } catch (e) {
      _error$.add(handleApiError(e));
      return null;
    } finally {
      _busy$.add(false);
    }
  }

  Future<bool> removeWatchlist(WatchlistId id) async {
    try {
      _busy$.add(true);
      _error$.add(null);

      if (_localMode) {
        _store.remove(id);
        await _saveToStorage();
      } else {
        await _api.post(endpoint: _epDelete, body: {'id': id});
      }

      await refreshList();
      if (_detail$.valueOrNull?.id == id) _detail$.add(null);
      return true;
    } catch (e) {
      _error$.add(handleApiError(e));
      return false;
    } finally {
      _busy$.add(false);
    }
  }

  Future<WatchlistDetail?> addToWatchlist({
    required WatchlistId id,
    required List<AssetId> assetIds,
  }) async {
    if (assetIds.isEmpty) return _detail$.valueOrNull;

    final prev = _detail$.valueOrNull;

    try {
      _busy$.add(true);
      _error$.add(null);

      // Optimistic detail update (if currently open)
      if (prev != null && prev.id == id) {
        final optimistic = prev.copyWith(assetIds: {...prev.assetIds, ...assetIds}.toList());
        _detail$.add(optimistic);
      }

      WatchlistDetail updated;

      if (_localMode) {
        final cur = _store[id];
        if (cur == null) throw StateError('Watchlist not found');
        final set = {...cur.assetIds, ...assetIds}.toList();
        updated = cur.copyWith(assetIds: set);
        _store[id] = updated;
        await _saveToStorage();
      } else {
        final res = await _api.post(endpoint: _epAdd, body: {'id': id, 'assets': assetIds});
        updated = WatchlistDetail.fromJson(res as Map<String, dynamic>);
      }

      _detail$.add(updated);
      await refreshList();
      return updated;
    } catch (e) {
      _error$.add(handleApiError(e));
      if (prev != null && prev.id == id) _detail$.add(prev); // rollback
      return prev;
    } finally {
      _busy$.add(false);
    }
  }

  Future<WatchlistDetail?> removeFromWatchlist({
    required WatchlistId id,
    required List<AssetId> assetIds,
  }) async {
    if (assetIds.isEmpty) return _detail$.valueOrNull;

    final prev = _detail$.valueOrNull;

    try {
      _busy$.add(true);
      _error$.add(null);

      // Optimistic
      if (prev != null && prev.id == id) {
        final optimistic =
        prev.copyWith(assetIds: prev.assetIds.where((a) => !assetIds.contains(a)).toList());
        _detail$.add(optimistic);
      }

      WatchlistDetail updated;

      if (_localMode) {
        final cur = _store[id];
        if (cur == null) throw StateError('Watchlist not found');
        final set = cur.assetIds.where((a) => !assetIds.contains(a)).toList();
        updated = cur.copyWith(assetIds: set);
        _store[id] = updated;
        await _saveToStorage();
      } else {
        final res = await _api.post(endpoint: _epRemove, body: {'id': id, 'assets': assetIds});
        updated = WatchlistDetail.fromJson(res as Map<String, dynamic>);
      }

      _detail$.add(updated);
      await refreshList();
      return updated;
    } catch (e) {
      _error$.add(handleApiError(e));
      if (prev != null && prev.id == id) _detail$.add(prev); // rollback
      return prev;
    } finally {
      _busy$.add(false);
    }
  }


  // In a separate StockService or add to existing service

  Future<List<Map<String, dynamic>>> fetchBulkStockData(List<AssetId> assetIds) async {
    if (assetIds.isEmpty) return [];

    try {
      final response = await _api.post(
        endpoint: '/stock/bulk-quotes',
        body: {'symbols': assetIds},
      );

      return List<Map<String, dynamic>>.from(response['stocks'] ?? []);
    } catch (e) {
      print('Error fetching bulk stock data: $e');
      return [];
    }
  }




  // ===================================================
  // Helpers
  // ===================================================

  String _nextLocalId() {
    // simple incremental id generator (w{n+1})
    int max = 0;
    for (final k in _store.keys) {
      if (k.startsWith('w')) {
        final n = int.tryParse(k.substring(1)) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'w${max + 1}';
  }
}
