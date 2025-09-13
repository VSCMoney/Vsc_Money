import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/bottomsheet.dart';
import '../../constants/colors.dart';
import '../../services/asset_service.dart';
import '../../services/theme_service.dart';


// class StockSearchScreen extends StatefulWidget {
//   final VoidCallback? onBack;
//
//   /// Pass the global/root ChatGPTBottomSheetWrapper key if available.
//   /// When provided, we use that wrapper to open sheets so they are NOT clipped by the drawer.
//   final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetHostKey;
//
//   const StockSearchScreen({super.key, this.onBack, this.sheetHostKey});
//
//   @override
//   State<StockSearchScreen> createState() => _StockSearchScreenState();
// }
//
// class _StockSearchScreenState extends State<StockSearchScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   // Local wrapper is still here, but only used if no host key is provided.
//   final GlobalKey<ChatGPTBottomSheetWrapperState> _localSheetKey =
//   GlobalKey(debugLabel: 'StockSearchLocalSheet');
//
//   late final AssetService _assetService;
//   late final StreamSubscription _searchSubscription;
//
//   bool _loading = false;
//   String _lastQuery = '';
//   List<AssetMini> _results = [];
//
//   List<String> _recentSearches = [];
//   static const String _recentSearchesKey = 'recent_searches';
//
//   void _closeKeyboard() {
//     if (_focusNode.hasFocus) _focusNode.unfocus();
//     FocusManager.instance.primaryFocus?.unfocus();
//     SystemChannels.textInput.invokeMethod('TextInput.hide');
//   }
//
//   Future<bool> _handleBackNavigation() async {
//     _closeKeyboard();
//     if (widget.onBack != null) {
//       widget.onBack!();
//       return false;
//     }
//     return true;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _assetService = AssetService();
//     _searchSubscription = _assetService.searchResults.listen((results) {
//       if (!mounted) return;
//       setState(() {
//         _results = results;
//         _loading = false;
//       });
//     });
//     _loadRecentSearches();
//   }
//
//   @override
//   void dispose() {
//     _searchSubscription.cancel();
//     _assetService.dispose();
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadRecentSearches() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final searches = prefs.getStringList(_recentSearchesKey);
//       if (!mounted) return;
//       setState(() => _recentSearches = searches ?? []);
//     } catch (_) {}
//   }
//
//   Future<void> _saveRecentSearch(String q) async {
//     try {
//       final term = q.trim();
//       if (term.isEmpty) return;
//       if (_recentSearches.contains(term)) {
//         setState(() {
//           _recentSearches.remove(term);
//           _recentSearches.insert(0, term);
//         });
//       } else {
//         setState(() {
//           _recentSearches.insert(0, term);
//           if (_recentSearches.length > 5) {
//             _recentSearches = _recentSearches.sublist(0, 5);
//           }
//         });
//       }
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setStringList(_recentSearchesKey, _recentSearches);
//     } catch (_) {}
//   }
//
//   Future<void> _removeRecentSearch(String term) async {
//     try {
//       setState(() => _recentSearches.remove(term));
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setStringList(_recentSearchesKey, _recentSearches);
//     } catch (_) {}
//   }
//
//   void _searchStock(String raw) {
//     final keyword = raw.trim();
//     if (keyword.isEmpty) {
//       setState(() {
//         _results = [];
//         _lastQuery = '';
//         _loading = false;
//       });
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _lastQuery = keyword;
//     });
//     _saveRecentSearch(keyword);
//     _assetService.setSearchQuery(keyword);
//   }
//
//   void _onSearchSubmitted(String value) {
//     _closeKeyboard();
//     _searchStock(value);
//   }
//
//   // 🔑 Open sheet using: host wrapper (preferred) → local wrapper → root modal sheet
//   void _openStockDetailSheet(String assetId) {
//     _closeKeyboard();
//
//     final stockSheet = BottomSheetManager.buildStockDetailSheet(
//       assetId: assetId,
//       onTap: () {
//         // Close whichever wrapper we used
//         widget.sheetHostKey?.currentState?.closeSheet();
//         _localSheetKey.currentState?.closeSheet();
//       },
//     );
//
//     // 1) Prefer a root/host wrapper if provided (won't be clipped by drawer)
//     final hostState = widget.sheetHostKey?.currentState;
//     if (hostState != null && hostState.mounted) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         hostState.openSheet(stockSheet);
//       });
//       return;
//     }
//
//     // 2) Else try local wrapper (works when screen is full width)
//     final localState = _localSheetKey.currentState;
//     if (localState != null && localState.mounted) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         localState.openSheet(stockSheet);
//       });
//       return;
//     }
//
//     // 3) Last resort: root modal bottom sheet
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     showModalBottomSheet(
//       context: context,
//       useRootNavigator: true,
//       isScrollControlled: true,
//       backgroundColor: theme.background,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
//       ),
//       builder: (_) => SafeArea(top: false, child: stockSheet),
//     );
//   }
//
//   // UI helpers
//   List<String> trendingStocks = const ["Tata Motors", "Reliance", "BSE", "Tata Steel"];
//
//   Widget _buildChip(String label, {bool selected = false, VoidCallback? onTap}) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     return GestureDetector(
//       onTap: () {
//         _closeKeyboard();
//         onTap?.call();
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
//         margin: const EdgeInsets.symmetric(horizontal: 6),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: selected ? AppColors.black : AppColors.black.withOpacity(0.25),
//           ),
//           color: selected ? AppColors.primary.withOpacity(0.2) : theme.box,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//             color: selected ? Colors.black : theme.text,
//             fontFamily: 'DM Sans',
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isTablet = screenWidth > 600;
//     final horizontalPadding = isTablet ? 24.0 : 16.0;
//
//     final content = PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         if (!didPop) {
//           await _handleBackNavigation();
//         }
//       },
//       child: GestureDetector(
//         onTap: _closeKeyboard,
//         child: SafeArea(
//           top: false,
//           bottom: false,
//           child: Scaffold(
//             backgroundColor: theme.background,
//             appBar: AppBar(
//               leading: IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.icon, size: 24),
//                 onPressed: () {
//                   HapticFeedback.mediumImpact();
//                   _handleBackNavigation();
//                 },
//               ),
//               titleSpacing: 0,
//               title: TextField(
//                 controller: _controller,
//                 focusNode: _focusNode,
//                 onSubmitted: _onSearchSubmitted,
//                 onChanged: _searchStock,
//                 autofocus: true,
//                 textInputAction: TextInputAction.search,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: theme.text,
//                   fontFamily: 'DM Sans',
//                 ),
//                 decoration: InputDecoration(
//                   hintText: 'Search stocks',
//                   hintStyle: TextStyle(
//                     color: theme.text.withOpacity(0.6),
//                     fontSize: 16,
//                     fontFamily: 'DM Sans',
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
//                 ),
//               ),
//               backgroundColor: theme.background,
//               surfaceTintColor: theme.background,
//               shadowColor: Colors.transparent,
//               systemOverlayStyle: SystemUiOverlayStyle(
//                 statusBarColor: theme.background,
//                 statusBarIconBrightness: Brightness.dark,
//               ),
//             ),
//             body: SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
//                 child: SingleChildScrollView(
//                   keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Divider(thickness: 0, color: Colors.grey.withOpacity(0.5)),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         height: 30,
//                         child: ListView(
//                           scrollDirection: Axis.horizontal,
//                           children: [
//                             const SizedBox(width: 8),
//                             _buildChip("All", selected: true),
//                             _buildChip("Stocks"),
//                             _buildChip("MF"),
//                             _buildChip("ETF"),
//                             const SizedBox(width: 8),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       if (!_loading && _results.isEmpty && _lastQuery.isEmpty && _recentSearches.isNotEmpty)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ..._recentSearches.take(3).map(
//                                   (term) => InkWell(
//                                 onTap: () {
//                                   _controller.text = term;
//                                   _onSearchSubmitted(term);
//                                 },
//                                 child: Padding(
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: horizontalPadding,
//                                     vertical: 8,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.all(8),
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey.shade200,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: const Icon(Icons.history, size: 18, color: Colors.black54),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Text(
//                                           term,
//                                           style: const TextStyle(fontSize: 16, fontFamily: 'DM Sans'),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
//                                         onPressed: () {
//                                           _closeKeyboard();
//                                           _removeRecentSearch(term);
//                                         },
//                                         constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
//                                         padding: EdgeInsets.zero,
//                                         splashRadius: 20,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       if (_loading)
//                         const Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(24.0),
//                             child: CircularProgressIndicator(color: Color(0xFFF66A00)),
//                           ),
//                         ),
//                       if (!_loading && _results.isNotEmpty)
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: _results.map((asset) {
//                               return ListTile(
//                                 contentPadding: EdgeInsets.zero,
//                                 title: Row(
//                                   children: [
//                                     const CircleAvatar(
//                                       child: Icon(Icons.trending_up, size: 18, color: Colors.black),
//                                       backgroundColor: Color(0xFFD9D9D9),
//                                       maxRadius: 15,
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text(
//                                         asset.name,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontFamily: 'DM Sans',
//                                           color: theme.text,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 onTap: () => _openStockDetailSheet(asset.id),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       if (!_loading && _results.isEmpty && _lastQuery.isNotEmpty)
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
//                           child: Text(
//                             'No results for "$_lastQuery"',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                               fontFamily: 'DM Sans',
//                             ),
//                           ),
//                         ),
//                       const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//
//     // If a host (root) sheet is provided, DON'T wrap locally (avoids double overlays).
//     return widget.sheetHostKey == null
//         ? ChatGPTBottomSheetWrapper(key: _localSheetKey, child: content)
//         : content;
//   }
// }



class StockSearchScreen extends StatefulWidget {
  VoidCallback? onBack;
   StockSearchScreen({super.key, this.onBack});

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

  // Handle back navigation - go to home and open drawer
  Future<bool> _handleBackNavigation() async {
    debugPrint('Back pressed from StockSearch - navigating to home with drawer open');

    _closeKeyboard(); // Close keyboard first

    // Go back to home and open drawer
    context.pop();

    // Open the drawer after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldState = Scaffold.maybeOf(context);
      if (scaffoldState != null && scaffoldState.hasDrawer) {
        scaffoldState.openDrawer();
      }
    });

    return false; // Prevent default back behavior since we're handling it
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.black.withOpacity(0.25),
          ),
          color: selected ? AppColors.primary.withOpacity(0.2) : theme.box,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: selected ? Colors.black : theme.text,
            fontFamily: 'DM Sans',
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
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            await _handleBackNavigation();
          }
        },
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
                    HapticFeedback.mediumImpact();
                    _handleBackNavigation(); // Use our custom navigation handler
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
                    fontFamily: 'DM Sans',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search stocks',
                    hintStyle: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                ),
                backgroundColor: theme.background,
                surfaceTintColor: theme.background,
                shadowColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: theme.background,
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
                        Divider(thickness: 0, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),

                        // Filter chips
                        SizedBox(
                          height: 30,
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
                                              fontFamily: 'DM Sans',
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
                                            fontFamily: 'DM Sans',
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
                                fontFamily: 'DM Sans',
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
                            fontFamily: 'DM Sans',
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

