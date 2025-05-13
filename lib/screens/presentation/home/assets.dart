// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
//
//
// class AssetsScreen extends StatefulWidget {
//   const AssetsScreen({super.key});
//
//   @override
//   State<AssetsScreen> createState() => _AssetsScreenState();
// }
//
// class _AssetsScreenState extends State<AssetsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWatchlist = _tabController.index == 1;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//           backgroundColor: Colors.white,
//         title: TabBar(
//           controller: _tabController,
//           labelColor: Colors.black,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: Colors.orange,
//           indicatorWeight: 3,
//           labelStyle: const TextStyle(fontWeight: FontWeight.w500),
//           tabs: const [
//             Tab(text: 'Portfolio'),
//             Tab(text: 'Watchlist'),
//           ],
//           onTap: (_) => setState(() {}),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           buildPortfolioView(),
//           buildWatchlistView(),
//         ],
//       ),
//     );
//   }
//
//   Widget buildPortfolioView() {
//     return ListView(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       children: [
//         Align(
//           alignment: Alignment.centerRight,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: const [
//               Text('Sort', style: TextStyle(color: Colors.grey)),
//               Icon(Icons.sort, color: Colors.orange, size: 18),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...[
//           'HDFC Bank',
//           'ICICI Bank',
//           'Eternal',
//           'Tata Steel',
//           'PNB',
//         ].map((e) => buildStockTile(
//           name: e,
//           isPositive: e != 'ICICI Bank',
//         )),
//       ],
//     );
//   }
//
//   Widget buildWatchlistView() {
//     return ListView(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       children: [
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 12,
//           runSpacing: 8,
//           children: [
//             Chip(label: Text('Entertainment')),
//             Chip(label: Text('Watchlist')),
//             const Chip(
//               label: Text(
//                 '+ Watchlist',
//                 style: TextStyle(color: Colors.white),
//               ),
//               backgroundColor: Colors.black,
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Align(
//           alignment: Alignment.centerRight,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: const [
//               Text('Sort', style: TextStyle(color: Colors.grey)),
//               Icon(Icons.sort, color: Colors.orange, size: 18),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...[
//           'PVR Inox Ltd',
//           'Tips Music Ltd',
//           'DB Corp Ltd',
//           'Prime Focus Ltd',
//           'Sandesh Ltd',
//         ].map((e) => buildStockTile(
//           name: e,
//           isPositive: e != 'Tips Music Ltd',
//         )),
//         const SizedBox(height: 16),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: const [
//             Text('Edit watchlist', style: TextStyle(color: Colors.orange)),
//             Text('Add stocks', style: TextStyle(color: Colors.orange)),
//           ],
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }
//
//   Widget buildStockTile({required String name, required bool isPositive}) {
//     return Column(
//       children: [
//         ListTile(
//           contentPadding: EdgeInsets.zero,
//           title: Text(name),
//           subtitle: isPositive
//               ? const Text(
//             '+21.45 (1.19%)',
//             style: TextStyle(color: Colors.green, fontSize: 13),
//           )
//               : const Text(
//             '-14.45 (1.06%)',
//             style: TextStyle(color: Colors.red, fontSize: 13),
//           ),
//           trailing: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SvgPicture.asset(
//                 isPositive
//                     ? 'assets/images/Group 150.svg'
//                     : 'assets/images/Group 150.svg',
//                 height: 18,
//                 width: 70,
//                 fit: BoxFit.cover,
//               ),
//               const SizedBox(height: 4),
//               const Text('₹1821.45'),
//             ],
//           ),
//         ),
//         const Divider(height: 0),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/screens/widgets/drawer.dart';

class Assets extends StatefulWidget {
  const Assets({Key? key}) : super(key: key);

  @override
  State<Assets> createState() => _AssetsState();
}

class _AssetsState extends State<Assets> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedRoute: "Portfolio",
      ),
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(
          builder: (context) => appBars(context, "Portfolio", () {}),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(),
          _buildWatchlistTab(),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    final portfolioItems = [
      StockItem(
        name: 'HDFC Bank',
        price: '₹1821.45',
        change: '+21.45 (1.19%)',
        isPositive: true,
        chartType: ChartType.positive,
      ),
      StockItem(
        name: 'ICICI Bank',
        price: '₹1821.45',
        change: '-14.45 (1.06%)',
        isPositive: false,
        chartType: ChartType.negative,
      ),
      StockItem(
        name: 'Eternal',
        price: '₹1821.45',
        change: '+21.45 (1.19%)',
        isPositive: true,
        chartType: ChartType.positive,
      ),
      StockItem(
        name: 'Tata Steel',
        price: '₹1821.45',
        change: '+21.45 (1.19%)',
        isPositive: true,
        chartType: ChartType.positive,
      ),
      StockItem(
        name: 'PNB',
        price: '₹1821.45',
        change: '+21.45 (1.19%)',
        isPositive: true,
        chartType: ChartType.positive,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 12.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.sort,
                  color: Colors.deepOrange[400],
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: portfolioItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return StockListItem(item: portfolioItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistTab() {
    final watchlistItems = [
      StockItem(name: 'PVR Inox Ltd', price: '₹1821.45', change: '+21.45 (1.19%)', isPositive: true, chartType: ChartType.positive),
      StockItem(name: 'Eternal', price: '₹1821.45', change: '-14.45 (1.06%)', isPositive: false, chartType: ChartType.negative),
      StockItem(name: 'HDFC Bank', price: '₹1821.45', change: '+21.45 (1.19%)', isPositive: true, chartType: ChartType.positive),
      StockItem(name: 'Prime Focus Ltd', price: '₹1821.45', change: '+21.45 (1.19%)', isPositive: true, chartType: ChartType.positive),
      StockItem(name: 'Sandesh Ltd', price: '₹1821.45', change: '+21.45 (1.19%)', isPositive: true, chartType: ChartType.positive),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 70), // space for bottom buttons
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0),
                child: Row(
                  children: [
                    _buildChip('Entertainment'),
                    const SizedBox(width: 8),
                    _buildChip('Watchlist'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.add, size: 20, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Watchlist', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.sort, color: Colors.deepOrange[400], size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: watchlistItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return StockListItem(item: watchlistItems[index]);
                  },
                ),
              ),
            ],
          ),
        ),

        // ✅ Fixed Bottom Buttons
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit watchlist',
                  style: TextStyle(
                    color: Colors.deepOrange[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Add stocks',
                  style: TextStyle(
                    color: Colors.deepOrange[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

}

enum ChartType {
  positive,
  negative,
}

class StockItem {
  final String name;
  final String price;
  final String change;
  final bool isPositive;
  final ChartType chartType;
  final bool hasAdditional;

  StockItem({
    required this.name,
    required this.price,
    required this.change,
    required this.isPositive,
    required this.chartType,
    this.hasAdditional = false,
  });
}

class StockListItem extends StatelessWidget {
  final StockItem item;

  const StockListItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            "assets/images/Group 150.svg"
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.change,
                  style: TextStyle(
                    color: item.isPositive ? Colors.green : Colors.red,
                    fontSize: 14,
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

class ChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  ChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    final dx = size.width / (points.length - 1);
    final maxPoint = points.reduce((a, b) => a > b ? a : b);
    final minPoint = points.reduce((a, b) => a < b ? a : b);
    final range = maxPoint - minPoint;

    path.moveTo(0, size.height - ((points[0] - minPoint) / range * size.height));

    for (int i = 1; i < points.length; i++) {
      final x = i * dx;
      final y = size.height - ((points[i] - minPoint) / range * size.height);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Status bar time widget to mimic iOS status bar
class StatusBarTime extends StatelessWidget {
  const StatusBarTime({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: const Text(
        '9:41',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Custom tab indicator that matches the design
class CustomTabIndicator extends Decoration {
  final Color color;
  final double height;

  const CustomTabIndicator({required this.color, this.height = 3.0});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomTabIndicatorPainter(this, onChanged);
  }
}

class _CustomTabIndicatorPainter extends BoxPainter {
  final CustomTabIndicator decoration;

  _CustomTabIndicatorPainter(this.decoration, VoidCallback? onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;

    final indicatorRect = Rect.fromLTWH(
      rect.left,
      rect.bottom - decoration.height,
      rect.width,
      decoration.height,
    );

    canvas.drawRect(indicatorRect, paint);
  }
}

// A widget to display the mini stock chart with the sparkline effect
class MiniStockChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const MiniStockChart({
    Key? key,
    required this.data,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 30,
      child: CustomPaint(
        painter: ChartPainter(
          points: data,
          color: color,
        ),
      ),
    );
  }
}

// Bottom navigation implementation for future expansion
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Markets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Assets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}




PreferredSizeWidget appBars(BuildContext context, String title, VoidCallback onNewChatTap) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(150),
    child: Card(
      elevation: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 👈 Center logo
                Text("Portfolio" , style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18
                ),),

                // 👈 Row for left and right buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left menu icon
                    // ✅ Wrap this with Builder to get the right context
                    Builder(
                      builder: (BuildContext scaffoldContext) {
                        return GestureDetector(
                          onTap: () {
                            print("jdn");
                            // ✅ This will definitely open the drawer
                            Scaffold.of(scaffoldContext).openDrawer();
                          },
                          child: SvgPicture.asset('assets/images/drawer.svg'),
                        );
                      },
                    ),



                    // Right-side icons
                    Row(
                      children: [
                        GestureDetector(
                            onTap: (){

                            },
                            child: const Icon(Icons.notifications_none_outlined, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),

  );
}
