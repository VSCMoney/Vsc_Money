import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/session_manager.dart';
import 'home/chat_screen.dart';






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


  final baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app"; // 🔥 change when deploying

  Future<void> _searchStock(String symbol) async {
    setState(() {
      _loading = true;
      _stock = null;
    });

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

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("❌ $userFriendly"),
      //     backgroundColor: Colors.red,
      //   ),
      showPortfolioToast(context, userFriendly);
    }
  }


  Future<void> _updatePortfolio({required bool add}) async {
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   // SnackBar(content: Text("✅ ${add ? "Added" : "Removed"} from portfolio")),
      //   showPor
      // );
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
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
                Text(
                  "Portfolio",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF66A00),
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



  List<String> recentSearches = ["Eternal Ltd."];
  List<String> trendingStocks = [
    "Tata Motors Ltd",
    "Reliance Industry",
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
          border: Border.all(color: selected ? Color(0XFFF66A00) : Colors.grey.shade300),
          color: selected ? Color(0XFFF66A00) : Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black,
            )),
      ),
    );
  }

  Widget _buildTrendingItem(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                   color: Colors.black,fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>  Navigator.of(context).pop()
        ),
        title: TextField(
          controller: _controller,
          onSubmitted: _searchStock,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search stocks',
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding:const EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  children: [
                    _buildChip("All", selected: true),
                    _buildChip("Stocks"),
                    _buildChip("MF"),
                    _buildChip("ETF"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _loading
                ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: const CircularProgressIndicator()),
                  ],
                )
                : _stock != null
                ? ListTile(
              title: Row(
                children: [
                  CircleAvatar(
                    child: const Icon(Icons.trending_up, size: 18, color: Colors.black),
                    backgroundColor: Color(0XFFD9D9D9),
                    maxRadius: 15,
                  ),
                  SizedBox(width: 6),

                  /// ✅ Wrap Text in Expanded so it doesn't overflow
                  Expanded(
                    child: Text(
                      _stock!['name'] ?? '',
                      overflow: TextOverflow.ellipsis, // if it's still long
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
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
                        valueColor: AlwaysStoppedAnimation(Color(0XFFF66A00)),
                      ),
                    )
                        : Icon(
                      _isInPortfolio ? Icons.bookmark : Icons.bookmark_outline,
                      color: Color(0XFFF66A00),
                    ),
                  ),
                ],
              ),

                // subtitle: Text("Price: ${_stock!['price']} | Change: ${_stock!['change']}",style: const TextStyle(
              //   fontSize: 14,
              //   fontWeight: FontWeight.bold,
              //     color: Colors.black54
              // ),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockDetailScreen(symbol: _stock!['name'],),
                  ),
                );
              },
            )
                : const SizedBox(),
              const SizedBox(height: 16),
              _loading
                  ? SizedBox.shrink() :  Padding(
                padding:  EdgeInsets.symmetric(horizontal: 15),
                child: const Text("Trending Searches",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),
              _loading
                  ? SizedBox.shrink() :
              // Padding(
              //   padding:  EdgeInsets.symmetric(horizontal: 10),
              //   child: Wrap(
              //     children:
              //     trendingStocks.map((e) => _buildTrendingItem(e)).toList(),
              //   ),
              // ),
              _buildTrendingGrid(trendingStocks),
              // const SizedBox(height: 16),
              // if (_isLoading) const Center(child: CircularProgressIndicator()),
              // if (!_isLoading && _searchResults.isNotEmpty)
              //   Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: _searchResults
              //         .map((stock) => ListTile(
              //       title: Text(stock),
              //       onTap: () {},
              //     ))
              //         .toList(),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTrendingGrid(List<String> trendingLabels) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trendingLabels.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Scroll handled by parent
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5, // Adjust height
      ),
      itemBuilder: (context, index) {
        return _buildTrendingItem(trendingLabels[index]);
      },
    );
  }
}


// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
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
//   Future<void> _searchStock(String query) async {
//     setState(() {
//       _loading = true;
//       _stock = null;
//     });
//
//     final url = Uri.parse("https://fastapi-chatbot-717280964807.asia-south1.run.app//stocks/search?symbol=$query");
//     final res = await http.get(url);
//
//     if (res.statusCode == 200) {
//       final data = json.decode(res.body);
//       setState(() {
//         _stock = data;
//         _isInPortfolio = data['is_in_portfolio'] ?? false;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ ${res.body}")),
//       );
//     }
//
//     setState(() => _loading = false);
//   }
//
// //   Future<void> _updatePortfolio({required bool add}) async {
// //     final token = await FirebaseAuth.instance.currentUser?.getIdToken();
// //     if (token == null || token.isEmpty) {
// //       print("❌ Firebase token missing");
// //       return;
// //     }
// //
// //     final isin = _stock?['isin'];
// //     if (isin == null || isin.isEmpty) {
// //       print("❌ ISIN missing");
// //       return;
// //     }
// //
// //     final url = Uri.parse("$baseUrl/portfolio/add?isin=$isin");
// //     print(isin);
// //     final res = await http.post(
// //       url,
// //       headers: {
// //         'Authorization': 'Bearer $token',
// //         'Content-Type': 'application/x-www-form-urlencoded',
// //       },
// //     );
// //     print("This is my res");
// // print(token);
// //     if (res.statusCode == 200) {
// //       setState(() => _isInPortfolio = add);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("✅ ${add ? "Added" : "Removed"} from portfolio")),
// //       );
// //     } else {
// //       print("❌ Failed to update portfolio: ${res.body}");
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("❌ ${res.body}")),
// //       );
// //     }
// //   }
//
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("✅ ${add ? "Added" : "Removed"} from portfolio")),
//       );
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           controller: _controller,
//           onSubmitted: _searchStock,
//           autofocus: true,
//           decoration: const InputDecoration(
//             hintText: 'Search stocks',
//             border: InputBorder.none,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: Colors.white,
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _stock != null
//           ? ListTile(
//         title: Text(_stock!['name']),
//         subtitle: Text("ISIN: ${_stock!['isin']}"),
//         trailing: IconButton(
//           onPressed: _portfolioLoading
//               ? null
//               : () => _updatePortfolio(add: !_isInPortfolio),
//           icon: _portfolioLoading
//               ? SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation(Color(0XFFF66A00)),
//             ),
//           )
//               : Icon(
//             _isInPortfolio ? Icons.bookmark : Icons.bookmark_outline,
//             color: Color(0XFFF66A00),
//           ),
//         ),
//
//       )
//           : const Center(child: Text("Search for a stock")),
//     );
//   }
// }
//
//
//
