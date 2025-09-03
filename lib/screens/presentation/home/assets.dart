


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/screens/widgets/drawer.dart';

import '../../../constants/app_bar.dart';
import '../../../constants/bottomsheet.dart';
import '../../../main.dart';
import '../../../services/theme_service.dart';
import 'home_screen.dart';

class AssetItem {
  final String title;
  final double amount;
  final double change;
  final double changePercent;
  final bool isGain;

  AssetItem({
    required this.title,
    required this.amount,
    required this.change,
    required this.changePercent,
  }) : isGain = change >= 0;
}

class PortfolioScreen extends StatefulWidget {
   PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey();

  // You can replace this with actual API response
  List<AssetItem> get assetItems => [
    AssetItem(title: 'Stocks', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Mutual Funds', amount: 1821.45, change: -14.45, changePercent: 1.06),
    AssetItem(title: 'ETF', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
    AssetItem(title: 'Gold', amount: 1821.45, change: 21.45, changePercent: 1.19),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Scaffold(
      appBar: appBar(context, "Portfolio", (){}, false),
      backgroundColor: theme.background,
      //backgroundColor: Colors.black,
      drawer: CustomDrawer(
       // onTap: () => _sheetKey.currentState?.openSheet(),
        selectedRoute: "Portfolio",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tabs
              Row(
                children: [
                  _chip('Holdings', context),
                  const SizedBox(width: 10),
                  _chip('Entertainment',context),
                  const SizedBox(width: 10),
                  _chip('+ Watchlist',context, filled: true),
                ],
              ),
              const SizedBox(height: 24),

              // Filters
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: ['All', 'Stocks', 'Mutual Funds', 'Gold', 'ETF']
                    .map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: e == 'All' ? Colors.orange : Colors.white24),
                    const SizedBox(width: 6),
                    SelectableText(
                      e,
                      style:  TextStyle(
                        color: theme.text,
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                      ),
                      contextMenuBuilder: (context, editableTextState) {
                        final selection = editableTextState.textEditingValue.selection;
                        final text = editableTextState.textEditingValue.text;
                        final selectedText = selection.textInside(text);
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: editableTextState.contextMenuAnchors,
                          buttonItems: [
                            ContextMenuButtonItem(
                              label: 'Ask Vitty 🤖',
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => Text("Vitty: $selectedText"),
                                );
                              },
                            ),
                            ContextMenuButtonItem(
                              label: 'Copy',
                              onPressed: () {
                                Navigator.pop(context);
                                Clipboard.setData(ClipboardData(text: selectedText));
                              },
                            ),
                          ],
                        );
                      },
                    )
                  ],
                ))
                    .toList(),
              ),

              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.shadow),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
                          Text('Current',
                              style: TextStyle(color: theme.secondaryText, fontFamily: 'DM Sans')),
                          SizedBox(height: 4),
                          Text('₹210.18',
                              style: TextStyle(
                                  color: theme.text,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'DM Sans')),
                          SizedBox(height: 16),
                          Text('Invested',
                              style: TextStyle(color: theme.secondaryText, fontFamily: 'DM Sans')),
                          SizedBox(height: 4),
                          Text('₹300.18',
                              style: TextStyle(
                                  color: theme.text,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'DM Sans')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:  [
                          Text('Total returns',
                              style: TextStyle(color: theme.secondaryText, fontFamily: 'DM Sans')),
                          SizedBox(height: 4),
                          Text('+ ₹45.98 (28.00%)',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'DM Sans')),
                          SizedBox(height: 16),
                          Text('1D returns',
                              style: TextStyle(color:  theme.secondaryText, fontFamily: 'DM Sans')),
                          SizedBox(height: 4),
                          Text('- ₹2.92 (1.37%)',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'DM Sans')),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Dynamic Asset List
              for (final asset in assetItems) ...[
                _assetTile(asset,context),
                _divider(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, BuildContext context,{bool filled = false}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFF8C3B) : theme.shadow,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.black : theme.text,
          fontWeight: FontWeight.w500,
          fontFamily: 'DM Sans',
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(color: Color(0xFF828282), thickness: 0.8),
    );
  }

  // Widget _assetTile(AssetItem asset, BuildContext  context) {
  Widget _assetTile(AssetItem asset, BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final color = asset.isGain ? Colors.green : Colors.redAccent;
    final sign = asset.isGain ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Title
          Expanded(
            flex: 4,
            child: Text(
              asset.title,
              style: TextStyle(
                color: theme.text,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
            ),
          ),

          // Middle: Graph (fixed width)
          SizedBox(
            width: 60,
            height: 24,
            child: Image.asset(
              "assets/images/graph.png",
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 16),

          // Right: Amounts
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${asset.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: theme.text,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "$sign ₹${asset.change.abs().toStringAsFixed(2)} (${asset.changePercent.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// enum ChartType {
//   positive,
//   negative,
// }
//
// class StockItem {
//   final String name;
//   final String price;
//   final String change;
//   final bool isPositive;
//   final ChartType chartType;
//   final bool hasAdditional;
//
//   StockItem({
//     required this.name,
//     required this.price,
//     required this.change,
//     required this.isPositive,
//     required this.chartType,
//     this.hasAdditional = false,
//   });
// }
//
// class StockListItem extends StatelessWidget {
//   final StockItem item;
//
//   const StockListItem({Key? key, required this.item}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 4,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item.name,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SvgPicture.asset(
//             "assets/images/Group 150.svg"
//           ),
//           Expanded(
//             flex: 3,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   item.price,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   item.change,
//                   style: TextStyle(
//                     color: item.isPositive ? Colors.green : Colors.red,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
// }
//
// class ChartPainter extends CustomPainter {
//   final List<double> points;
//   final Color color;
//
//   ChartPainter({required this.points, required this.color});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 2.0
//       ..style = PaintingStyle.stroke;
//
//     final path = Path();
//
//     final dx = size.width / (points.length - 1);
//     final maxPoint = points.reduce((a, b) => a > b ? a : b);
//     final minPoint = points.reduce((a, b) => a < b ? a : b);
//     final range = maxPoint - minPoint;
//
//     path.moveTo(0, size.height - ((points[0] - minPoint) / range * size.height));
//
//     for (int i = 1; i < points.length; i++) {
//       final x = i * dx;
//       final y = size.height - ((points[i] - minPoint) / range * size.height);
//       path.lineTo(x, y);
//     }
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
//
// // Status bar time widget to mimic iOS status bar
// class StatusBarTime extends StatelessWidget {
//   const StatusBarTime({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(top: 10),
//       child: const Text(
//         '9:41',
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//     );
//   }
// }
//
// // Custom tab indicator that matches the design
// class CustomTabIndicator extends Decoration {
//   final Color color;
//   final double height;
//
//   const CustomTabIndicator({required this.color, this.height = 3.0});
//
//   @override
//   BoxPainter createBoxPainter([VoidCallback? onChanged]) {
//     return _CustomTabIndicatorPainter(this, onChanged);
//   }
// }
//
// class _CustomTabIndicatorPainter extends BoxPainter {
//   final CustomTabIndicator decoration;
//
//   _CustomTabIndicatorPainter(this.decoration, VoidCallback? onChanged)
//       : super(onChanged);
//
//   @override
//   void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
//     final Rect rect = offset & configuration.size!;
//     final Paint paint = Paint()
//       ..color = decoration.color
//       ..style = PaintingStyle.fill;
//
//     final indicatorRect = Rect.fromLTWH(
//       rect.left,
//       rect.bottom - decoration.height,
//       rect.width,
//       decoration.height,
//     );
//
//     canvas.drawRect(indicatorRect, paint);
//   }
// }
//
// // A widget to display the mini stock chart with the sparkline effect
// class MiniStockChart extends StatelessWidget {
//   final List<double> data;
//   final Color color;
//
//   const MiniStockChart({
//     Key? key,
//     required this.data,
//     required this.color,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 80,
//       height: 30,
//       child: CustomPaint(
//         painter: ChartPainter(
//           points: data,
//           color: color,
//         ),
//       ),
//     );
//   }
// }
//
// // Bottom navigation implementation for future expansion
// class BottomNavBar extends StatelessWidget {
//   final int selectedIndex;
//   final Function(int) onTap;
//
//   const BottomNavBar({
//     Key? key,
//     required this.selectedIndex,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: selectedIndex,
//       onTap: onTap,
//       selectedItemColor: Colors.black,
//       unselectedItemColor: Colors.grey,
//       type: BottomNavigationBarType.fixed,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.trending_up),
//           label: 'Markets',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.account_balance_wallet),
//           label: 'Assets',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profile',
//         ),
//       ],
//     );
//   }
// }
//
//
//
//
// PreferredSizeWidget appBars(BuildContext context, String title, VoidCallback onNewChatTap) {
//   return PreferredSize(
//     preferredSize: const Size.fromHeight(150),
//     child: Card(
//       elevation: 1.0,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         color: Colors.white,
//         child: SafeArea(
//           bottom: false,
//           child: SizedBox(
//             height: 60,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // 👈 Center logo
//                 Text("Portfolio" , style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                     fontSize: 18
//                 ),),
//
//                 // 👈 Row for left and right buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Left menu icon
//                     // ✅ Wrap this with Builder to get the right context
//                     Builder(
//                       builder: (BuildContext scaffoldContext) {
//                         return GestureDetector(
//                           onTap: () {
//                             print("jdn");
//                             // ✅ This will definitely open the drawer
//                             Scaffold.of(scaffoldContext).openDrawer();
//                           },
//                           child: SvgPicture.asset('assets/images/drawer.svg'),
//                         );
//                       },
//                     ),
//
//
//
//                     // Right-side icons
//                     Row(
//                       children: [
//                         GestureDetector(
//                             onTap: (){
//
//                             },
//                             child: const Icon(Icons.notifications_none_outlined, color: Colors.black)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//
//   );
// }
