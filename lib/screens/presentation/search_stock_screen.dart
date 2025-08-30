import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/bottomsheet.dart';
import '../../constants/colors.dart';
import '../../services/asset_service.dart';
import '../../services/theme_service.dart';

// import your own classes:
/// import 'package:your_app/theme/app_theme_extension.dart';
/// import 'package:your_app/widgets/chatgpt_bottom_sheet_wrapper.dart';
/// import 'package:your_app/services/asset_service.dart';
/// import 'package:your_app/models/asset_mini.dart';
/// import 'package:your_app/bottom_sheet/bottom_sheet_manager.dart';
/// import 'package:your_app/theme/app_colors.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  late final AssetService _assetService;
  late final StreamSubscription _searchSubscription;

  bool _loading = false;
  String _lastQuery = '';
  List<AssetMini> _results = [];

  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  // ---------- UTIL: always-close keyboard (reliable on iOS & Android) ----------
  void _closeKeyboard() {
    // 1) Unfocus the text field we control
    if (_focusNode.hasFocus) _focusNode.unfocus();

    // 2) Also clear any other primary focus in case AppBar has its own scope
    FocusManager.instance.primaryFocus?.unfocus();

    // 3) Tell the system keyboard to hide (covers iOS cases with sheets)
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void initState() {
    super.initState();

    _assetService = AssetService();

    _searchSubscription = _assetService.searchResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    });

    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchSubscription.cancel();
    _assetService.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- Recent searches ----------------

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey);
      if (searches != null) {
        if (!mounted) return;
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

  // Search (keeps keyboard open while typing)
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

    _saveRecentSearch(keyword);
    _assetService.setSearchQuery(keyword); // debounced inside service
  }

  // Submit (auto-close keyboard)
  void _onSearchSubmitted(String value) {
    _closeKeyboard();            // <— force close
    _searchStock(value);
  }

  void _openStockDetailSheet(String assetId) {
    _closeKeyboard();            // <— force close before opening sheet

    // Open sheet on next frame to ensure IME is already dismissed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockSheet = BottomSheetManager.buildStockDetailSheet(
        assetId: assetId,
        onTap: () => _sheetKey.currentState?.closeSheet(),
      );
      _sheetKey.currentState?.openSheet(stockSheet);
    });
  }

  // ---------------- UI ----------------

  List<String> trendingStocks = const ["Tata Motors", "Reliance", "BSE", "Tata Steel"];

  Widget _buildChip(String label, {bool selected = false, VoidCallback? onTap}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return GestureDetector(
      onTap: () {
        _closeKeyboard(); // <— close when tapping filters
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? theme.box : theme.box,
          ),
          color: selected ? AppColors.primary : theme.box,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: selected ? Colors.white : theme.text,
            fontFamily: 'SF Pro',
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
      child: GestureDetector(
        // Dismiss keyboard when tapping outside ANYWHERE
        onTap: _closeKeyboard,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            backgroundColor: theme.background,
            // extendBody: true,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.icon, size: 24),
                onPressed: () {
                  _closeKeyboard(); // <— make sure it closes on back
                  Navigator.of(context).pop();
                },
              ),
              titleSpacing: 0,
              title: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: _onSearchSubmitted, // closes keyboard
                onChanged: _searchStock,         // real-time, keep open
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.text,
                  fontFamily: 'SF Pro',
                ),
                decoration: InputDecoration(
                  hintText: 'Search stocks',
                  hintStyle: TextStyle(
                    color: theme.text.withOpacity(0.6),
                    fontSize: 16,
                    fontFamily: 'SF Pro',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                ),
              ),
              backgroundColor: theme.box,
              surfaceTintColor: theme.background,
              shadowColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle:  SystemUiOverlayStyle(
                statusBarColor: theme.box,
                statusBarIconBrightness: Brightness.dark,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: SingleChildScrollView(
                  // Also dismiss on scroll gestures
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
          
                      // Filter chips
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
          
                      // Recent searches
                      if (!_loading && _results.isEmpty && _lastQuery.isEmpty && _recentSearches.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._recentSearches.take(3).map(
                                  (term) => InkWell(
                                onTap: () {
                                  _controller.text = term;
                                  _onSearchSubmitted(term); // closes inside
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
                                            fontFamily: 'SF Pro',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                                        onPressed: () {
                                          _closeKeyboard();
                                          _removeRecentSearch(term);
                                        },
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
          
                      // Results
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
                                    const CircleAvatar(
                                      child: Icon(Icons.trending_up, size: 18, color: Colors.black),
                                      backgroundColor: Color(0xFFD9D9D9),
                                      maxRadius: 15,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        asset.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'SF Pro',
                                          color: theme.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _openStockDetailSheet(asset.id), // closes + opens sheet
                              );
                            }).toList(),
                          ),
                        ),
          
                      // No results
                      if (!_loading && _results.isEmpty && _lastQuery.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                          child: Text(
                            'No results for "$_lastQuery"',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontFamily: 'SF Pro',
                            ),
                          ),
                        ),
          
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
                  _onSearchSubmitted(label); // closes inside
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
                            fontFamily: 'SF Pro',
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

