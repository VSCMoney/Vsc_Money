import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vscmoney/testpage.dart';

import '../../constants/colors.dart';

class StockDetailPage extends StatefulWidget {
  final String stockName;
  final String stockSymbol;
  VoidCallback onClose;

  StockDetailPage({
    Key? key,
    required this.stockName,
    required this.stockSymbol,
    required this.onClose,
  }) : super(key: key);

  @override
  _StockDetailPageState createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage>
    with TickerProviderStateMixin {
  String selectedPeriod = '1W';
  List<String> periods = ['1D', '1W', '1M', '1Y', '5Y', 'ALL'];

  late String stockName;
  late String stockSymbol;
  final double currentPrice = 3665.10;
  final double changeAmount = 174.30;
  final double changePercent = 5.00;
  final bool isPositive = true;

  // Chart interaction and animation
  List<FlSpot> chartData = [];
  double? touchedPrice;
  String? touchedTime;
  bool showTooltip = false;

  // Streaming animation
  late AnimationController _streamingController;
  late Animation<double> _streamingAnimation;
  bool isAnimating = false;
  late TabController _tabController;


  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    stockName = widget.stockName;
    stockSymbol = widget.stockSymbol;

    _initializeChart();

    _streamingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _streamingAnimation = CurvedAnimation(
      parent: _streamingController,
      curve: Curves.easeOutCubic,
    );

    _startStreamingAnimation();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamingController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeChart() {
    chartData = _generateChartData();
  }

  void _startStreamingAnimation() {
    setState(() {
      isAnimating = true;
    });
    _streamingController.reset();
    _streamingController.forward().then((_) {
      setState(() {
        isAnimating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 5,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                child: StockappBar(widget: widget, stockName: stockName),
              ),
            ),

            SliverToBoxAdapter(child: _buildStockHeader()),
            SliverToBoxAdapter(child: _buildChart()),
            SliverToBoxAdapter(child: _buildPeriodSelector()),
            SliverToBoxAdapter(
              child: StockPortfolioCard(
                shares: 15,
                avgPrice: 2450.30,
                currentValue: 42500.75,
                changePercent: 8.5,
                changeAmount: 12.3,
                isPositive: true,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                height: 48,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildTabSection(), // This returns your TabBar
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

  Widget _wrapWithScroll(Widget child) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: child,
    );
  }


  Widget _buildStockHeader() {
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
                // Row: Stock name + Notes tag + Logo
                Row(
                  children: [
                    Text(
                      stockName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E7E7E),
                        fontFamily: "DM Sans",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF1EAE4), // cream
                            Color(0xFFFFFFFF), // white
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/images/notes.png",
                            width: 10,
                            height: 10,
                          ),
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
                    const Spacer(), // Push logo to the right
                    // Microsoft logo positioned properly
                    Padding(
                      padding:  EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          "assets/images/microsoft.png",
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain, // Ensure proper scaling
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Price
                Text(
                  '₹${currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    fontFamily: "DM Sans",
                  ),
                ),

                const SizedBox(height: 5),

                // Percentage and amount
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_drop_up,
                      color: Color(0xFF3F840F),
                      size: 20, // Explicit size for consistency
                    ),
                    Text(
                      '${changePercent.toStringAsFixed(2)}% ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3F840F),
                        fontFamily: "DM Sans",
                      ),
                    ),
                    Text(
                      '(+${changeAmount.toStringAsFixed(1)}) ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3F840F),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 200,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX:
                  chartData.isNotEmpty ? chartData.length.toDouble() + 0.1 : 0,
              minY: _getMinY(),
              maxY: _getMaxY(),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      chartData.map((spot) {
                        return FlSpot(
                          spot.x,
                          spot.y * _animation.value +
                              _getMinY() * (1 - _animation.value),
                        );
                      }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.0,
                  // ✅ VERY HIGH for smooth flowing curves like your image
                  preventCurveOverShooting: true,
                  // ✅ Allow natural flow
                  preventCurveOvershootingThreshold: 9.0,
                  // ✅ Minimal threshold
                  color: Color(0xFF00C853),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF00E676).withOpacity(0.3),
                        Color(0xFF00E676).withOpacity(0.1),
                        Color(0xFF00E676).withOpacity(0.0),
                      ],
                      stops: [0.0, 0.2, 1.0],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (
                  FlTouchEvent event,
                  LineTouchResponse? touchResponse,
                ) {
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
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final price = touchedSpot.y;
                      final time = _getTimeFromIndex(touchedSpot.x.toInt());
                      return LineTooltipItem(
                        '₹${price.toStringAsFixed(2)}\n$time',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (
                  LineChartBarData barData,
                  List<int> spotIndexes,
                ) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: Color(0xFF00C853),
                        strokeWidth: 2,
                        dashArray: [3, 3],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Color(0xFF00C853),
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
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      },
    );
  }

  // ✅ EXACT PATTERN from your chart image
  List<FlSpot> _generateChartData() {
    List<FlSpot> data = [];
    int dataPoints = _getDataPointsForPeriod();

    double minPrice = 3400.0;
    double maxPrice = 3700.0;
    double priceRange = maxPrice - minPrice;

    // ✅ EXACT pattern matching your Zomato chart image
    List<double> exactPattern = [
      0.75, // Start high (left side of your image)
      0.65, // Going down
      0.45, // Continuing down toward the valley
      0.25, // Deep valley (the lowest point in your image)
      0.20, // Bottom of valley
      0.35, // Starting to rise
      0.55, // Rising toward first peak
      0.62, // Small peak in center
      0.58, // Small dip after center peak
      0.52, // Small valley
      0.68, // Rising toward major peak
      0.85, // Major peak (highest point on right side)
      0.88, // Peak continues
      0.75, // Coming down from peak
      0.65, // Valley after major peak
      0.82, // Sharp rise at the end (exactly like your image)
    ];

    for (int i = 0; i < dataPoints; i++) {
      double t = i / (dataPoints - 1);
      double patternIndex = t * (exactPattern.length - 1);
      int lowerIndex = patternIndex.floor();
      int upperIndex = (lowerIndex + 1).clamp(0, exactPattern.length - 1);
      double fraction = patternIndex - lowerIndex;

      // ✅ Smooth interpolation but not too smooth to maintain the shape
      double smoothFraction = fraction * fraction * (3.0 - 2.0 * fraction);

      double heightRatio =
          exactPattern[lowerIndex] * (1 - smoothFraction) +
          exactPattern[upperIndex] * smoothFraction;

      double price = minPrice + (heightRatio * priceRange);

      // ✅ Very minimal variation to keep the exact shape
      price += (Random().nextDouble() - 0.5) * 17;

      data.add(FlSpot(i.toDouble(), price));
    }

    // ✅ Moderate smoothing - enough to be smooth but maintain the distinct peaks/valleys
    List<FlSpot> smoothedData = List.from(data);

    // Apply 3 passes of smoothing (not too much to maintain shape definition)
    for (int pass = 0; pass < 3; pass++) {
      List<FlSpot> tempData = [];
      for (int i = 0; i < smoothedData.length; i++) {
        if (i == 0 || i == smoothedData.length - 1) {
          tempData.add(smoothedData[i]);
        } else if (i >= 1 && i < smoothedData.length - 1) {
          // 3-point smoothing to maintain shape while making curves flow
          double smoothedY =
              (smoothedData[i - 1].y * 0.25 +
                  smoothedData[i].y * 0.5 +
                  smoothedData[i + 1].y * 0.25);
          tempData.add(FlSpot(smoothedData[i].x, smoothedY));
        }
      }
      smoothedData = tempData;
    }

    // Ensure the last point matches current price for the sharp end rise
    if (smoothedData.isNotEmpty) {
      smoothedData[smoothedData.length - 1] = FlSpot(
        (smoothedData.length - 1).toDouble(),
        currentPrice,
      );
    }

    return smoothedData;
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  periods.map((period) {
                    final isSelected = period == selectedPeriod;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPeriod = period;
                          _initializeChart();
                          _startStreamingAnimation();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Color(0xFFFCE4D2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "DM Sans",
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey[600],
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

  int selectedTabIndex = 0; // Add this to your state class

  TabBar _buildTabSection() {
    return TabBar(
      controller: _tabController,
      onTap: (index) {
        setState(() {
          selectedTabIndex = index;
        });
      },
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



  Widget _buildTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return _buildSummaryTab();
      case 1:
        return _buildOverviewTab();
      case 2:
        return _buildNewsTab();
      case 3:
        return _buildEventsTab();
      case 4:
        return _buildFOTab();
      default:
        return const SizedBox.shrink();
    }
  }


// Tab content widgets (customize as needed)
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Container(
        //padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ForYouCard(
              title: "Market Insight",
              content: "Zomato is currently trading at ₹3,665.10, showing strong bullish momentum with a 5% gain today. The stock has broken above key resistance levels, supported by positive quarterly results and expansion plans.",
            ),
            Divider(
              thickness: 0,
            ),
            CustomFundamentalsSection(
              title: "Fundamentals",
                fundamentals: [
              FundamentalData(
                // icon: Icons.restaurant,
                // iconColor: Color(0xFF8B5A3C),
                imageName: 'assets/images/upward.png',
                title: 'Market Leadership',
                description: 'Zomato holds a dominant position in India\'s food delivery market with strong brand recognition and extensive restaurant network.',
              ),
              FundamentalData(
                imageName: 'assets/images/downward.png',
                title: 'Revenue Growth',
                description: 'Consistent revenue growth driven by increasing order volumes and expansion into new markets and services.',
              ),
              FundamentalData(
                imageName: 'assets/images/eye.png',
                title: 'Path to Profitability',
                description: 'Company is focusing on achieving sustainable profitability while maintaining market share in competitive landscape.',
              ),
            ]),
            CustomFundamentalsSection(
              title: 'Technical',
                fundamentals: [
              FundamentalData(
                // icon: Icons.restaurant,
                // iconColor: Color(0xFF8B5A3C),
                imageName: 'assets/images/upward.png',
                title: 'Market Leadership',
                description: 'Zomato holds a dominant position in India\'s food delivery market with strong brand recognition and extensive restaurant network.',
              ),
              FundamentalData(
                imageName: 'assets/images/downward.png',
                title: 'Revenue Growth',
                description: 'Consistent revenue growth driven by increasing order volumes and expansion into new markets and services.',
              ),
              FundamentalData(
                imageName: 'assets/images/eye.png',
                title: 'Path to Profitability',
                description: 'Company is focusing on achieving sustainable profitability while maintaining market share in competitive landscape.',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerformanceSection(
            currentPrice: 3665.10,
            todayLow: 3620.00,
            todayHigh: 3680.50,
            weekLow52: 2450.30,
            weekHigh52: 4196.00,
            openPrice: 3650.00,
            prevClose: 3491.80,
            volume: "1,25,43,567",
            lowerCircuit: 3142.62,
            upperCircuit: 3841.08,
          ),
          ExpandableTilesSection(),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          4,
              (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NewsCard(),
          ),
        ),
      ),
    );
  }


  Widget _buildEventsTab() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
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
          // Add your events content here
          Text('Events information goes here...'),
        ],
      ),
    );
  }

  Widget _buildFOTab() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
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
          // Add your F&O content here
          Text('F&O information goes here...'),
        ],
      ),
    );
  }


  int _getDataPointsForPeriod() {
    switch (selectedPeriod) {
      case '1D':
        return 30;
      case '1W':
        return 35;
      case '1M':
        return 40;
      case '1Y':
        return 45;
      case '5Y':
        return 50;
      case 'ALL':
        return 60;
      default:
        return 35;
    }
  }

  double _getMinY() {
    if (chartData.isEmpty) return 3400;
    return chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 50;
  }

  double _getMaxY() {
    if (chartData.isEmpty) return 3800;
    return chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 50;
  }

  String _getTimeFromIndex(int index) {
    // Convert index to time based on selected period
    switch (selectedPeriod) {
      case '1D':
        int totalMinutes =
            9 * 60 + 30 + (index * 15); // Start at 9:30, 15-min intervals
        int hour = totalMinutes ~/ 60;
        int minute = totalMinutes % 60;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      case '1W':
        List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[index % days.length];
      case '1M':
        return '${index + 1} ${_getMonthName()}';
      case '1Y':
        List<String> months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[index % months.length];
      case '5Y':
        return '${2020 + (index ~/ 10)}';
      case 'ALL':
        return '${2015 + (index ~/ 5)}';
      default:
        return 'Time';
    }
  }

  String _getMonthName() {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[DateTime.now().month - 1];
  }
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
     // elevation: 1,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}


class StockappBar extends StatelessWidget {
  const StockappBar({
    super.key,
    required this.widget,
    required this.stockName,
  });

  final StockDetailPage widget;
  final String stockName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// 🔹 Center title always centered regardless of sides
          Text(
            stockName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: "DM Sans",
            ),
          ),

          /// 🔹 Left and Right controls positioned exactly
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 18),
              GestureDetector(
                onTap: widget.onClose,
                child: Image.asset(
                  "assets/images/cancel.png",
                  width: 30,
                  height: 30,
                  color: Color(0xFF734012),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF734012),
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.bookmark_border,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StockPortfolioCard extends StatelessWidget {
  final int shares;
  final double avgPrice;
  final double currentValue;
  final double changePercent;
  final double changeAmount;
  final bool isPositive;

  const StockPortfolioCard({
    Key? key,
    this.shares = 20,
    this.avgPrice = 1821.45,
    this.currentValue = 36429.00,
    this.changePercent = 10.0,
    this.changeAmount = 14.9,
    this.isPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row - Shares info and current value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Shares info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$shares Shares',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Avg price ₹${avgPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                // Right side - Current value and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color:
                              isPositive
                                  ? Color(0xFF10B981)
                                  : Color(0xFFEF4444),
                          size: 16,
                        ),
                        Text(
                          '${changePercent.toStringAsFixed(0)}% (+${changeAmount.toStringAsFixed(1)})',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color:
                                isPositive
                                    ? Color(0xFF10B981)
                                    : Color(0xFFEF4444),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 1),
            Divider(thickness: 0),
            SizedBox(height: 10),

            // Bottom row - Broker logos and action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Broker logos
                Row(
                  children: [
                    // First broker logo (teal circle)
                    Image.asset("assets/images/choose_broker.png", width: 40),
                  ],
                ),

                // Right side - Go to broker action
                Row(
                  children: [
                    Text(
                      'Go to your broker',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.black, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




class ForYouCard extends StatelessWidget {
  final String title;
  final String content;

  const ForYouCard({
    Key? key,
    this.title = "For you",
    this.content = "Microsoft is currently trading at ₹1,821.45, near its 52-week high, showing positive momentum. Over the last month, the stock gained 5.2% driven by strong quarterly earnings and increased interest in its AI initiatives.",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Subtle gradient background matching the image
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF1EAE4), // Slightly darker warm beige
            Color(0xFFFFFFFF), // Even more subtle variation
          ],
          stops: [0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF734012), // Warm brown color
                  height: 1.2,
                ),
              ),

              SizedBox(height: 12),

              // Content text
              Text(
                content,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black, // Dark gray for readability
                  height: 1.5,
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOrb(size: 20,),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FundamentalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Fundamentals',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 20),

          // Strong Profitability Card
          FundamentalCard(

            imageName: "assets/images/upward.png",
            title: 'Strong Profitability',
            description: 'Microsoft maintains high operating margins (~40%) and consistently strong net income, reflecting excellent cost control and scalable business models.',
          ),

          SizedBox(height: 16),

          // Premium Valuation Card
          FundamentalCard(

            imageName: "assets/images/downward.png",
            title: 'Premium Valuation',
            description: 'Current price-to-earnings ratio is notably above the tech sector average, which may indicate overvaluation in the short term.',
          ),

          SizedBox(height: 16),

          // Low Debt-to-Equity Ratio Card
          FundamentalCard(

            imageName: "assets/images/eye.png",
            title: 'Low Debt-to-Equity Ratio:',
            description: 'Microsoft maintains a return on equity above 35% and solid return on invested capital, highlighting efficient capital use.',
          ),
        ],
      ),
    );
  }
}

class FundamentalCard extends StatelessWidget {
  final String imageName;
  final String title;
  final String description;

  const FundamentalCard({
    Key? key,
    required this.imageName,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child:
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imageName,width: 30,),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedOrb(size: 20,),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// Alternative version with custom data
class CustomFundamentalsSection extends StatelessWidget {
  final List<FundamentalData> fundamentals;
  final String title;

  const CustomFundamentalsSection({
    Key? key,
    required this.fundamentals,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          ...fundamentals.map((fundamental) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: FundamentalCard(
              // icon: fundamental.icon,
              // iconColor: fundamental.iconColor,
              imageName: fundamental.imageName,
              title: fundamental.title,
              description: fundamental.description,
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class FundamentalData {

  final String title;
  final String description;
  final String imageName;

  FundamentalData({
    required this.title,
    required this.description,
  required this.imageName
  });
}





class PerformanceSection extends StatelessWidget {
  final double currentPrice;
  final double todayLow;
  final double todayHigh;
  final double weekLow52;
  final double weekHigh52;
  final double openPrice;
  final double prevClose;
  final String volume;
  final double lowerCircuit;
  final double upperCircuit;

  const PerformanceSection({
    Key? key,
    this.currentPrice = 210.54,
    this.todayLow = 210.54,
    this.todayHigh = 216.00,
    this.weekLow52 = 210.54,
    this.weekHigh52 = 216.00,
    this.openPrice = 210.54,
    this.prevClose = 210.54,
    this.volume = "60,62,086",
    this.lowerCircuit = 210.54,
    this.upperCircuit = 210.54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Title
          Text(
            'Performance',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),

          SizedBox(height: 30),

          // Today's Range
          _buildPriceRange(
            "Today's low",
            "Today's high",
            todayLow,
            todayHigh,
            currentPrice,
          ),

          SizedBox(height: 40),

          // 52 Week Range
          _buildPriceRange(
            "52 week low",
            "52 week high",
            weekLow52,
            weekHigh52,
            currentPrice,
          ),

          SizedBox(height: 40),

          // Price Data Grid (2x3)
          Column(
            children: [
              // First Row
              Row(
                children: [
                  _buildDataItem("Open Price", openPrice.toStringAsFixed(2)),
                  _buildDataItem("Prev. close", prevClose.toStringAsFixed(2)),
                  _buildDataItem("Volume", volume),
                ],
              ),

              SizedBox(height: 30),

              // Second Row
              Row(
                children: [
                  _buildDataItem("Lower circuit", lowerCircuit.toStringAsFixed(2)),
                  _buildDataItem("Upper circuit", upperCircuit.toStringAsFixed(2)),
                  Expanded(child: SizedBox()), // Empty space for alignment
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRange(String lowLabel, String highLabel, double lowValue, double highValue, double currentValue) {
    // Calculate the position of the current price indicator
    double progress = (currentValue - lowValue) / (highValue - lowValue);
    progress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        // Labels and Values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lowLabel,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7E7E7E),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  lowValue.toStringAsFixed(2),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  highLabel,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7E7E7E),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  highValue.toStringAsFixed(2),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 16),

        // Progress Bar with Indicator
        Stack(
          children: [
            // Background bar
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Color(0xFFD97706), // Orange background
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Current price indicator (triangle)
            Positioned(
            //  left: (MediaQuery.of(context).size.width - 40) * progress - 6, // Adjust for padding and triangle width
              top: -4,
              child: Container(
                width: 12,
                height: 16,
                child: CustomPaint(
                  painter: TrianglePainter(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7E7E7E),
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the triangle indicator
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}








class FinancialMetricsWidget extends StatelessWidget {
  final String marketCap;
  final String roe;
  final String peRatio;
  final String eps;
  final String pbRatio;
  final String divYield;
  final String industryPE;
  final String bookValue;
  final String debtToEquity;
  final String faceValue;

  const FinancialMetricsWidget({
    Key? key,
    this.marketCap = "₹25,473Cr",
    this.roe = "1.33%",
    this.peRatio = "75.58",
    this.eps = "13.23",
    this.pbRatio = "1.18",
    this.divYield = "1.10%",
    this.industryPE = "45.54",
    this.bookValue = "847.61",
    this.debtToEquity = "0.33",
    this.faceValue = "10",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        children: [
          // Row 1: Mkt Cap & ROE
          _buildMetricRow("Mkt Cap", marketCap, "ROE", roe),

          SizedBox(height: 24),

          // Row 2: P/E Ratio & EPS
          _buildMetricRow("P/E Ratio(TTM)", peRatio, "EPS(TTM)", eps),

          SizedBox(height: 24),

          // Row 3: P/B Ratio & Div Yield
          _buildMetricRow("P/B Ratio", pbRatio, "Div Yield", divYield),

          SizedBox(height: 24),

          // Row 4: Industry P/E & Book Value
          _buildMetricRow("Industry P/E", industryPE, "Book Value", bookValue),

          SizedBox(height: 24),

          // Row 5: Debt to Equity & Face Value
          _buildMetricRow("Debt to Equity", debtToEquity, "Face Value", faceValue),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String leftLabel, String leftValue, String rightLabel, String rightValue) {
    return Row(
      children: [
        // Left side metric
        Expanded(
          child: Row(
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E), // Gray color
                  height: 1.2,
                ),
              ),
              Spacer(),
              Text(
                leftValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 20), // Space between columns

        // Right side metric
        Expanded(
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E), // Gray color
                  height: 1.2,
                ),
              ),
              Spacer(),
              Text(
                rightValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// Customizable version for different companies
class CustomFinancialMetrics extends StatelessWidget {
  final List<MetricPair> metricPairs;

  const CustomFinancialMetrics({
    Key? key,
    required this.metricPairs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: List.generate(metricPairs.length, (index) {
          final pair = metricPairs[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < metricPairs.length - 1 ? 24 : 0),
            child: _buildCustomMetricRow(
              pair.leftMetric.label,
              pair.leftMetric.value,
              pair.rightMetric.label,
              pair.rightMetric.value,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCustomMetricRow(String leftLabel, String leftValue, String rightLabel, String rightValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E),
                ),
              ),
              SizedBox(height: 8),
              Text(
                leftValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E),
                ),
              ),
              SizedBox(height: 8),
              Text(
                rightValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MetricData {
  final String label;
  final String value;

  MetricData({required this.label, required this.value});
}

class MetricPair {
  final MetricData leftMetric;
  final MetricData rightMetric;

  MetricPair({required this.leftMetric, required this.rightMetric});
}



class ExpandableTilesSection extends StatefulWidget {
  @override
  _ExpandableTilesSectionState createState() => _ExpandableTilesSectionState();
}

class _ExpandableTilesSectionState extends State<ExpandableTilesSection> {
  Set<int> expandedTiles = {};

  @override
  Widget build(BuildContext context) {
    final tiles = [
      TileData(
        title: "Market Depth",
        content: _buildMarketDepthContent(),
      ),
      TileData(
        title: "Fundamentals",
        content: _buildFundamentalsContent(),
      ),
      TileData(
        title: "Financials",
        content: _buildFinancialsContent(),
      ),
      TileData(
        title: "About",
        content: _buildAboutContent(),
      ),
      TileData(
        title: "Shareholding pattern",
        content: _buildShareholdingContent(),
      ),
    ];

    return Container(
      color: Color(0xFFF5F5F5), // Light gray background
      child: Column(
        children: List.generate(tiles.length, (index) {
          return _buildExpandableTile(
            index,
            tiles[index].title,
            tiles[index].content,
          );
        }),
      ),
    );
  }

  Widget _buildExpandableTile(int index, String title, Widget content) {
    final isExpanded = expandedTiles.contains(index);

    return Container(
      margin: EdgeInsets.only(bottom: 1), // Thin separator between tiles
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: index == 0 ? BorderSide(color: Color(0xFFE5E5E5), width: 1) : BorderSide.none,
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Tile Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedTiles.remove(index);
                } else {
                  expandedTiles.add(index);
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: 10,),
                      isExpanded ?AnimatedOrb(size: 20,) : SizedBox.shrink()
                    ],
                  ),

                  // Chevron Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.black,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 250),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: content,
              )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // Content for each tile
  Widget _buildMarketDepthContent() {
    return  MarketDepthWidget(
      buyPercentage: 45.20,
      sellPercentage: 54.80,
      bidOrders: [
        OrderData(price: 3664.50, quantity: 125),
        OrderData(price: 3664.00, quantity: 89),
        OrderData(price: 3663.50, quantity: 0),
        OrderData(price: 3663.00, quantity: 234),
        OrderData(price: 3662.50, quantity: 156),
      ],
      askOrders: [
        OrderData(price: 3665.00, quantity: 2456),
        OrderData(price: 3665.50, quantity: 189),
        OrderData(price: 3666.00, quantity: 0),
        OrderData(price: 3666.50, quantity: 345),
        OrderData(price: 3667.00, quantity: 123),
      ],
      bidTotal: 245680,
      askTotal: 298450,
    );
  }

  Widget _buildFundamentalsContent() {
    return FinancialMetricsWidget(
      marketCap: "₹25,473Cr",
      roe: "1.33%",
      peRatio: "75.58",
      eps: "13.23",
      pbRatio: "1.18",
      divYield: "1.10%",
      industryPE: "45.54",
      bookValue: "847.61",
      debtToEquity: "0.33",
      faceValue: "10",
    );
  }

  Widget _buildFinancialsContent() {
    return FinancialChartsWidget();
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      //  SizedBox(height: 12),
        Text(
          'Zomato is an Indian multinational restaurant aggregator and food delivery company founded by Deepinder Goyal and Pankaj Chaddah in 2008. The company provides information, menus and user-reviews of restaurants as well as food delivery options from partner restaurants in select cities.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShareholdingContent() {
    return ShareholdingPatternWidget();
  }


}

class TileData {
  final String title;
  final Widget content;

  TileData({required this.title, required this.content});
}



// Customizable version with external data
class CustomExpandableTiles extends StatefulWidget {
  final List<ExpandableTileItem> tiles;

  const CustomExpandableTiles({
    Key? key,
    required this.tiles,
  }) : super(key: key);

  @override
  _CustomExpandableTilesState createState() => _CustomExpandableTilesState();
}

class _CustomExpandableTilesState extends State<CustomExpandableTiles> {
  Set<int> expandedTiles = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(widget.tiles.length, (index) {
          final tile = widget.tiles[index];
          final isExpanded = expandedTiles.contains(index);

          return Container(
            margin: EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: index == 0 ? BorderSide(color: Color(0xFFE5E5E5), width: 1) : BorderSide.none,
                bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        expandedTiles.remove(index);
                      } else {
                        expandedTiles.add(index);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tile.title,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                 // height: isExpanded ? null : 0,
                  constraints: isExpanded
                      ? BoxConstraints()
                      : BoxConstraints(maxHeight: 0),

                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 250),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: isExpanded
                        ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      child: tile.content,
                    )
                        : SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ExpandableTileItem {
  final String title;
  final Widget content;

  ExpandableTileItem({required this.title, required this.content});
}







class MarketDepthWidget extends StatelessWidget {
  final double buyPercentage;
  final double sellPercentage;
  final List<OrderData> bidOrders;
  final List<OrderData> askOrders;
  final int bidTotal;
  final int askTotal;

  const MarketDepthWidget({
    Key? key,
    this.buyPercentage = 37.66,
    this.sellPercentage = 62.34,
    this.bidOrders = const [
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
    ],
    this.askOrders = const [
      OrderData(price: 0.00, quantity: 1464),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
    ],
    this.bidTotal = 164634,
    this.askTotal = 164634,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
     // padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        children: [
          // Header with percentages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy orders',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${buyPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sell orders',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${sellPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20),

          // Progress bar showing buy vs sell ratio
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                // Buy orders (Green)
                Expanded(
                  flex: (buyPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF22C55E), // Green
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                // Sell orders (Red/Orange)
                Expanded(
                  flex: (sellPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444), // Red
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Order book table
          Row(
            children: [
              // Bid orders (Left side)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF9E6F37), width: 1), // 🟤 brown border
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid price',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              'Qty',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bid rows
                      ...bidOrders.map((order) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(order.quantity),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00AF41), // ✅ green
                              ),
                            ),
                          ],
                        ),
                      )),

                      // Bid total
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid total',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(bidTotal),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              //SizedBox(width: 6), // gap between tables

              // Ask orders (Right side)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF9E6F37), width: 1), // 🟤 brown border
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ask price',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              'Qty',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ask rows
                      ...askOrders.map((order) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              order.quantity == 0 ? "0" : _formatNumber(order.quantity),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF3D3D), // ✅ red
                              ),
                            ),
                          ],
                        ),
                      )),

                      // Ask total
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ask total',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(askTotal),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )

        ],
      ),
    );
  }

  Widget _buildOrderRow(String price, String quantity, bool isBid) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            price,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            quantity,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isBid ? Color(0xFF22C55E) : Color(0xFFEF4444), // Green for bid, Red for ask
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toString();
    }
  }
}

class OrderData {
  final double price;
  final int quantity;

  const OrderData({required this.price, required this.quantity});
}





class FinancialChartsWidget extends StatefulWidget {
  @override
  _FinancialChartsWidgetState createState() => _FinancialChartsWidgetState();
}

class _FinancialChartsWidgetState extends State<FinancialChartsWidget> {
  int selectedTab = 0; // 0 = Revenue, 1 = Profit, 2 = Net Worth
  String selectedPeriod = 'Quarterly'; // Quarterly or Yearly

  // Revenue data (only tab with data)
  final List<ChartData> revenueData = [
    ChartData(period: 'Jun \'24', value: 76),
    ChartData(period: 'Sep \'24', value: 91),
    ChartData(period: 'Dec \'24', value: 70),
    ChartData(period: 'Mar \'24', value: 81),
    ChartData(period: 'Jun \'25', value: 90),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab('Revenue', 0),
              SizedBox(width: 40),
              _buildTab('Profit', 1),
              SizedBox(width: 40),
              _buildTab('Net Worth', 2),
            ],
          ),

          SizedBox(height: 20),

          // Chart Area
          Container(
            height: 300,
            child: selectedTab == 0
                ? _buildRevenueChart()
                : _buildEmptyChart(),
          ),

          SizedBox(height: 30),

          // Bottom Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildPeriodButton('Quarterly', true),
                  SizedBox(width: 16),
                  _buildPeriodButton('Yearly', false),
                ],
              ),
              Spacer(),
              // See Details Button
              Text(
                'See details',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary, // Orange color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Color(0xFFE87E2E) : Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 8),
          // Underline for selected tab
          Container(
            height: 2,
            width: title.length * 8.0, // Approximate width based on text
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFE87E2E) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // "All values are in Rs. CR" text
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'All values are in Rs. CR',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ),

        // Chart bars
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: revenueData.map((data) => _buildChartBar(data)).toList(),
          ),
        ),

        SizedBox(height: 12),

        // Period labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: revenueData.map((data) =>
              Text(
                data.period,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7E7E7E),
                ),
              ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildChartBar(ChartData data) {
    // Calculate bar height (max value is 91, so scale accordingly)
    final maxValue = 91.0;
    final maxBarHeight = 200.0;
    final barHeight = (data.value / maxValue) * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value label above bar
        Text(
          data.value.toString(),
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7E7E7E),
          ),
        ),
        SizedBox(height: 8),

        // Bar
        Container(
          width: 24,
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.primary, // Orange color
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Color(0xFFE5E7EB),
          ),
          SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data for this metric will be displayed here when available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFFDF2F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.primary : Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class ChartData {
  final String period;
  final int value;

  ChartData({required this.period, required this.value});
}





class ShareholdingPatternWidget extends StatefulWidget {
  @override
  _ShareholdingPatternWidgetState createState() => _ShareholdingPatternWidgetState();
}

class _ShareholdingPatternWidgetState extends State<ShareholdingPatternWidget> {
  final List<String> _timePeriods = ['Jun ‘24', 'Sep ‘24', 'Dec ‘24', 'Mar ‘24', 'Jun ‘25'];
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _staticData = [
    {
      "Promoters": 0.3798,
      "Retail & Others": 0.25,
      "Foreign Institutions": 0.15,
      "Other Domestic Institutions": 0.3798,
      "Mutual Funds": 0.25,
    },
    {
      "Promoters": 0.4,
      "Retail & Others": 0.2,
      "Foreign Institutions": 0.1,
      "Other Domestic Institutions": 0.3,
      "Mutual Funds": 0.3,
    },
    {
      "Promoters": 0.35,
      "Retail & Others": 0.3,
      "Foreign Institutions": 0.1,
      "Other Domestic Institutions": 0.3,
      "Mutual Funds": 0.2,
    },
    {
      "Promoters": 0.3,
      "Retail & Others": 0.35,
      "Foreign Institutions": 0.2,
      "Other Domestic Institutions": 0.25,
      "Mutual Funds": 0.3,
    },
    {
      "Promoters": 0.42,
      "Retail & Others": 0.18,
      "Foreign Institutions": 0.15,
      "Other Domestic Institutions": 0.25,
      "Mutual Funds": 0.22,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> currentData = _staticData[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 14),
        ...currentData.entries.map((entry) => _buildShareholdingRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_timePeriods.length, (index) {
        final isSelected = _selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF0E6) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _timePeriods[index],
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFB8C00) : Color(0xFF7E7E7E),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'DM Sans',
                    fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShareholdingRow(String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Label
          // Expanded(
          //   flex: 2,
          //   child: Text(
          //     label,
          //     style: const TextStyle(
          //       fontSize: 15,
          //       color: Colors.black87,
          //     ),
          //   ),
          // ),

          // Progress bar
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label above bar
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Progress bar with background and foreground
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316), // Orange
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),


          // Percentage Text
          SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              '${(percentage * 100).toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





class NewsCard extends StatelessWidget {
  final String source;
  final String timeAgo;
  final String title;
  final String description;
  final Widget? trailingWidget;

  const NewsCard({
    Key? key,
    this.source = "ScoutQuest",
    this.timeAgo = "5 days",
    this.title = "Microsoft reveals 40 jobs about to be destroyed by AI – see the list?",
    this.description = "A Microsoft Research paper has listed out 40 professions it believes are most at risk from the rise of AI, as well as 40 professions that should be safe.",
    this.trailingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source and time
          Text(
            '$source • $timeAgo',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Title (with right padding for the orb)
          Container(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7E7E7E),
              height: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOrb(size: 20,)
            ],
          )
        ],
      ),
    );
  }
}

