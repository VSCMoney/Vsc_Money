import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../constants/colors.dart';
import '../../models/asset_model.dart' as models;
import '../../services/asset_service.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';
import 'asset_appbar.dart';
import 'expandble_tiles.dart';
import 'finanical_data.dart';
import 'for_you_card.dart';
import 'fundamentals.dart';
import 'news_card.dart';
import 'performance.dart';

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
  // Service wiring
  late final AssetService _svc = GetIt.I<AssetService>();
  StreamSubscription<AssetViewState>? _sub;
  AssetViewState _view = AssetViewState.loading('ALL');

  // UI state
  String selectedPeriod = 'ALL';
  List<FlSpot> chartData = [];
  List<models.ChartPoint> _lastRawPoints = [];

  // Tooltip state
  double? touchedPrice;
  String? touchedTime;
  bool showTooltip = false;

  // Animations
  late AnimationController _streamingController;
  late Animation<double> _streamingAnimation;
  bool isAnimating = false;
  Timer? _ticker;

  late AnimationController _animationController;
  late Animation<double> _animation;

  late TabController _tabController;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _streamingController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this
    );
    _streamingAnimation = CurvedAnimation(
      parent: _streamingController,
      curve: Curves.easeOutCubic,
    );

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this
    );
    _animation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut
    );
    _animationController.forward();

    _sub = _svc.state.listen(_onState);

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
      initialPeriod: _svc.getDefaultPeriod(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamingController.dispose();
    _animationController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  DateTime _convertUtcToIst(DateTime utcTime) {
    // Convert UTC to IST (UTC+5:30)
    return utcTime.add(const Duration(hours: 5, minutes: 30));
  }

  void _onState(AssetViewState s) {
    _view = s;
    selectedPeriod = s.activePeriod;
    _setChartFromService(s.currentChart);
    if (mounted) setState(() {});
  }

  List<String> get _periods {
    final available = _svc.getAvailablePeriods();
    final order = ['1D', '1W', '1M', '1Y', '2Y', '3Y', '4Y', '5Y', '6Y', '7Y', '8Y', '9Y', '10Y', 'ALL'];
    final result = order.where((period) => available.contains(period)).toList();

    for (final period in available) {
      if (!result.contains(period)) {
        result.add(period);
      }
    }
    return result;
  }

  void _setChartFromService(List<models.ChartPoint> points) {
    if (points.isEmpty) return;

    _lastRawPoints = points.map((point) {
      // Convert UTC timestamp to IST before storing
      final istTimestamp = _convertUtcToIst(point.timestamp);
      return models.ChartPoint(
        timestamp: istTimestamp,
        price: point.price,
      );
    }).toList();

    final sortedPoints = List<models.ChartPoint>.from(_lastRawPoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    chartData = sortedPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return FlSpot(index.toDouble(), point.price);
    }).toList();

    if (mounted) {
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final d = _view.data;
    final currency = d?.additionalData?.currencySymbol ?? '₹';
    final screenSize = MediaQuery.of(context).size;

    const toolbarHeight = 60.0;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        backgroundColor: theme.background,
        body: DefaultTabController(
          length: 5,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ✅ App Bar without any top padding
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  height: toolbarHeight,
                  child: Container(
                    color: theme.background,
                    child: StockAppBar(
                      onClose: widget.onClose,
                      fallbackTitle: d?.basicInfo.symbol.isNotEmpty == true
                          ? d!.basicInfo.symbol
                          : "",
                    ),
                  ),
                ),
              ),

              // Stock Header
              SliverToBoxAdapter(
                child: _buildResponsiveStockHeader(d, currency, screenSize),
              ),

              // Chart
              SliverToBoxAdapter(
                child: _buildResponsiveChart(currency, screenSize),
              ),

              // Period Selector
              SliverToBoxAdapter(child: _buildPeriodSelector()),

              // Portfolio Card
              SliverToBoxAdapter(child: _buildPortfolioCardFromService()),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  height: 48,
                  child: Container(
                    color: theme.background,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width < 350 ? 8 : 12,
                    ),
                    child: _buildResponsiveTabSection(screenSize),
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
      ),
    );
  }


  Widget _buildResponsiveStockHeader(models.AssetData? data, String currency, Size screenSize) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final name = data?.basicInfo.name;
    final price = data?.priceData.currentPrice;
    final changePct = data?.priceData.changePercent;
    final changeAmt = data?.priceData.changeAmount;
    final isUp = data?.priceData.isPositive ?? true;

    final upColor = const Color(0xFF3F840F);
    final downColor = const Color(0xFFEF4444);
    final arrow = isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final color = isUp ? upColor : downColor;

    // Responsive sizing
    final isSmallScreen = screenSize.width < 350;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final logoSize = isSmallScreen ? 45.0 : 50.0;
    final priceFontSize = isSmallScreen ? 24.0 : 28.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Company name + Notes button + Logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company name + Notes button (flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company name with proper wrapping
                    Text(
                      name ?? "",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7E7E7E),
                        fontFamily: "SF Pro",
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Notes button
                    InkWell(
                      onTap: () {
                        // context.go("/premium");
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 4 : 6
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF8F4F0), Color(0xFFFFFFFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/notes.png",
                              width: 10,
                              height: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                                fontFamily: "SF Pro",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isSmallScreen ? 8 : 12),

              // Company logo (responsive size)
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/images/microsoft.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(
                          Icons.business,
                          color: Colors.grey,
                          size: logoSize * 0.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price section
          Text(
            price == null ? '—' : '$currency${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.w600,
              color: theme.text,
              fontFamily: "SF Pro",
            ),
          ),

          const SizedBox(height: 8),

          // Change data with responsive layout
          if (price != null && changePct != null && changeAmt != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(arrow, color: color, size: isSmallScreen ? 18 : 20),
                    Text(
                      '${changePct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                        fontFamily: "SF Pro",
                      ),
                    ),
                  ],
                ),
                Text(
                  '(${changeAmt >= 0 ? '+' : ''}${changeAmt.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: theme.text,
                    fontFamily: "SF Pro",
                  ),
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    color: theme.text.withOpacity(0.7),
                    fontFamily: "SF Pro",
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildResponsiveChart(String currency, Size screenSize) {
    final chartHeight = screenSize.height * 0.25; // 25% of screen height
    final horizontalPadding = screenSize.width < 350 ? 12.0 : 16.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (chartData.isEmpty) {
          return Container(
            height: chartHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final isPositive = _isPricePositive();
        final chartColor = isPositive
            ? const Color(0xFF00E676)
            : const Color(0xFFEF4444);
        final gradientColors = isPositive
            ? [
          const Color(0xFF00E676).withOpacity(0.3),
          const Color(0xFF00E676).withOpacity(0.1),
          const Color(0xFF00E676).withOpacity(0.0),
        ]
            : [
          const Color(0xFFEF4444).withOpacity(0.3),
          const Color(0xFFEF4444).withOpacity(0.1),
          const Color(0xFFEF4444).withOpacity(0.0),
        ];

        return Container(
          height: chartHeight,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              clipData: const FlClipData.all(),
              minX: 0,
              maxX: chartData.isNotEmpty ? chartData.length.toDouble() - 1 : 0,
              minY: _paddedMinY(),
              maxY: _paddedMaxY(),
              lineBarsData: [
                LineChartBarData(
                  spots: (chartData..sort((a, b) => a.x.compareTo(b.x)))
                      .map((s) => FlSpot(
                    s.x,
                    s.y * _animation.value + _paddedMinY() * (1 - _animation.value),
                  ))
                      .toList(),
                  isCurved: true,
                  curveSmoothness: 0.4,
                  preventCurveOverShooting: true,
                  preventCurveOvershootingThreshold: 10.0,
                  barWidth: screenSize.width < 350 ? 2.0 : 2.8,
                  isStrokeCapRound: true,
                  color: chartColor,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors,
                      stops: const [0.0, 0.4, 1.0],
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
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width < 350 ? 12 : 14,
                          fontFamily: "SF Pro",
                        ),
                        textAlign: TextAlign.center,
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: chartColor,
                        strokeWidth: 2,
                        dashArray: [3, 3],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, barData, i) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: chartColor,
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

  Widget _buildPeriodSelector() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
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
                    print("👆 Tapped period: $period");
                    setState(() => selectedPeriod = period);

                    final longLabel = _svc.longPeriodLabel;

                    if (period == longLabel && period != 'ALL' && period != '1Y') {
                      print("🎯 Using setLongPeriod");
                      _svc.setLongPeriod();
                    } else {
                      print("🎯 Using setPeriod");
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
                        fontFamily: "SF Pro",
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.primary : theme.text,
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

  TabBar _buildResponsiveTabSection(Size screenSize) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isSmallScreen = screenSize.width < 350;

    return TabBar(
      controller: _tabController,
      onTap: (index) => setState(() => selectedTabIndex = index),
      isScrollable: false,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: EdgeInsets.zero,
      labelColor: theme.text,
      unselectedLabelColor: Colors.grey[600],
      labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
      labelStyle: TextStyle(
        fontFamily: "SF Pro",
        fontSize: isSmallScreen ? 10 : 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: "SF Pro",
        fontSize: isSmallScreen ? 10 : 12,
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
    final forYouCard = _view.data?.fundamentals?.forYouCard;
    final marketInsight = _view.data?.fundamentals?.marketInsight;
    final fundamentalsList = _fundamentalsFromService();
    final technicalsList = _technicalsFromService();

    // Check if we have any actual content to show
    final hasForYouContent = forYouCard?.content?.isNotEmpty == true;
    final hasMarketInsight = marketInsight?.isNotEmpty == true;
    final hasAnyContent = hasForYouContent || hasMarketInsight ||
        fundamentalsList.isNotEmpty || technicalsList.isNotEmpty;

    if (!hasAnyContent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No summary data available yet.',
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show ForYouCard if there's actual content
          if (hasForYouContent || hasMarketInsight)
            ForYouCard(
              title: forYouCard?.title ?? 'Market Insight',
              content: forYouCard?.content ?? marketInsight ?? '',
            ),

          if (fundamentalsList.isNotEmpty)
            CustomFundamentalsSection(
              title: "Fundamentals",
              fundamentals: fundamentalsList,
            ),

          if (technicalsList.isNotEmpty)
            CustomFundamentalsSection(
              title: "Technical",
              fundamentals: technicalsList,
            ),

          // Only add spacing if we actually have content
          if (hasAnyContent) const SizedBox(height: 16),
        ],
      ),
    );
  }





  Widget _buildOverviewTab() {
    final tiles = _view.data?.expandableTiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPerformanceFromService(),
        ExpandableTilesSection(
          marketDepth: tiles == null
              ? null
              : MarketDepthProps(
            buyPercentage: tiles.marketDepth.buyPercentage,
            sellPercentage: tiles.marketDepth.sellPercentage,
            // If your UI's MarketDepthProps expects List<models.OrderData>:
            bidOrders: tiles.marketDepth.bidOrders
                .map((o) => models.OrderData(
              price: o.price,
              quantity: o.quantity,
              // if your models.OrderData now includes `orders`, pass it too:
              orders: o.orders,
            ))
                .toList(),
            askOrders: tiles.marketDepth.askOrders
                .map((o) => models.OrderData(
              price: o.price,
              quantity: o.quantity,
              orders: o.orders,
            ))
                .toList(),
            bidTotal: tiles.marketDepth.bidTotal,
            askTotal: tiles.marketDepth.askTotal,
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
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            SizedBox(height: 8),
            Text(
              'No news available for this stock yet.',
              style: TextStyle(
                fontFamily: 'SF Pro',
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
              maxLines: 3, // Collapse after 3 lines
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
              fontFamily: "SF Pro",
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
              fontFamily: "SF Pro",
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

  // Keep all your existing helper methods unchanged
  bool _isPricePositive() {
    if (chartData.length < 2) return true;
    final firstPrice = chartData.first.y;
    final lastPrice = chartData.last.y;
    return lastPrice >= firstPrice;
  }

  double _paddedMinY() {
    if (chartData.isEmpty) return 0;
    final ys = chartData.map((s) => s.y);
    final min = ys.reduce((a, b) => a < b ? a : b);
    final max = ys.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    final pad = range == 0 ? (max == 0 ? 1 : max * 0.05) : range * 0.08;
    return min - pad;
  }

  double _paddedMaxY() {
    if (chartData.isEmpty) return 0;
    final ys = chartData.map((s) => s.y);
    final min = ys.reduce((a, b) => a < b ? a : b);
    final max = ys.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    final pad = range == 0 ? (max == 0 ? 1 : max * 0.05) : range * 0.08;
    return max + pad;
  }

  Widget _buildPortfolioCardFromService() {
    final p = _view.data?.portfolioData;
    if (p == null) {
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
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child
    );
  }

  // Keep all other existing methods (_buildSummaryTab, _buildOverviewTab, etc.)
  // ... [All other existing methods remain the same]

  String _getTimeFromIndex(int index) {
    if (index < 0 || index >= _lastRawPoints.length) return '';
    final ts = _lastRawPoints[index].timestamp; // Now already in IST

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

  _SliverAppBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}






// class AssetPage extends StatefulWidget {
//   final String assetId;
//   final VoidCallback onClose;
//
//   const AssetPage({
//     Key? key,
//     required this.assetId,
//     required this.onClose,
//   }) : super(key: key);
//
//   @override
//   _AssetPageState createState() => _AssetPageState();
// }
//
// class _AssetPageState extends State<AssetPage> with TickerProviderStateMixin {
//   // Service wiring
//   late final AssetService _svc = GetIt.I<AssetService>();
//   StreamSubscription<AssetViewState>? _sub;
//   AssetViewState _view = AssetViewState.loading('ALL');
//
//   // UI state
//   String selectedPeriod = 'ALL';
//   List<FlSpot> chartData = [];
//   List<models.ChartPoint> _lastRawPoints = [];
//
//   // Tooltip state
//   double? touchedPrice;
//   String? touchedTime;
//   bool showTooltip = false;
//
//   // Animations
//   late AnimationController _streamingController;
//   late Animation<double> _streamingAnimation;
//   bool isAnimating = false;
//   Timer? _ticker;
//
//   late AnimationController _animationController;
//   late Animation<double> _animation;
//
//   late TabController _tabController;
//   int selectedTabIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(length: 5, vsync: this);
//
//     _streamingController = AnimationController(
//         duration: const Duration(milliseconds: 1500),
//         vsync: this
//     );
//     _streamingAnimation = CurvedAnimation(
//       parent: _streamingController,
//       curve: Curves.easeOutCubic,
//     );
//
//     _animationController = AnimationController(
//         duration: const Duration(milliseconds: 300),
//         vsync: this
//     );
//     _animation = CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut
//     );
//     _animationController.forward();
//
//     _sub = _svc.state.listen(_onState);
//
//     _svc.init(
//       assetId: widget.assetId,
//       sections: {
//         Section.overview,
//         Section.summary,
//         Section.news,
//         Section.marketDepth,
//         Section.shareholding,
//         Section.fundamentals,
//         Section.financials,
//         Section.portfolio
//       },
//       initialPeriod: _svc.getDefaultPeriod(),
//     );
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _streamingController.dispose();
//     _animationController.dispose();
//     _sub?.cancel();
//     super.dispose();
//   }
//
//   DateTime _convertUtcToIst(DateTime utcTime) {
//     // Convert UTC to IST (UTC+5:30)
//     return utcTime.add(const Duration(hours: 5, minutes: 30));
//   }
//
//   void _onState(AssetViewState s) {
//     _view = s;
//     selectedPeriod = s.activePeriod;
//     _setChartFromService(s.currentChart);
//     if (mounted) setState(() {});
//   }
//
//   List<String> get _periods {
//     final available = _svc.getAvailablePeriods();
//     final order = ['1D', '1W', '1M', '1Y', '2Y', '3Y', '4Y', '5Y', '6Y', '7Y', '8Y', '9Y', '10Y', 'ALL'];
//     final result = order.where((period) => available.contains(period)).toList();
//
//     for (final period in available) {
//       if (!result.contains(period)) {
//         result.add(period);
//       }
//     }
//     return result;
//   }
//
//   void _setChartFromService(List<models.ChartPoint> points) {
//     if (points.isEmpty) return;
//
//     _lastRawPoints = points.map((point) {
//       // Convert UTC timestamp to IST before storing
//       final istTimestamp = _convertUtcToIst(point.timestamp);
//       return models.ChartPoint(
//         timestamp: istTimestamp,
//         price: point.price,
//       );
//     }).toList();
//
//     final sortedPoints = List<models.ChartPoint>.from(_lastRawPoints)
//       ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//     chartData = sortedPoints.asMap().entries.map((entry) {
//       final index = entry.key;
//       final point = entry.value;
//       return FlSpot(index.toDouble(), point.price);
//     }).toList();
//
//     if (mounted) {
//       setState(() {});
//     }
//     _startStreamingAnimation();
//   }
//
//
//   void _startStreamingAnimation() {
//     if (!mounted) return;
//     setState(() => isAnimating = true);
//     _streamingController.reset();
//     _streamingController.forward().then((_) {
//       if (!mounted) return;
//       setState(() => isAnimating = false);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final d = _view.data;
//     final currency = d?.additionalData?.currencySymbol ?? '₹';
//     final screenSize = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: DefaultTabController(
//         length: 5,
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) => [
//             // App Bar
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: _SliverAppBarDelegate(
//                 child: StockAppBar(
//                   onClose: widget.onClose,
//                   fallbackTitle: d?.basicInfo.symbol.isNotEmpty == true
//                       ? d!.basicInfo.symbol
//                       : "",
//                 ),
//               ),
//             ),
//
//             // Stock Header
//             SliverToBoxAdapter(
//               child: _buildResponsiveStockHeader(d, currency, screenSize),
//             ),
//
//             // Chart
//             SliverToBoxAdapter(
//               child: _buildResponsiveChart(currency, screenSize),
//             ),
//
//             // Period Selector
//             SliverToBoxAdapter(
//               child: _buildPeriodSelector(),
//             ),
//
//             // Portfolio Card
//             SliverToBoxAdapter(
//               child: _buildPortfolioCardFromService(),
//             ),
//
//             // Tab Section
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: _SliverAppBarDelegate(
//                 height: 48,
//                 child: Container(
//                   color: theme.background,
//                   padding: EdgeInsets.symmetric(
//                       horizontal: screenSize.width < 350 ? 8 : 12
//                   ),
//                   child: _buildResponsiveTabSection(screenSize),
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
//   Widget _buildResponsiveStockHeader(models.AssetData? data, String currency, Size screenSize) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final name = data?.basicInfo.name;
//     final price = data?.priceData.currentPrice;
//     final changePct = data?.priceData.changePercent;
//     final changeAmt = data?.priceData.changeAmount;
//     final isUp = data?.priceData.isPositive ?? true;
//
//     final upColor = const Color(0xFF3F840F);
//     final downColor = const Color(0xFFEF4444);
//     final arrow = isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down;
//     final color = isUp ? upColor : downColor;
//
//     // Responsive sizing
//     final isSmallScreen = screenSize.width < 350;
//     final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
//     final logoSize = isSmallScreen ? 45.0 : 50.0;
//     final priceFontSize = isSmallScreen ? 24.0 : 28.0;
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//           horizontal: horizontalPadding,
//           vertical: 16
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Top row: Company name + Notes button + Logo
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Company name + Notes button (flexible)
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Company name with proper wrapping
//                     Text(
//                       name ?? "",
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 14 : 16,
//                         fontWeight: FontWeight.w500,
//                         color: const Color(0xFF7E7E7E),
//                         fontFamily: "SF Pro",
//                         height: 1.2,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//
//                     // Notes button
//                     InkWell(
//                       onTap: () {
//                         // context.go("/premium");
//                       },
//                       borderRadius: BorderRadius.circular(6),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                             horizontal: isSmallScreen ? 6 : 8,
//                             vertical: isSmallScreen ? 4 : 6
//                         ),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFF8F4F0), Color(0xFFFFFFFF)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Image.asset(
//                               "assets/images/notes.png",
//                               width: 10,
//                               height: 10,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               'Notes',
//                               style: TextStyle(
//                                 fontSize: isSmallScreen ? 10 : 12,
//                                 color: AppColors.black,
//                                 fontWeight: FontWeight.w500,
//                                 fontFamily: "SF Pro",
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(width: isSmallScreen ? 8 : 12),
//
//               // Company logo (responsive size)
//               Container(
//                 width: logoSize,
//                 height: logoSize,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   color: Colors.grey.withOpacity(0.1),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.asset(
//                     "assets/images/microsoft.png",
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey.withOpacity(0.2),
//                         child: Icon(
//                           Icons.business,
//                           color: Colors.grey,
//                           size: logoSize * 0.5,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//
//           // Price section
//           Text(
//             price == null ? '—' : '$currency${price.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: priceFontSize,
//               fontWeight: FontWeight.w600,
//               color: theme.text,
//               fontFamily: "SF Pro",
//             ),
//           ),
//
//           const SizedBox(height: 8),
//
//           // Change data with responsive layout
//           if (price != null && changePct != null && changeAmt != null)
//             Wrap(
//               crossAxisAlignment: WrapCrossAlignment.center,
//               spacing: 4,
//               children: [
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(arrow, color: color, size: isSmallScreen ? 18 : 20),
//                     Text(
//                       '${changePct.toStringAsFixed(2)}%',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 12 : 14,
//                         fontWeight: FontWeight.w500,
//                         color: color,
//                         fontFamily: "SF Pro",
//                       ),
//                     ),
//                   ],
//                 ),
//                 Text(
//                   '(${changeAmt >= 0 ? '+' : ''}${changeAmt.toStringAsFixed(1)})',
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 12 : 14,
//                     fontWeight: FontWeight.w500,
//                     color: theme.text,
//                     fontFamily: "SF Pro",
//                   ),
//                 ),
//                 Text(
//                   'Today',
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 10 : 12,
//                     fontWeight: FontWeight.w500,
//                     color: theme.text.withOpacity(0.7),
//                     fontFamily: "SF Pro",
//                   ),
//                 ),
//               ],
//             )
//           else
//             const SizedBox.shrink(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildResponsiveChart(String currency, Size screenSize) {
//     final chartHeight = screenSize.height * 0.25; // 25% of screen height
//     final horizontalPadding = screenSize.width < 350 ? 12.0 : 16.0;
//
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         if (chartData.isEmpty) {
//           return Container(
//             height: chartHeight,
//             padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//             alignment: Alignment.center,
//             child: const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           );
//         }
//
//         final isPositive = _isPricePositive();
//         final chartColor = isPositive
//             ? const Color(0xFF00E676)
//             : const Color(0xFFEF4444);
//         final gradientColors = isPositive
//             ? [
//           const Color(0xFF00E676).withOpacity(0.3),
//           const Color(0xFF00E676).withOpacity(0.1),
//           const Color(0xFF00E676).withOpacity(0.0),
//         ]
//             : [
//           const Color(0xFFEF4444).withOpacity(0.3),
//           const Color(0xFFEF4444).withOpacity(0.1),
//           const Color(0xFFEF4444).withOpacity(0.0),
//         ];
//
//         return Container(
//           height: chartHeight,
//           padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//           child: LineChart(
//             LineChartData(
//               gridData: const FlGridData(show: false),
//               titlesData: const FlTitlesData(show: false),
//               borderData: FlBorderData(show: false),
//               clipData: const FlClipData.all(),
//               minX: 0,
//               maxX: chartData.isNotEmpty ? chartData.length.toDouble() - 1 : 0,
//               minY: _paddedMinY(),
//               maxY: _paddedMaxY(),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: (chartData..sort((a, b) => a.x.compareTo(b.x)))
//                       .map((s) => FlSpot(
//                     s.x,
//                     s.y * _animation.value + _paddedMinY() * (1 - _animation.value),
//                   ))
//                       .toList(),
//                   isCurved: true,
//                   curveSmoothness: 0.4,
//                   preventCurveOverShooting: true,
//                   preventCurveOvershootingThreshold: 10.0,
//                   barWidth: screenSize.width < 350 ? 2.0 : 2.8,
//                   isStrokeCapRound: true,
//                   color: chartColor,
//                   dotData: const FlDotData(show: false),
//                   belowBarData: BarAreaData(
//                     show: true,
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: gradientColors,
//                       stops: const [0.0, 0.4, 1.0],
//                     ),
//                   ),
//                 ),
//               ],
//               lineTouchData: LineTouchData(
//                 enabled: true,
//                 touchCallback: (event, touchResponse) {
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
//                     return touchedSpots.map((t) {
//                       final price = t.y;
//                       final time = _getTimeFromIndex(t.x.toInt());
//                       return LineTooltipItem(
//                         '$currency${price.toStringAsFixed(2)}\n$time',
//                         TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: screenSize.width < 350 ? 12 : 14,
//                           fontFamily: "SF Pro",
//                         ),
//                         textAlign: TextAlign.center,
//                       );
//                     }).toList();
//                   },
//                 ),
//                 getTouchedSpotIndicator: (barData, spotIndexes) {
//                   return spotIndexes.map((index) {
//                     return TouchedSpotIndicatorData(
//                       FlLine(
//                         color: chartColor,
//                         strokeWidth: 2,
//                         dashArray: [3, 3],
//                       ),
//                       FlDotData(
//                         getDotPainter: (spot, percent, barData, i) {
//                           return FlDotCirclePainter(
//                             radius: 6,
//                             color: chartColor,
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
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildPeriodSelector() {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final periods = _periods;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
//       child: Row(
//         children: [
//           const SizedBox(width: 16),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: periods.map((period) {
//                 final isSelected = period == selectedPeriod;
//                 final longLabel = _svc.longPeriodLabel;
//
//                 return GestureDetector(
//                   onTap: () {
//                     print("👆 Tapped period: $period");
//                     setState(() => selectedPeriod = period);
//
//                     final longLabel = _svc.longPeriodLabel;
//
//                     if (period == longLabel && period != 'ALL' && period != '1Y') {
//                       print("🎯 Using setLongPeriod");
//                       _svc.setLongPeriod();
//                     } else {
//                       print("🎯 Using setPeriod");
//                       _svc.setPeriod(period);
//                     }
//                     _startStreamingAnimation();
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: isSelected ? const Color(0xFFFCE4D2) : Colors.transparent,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       period,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontFamily: "SF Pro",
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? AppColors.primary : theme.text,
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   TabBar _buildResponsiveTabSection(Size screenSize) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final isSmallScreen = screenSize.width < 350;
//
//     return TabBar(
//       controller: _tabController,
//       onTap: (index) => setState(() => selectedTabIndex = index),
//       isScrollable: false,
//       indicatorColor: AppColors.primary,
//       indicatorWeight: 2,
//       indicatorSize: TabBarIndicatorSize.tab,
//       indicatorPadding: EdgeInsets.zero,
//       labelColor: theme.text,
//       unselectedLabelColor: Colors.grey[600],
//       labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
//       labelStyle: TextStyle(
//         fontFamily: "SF Pro",
//         fontSize: isSmallScreen ? 10 : 12,
//         fontWeight: FontWeight.w500,
//         height: 1.2,
//       ),
//       unselectedLabelStyle: TextStyle(
//         fontFamily: "SF Pro",
//         fontSize: isSmallScreen ? 10 : 12,
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
//   List<FundamentalData> _fundamentalsFromService() {
//     final f = _view.data?.fundamentals;
//     if (f == null || f.insights.isEmpty) return const [];
//
//     // model items likely expose title/description and (optionally) imageName
//     return f.insights.map((item) {
//       final img = (item.imageName?.isNotEmpty == true)
//           ? item.imageName!
//           : _pickIconByText(item.title + ' ' + item.description);
//       return FundamentalData(
//         title: item.title,
//         description: item.description,
//         imageName: img,
//       );
//     }).toList();
//   }
//
//   List<FundamentalData> _technicalsFromService() {
//     final t = _view.data?.technicals;
//     if (t == null || t.insights.isEmpty) return const [];
//
//     // your tech insights don’t carry image_name → choose by text cue
//     return t.insights.map((item) {
//       return FundamentalData(
//         title: item.title,
//         description: item.description,
//         imageName: _pickIconByText(item.title + ' ' + item.description),
//       );
//     }).toList();
//   }
//
//   String _pickIconByText(String text) {
//     final s = text.toLowerCase();
//     if (s.contains('bull') || s.contains('up') || s.contains('breakout')) {
//       return 'assets/images/upward.png';
//     }
//     if (s.contains('bear') || s.contains('down') || s.contains('resistance')) {
//       return 'assets/images/downward.png';
//     }
//     return 'assets/images/eye.png';
//   }
//
//
//   Widget _buildSummaryTab() {
//     final forYouCard = _view.data?.fundamentals?.forYouCard;
//     final marketInsight = _view.data?.fundamentals?.marketInsight;
//     final fundamentalsList = _fundamentalsFromService();
//     final technicalsList = _technicalsFromService();
//
//     // Check if we have any actual content to show
//     final hasForYouContent = forYouCard?.content?.isNotEmpty == true;
//     final hasMarketInsight = marketInsight?.isNotEmpty == true;
//     final hasAnyContent = hasForYouContent || hasMarketInsight ||
//         fundamentalsList.isNotEmpty || technicalsList.isNotEmpty;
//
//     if (!hasAnyContent) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(32.0),
//           child: Text(
//             'No summary data available yet.',
//             style: TextStyle(
//               fontFamily: 'SF Pro',
//               fontSize: 14,
//               color: Color(0xFF9CA3AF),
//             ),
//           ),
//         ),
//       );
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Only show ForYouCard if there's actual content
//           if (hasForYouContent || hasMarketInsight)
//             ForYouCard(
//               title: forYouCard?.title ?? 'Market Insight',
//               content: forYouCard?.content ?? marketInsight ?? '',
//             ),
//
//           if (fundamentalsList.isNotEmpty)
//             CustomFundamentalsSection(
//               title: "Fundamentals",
//               fundamentals: fundamentalsList,
//             ),
//
//           if (technicalsList.isNotEmpty)
//             CustomFundamentalsSection(
//               title: "Technical",
//               fundamentals: technicalsList,
//             ),
//
//           // Only add spacing if we actually have content
//           if (hasAnyContent) const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
//
//
//
//
//
//   Widget _buildOverviewTab() {
//     final tiles = _view.data?.expandableTiles;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildPerformanceFromService(),
//         ExpandableTilesSection(
//           marketDepth: tiles == null
//               ? null
//               : MarketDepthProps(
//             buyPercentage: tiles.marketDepth.buyPercentage,
//             sellPercentage: tiles.marketDepth.sellPercentage,
//             // If your UI's MarketDepthProps expects List<models.OrderData>:
//             bidOrders: tiles.marketDepth.bidOrders
//                 .map((o) => models.OrderData(
//               price: o.price,
//               quantity: o.quantity,
//               // if your models.OrderData now includes `orders`, pass it too:
//               orders: o.orders,
//             ))
//                 .toList(),
//             askOrders: tiles.marketDepth.askOrders
//                 .map((o) => models.OrderData(
//               price: o.price,
//               quantity: o.quantity,
//               orders: o.orders,
//             ))
//                 .toList(),
//             bidTotal: tiles.marketDepth.bidTotal,
//             askTotal: tiles.marketDepth.askTotal,
//           ),
//         )
//
//       ],
//     );
//   }
//
//
//   Widget _buildPerformanceFromService() {
//     final pd   = _view.data?.priceData;
//     final perf = _view.data?.performanceData;
//
//     if (pd == null && perf == null) {
//       // nothing yet → show nothing (or return a skeleton if you prefer)
//       return const SizedBox.shrink();
//     }
//
//     final currentPrice = pd?.currentPrice ?? 0.0;
//     final todayLow     = pd?.dayLow ?? perf?.todayLow ?? 0.0;
//     final todayHigh    = pd?.dayHigh ?? perf?.todayHigh ?? 0.0;
//
//     final weekLow52    = perf?.week52Low  ?? 0.0;
//     final weekHigh52   = perf?.week52High ?? 0.0;
//
//     final openPrice    = pd?.openPrice ?? perf?.openPrice ?? 0.0;
//     final prevClose    = pd?.prevClose ?? perf?.prevClose ?? 0.0;
//     final volume       = pd?.volume ?? perf?.volume ?? '';
//     final lowerCircuit = pd?.lowerCircuit ?? perf?.lowerCircuit ?? 0.0;
//     final upperCircuit = pd?.upperCircuit ?? perf?.upperCircuit ?? 0.0;
//
//     return PerformanceSection(
//       currentPrice: currentPrice,
//       todayLow: todayLow,
//       todayHigh: todayHigh,
//       weekLow52: weekLow52,
//       weekHigh52: weekHigh52,
//       openPrice: openPrice,
//       prevClose: prevClose,
//       volume: volume,
//       lowerCircuit: lowerCircuit,
//       upperCircuit: upperCircuit,
//     );
//   }
//
//
//   String _formatTimeAgo(DateTime? publishedAt, {String? fallback}) {
//     if (fallback != null && fallback.trim().isNotEmpty) return fallback;
//     if (publishedAt == null) return '—';
//     final now = DateTime.now().toUtc();
//     final diff = now.difference(publishedAt.toUtc());
//     if (diff.inMinutes < 1) return 'just now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes} min';
//     if (diff.inHours < 24) return '${diff.inHours} hr';
//     if (diff.inDays < 7) return '${diff.inDays} day';
//     final weeks = (diff.inDays / 7).floor();
//     return weeks <= 1 ? '1 week' : '$weeks weeks';
//   }
//
//   Widget _buildNewsTab() {
//     final items = _view.data?.news ?? const <models.AssetNewsItem>[];
//
//     if (items.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: const [
//             SizedBox(height: 8),
//             Text(
//               'No news available for this stock yet.',
//               style: TextStyle(
//                 fontFamily: 'SF Pro',
//                 fontSize: 12,
//                 color: Color(0xFF9CA3AF),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: items.map((n) {
//           final timeAgo = _formatTimeAgo(n.publishedAt, fallback: n.timeAgo);
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: NewsCard(
//               source: (n.source ?? '').isEmpty ? '—' : n.source!,
//               timeAgo: timeAgo,
//               title: n.title,
//               description: (n.description ?? '').isEmpty ? ' ' : n.description!,
//               maxLines: 3, // Collapse after 3 lines
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildEventsTab() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Events Content',
//             style: TextStyle(
//               fontFamily: "SF Pro",
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 16),
//           Text('Events information goes here...'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFOTab() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'F&O Content',
//             style: TextStyle(
//               fontFamily: "SF Pro",
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 16),
//           Text('F&O information goes here...'),
//         ],
//       ),
//     );
//   }
//
//   // Keep all your existing helper methods unchanged
//   bool _isPricePositive() {
//     if (chartData.length < 2) return true;
//     final firstPrice = chartData.first.y;
//     final lastPrice = chartData.last.y;
//     return lastPrice >= firstPrice;
//   }
//
//   double _paddedMinY() {
//     if (chartData.isEmpty) return 0;
//     final ys = chartData.map((s) => s.y);
//     final min = ys.reduce((a, b) => a < b ? a : b);
//     final max = ys.reduce((a, b) => a > b ? a : b);
//     final range = (max - min).abs();
//     final pad = range == 0 ? (max == 0 ? 1 : max * 0.05) : range * 0.08;
//     return min - pad;
//   }
//
//   double _paddedMaxY() {
//     if (chartData.isEmpty) return 0;
//     final ys = chartData.map((s) => s.y);
//     final min = ys.reduce((a, b) => a < b ? a : b);
//     final max = ys.reduce((a, b) => a > b ? a : b);
//     final range = (max - min).abs();
//     final pad = range == 0 ? (max == 0 ? 1 : max * 0.05) : range * 0.08;
//     return max + pad;
//   }
//
//   Widget _buildPortfolioCardFromService() {
//     final p = _view.data?.portfolioData;
//     if (p == null) {
//       return const SizedBox.shrink();
//     }
//
//     return StockPortfolioCard(
//       shares: p.shares,
//       avgPrice: p.avgPrice,
//       currentValue: p.currentValue,
//       changePercent: p.changePercent,
//       changeAmount: p.changeAmount,
//       isPositive: p.isPositive,
//     );
//   }
//
//   Widget _wrapWithScroll(Widget child) {
//     return SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: child
//     );
//   }
//
//   // Keep all other existing methods (_buildSummaryTab, _buildOverviewTab, etc.)
//   // ... [All other existing methods remain the same]
//
//   String _getTimeFromIndex(int index) {
//     if (index < 0 || index >= _lastRawPoints.length) return '';
//     final ts = _lastRawPoints[index].timestamp; // Now already in IST
//
//     final isLong = selectedPeriod.endsWith('Y') && selectedPeriod != '1Y';
//     if (selectedPeriod == '1D') {
//       return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
//     } else if (selectedPeriod == '1W' || selectedPeriod == '1M') {
//       return '${ts.day.toString().padLeft(2, '0')} ${_monthShort(ts.month)}';
//     } else if (selectedPeriod == '1Y' || isLong || selectedPeriod == '5Y' || selectedPeriod == 'ALL') {
//       return '${_monthShort(ts.month)} ${ts.year}';
//     }
//     return '${_monthShort(ts.month)} ${ts.day}';
//   }
//
//   String _monthShort(int m) => const [
//     'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
//   ][m - 1];
// }
































































