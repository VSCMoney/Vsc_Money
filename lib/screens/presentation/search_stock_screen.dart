import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/bottomsheet.dart';
import '../../services/asset_service.dart';
import '../../services/theme_service.dart';
// If you’ll open details, keep whichever you use:
// import '../asset_page/assets_page.dart';
// Or use your bottom sheet manager in onTap (commented below).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  // ✅ Replace API calls with AssetService
  late final AssetService _assetService;
  late final StreamSubscription _searchSubscription;

  bool _loading = false;
  String _lastQuery = '';
  List<AssetMini> _results = []; // ✅ Use AssetMini from AssetService

  // Recent searches (local)
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();

    // ✅ Initialize AssetService
    _assetService = AssetService();

    // ✅ Listen to search results stream
    _searchSubscription = _assetService.searchResults.listen((results) {
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    });

    _loadRecentSearches();
  }

  @override
  void dispose() {
    // ✅ Clean up AssetService and subscription
    _searchSubscription.cancel();
    _assetService.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------- Recent searches ----------------

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey);
      if (searches != null) {
        setState(() => _recentSearches = searches);
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String q) async {
    try {
      final term = q.trim();
      if (term.isEmpty) return;

      if (_recentSearches.contains(term)) {
        setState(() {
          _recentSearches.remove(term);
          _recentSearches.insert(0, term);
        });
      } else {
        setState(() {
          _recentSearches.insert(0, term);
          if (_recentSearches.length > 5) {
            _recentSearches = _recentSearches.sublist(0, 5);
          }
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String term) async {
    try {
      setState(() => _recentSearches.remove(term));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (_) {}
  }

  // ✅ Updated search method using AssetService
  void _searchStock(String raw) {
    final keyword = raw.trim();
    if (keyword.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _lastQuery = keyword;
    });

    // Save to recent searches
    _saveRecentSearch(keyword);

    // ✅ Use AssetService search (debounced automatically)
    _assetService.setSearchQuery(keyword);
  }

  // // ✅ Navigate to asset details (implement based on your navigation pattern)
  // void _openAssetDetails(AssetMini asset) {
  //   // TODO: Implement navigation to asset details
  //   // Option 1: Using your existing bottom sheet
  //   // BottomSheetManager.buildStockDetailSheet(
  //   //   assetId: asset.id,
  //   //   onTap: () => Navigator.pop(context),
  //   // );
  //
  //   // Option 2: Navigate to dedicated page
  //   // Navigator.push(context, MaterialPageRoute(
  //   //   builder: (_) => AssetDetailsPage(assetId: asset.id, assetName: asset.name),
  //   // ));
  //
  //   // Option 3: Return selected asset to parent
  //   Navigator.pop(context, asset);
  //
  //   print("Selected asset: ${asset.name} (${asset.id})");
  // }

  void _openStockDetailSheet(String assetId) {
    print(assetId);
    final stockSheet = BottomSheetManager.buildStockDetailSheet(
      assetId: assetId,
      onTap: () => _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(stockSheet);
  }

  // ---------------- UI ----------------

  List<String> trendingStocks = const [
    "Tata Motors",
    "Reliance",
    "BSE",
    "Tata Steel",
  ];

  Widget _buildChip(String label, {bool selected = false, VoidCallback? onTap}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFFF66A00) : Colors.grey.shade300,
          ),
          color: selected ? const Color(0xFFF66A00) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: selected ? Colors.white : theme.text,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return ChatGPTBottomSheetWrapper(
      key: _sheetKey,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.icon, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: TextField(
            controller: _controller,
            onSubmitted: _searchStock, // 🔎 hit enter to search
            onChanged: _searchStock,   // ✅ Search on every keystroke (debounced by AssetService)
            autofocus: true,
            style: TextStyle(
              fontSize: 16,
              color: theme.text,
              fontFamily: 'SF Pro Display',
            ),
            decoration: InputDecoration(
              hintText: 'Search stocks',
              hintStyle: TextStyle(
                color: theme.text.withOpacity(0.6),
                fontSize: 16,
                fontFamily: 'SF Pro Display',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          backgroundColor: theme.background,
          elevation: 1,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Filter chips (static as requested)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 8),
                        _buildChip("All", selected: true),
                        _buildChip("Stocks"),
                        _buildChip("MF"),
                        _buildChip("ETF"),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent searches when nothing shown
                  if (!_loading && _results.isEmpty && _lastQuery.isEmpty && _recentSearches.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._recentSearches.take(3).map(
                              (term) => InkWell(
                            onTap: () {
                              _controller.text = term;
                              _searchStock(term);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.history, size: 18, color: Colors.black54),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      term,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                                    onPressed: () => _removeRecentSearch(term),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Loading
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: Color(0xFFF66A00)),
                      ),
                    ),

                  // ✅ Updated Results using AssetMini
                  if (!_loading && _results.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _results.map((asset) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                CircleAvatar(
                                  child: const Icon(Icons.trending_up, size: 18, color: Colors.black),
                                  backgroundColor: const Color(0xFFD9D9D9),
                                  maxRadius: 15,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    asset.name, // ✅ Use AssetMini.name
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'SF Pro Display',
                                      color: theme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _openStockDetailSheet(asset.id);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  // No results (after a query)
                  if (!_loading && _results.isEmpty && _lastQuery.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                      child: Text(
                        'No results for "$_lastQuery"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Trending (static as requested)
                  // if (!_loading)
                  //   Padding(
                  //     padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  //     child: const Text(
                  //       "Trending Searches",
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.bold,
                  //         fontSize: 18,
                  //         fontFamily: 'SF Pro Display',
                  //       ),
                  //     ),
                  //   ),
                  // const SizedBox(height: 12),
                  // if (!_loading) _buildTrendingGrid(trendingStocks),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingGrid(List<String> trendingLabels) {
    final double padding = MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: trendingLabels.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 56,
            ),
            itemBuilder: (context, index) {
              final label = trendingLabels[index];
              return InkWell(
                onTap: () {
                  _controller.text = label;
                  _searchStock(label);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
