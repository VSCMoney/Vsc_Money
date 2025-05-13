import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/session_manager.dart';
import '../stock_detail_screen.dart';
import 'home/chat_screen.dart';






// class StockSearchScreen extends StatefulWidget {
//   const StockSearchScreen({super.key});
//
//   @override
//   State<StockSearchScreen> createState() => _StockSearchScreenState();
// }
//
// class _StockSearchScreenState extends State<StockSearchScreen> {
//   final TextEditingController _controller = TextEditingController();
//   Map<String, dynamic>? _stock;
//   bool _loading = false;
//   bool _isInPortfolio = false;
//   bool _portfolioLoading = false; // 🔁 Loader flag
//
//
//   final baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app"; // 🔥 change when deploying
//
//   Future<void> _searchStock(String symbol) async {
//     setState(() {
//       _loading = true;
//       _stock = null;
//     });
//
//     final url = Uri.parse("$baseUrl/stocks/search?symbol=$symbol");
//     final token = await FirebaseAuth.instance.currentUser?.getIdToken();
//
//     final res = await http.get(url, headers: {
//       'Authorization': 'Bearer $token',
//     });
//
//     setState(() => _loading = false);
//
//     if (res.statusCode == 200) {
//       final data = json.decode(res.body);
//       setState(() {
//         _stock = data;
//         _isInPortfolio = data["in_portfolio"] ?? false;
//       });
//     } else {
//       print("❌ Failed to search: ${res.body}");
//
//       final errorMsg = json.decode(res.body)['detail'];
//       final userFriendly = errorMsg.contains("404") ? "Stock not available" : "";
//
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(
//       //     content: Text("❌ $userFriendly"),
//       //     backgroundColor: Colors.red,
//       //   ),
//       showPortfolioToast(context, userFriendly);
//     }
//   }
//
//
//   Future<void> _updatePortfolio({required bool add}) async {
//     final token = await FirebaseAuth.instance.currentUser?.getIdToken();
//     if (token == null || token.isEmpty) {
//       print("❌ Firebase token missing");
//       return;
//     }
//
//     final isin = _stock?['isin'];
//     if (isin == null || isin.isEmpty) {
//       print("❌ ISIN missing");
//       return;
//     }
//
//     setState(() => _portfolioLoading = true); // ⏳ Show loader
//
//     final action = add ? "add" : "remove";
//     final url = Uri.parse("$baseUrl/portfolio/$action?isin=$isin");
//
//     final res = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//     );
//
//     setState(() => _portfolioLoading = false); // ✅ Hide loader
//
//     if (res.statusCode == 200) {
//       setState(() => _isInPortfolio = add);
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   // SnackBar(content: Text("✅ ${add ? "Added" : "Removed"} from portfolio")),
//       //   showPor
//       // );
//       showPortfolioToast(context, "${add ? "Added" : "Removed"} to portfolio");
//     } else {
//       print("❌ Failed to update portfolio: ${res.body}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ ${res.body}")),
//       );
//     }
//   }
//
//
//
//   void showPortfolioToast(BuildContext context, String message, {bool isAdded = true}) {
//     final overlay = Overlay.of(context);
//     final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
//     final entry = OverlayEntry(
//       builder: (context) => Positioned(
//         bottom: (keyboardHeight > 0 ? keyboardHeight : 20) + 50,
//         left: 20,
//         right: 20,
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF1F1F1),
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.bookmark, size: 18, color: Colors.grey.shade600),
//                     const SizedBox(width: 8),
//                     Text(
//                       message,
//                       style: const TextStyle(fontSize: 14, color: Colors.black),
//                     ),
//                   ],
//                 ),
//                 Text(
//                   "Portfolio",
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFFF66A00),
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//
//     overlay.insert(entry);
//
//     Future.delayed(const Duration(seconds: 2), () => entry.remove());
//   }
//
//
//
//   List<String> recentSearches = ["Eternal Ltd."];
//   List<String> trendingStocks = [
//     "Tata Motors Ltd",
//     "Reliance Industry",
//     "BSE Ltd",
//     "Tata Steel Ltd"
//   ];
//
//
//
//   Widget _buildChip(String label, {bool selected = false, VoidCallback? onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         margin: const EdgeInsets.symmetric(horizontal: 6),
//         decoration: BoxDecoration(
//           border: Border.all(color: selected ? Color(0XFFF66A00) : Colors.grey.shade300),
//           color: selected ? Color(0XFFF66A00) : Colors.white,
//           borderRadius: BorderRadius.circular(7),
//         ),
//         child: Text(label,
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: selected ? Colors.white : Colors.black,
//             )),
//       ),
//     );
//   }
//
//   // Widget _buildTrendingItem(String label) {
//   //   return Container(
//   //     margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
//   //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//   //     decoration: BoxDecoration(
//   //       border: Border.all(color: Colors.grey.shade300),
//   //       borderRadius: BorderRadius.circular(12),
//   //     ),
//   //     child: Row(
//   //       mainAxisSize: MainAxisSize.min,
//   //       children: [
//   //         const Icon(Icons.trending_up, size: 20, color: Colors.grey),
//   //         const SizedBox(width: 10),
//   //         Text(label,
//   //             textAlign: TextAlign.center,
//   //             overflow: TextOverflow.ellipsis,
//   //             style: const TextStyle(
//   //                  color: Colors.black,fontSize: 12)),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () =>  Navigator.of(context).pop()
//         ),
//         title: TextField(
//           controller: _controller,
//           onSubmitted: _searchStock,
//           autofocus: true,
//           decoration: const InputDecoration(
//             hintText: 'Search stocks',
//             border: InputBorder.none,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 2),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 16),
//               Padding(
//                 padding:const EdgeInsets.symmetric(horizontal: 10),
//                 child: Wrap(
//                   children: [
//                     _buildChip("All", selected: true),
//                     _buildChip("Stocks"),
//                     _buildChip("MF"),
//                     _buildChip("ETF"),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _loading
//                 ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Center(child: const CircularProgressIndicator()),
//                   ],
//                 )
//                 : _stock != null
//                 ? ListTile(
//               title: Row(
//                 children: [
//                   CircleAvatar(
//                     child: const Icon(Icons.trending_up, size: 18, color: Colors.black),
//                     backgroundColor: Color(0XFFD9D9D9),
//                     maxRadius: 15,
//                   ),
//                   SizedBox(width: 6),
//
//                   /// ✅ Wrap Text in Expanded so it doesn't overflow
//                   Expanded(
//                     child: Text(
//                       _stock!['name'] ?? '',
//                       overflow: TextOverflow.ellipsis, // if it's still long
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//
//                   IconButton(
//                     onPressed: _portfolioLoading
//                         ? null
//                         : () => _updatePortfolio(add: !_isInPortfolio),
//                     icon: _portfolioLoading
//                         ? SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation(Color(0XFFF66A00)),
//                       ),
//                     )
//                         : Icon(
//                       _isInPortfolio ? Icons.bookmark : Icons.bookmark_outline,
//                       color: Color(0XFFF66A00),
//                     ),
//                   ),
//                 ],
//               ),
//
//                 // subtitle: Text("Price: ${_stock!['price']} | Change: ${_stock!['change']}",style: const TextStyle(
//               //   fontSize: 14,
//               //   fontWeight: FontWeight.bold,
//               //     color: Colors.black54
//               // ),),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => StockDetailScreen(symbol: _stock!['name'],),
//                   ),
//                 );
//               },
//             )
//                 : const SizedBox(),
//               const SizedBox(height: 16),
//               _loading
//                   ? SizedBox.shrink() :  Padding(
//                 padding:  EdgeInsets.symmetric(horizontal: 15),
//                 child: const Text("Trending Searches",
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//               ),
//               const SizedBox(height: 10),
//               _loading
//                   ? SizedBox.shrink() :
//               // Padding(
//               //   padding:  EdgeInsets.symmetric(horizontal: 10),
//               //   child: Wrap(
//               //     children:
//               //     trendingStocks.map((e) => _buildTrendingItem(e)).toList(),
//               //   ),
//               // ),
//               _buildTrendingGrid(trendingStocks),
//               // const SizedBox(height: 16),
//               // if (_isLoading) const Center(child: CircularProgressIndicator()),
//               // if (!_isLoading && _searchResults.isNotEmpty)
//               //   Column(
//               //     crossAxisAlignment: CrossAxisAlignment.start,
//               //     children: _searchResults
//               //         .map((stock) => ListTile(
//               //       title: Text(stock),
//               //       onTap: () {},
//               //     ))
//               //         .toList(),
//               //   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   Widget _buildTrendingGrid(List<String> trendingLabels) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: trendingLabels.length,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2, // Fixed to 2 columns
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         mainAxisExtent: 55, // Fixed height instead of using childAspectRatio
//       ),
//       itemBuilder: (context, index) {
//         return _buildTrendingItem(trendingLabels[index]);
//       },
//     );
//   }
//
// // Improved trending item with auto text wrapping
//   Widget _buildTrendingItem(String label) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       child: Row(
//         children: [
//           Icon(Icons.trending_up, size: 16, color: Colors.blue.shade700),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               label,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _stock;
  bool _loading = false;
  bool _isInPortfolio = false;
  bool _portfolioLoading = false; // 🔁 Loader flag

  // Keep track of recent searches
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  final baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app"; // 🔥 change when deploying

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  // Load recent searches from local storage
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? searches = prefs.getStringList(_recentSearchesKey);

      if (searches != null) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print("❌ Error loading recent searches: $e");
    }
  }

  // Save recent searches to local storage
  Future<void> _saveRecentSearch(String symbol) async {
    try {
      // Don't add if already exists
      if (_recentSearches.contains(symbol)) {
        // Move to the top if it exists
        setState(() {
          _recentSearches.remove(symbol);
          _recentSearches.insert(0, symbol);
        });
      } else {
        // Add to the beginning of the list
        setState(() {
          _recentSearches.insert(0, symbol);
          // Keep only the last 5 searches
          if (_recentSearches.length > 5) {
            _recentSearches = _recentSearches.sublist(0, 5);
          }
        });
      }

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      print("❌ Error saving recent search: $e");
    }
  }

  // Remove a recent search
  Future<void> _removeRecentSearch(String symbol) async {
    try {
      setState(() {
        _recentSearches.remove(symbol);
      });

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      print("❌ Error removing recent search: $e");
    }
  }

  Future<void> _searchStock(String symbol) async {
    if (symbol.isEmpty) return;

    setState(() {
      _loading = true;
      _stock = null;
    });

    // Save to recent searches
    await _saveRecentSearch(symbol);

    final url = Uri.parse("$baseUrl/stocks/search?symbol=$symbol");
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    setState(() => _loading = false);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _stock = data;
        _isInPortfolio = data["in_portfolio"] ?? false;
      });
    } else {
      print("❌ Failed to search: ${res.body}");

      final errorMsg = json.decode(res.body)['detail'];
      final userFriendly = errorMsg.contains("404") ? "Stock not available" : "";

      showPortfolioToast(context, userFriendly);
    }
  }



  void _showAnimatedPortfolioSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: BottomSheetDemo( // proceed with backend call
          ),
        );
      },
    );
  }


  Future<void> _updatePortfolio({required bool add}) async {
    //_showAnimatedPortfolioSheet(context);
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      print("❌ Firebase token missing");
      return;
    }

    final isin = _stock?['isin'];
    if (isin == null || isin.isEmpty) {
      print("❌ ISIN missing");
      return;
    }

    setState(() => _portfolioLoading = true); // ⏳ Show loader

    final action = add ? "add" : "remove";
    final url = Uri.parse("$baseUrl/portfolio/$action?isin=$isin");

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    setState(() => _portfolioLoading = false); // ✅ Hide loader

    if (res.statusCode == 200) {
      setState(() => _isInPortfolio = add);
      showPortfolioToast(context, "${add ? "Added" : "Removed"} to portfolio");
    } else {
      print("❌ Failed to update portfolio: ${res.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${res.body}")),
      );
    }
  }

  void showPortfolioToast(BuildContext context, String message, {bool isAdded = true}) {
    final overlay = Overlay.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: (keyboardHeight > 0 ? keyboardHeight : 20) + 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
                const Text(
                  "Portfolio",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF66A00),
                    fontFamily: 'SF Pro Display',
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  List<String> trendingStocks = [
    "Tata Motors Ltd",
    "Reliance Industries Ltd",
    "BSE Ltd",
    "Tata Steel Ltd"
  ];

  Widget _buildChip(String label, {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? const Color(0xFFF66A00) : Colors.grey.shade300),
          color: selected ? const Color(0xFFF66A00) : Colors.white,
          borderRadius: BorderRadius.circular(10), // More rounded to match screenshot
        ),
        child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: selected ? Colors.white : Colors.black,
              fontFamily: 'SF Pro Display',
            )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;

    // Adjust padding based on device size
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => Navigator.of(context).pop()
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          onSubmitted: _searchStock,
          autofocus: true,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontFamily: 'SF Pro Display',
          ),
          decoration: const InputDecoration(
            hintText: 'Search stocks',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontFamily: 'SF Pro Display',
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        backgroundColor: Colors.white,
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

                // Recent search items with remove button
                if (!_loading && _stock == null && _recentSearches.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show only the first few recent searches
                      ..._recentSearches.take(3).map((searchTerm) =>
                          InkWell(
                            onTap: () => _searchStock(searchTerm),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                              child: Row(
                                children: [
                                  // History icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.history,
                                        size: 18,
                                        color: Colors.black54
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Search term
                                  Expanded(
                                    child: Text(
                                      searchTerm,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Cross/remove button
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () => _removeRecentSearch(searchTerm),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                      ).toList(),
                    ],
                  ),

                // Loading indicator
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFFF66A00)),
                    ),
                  ),

                // Search result
                if (!_loading && _stock != null)
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                            _stock!['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _portfolioLoading
                              ? null
                              : () => _updatePortfolio(add: !_isInPortfolio),
                          icon: _portfolioLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFF66A00)),
                            ),
                          )
                              : Icon(
                            _isInPortfolio ? Icons.bookmark : Icons.bookmark_outline,
                            color: const Color(0xFFF66A00),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(symbol: _stock!['name']),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Trending searches title
                if (!_loading)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const Text(
                        "Trending Searches",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'SF Pro Display',
                        )
                    ),
                  ),

                const SizedBox(height: 12),

                // Trending searches grid
                if (!_loading)
                  _buildTrendingGrid(trendingStocks),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingGrid(List<String> trendingLabels) {
    // Calculate responsive padding based on screen size
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
              gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Use a fixed height that will adjust based on content
                mainAxisExtent: 56,
              ),
              itemBuilder: (context, index) {
                return _buildTrendingItem(trendingLabels[index]);
              },
            );
          }
      ),
    );
  }

  Widget _buildTrendingItem(String label) {
    return InkWell(
      onTap: () => _searchStock(label),
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
            Icon(
                Icons.trending_up,
                size: 16,
                color: Colors.grey.shade600
            ),
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
  }
}


class BottomSheetDemo extends StatelessWidget {
  const BottomSheetDemo({super.key});

  void _showAnimatedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.3),
      backgroundColor: Colors.transparent,
      builder: (_) => const _BottomSheetContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Demo")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showAnimatedSheet(context),
          child: const Text("Show BottomSheet"),
        ),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.all(16),
          itemCount: 20,
          itemBuilder: (_, index) => ListTile(
            leading: const Icon(Icons.star),
            title: Text("Item ${index + 1}"),
          ),
        ),
      ),
    );
  }
}