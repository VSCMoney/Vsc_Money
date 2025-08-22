import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/colors.dart';
import '../../models/asset_model.dart' as models;
import '../../services/asset_service.dart';
import 'asset_appbar.dart';
import 'expandble_tiles.dart';
import 'finanical_data.dart';
import 'for_you_card.dart';
import 'fundamentals.dart';
import 'news_card.dart';
import 'performance.dart';

// class AssetPage extends StatefulWidget {
//   final String stockName;
//   final String stockSymbol;
//   VoidCallback onClose;
//
//   AssetPage({
//     Key? key,
//     required this.stockName,
//     required this.stockSymbol,
//     required this.onClose,
//   }) : super(key: key);
//
//   @override
//   _AssetPageState createState() => _AssetPageState();
// }
//
// class _AssetPageState extends State<AssetPage>
//     with TickerProviderStateMixin {
//   String selectedPeriod = '1W';
//   List<String> periods = ['1D', '1W', '1M', '1Y', '5Y', 'ALL'];
//
//   late String stockName;
//   late String stockSymbol;
//   final double currentPrice = 3665.10;
//   final double changeAmount = 174.30;
//   final double changePercent = 5.00;
//   final bool isPositive = true;
//
//   // Chart interaction and animation
//   List<FlSpot> chartData = [];
//   double? touchedPrice;
//   String? touchedTime;
//   bool showTooltip = false;
//
//   // Streaming animation
//   late AnimationController _streamingController;
//   late Animation<double> _streamingAnimation;
//   bool isAnimating = false;
//   late TabController _tabController;
//
//
//   // Animation
//   late AnimationController _animationController;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//     stockName = widget.stockName;
//     stockSymbol = widget.stockSymbol;
//
//     _initializeChart();
//
//     _streamingController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _streamingAnimation = CurvedAnimation(
//       parent: _streamingController,
//       curve: Curves.easeOutCubic,
//     );
//
//     _startStreamingAnimation();
//
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _streamingController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _initializeChart() {
//     chartData = _generateChartData();
//   }
//
//   void _startStreamingAnimation() {
//     setState(() {
//       isAnimating = true;
//     });
//     _streamingController.reset();
//     _streamingController.forward().then((_) {
//       setState(() {
//         isAnimating = false;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: DefaultTabController(
//         length: 5,
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) => [
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: _SliverAppBarDelegate(
//                 child: StockAppBar(
//                   onClose: () => Navigator.of(context).maybePop(),
//                   fallbackTitle: 'ZOMATO', // symbol or provisional name while first load happens
//                 )
//
//               ),
//             ),
//
//             SliverToBoxAdapter(child: _buildStockHeader()),
//             SliverToBoxAdapter(child: _buildChart()),
//             SliverToBoxAdapter(child: _buildPeriodSelector()),
//             SliverToBoxAdapter(
//               child: StockPortfolioCard(
//                 shares: 15,
//                 avgPrice: 2450.30,
//                 currentValue: 42500.75,
//                 changePercent: 8.5,
//                 changeAmount: 12.3,
//                 isPositive: true,
//               ),
//             ),
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: _SliverAppBarDelegate(
//                 height: 48,
//                 child: Container(
//                   color: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: _buildTabSection(), // This returns your TabBar
//                 ),
//               ),
//             ),
//           ],
//           body: TabBarView(
//             controller: _tabController,
//             children: [
//               _wrapWithScroll(_buildSummaryTab()),
//               _wrapWithScroll(_buildOverviewTab()),
//               _wrapWithScroll(_buildNewsTab()),
//               _wrapWithScroll(_buildEventsTab()),
//               _wrapWithScroll(_buildFOTab()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _wrapWithScroll(Widget child) {
//     return SingleChildScrollView(
//       physics: BouncingScrollPhysics(),
//       child: child,
//     );
//   }
//
//
//   Widget _buildStockHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left Side: Stock details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Row: Stock name + Notes tag + Logo
//                 Row(
//                   children: [
//                     Text(
//                       stockName,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF7E7E7E),
//                         fontFamily: "DM Sans",
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [
//                             Color(0xFFF1EAE4), // cream
//                             Color(0xFFFFFFFF), // white
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Row(
//                         children: [
//                           Image.asset(
//                             "assets/images/notes.png",
//                             width: 10,
//                             height: 10,
//                           ),
//                           const SizedBox(width: 4),
//                           const Text(
//                             'Notes',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: AppColors.black,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Spacer(), // Push logo to the right
//                     // Microsoft logo positioned properly
//                     Padding(
//                       padding:  EdgeInsets.only(top: 10),
//                       child: SizedBox(
//                         width: 40,
//                         height: 40,
//                         child: Image.asset(
//                           "assets/images/microsoft.png",
//                           width: 40,
//                           height: 40,
//                           fit: BoxFit.contain, // Ensure proper scaling
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 // Price
//                 Text(
//                   '₹${currentPrice.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.black,
//                     fontFamily: "DM Sans",
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 // Percentage and amount
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.arrow_drop_up,
//                       color: Color(0xFF3F840F),
//                       size: 20, // Explicit size for consistency
//                     ),
//                     Text(
//                       '${changePercent.toStringAsFixed(2)}% ',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF3F840F),
//                         fontFamily: "DM Sans",
//                       ),
//                     ),
//                     Text(
//                       '(+${changeAmount.toStringAsFixed(1)}) ',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF3F840F),
//                         fontFamily: "DM Sans",
//                       ),
//                     ),
//                     Text(
//                       'Today',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[600],
//                         fontFamily: "DM Sans",
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChart() {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return Container(
//           height: 200,
//           padding: EdgeInsets.symmetric(horizontal: 16),
//           child: LineChart(
//             LineChartData(
//               gridData: FlGridData(show: false),
//               titlesData: FlTitlesData(show: false),
//               borderData: FlBorderData(show: false),
//               minX: 0,
//               maxX:
//                   chartData.isNotEmpty ? chartData.length.toDouble() + 0.1 : 0,
//               minY: _getMinY(),
//               maxY: _getMaxY(),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots:
//                       chartData.map((spot) {
//                         return FlSpot(
//                           spot.x,
//                           spot.y * _animation.value +
//                               _getMinY() * (1 - _animation.value),
//                         );
//                       }).toList(),
//                   isCurved: true,
//                   curveSmoothness: 0.0,
//                   // ✅ VERY HIGH for smooth flowing curves like your image
//                   preventCurveOverShooting: true,
//                   // ✅ Allow natural flow
//                   preventCurveOvershootingThreshold: 9.0,
//                   // ✅ Minimal threshold
//                   color: Color(0xFF00C853),
//                   barWidth: 2.5,
//                   isStrokeCapRound: true,
//                   dotData: FlDotData(show: false),
//                   belowBarData: BarAreaData(
//                     show: true,
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Color(0xFF00E676).withOpacity(0.3),
//                         Color(0xFF00E676).withOpacity(0.1),
//                         Color(0xFF00E676).withOpacity(0.0),
//                       ],
//                       stops: [0.0, 0.2, 1.0],
//                     ),
//                   ),
//                 ),
//               ],
//               lineTouchData: LineTouchData(
//                 enabled: true,
//                 touchCallback: (
//                   FlTouchEvent event,
//                   LineTouchResponse? touchResponse,
//                 ) {
//                   setState(() {
//                     if (event is FlTapUpEvent || event is FlPanEndEvent) {
//                       showTooltip = false;
//                       touchedPrice = null;
//                       touchedTime = null;
//                     } else if (touchResponse != null &&
//                         touchResponse.lineBarSpots != null &&
//                         touchResponse.lineBarSpots!.isNotEmpty) {
//                       showTooltip = true;
//                       touchedPrice = touchResponse.lineBarSpots!.first.y;
//                       touchedTime = _getTimeFromIndex(
//                         touchResponse.lineBarSpots!.first.x.toInt(),
//                       );
//                     }
//                   });
//                 },
//                 touchTooltipData: LineTouchTooltipData(
//                   getTooltipItems: (touchedSpots) {
//                     return touchedSpots.map((LineBarSpot touchedSpot) {
//                       final price = touchedSpot.y;
//                       final time = _getTimeFromIndex(touchedSpot.x.toInt());
//                       return LineTooltipItem(
//                         '₹${price.toStringAsFixed(2)}\n$time',
//                         TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       );
//                     }).toList();
//                   },
//                 ),
//                 getTouchedSpotIndicator: (
//                   LineChartBarData barData,
//                   List<int> spotIndexes,
//                 ) {
//                   return spotIndexes.map((index) {
//                     return TouchedSpotIndicatorData(
//                       FlLine(
//                         color: Color(0xFF00C853),
//                         strokeWidth: 2,
//                         dashArray: [3, 3],
//                       ),
//                       FlDotData(
//                         getDotPainter: (spot, percent, barData, index) {
//                           return FlDotCirclePainter(
//                             radius: 6,
//                             color: Color(0xFF00C853),
//                             strokeWidth: 3,
//                             strokeColor: Colors.white,
//                           );
//                         },
//                       ),
//                     );
//                   }).toList();
//                 },
//               ),
//             ),
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           ),
//         );
//       },
//     );
//   }
//
//   // ✅ EXACT PATTERN from your chart image
//   List<FlSpot> _generateChartData() {
//     List<FlSpot> data = [];
//     int dataPoints = _getDataPointsForPeriod();
//
//     double minPrice = 3400.0;
//     double maxPrice = 3700.0;
//     double priceRange = maxPrice - minPrice;
//
//     // ✅ EXACT pattern matching your Zomato chart image
//     List<double> exactPattern = [
//       0.75, // Start high (left side of your image)
//       0.65, // Going down
//       0.45, // Continuing down toward the valley
//       0.25, // Deep valley (the lowest point in your image)
//       0.20, // Bottom of valley
//       0.35, // Starting to rise
//       0.55, // Rising toward first peak
//       0.62, // Small peak in center
//       0.58, // Small dip after center peak
//       0.52, // Small valley
//       0.68, // Rising toward major peak
//       0.85, // Major peak (highest point on right side)
//       0.88, // Peak continues
//       0.75, // Coming down from peak
//       0.65, // Valley after major peak
//       0.82, // Sharp rise at the end (exactly like your image)
//     ];
//
//     for (int i = 0; i < dataPoints; i++) {
//       double t = i / (dataPoints - 1);
//       double patternIndex = t * (exactPattern.length - 1);
//       int lowerIndex = patternIndex.floor();
//       int upperIndex = (lowerIndex + 1).clamp(0, exactPattern.length - 1);
//       double fraction = patternIndex - lowerIndex;
//
//       // ✅ Smooth interpolation but not too smooth to maintain the shape
//       double smoothFraction = fraction * fraction * (3.0 - 2.0 * fraction);
//
//       double heightRatio =
//           exactPattern[lowerIndex] * (1 - smoothFraction) +
//           exactPattern[upperIndex] * smoothFraction;
//
//       double price = minPrice + (heightRatio * priceRange);
//
//       // ✅ Very minimal variation to keep the exact shape
//       price += (Random().nextDouble() - 0.5) * 17;
//
//       data.add(FlSpot(i.toDouble(), price));
//     }
//
//     // ✅ Moderate smoothing - enough to be smooth but maintain the distinct peaks/valleys
//     List<FlSpot> smoothedData = List.from(data);
//
//     // Apply 3 passes of smoothing (not too much to maintain shape definition)
//     for (int pass = 0; pass < 3; pass++) {
//       List<FlSpot> tempData = [];
//       for (int i = 0; i < smoothedData.length; i++) {
//         if (i == 0 || i == smoothedData.length - 1) {
//           tempData.add(smoothedData[i]);
//         } else if (i >= 1 && i < smoothedData.length - 1) {
//           // 3-point smoothing to maintain shape while making curves flow
//           double smoothedY =
//               (smoothedData[i - 1].y * 0.25 +
//                   smoothedData[i].y * 0.5 +
//                   smoothedData[i + 1].y * 0.25);
//           tempData.add(FlSpot(smoothedData[i].x, smoothedY));
//         }
//       }
//       smoothedData = tempData;
//     }
//
//     // Ensure the last point matches current price for the sharp end rise
//     if (smoothedData.isNotEmpty) {
//       smoothedData[smoothedData.length - 1] = FlSpot(
//         (smoothedData.length - 1).toDouble(),
//         currentPrice,
//       );
//     }
//
//     return smoothedData;
//   }
//
//   Widget _buildPeriodSelector() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 1, vertical: 8),
//       child: Row(
//         children: [
//           SizedBox(width: 16),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children:
//                   periods.map((period) {
//                     final isSelected = period == selectedPeriod;
//                     return GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           selectedPeriod = period;
//                           _initializeChart();
//                           _startStreamingAnimation();
//                         });
//                       },
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color:
//                               isSelected
//                                   ? Color(0xFFFCE4D2)
//                                   : Colors.transparent,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           period,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontFamily: "DM Sans",
//                             fontWeight: FontWeight.w500,
//                             color:
//                                 isSelected
//                                     ? AppColors.primary
//                                     : Colors.grey[600],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   int selectedTabIndex = 0; // Add this to your state class
//
//   TabBar _buildTabSection() {
//     return TabBar(
//       controller: _tabController,
//       onTap: (index) {
//         setState(() {
//           selectedTabIndex = index;
//         });
//       },
//       isScrollable: false,
//       indicatorColor: AppColors.primary,
//       indicatorWeight: 2,
//       indicatorSize: TabBarIndicatorSize.tab,
//       indicatorPadding: EdgeInsets.zero,
//       labelColor: AppColors.primary,
//       unselectedLabelColor: Colors.grey[600],
//       labelPadding: const EdgeInsets.symmetric(horizontal: 4),
//       labelStyle: const TextStyle(
//         fontFamily: "DM Sans",
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//         height: 1.2,
//       ),
//       unselectedLabelStyle: const TextStyle(
//         fontFamily: "DM Sans",
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//         height: 1.2,
//       ),
//       dividerColor: Colors.transparent,
//       dividerHeight: 0,
//       tabs: const [
//         Tab(text: 'Summary'),
//         Tab(text: 'Overview'),
//         Tab(text: 'News'),
//         Tab(text: 'Events'),
//         Tab(text: 'F&O'),
//       ],
//     );
//   }
//
//
//
//   Widget _buildTabContent() {
//     switch (selectedTabIndex) {
//       case 0:
//         return _buildSummaryTab();
//       case 1:
//         return _buildOverviewTab();
//       case 2:
//         return _buildNewsTab();
//       case 3:
//         return _buildEventsTab();
//       case 4:
//         return _buildFOTab();
//       default:
//         return const SizedBox.shrink();
//     }
//   }
//
//
// // Tab content widgets (customize as needed)
//   Widget _buildSummaryTab() {
//     return SingleChildScrollView(
//       child: Container(
//         //padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ForYouCard(
//               title: "Market Insight",
//               content: "Zomato is currently trading at ₹3,665.10, showing strong bullish momentum with a 5% gain today. The stock has broken above key resistance levels, supported by positive quarterly results and expansion plans.",
//             ),
//             Divider(
//               thickness: 0,
//             ),
//             CustomFundamentalsSection(
//               title: "Fundamentals",
//                 fundamentals: [
//               FundamentalData(
//                 // icon: Icons.restaurant,
//                 // iconColor: Color(0xFF8B5A3C),
//                 imageName: 'assets/images/upward.png',
//                 title: 'Market Leadership',
//                 description: 'Zomato holds a dominant position in India\'s food delivery market with strong brand recognition and extensive restaurant network.',
//               ),
//               FundamentalData(
//                 imageName: 'assets/images/downward.png',
//                 title: 'Revenue Growth',
//                 description: 'Consistent revenue growth driven by increasing order volumes and expansion into new markets and services.',
//               ),
//               FundamentalData(
//                 imageName: 'assets/images/eye.png',
//                 title: 'Path to Profitability',
//                 description: 'Company is focusing on achieving sustainable profitability while maintaining market share in competitive landscape.',
//               ),
//             ]),
//             CustomFundamentalsSection(
//               title: 'Technical',
//                 fundamentals: [
//               FundamentalData(
//                 // icon: Icons.restaurant,
//                 // iconColor: Color(0xFF8B5A3C),
//                 imageName: 'assets/images/upward.png',
//                 title: 'Market Leadership',
//                 description: 'Zomato holds a dominant position in India\'s food delivery market with strong brand recognition and extensive restaurant network.',
//               ),
//               FundamentalData(
//                 imageName: 'assets/images/downward.png',
//                 title: 'Revenue Growth',
//                 description: 'Consistent revenue growth driven by increasing order volumes and expansion into new markets and services.',
//               ),
//               FundamentalData(
//                 imageName: 'assets/images/eye.png',
//                 title: 'Path to Profitability',
//                 description: 'Company is focusing on achieving sustainable profitability while maintaining market share in competitive landscape.',
//               ),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOverviewTab() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           PerformanceSection(
//             currentPrice: 3665.10,
//             todayLow: 3620.00,
//             todayHigh: 3680.50,
//             weekLow52: 2450.30,
//             weekHigh52: 4196.00,
//             openPrice: 3650.00,
//             prevClose: 3491.80,
//             volume: "1,25,43,567",
//             lowerCircuit: 3142.62,
//             upperCircuit: 3841.08,
//           ),
//           ExpandableTilesSection(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNewsTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: List.generate(
//           4,
//               (index) => Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: NewsCard(),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildEventsTab() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Events Content',
//             style: TextStyle(
//               fontFamily: "DM Sans",
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 16),
//           // Add your events content here
//           Text('Events information goes here...'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFOTab() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'F&O Content',
//             style: TextStyle(
//               fontFamily: "DM Sans",
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 16),
//           // Add your F&O content here
//           Text('F&O information goes here...'),
//         ],
//       ),
//     );
//   }
//
//
//   int _getDataPointsForPeriod() {
//     switch (selectedPeriod) {
//       case '1D':
//         return 30;
//       case '1W':
//         return 35;
//       case '1M':
//         return 40;
//       case '1Y':
//         return 45;
//       case '5Y':
//         return 50;
//       case 'ALL':
//         return 60;
//       default:
//         return 35;
//     }
//   }
//
//   double _getMinY() {
//     if (chartData.isEmpty) return 3400;
//     return chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 50;
//   }
//
//   double _getMaxY() {
//     if (chartData.isEmpty) return 3800;
//     return chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 50;
//   }
//
//   String _getTimeFromIndex(int index) {
//     // Convert index to time based on selected period
//     switch (selectedPeriod) {
//       case '1D':
//         int totalMinutes =
//             9 * 60 + 30 + (index * 15); // Start at 9:30, 15-min intervals
//         int hour = totalMinutes ~/ 60;
//         int minute = totalMinutes % 60;
//         return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
//       case '1W':
//         List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//         return days[index % days.length];
//       case '1M':
//         return '${index + 1} ${_getMonthName()}';
//       case '1Y':
//         List<String> months = [
//           'Jan',
//           'Feb',
//           'Mar',
//           'Apr',
//           'May',
//           'Jun',
//           'Jul',
//           'Aug',
//           'Sep',
//           'Oct',
//           'Nov',
//           'Dec',
//         ];
//         return months[index % months.length];
//       case '5Y':
//         return '${2020 + (index ~/ 10)}';
//       case 'ALL':
//         return '${2015 + (index ~/ 5)}';
//       default:
//         return 'Time';
//     }
//   }
//
//   String _getMonthName() {
//     List<String> months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     return months[DateTime.now().month - 1];
//   }
// }





class AssetPage extends StatefulWidget {
final String assetId;
  final VoidCallback onClose;

  const AssetPage({
    Key? key,
required this.assetId,
    required this.onClose,
  }) : super(key: key);

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> with TickerProviderStateMixin {
  // ───────── Service wiring ─────────
  late final AssetService _svc = GetIt.I<AssetService>();
  StreamSubscription<AssetViewState>? _sub;
  AssetViewState _view = AssetViewState.loading('ALL');

  // ───────── UI state ─────────
  String selectedPeriod = 'ALL';
  List<FlSpot> chartData = [];
  List<models.ChartPoint> _lastRawPoints = [];


  // Tooltip state
  double? touchedPrice;
  String? touchedTime;
  bool showTooltip = false;

  // Streaming animation
  late AnimationController _streamingController;
  late Animation<double> _streamingAnimation;
  bool isAnimating = false;
  Timer? _ticker;

  // Appear animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  late TabController _tabController;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _streamingController =
        AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _streamingAnimation = CurvedAnimation(
      parent: _streamingController,
      curve: Curves.easeOutCubic,
    );

    _animationController =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    _sub = _svc.state.listen(_onState);

    // kick off fetch (no dummy values)
    _svc.init(
      assetId: widget.assetId,
      sections: {
        Section.overview,
        Section.summary,
        Section.news,
        Section.marketDepth,
        Section.shareholding,
        Section.fundamentals,
        Section.financials,
        Section.portfolio
      },
      initialPeriod: _svc.getDefaultPeriod(), // Smart default
    );
    // _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
    //   if (!mounted) return;
    //   print("Refreshed");
    //   _svc.refresh();
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamingController.dispose();
    _animationController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // ───────── Service state sync ─────────
  void _onState(AssetViewState s) {
    _view = s;

    // Period + chart from service
    selectedPeriod = s.activePeriod;
    _setChartFromService(s.currentChart);

    if (mounted) setState(() {});
  }



  List<String> get _periods {
    final available = _svc.getAvailablePeriods();

    // Ensure we always show the most relevant periods in order
    final ordered = <String>[];

    if (available.contains('1D')) ordered.add('1D');
    if (available.contains('1W')) ordered.add('1W');
    if (available.contains('1M')) ordered.add('1M');
    if (available.contains('1Y')) ordered.add('1Y');

    // Add the dynamic long period if it's different from 1Y
    final longLabel = _svc.longPeriodLabel;
    if (longLabel != '1Y' && longLabel != 'ALL' && !ordered.contains(longLabel)) {
      ordered.add(longLabel);
    }

    ordered.add('ALL');

    return ordered;
  }

  void _setChartFromService(List<models.ChartPoint> points) {
    if (points.isEmpty) {
      // Don't blank out the chart - keep existing data
      return;
    }

    _lastRawPoints = points;
    chartData = List.generate(
        points.length,
            (i) => FlSpot(i.toDouble(), points[i].price)
    );

    _startStreamingAnimation();
  }

  void _startStreamingAnimation() {
    if (!mounted) return;
    setState(() => isAnimating = true);
    _streamingController.reset();
    _streamingController.forward().then((_) {
      if (!mounted) return;
      setState(() => isAnimating = false);
    });
  }

  // // dynamic periods including long chip (e.g., 3Y)
  // List<String> get _periods =>
  //     ['1D', '1W', '1M', '1Y', _svc.longPeriodLabel, 'ALL'];

  @override
  Widget build(BuildContext context) {
    final d = _view.data;
    final currency = d?.additionalData?.currencySymbol ?? '₹';
    print("view data ${d?.portfolioData?.avgPrice}");

    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 5,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                child: StockAppBar(
                  onClose: widget.onClose,
                  fallbackTitle: d?.basicInfo.symbol.isNotEmpty == true
                      ? d!.basicInfo.symbol
                      : "",
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildStockHeader(d, currency)),
            SliverToBoxAdapter(child: _buildChart(currency)),
            SliverToBoxAdapter(child: _buildPeriodSelector()),
            // SliverToBoxAdapter(
            //   child: const StockPortfolioCard(
            //     // stays static for now (we'll wire later)
            //     shares: 15,
            //     avgPrice: 2450.30,
            //     currentValue: 42500.75,
            //     changePercent: 8.5,
            //     changeAmount: 12.3,
            //     isPositive: true,
            //   ),
            // ),
            SliverToBoxAdapter(
              child: _buildPortfolioCardFromService(),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                height: 48,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildTabSection(),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _wrapWithScroll(_buildSummaryTab()),
              _wrapWithScroll(_buildOverviewTab()),
              _wrapWithScroll(_buildNewsTab()),
              _wrapWithScroll(_buildEventsTab()),
              _wrapWithScroll(_buildFOTab()),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPortfolioCardFromService() {
    final p = _view.data?.portfolioData;
    print("PORTFOLIO DATA: $p");
    if (p == null) {
      // no portfolio section from API → hide the card (or return a placeholder if you prefer)
      return const SizedBox.shrink();
    }

    return StockPortfolioCard(
      shares: p.shares,
      avgPrice: p.avgPrice,
      currentValue: p.currentValue,
      changePercent: p.changePercent,
      changeAmount: p.changeAmount,
      isPositive: p.isPositive,
    );
  }


  Widget _wrapWithScroll(Widget child) {
    return SingleChildScrollView(physics: const BouncingScrollPhysics(), child: child);
  }


  Widget _buildStockHeader(models.AssetData? data, String currency) {
    final name = data?.basicInfo.name;
    final price = data?.priceData.currentPrice;
    final changePct = data?.priceData.changePercent;
    final changeAmt = data?.priceData.changeAmount;
    final isUp = data?.priceData.isPositive ?? true;

    final upColor = const Color(0xFF3F840F);
    final downColor = const Color(0xFFEF4444);
    final arrow = isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final color = isUp ? upColor : downColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Stock details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: Stock name + Notes tag + Logo (logo static for now)
                Row(
                  children: [
                    Text(
                      name ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E7E7E),
                        fontFamily: "DM Sans",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1EAE4), Color(0xFFFFFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/images/notes.png", width: 10, height: 10),
                          const SizedBox(width: 4),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          "assets/images/microsoft.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Price
                Text(
                  price == null ? '—' : '$currency${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    fontFamily: "DM Sans",
                  ),
                ),
                const SizedBox(height: 5),

                // Percentage and amount
                if (price != null && changePct != null && changeAmt != null)
                  Row(
                    children: [
                      Icon(arrow, color: color, size: 20),
                      Text(
                        '${changePct.toStringAsFixed(2)}% ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color,
                          fontFamily: "DM Sans",
                        ),
                      ),
                      Text(
                        '(${changeAmt >= 0 ? '+' : ''}${changeAmt.toStringAsFixed(1)}) ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color,
                          fontFamily: "DM Sans",
                        ),
                      ),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          fontFamily: "DM Sans",
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Chart (API-driven; no dummy) ─────────
  Widget _buildChart(String currency) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (chartData.isEmpty) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              clipData: const FlClipData.all(),        // keeps the gradient neatly inside
              minX: 0,
              maxX: chartData.isNotEmpty ? chartData.length.toDouble() - 1 : 0,
              minY: _paddedMinY(),                     // small padding so curve breathes
              maxY: _paddedMaxY(),
              lineBarsData: [
                LineChartBarData(
                  // sort to keep the cubic bezier stable
                  spots: (chartData..sort((a, b) => a.x.compareTo(b.x)))
                      .map((s) => FlSpot(
                    s.x,
                    s.y * _animation.value + _paddedMinY() * (1 - _animation.value),
                  ))
                      .toList(),

                  isCurved: true,
                  curveSmoothness: 0.45,               // <-- the “wavy” look (try 0.40–0.55)
                  preventCurveOverShooting: true,
                  // if your fl_chart version supports it, keep a non-zero threshold:
                  // preventCurveOvershootingThreshold: 9.0,

                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  color: const Color(0xFF00C853),    // deeper green like your mock (optional)
                  dotData: FlDotData(show: false),

                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ const Color(0xFF00E676).withOpacity(0.3), const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF00E676).withOpacity(0.0), ], stops: const [0.0, 0.2, 1.0],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, touchResponse) {
                  setState(() {
                    if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      showTooltip = false;
                      touchedPrice = null;
                      touchedTime = null;
                    } else if (touchResponse != null &&
                        touchResponse.lineBarSpots != null &&
                        touchResponse.lineBarSpots!.isNotEmpty) {
                      showTooltip = true;
                      touchedPrice = touchResponse.lineBarSpots!.first.y;
                      touchedTime = _getTimeFromIndex(
                        touchResponse.lineBarSpots!.first.x.toInt(),
                      );
                    }
                  });
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((t) {
                      final price = t.y;
                      final time = _getTimeFromIndex(t.x.toInt());
                      return LineTooltipItem(
                        '$currency${price.toStringAsFixed(2)}\n$time',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: const Color(0xFF00C853), strokeWidth: 2, dashArray: [3, 3]),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, i) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFF00C853),
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      },
    );
  }


  double _paddedMinY() {
    if (chartData.isEmpty) return 0;
    final min = chartData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final max = chartData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (max - min) * 0.08; // 8% padding
    return min - pad;
  }

  double _paddedMaxY() {
    if (chartData.isEmpty) return 0;
    final min = chartData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final max = chartData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (max - min) * 0.08; // 8% padding
    return max + pad;
  }


  // Period selector → tells service (with dynamic long chip)
  Widget _buildPeriodSelector() {
    final periods = _periods;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: periods.map((period) {
                final isSelected = period == selectedPeriod;
                final longLabel = _svc.longPeriodLabel;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedPeriod = period);

                    if (period == longLabel && period != 'ALL' && period != '1Y') {
                      _svc.setLongPeriod();
                    } else {
                      _svc.setPeriod(period);
                    }
                    _startStreamingAnimation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFCE4D2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "DM Sans",
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  // Tabs (static for now; we’ll wire next)
  TabBar _buildTabSection() {
    return TabBar(
      controller: _tabController,
      onTap: (index) => setState(() => selectedTabIndex = index),
      isScrollable: false,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: EdgeInsets.zero,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey[600],
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: const TextStyle(
        fontFamily: "DM Sans",
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: "DM Sans",
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      tabs: const [
        Tab(text: 'Summary'),
        Tab(text: 'Overview'),
        Tab(text: 'News'),
        Tab(text: 'Events'),
        Tab(text: 'F&O'),
      ],
    );
  }


  List<FundamentalData> _fundamentalsFromService() {
    final f = _view.data?.fundamentals;
    if (f == null || f.insights.isEmpty) return const [];

    // model items likely expose title/description and (optionally) imageName
    return f.insights.map((item) {
      final img = (item.imageName?.isNotEmpty == true)
          ? item.imageName!
          : _pickIconByText(item.title + ' ' + item.description);
      return FundamentalData(
        title: item.title,
        description: item.description,
        imageName: img,
      );
    }).toList();
  }

  List<FundamentalData> _technicalsFromService() {
    final t = _view.data?.technicals;
    if (t == null || t.insights.isEmpty) return const [];

    // your tech insights don’t carry image_name → choose by text cue
    return t.insights.map((item) {
      return FundamentalData(
        title: item.title,
        description: item.description,
        imageName: _pickIconByText(item.title + ' ' + item.description),
      );
    }).toList();
  }

  String _pickIconByText(String text) {
    final s = text.toLowerCase();
    if (s.contains('bull') || s.contains('up') || s.contains('breakout')) {
      return 'assets/images/upward.png';
    }
    if (s.contains('bear') || s.contains('down') || s.contains('resistance')) {
      return 'assets/images/downward.png';
    }
    return 'assets/images/eye.png';
  }

  Widget _buildSummaryTab() {
    // For You card content (prefer for_you_card -> fallback to market_insight)
    final forYouTitle =
        _view.data?.fundamentals?.forYouCard?.title ?? 'Market Insight';
    final forYouContent =
        _view.data?.fundamentals?.forYouCard?.content ??
            _view.data?.fundamentals?.marketInsight ??
            "Loading latest insight…";

    // Map insights to UI cards
    final fundamentalsList = _fundamentalsFromService();
    final technicalsList   = _technicalsFromService();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- For You card (always shown with fallback copy) ---
          ForYouCard(title: forYouTitle, content: forYouContent),

          const Divider(thickness: 0),

          // --- Fundamentals section (only if we have items) ---
          if (fundamentalsList.isNotEmpty)
            CustomFundamentalsSection(
              title: "Fundamentals",
              fundamentals: fundamentalsList,
            ),

          // --- Technical section (only if we have items) ---
          if (technicalsList.isNotEmpty)
            CustomFundamentalsSection(
              title: "Technical",
              fundamentals: technicalsList,
            ),

          // Optional: tiny spacer so the last card breathes
          const SizedBox(height: 16),
        ],
      ),
    );
  }





  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       _buildPerformanceFromService(),
        ExpandableTilesSection(
          marketDepth: _view.data?.performanceData.marketDepth == null
              ? null
              : MarketDepthProps(
            buyPercentage: _view.data!.performanceData.marketDepth.buyPercentage,
            sellPercentage: _view.data!.performanceData.marketDepth.sellPercentage,
            bidOrders: _view.data!.performanceData.marketDepth.bidOrders
                .map((o) => models.OrderData(price: o.price, quantity: o.quantity))
                .toList(),
            askOrders: _view.data!.performanceData.marketDepth.askOrders
                .map((o) => models.OrderData(price: o.price, quantity: o.quantity))
                .toList(),
            bidTotal: _view.data!.performanceData.marketDepth.bidTotal,
            askTotal: _view.data!.performanceData.marketDepth.askTotal,
          ),
        )

      ],
    );
  }


  Widget _buildPerformanceFromService() {
    final pd   = _view.data?.priceData;
    final perf = _view.data?.performanceData;

    if (pd == null && perf == null) {
      // nothing yet → show nothing (or return a skeleton if you prefer)
      return const SizedBox.shrink();
    }

    final currentPrice = pd?.currentPrice ?? 0.0;
    final todayLow     = pd?.dayLow ?? perf?.todayLow ?? 0.0;
    final todayHigh    = pd?.dayHigh ?? perf?.todayHigh ?? 0.0;

    final weekLow52    = perf?.week52Low  ?? 0.0;
    final weekHigh52   = perf?.week52High ?? 0.0;

    final openPrice    = pd?.openPrice ?? perf?.openPrice ?? 0.0;
    final prevClose    = pd?.prevClose ?? perf?.prevClose ?? 0.0;
    final volume       = pd?.volume ?? perf?.volume ?? '';
    final lowerCircuit = pd?.lowerCircuit ?? perf?.lowerCircuit ?? 0.0;
    final upperCircuit = pd?.upperCircuit ?? perf?.upperCircuit ?? 0.0;

    return PerformanceSection(
      currentPrice: currentPrice,
      todayLow: todayLow,
      todayHigh: todayHigh,
      weekLow52: weekLow52,
      weekHigh52: weekHigh52,
      openPrice: openPrice,
      prevClose: prevClose,
      volume: volume,
      lowerCircuit: lowerCircuit,
      upperCircuit: upperCircuit,
    );
  }


  String _formatTimeAgo(DateTime? publishedAt, {String? fallback}) {
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    if (publishedAt == null) return '—';
    final now = DateTime.now().toUtc();
    final diff = now.difference(publishedAt.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    if (diff.inDays < 7) return '${diff.inDays} day';
    final weeks = (diff.inDays / 7).floor();
    return weeks <= 1 ? '1 week' : '$weeks weeks';
  }

  Widget _buildNewsTab() {
    final items = _view.data?.news ?? const <models.AssetNewsItem>[];

    if (items.isEmpty) {
      // loading ya empty state
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            SizedBox(height: 8),
            Text(
              'No news available for this stock yet.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((n) {
          final timeAgo = _formatTimeAgo(n.publishedAt, fallback: n.timeAgo);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NewsCard(
              source: (n.source ?? '').isEmpty ? '—' : n.source!,
              timeAgo: timeAgo,
              title: n.title,
              description: (n.description ?? '').isEmpty ? ' ' : n.description!,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events Content',
            style: TextStyle(
              fontFamily: "DM Sans",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text('Events information goes here...'),
        ],
      ),
    );
  }

  Widget _buildFOTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'F&O Content',
            style: TextStyle(
              fontFamily: "DM Sans",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text('F&O information goes here...'),
        ],
      ),
    );
  }

  // ───────── helpers ─────────
  double _getMinY() {
    if (chartData.isEmpty) return 0;
    final min = chartData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    return min - (min * 0.02); // small padding
  }

  double _getMaxY() {
    if (chartData.isEmpty) return 0;
    final max = chartData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return max + (max * 0.02); // small padding
  }

  String _getTimeFromIndex(int index) {
    if (index < 0 || index >= _lastRawPoints.length) return '';
    final ts = _lastRawPoints[index].timestamp;

    // Format based on selectedPeriod (or dynamic long “nY”)
    final isLong = selectedPeriod.endsWith('Y') && selectedPeriod != '1Y';
    if (selectedPeriod == '1D') {
      return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    } else if (selectedPeriod == '1W' || selectedPeriod == '1M') {
      return '${ts.day.toString().padLeft(2, '0')} ${_monthShort(ts.month)}';
    } else if (selectedPeriod == '1Y' || isLong || selectedPeriod == '5Y' || selectedPeriod == 'ALL') {
      return '${_monthShort(ts.month)} ${ts.year}';
    }
    return '${_monthShort(ts.month)} ${ts.day}';
  }

  String _monthShort(int m) => const [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ][m - 1];
}


class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverAppBarDelegate({
    required this.child,
    this.height = 60,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}





























// class FinancialMetricsWidget extends StatelessWidget {
//   final String marketCap;
//   final String roe;
//   final String peRatio;
//   final String eps;
//   final String pbRatio;
//   final String divYield;
//   final String industryPE;
//   final String bookValue;
//   final String debtToEquity;
//   final String faceValue;
//
//   const FinancialMetricsWidget({
//     Key? key,
//     this.marketCap = "₹25,473Cr",
//     this.roe = "1.33%",
//     this.peRatio = "75.58",
//     this.eps = "13.23",
//     this.pbRatio = "1.18",
//     this.divYield = "1.10%",
//     this.industryPE = "45.54",
//     this.bookValue = "847.61",
//     this.debtToEquity = "0.33",
//     this.faceValue = "10",
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(0),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(0), // No border radius for full width
//       ),
//       child: Column(
//         children: [
//           // Row 1: Mkt Cap & ROE
//           _buildMetricRow("Mkt Cap", marketCap, "ROE", roe),
//
//           SizedBox(height: 24),
//
//           // Row 2: P/E Ratio & EPS
//           _buildMetricRow("P/E Ratio(TTM)", peRatio, "EPS(TTM)", eps),
//
//           SizedBox(height: 24),
//
//           // Row 3: P/B Ratio & Div Yield
//           _buildMetricRow("P/B Ratio", pbRatio, "Div Yield", divYield),
//
//           SizedBox(height: 24),
//
//           // Row 4: Industry P/E & Book Value
//           _buildMetricRow("Industry P/E", industryPE, "Book Value", bookValue),
//
//           SizedBox(height: 24),
//
//           // Row 5: Debt to Equity & Face Value
//           _buildMetricRow("Debt to Equity", debtToEquity, "Face Value", faceValue),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMetricRow(String leftLabel, String leftValue, String rightLabel, String rightValue) {
//     return Row(
//       children: [
//         // Left side metric
//         Expanded(
//           child: Row(
//             children: [
//               Text(
//                 leftLabel,
//                 style: TextStyle(
//                   fontFamily: 'DM Sans',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFF7E7E7E), // Gray color
//                   height: 1.2,
//                 ),
//               ),
//               Spacer(),
//               Text(
//                 leftValue,
//                 style: TextStyle(
//                   fontFamily: 'DM Sans',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.black,
//                   height: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         SizedBox(width: 20), // Space between columns
//
//         // Right side metric
//         Expanded(
//           child: Row(
//             //crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 rightLabel,
//                 style: TextStyle(
//                   fontFamily: 'DM Sans',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFF7E7E7E), // Gray color
//                   height: 1.2,
//                 ),
//               ),
//               Spacer(),
//               Text(
//                 rightValue,
//                 style: TextStyle(
//                   fontFamily: 'DM Sans',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                   height: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
// class MetricData {
//   final String label;
//   final String value;
//
//   MetricData({required this.label, required this.value});
// }
//
// class MetricPair {
//   final MetricData leftMetric;
//   final MetricData rightMetric;
//
//   MetricPair({required this.leftMetric, required this.rightMetric});
// }



























