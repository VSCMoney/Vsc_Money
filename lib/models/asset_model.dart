// class AssetData {
//   final String assetId;
//   final AssetBasicInfo basicInfo;
//   final AssetPriceData priceData;
//   final AssetChartData chartData;
//   final AssetPortfolioData? portfolioData;
//   final AssetPerformanceData performanceData;
//   final AssetFundamentals fundamentals;
//   final AssetTechnicals technicals;
//   final List<AssetNewsItem> news;
//   final List<AssetEvent> events;
//   final AssetFuturesOptions? futuresOptions;
//   final AdditionalData? additionalData; // UPDATED: typed
//
//   AssetData({
//     required this.assetId,
//     required this.basicInfo,
//     required this.priceData,
//     required this.chartData,
//     this.portfolioData,
//     required this.performanceData,
//     required this.fundamentals,
//     required this.technicals,
//     this.news = const [],
//     this.events = const [],
//     this.futuresOptions,
//     this.additionalData,
//   });
//
//   factory AssetData.fromJson(Map<String, dynamic> json) {
//     return AssetData(
//       assetId: json['asset_id'] ?? '',
//       basicInfo: AssetBasicInfo.fromJson(json['basic_info'] ?? {}),
//       priceData: AssetPriceData.fromJson(json['price_data'] ?? {}),
//       chartData: AssetChartData.fromJson(json['chart_data'] ?? {}),
//       portfolioData: json['portfolio_data'] != null
//           ? AssetPortfolioData.fromJson(json['portfolio_data'])
//           : null,
//       performanceData:
//       AssetPerformanceData.fromJson(json['performance_data'] ?? {}),
//       fundamentals: AssetFundamentals.fromJson(json['fundamentals'] ?? {}),
//       technicals: AssetTechnicals.fromJson(json['technicals'] ?? {}),
//       news: (json['news'] as List<dynamic>?)
//           ?.map((item) => AssetNewsItem.fromJson(item))
//           .toList() ??
//           [],
//       events: (json['events'] as List<dynamic>?)
//           ?.map((item) => AssetEvent.fromJson(item))
//           .toList() ??
//           [],
//       futuresOptions: json['futures_options'] != null
//           ? AssetFuturesOptions.fromJson(json['futures_options'])
//           : null,
//       additionalData: json['additional_data'] != null
//           ? AdditionalData.fromJson(json['additional_data'])
//           : null,
//     );
//   }
// }
//
// // ============================================================================
// // BASIC INFO
// // ============================================================================
// class AssetBasicInfo {
//   final String name;
//   final String symbol;
//   final String? logoUrl;
//   final String? description;
//   final String sector;
//   final String industry;
//   final String exchange;
//   final String currency;
//
//   AssetBasicInfo({
//     required this.name,
//     required this.symbol,
//     this.logoUrl,
//     this.description,
//     required this.sector,
//     required this.industry,
//     required this.exchange,
//     this.currency = 'INR',
//   });
//
//   factory AssetBasicInfo.fromJson(Map<String, dynamic> json) {
//     return AssetBasicInfo(
//       name: json['name'] ?? '',
//       symbol: json['symbol'] ?? '',
//       logoUrl: json['logo_url'],
//       description: json['description'],
//       sector: json['sector'] ?? '',
//       industry: json['industry'] ?? '',
//       exchange: json['exchange'] ?? '',
//       currency: json['currency'] ?? 'INR',
//     );
//   }
// }
//
// // ============================================================================
// // PRICE DATA
// // ============================================================================
// class AssetPriceData {
//   final double currentPrice;
//   final double changeAmount;
//   final double changePercent;
//   final bool isPositive;
//   final double openPrice;
//   final double prevClose;
//   final double dayHigh;
//   final double dayLow;
//   final String volume; // formatted string
//   final double? lowerCircuit;
//   final double? upperCircuit;
//   final DateTime lastUpdated;
//
//   AssetPriceData({
//     required this.currentPrice,
//     required this.changeAmount,
//     required this.changePercent,
//     required this.isPositive,
//     required this.openPrice,
//     required this.prevClose,
//     required this.dayHigh,
//     required this.dayLow,
//     required this.volume,
//     this.lowerCircuit,
//     this.upperCircuit,
//     required this.lastUpdated,
//   });
//
//   factory AssetPriceData.fromJson(Map<String, dynamic> json) {
//     final changeAmount = (json['change_amount'] ?? 0.0).toDouble();
//     return AssetPriceData(
//       currentPrice: (json['current_price'] ?? 0.0).toDouble(),
//       changeAmount: changeAmount,
//       changePercent: (json['change_percent'] ?? 0.0).toDouble(),
//       isPositive: json['is_positive'] ?? (changeAmount >= 0),
//       openPrice: (json['open_price'] ?? 0.0).toDouble(),
//       prevClose: (json['prev_close'] ?? 0.0).toDouble(),
//       dayHigh: (json['day_high'] ?? 0.0).toDouble(),
//       dayLow: (json['day_low'] ?? 0.0).toDouble(),
//       volume: json['volume']?.toString() ?? '0',
//       lowerCircuit: (json['lower_circuit'] as num?)?.toDouble(),
//       upperCircuit: (json['upper_circuit'] as num?)?.toDouble(),
//       lastUpdated: json['last_updated'] != null
//           ? DateTime.parse(json['last_updated'])
//           : DateTime.now(),
//     );
//   }
// }
//
// // ============================================================================
// // CHART DATA
// // ============================================================================
// class AssetChartData {
//   final Map<String, List<ChartPoint>> timeSeriesData;
//   final String defaultPeriod;
//
//   AssetChartData({
//     required this.timeSeriesData,
//     this.defaultPeriod = '1W',
//   });
//
//   factory AssetChartData.fromJson(Map<String, dynamic> json) {
//     final timeSeriesData = <String, List<ChartPoint>>{};
//     if (json['time_series'] is Map<String, dynamic>) {
//       final timeSeries = json['time_series'] as Map<String, dynamic>;
//       timeSeries.forEach((period, data) {
//         if (data is List) {
//           timeSeriesData[period] =
//               data.map((point) => ChartPoint.fromJson(point)).toList();
//         }
//       });
//     }
//     return AssetChartData(
//       timeSeriesData: timeSeriesData,
//       defaultPeriod: json['default_period']?.toString() ?? '1W',
//     );
//   }
//
//   List<ChartPoint>? getDataForPeriod(String period) {
//     return timeSeriesData[period];
//   }
// }
//
// class ChartPoint {
//   final DateTime timestamp;
//   final double price;
//   final double? volume;
//   final double? high;
//   final double? low;
//   final double? open;
//
//   ChartPoint({
//     required this.timestamp,
//     required this.price,
//     this.volume,
//     this.high,
//     this.low,
//     this.open,
//   });
//
//   factory ChartPoint.fromJson(Map<String, dynamic> json) {
//     return ChartPoint(
//       timestamp: DateTime.parse(json['timestamp']),
//       price: (json['price'] ?? 0.0).toDouble(),
//       volume: (json['volume'] as num?)?.toDouble(),
//       high: (json['high'] as num?)?.toDouble(),
//       low: (json['low'] as num?)?.toDouble(),
//       open: (json['open'] as num?)?.toDouble(),
//     );
//   }
// }
//
// // ============================================================================
// // PORTFOLIO DATA
// // ============================================================================
// class AssetPortfolioData {
//   final int shares;
//   final double avgPrice;
//   final double currentValue;
//   final double changePercent;
//   final double changeAmount;
//   final bool isPositive;
//   final double investedAmount;
//   final double unrealizedPnL;
//
//   AssetPortfolioData({
//     required this.shares,
//     required this.avgPrice,
//     required this.currentValue,
//     required this.changePercent,
//     required this.changeAmount,
//     required this.isPositive,
//     required this.investedAmount,
//     required this.unrealizedPnL,
//   });
//
//   factory AssetPortfolioData.fromJson(Map<String, dynamic> json) {
//     final changeAmount = (json['change_amount'] ?? 0.0).toDouble();
//     return AssetPortfolioData(
//       shares: json['shares'] ?? 0,
//       avgPrice: (json['avg_price'] ?? 0.0).toDouble(),
//       currentValue: (json['current_value'] ?? 0.0).toDouble(),
//       changePercent: (json['change_percent'] ?? 0.0).toDouble(),
//       changeAmount: changeAmount,
//       isPositive: json['is_positive'] ?? (changeAmount >= 0),
//       investedAmount: (json['invested_amount'] ?? 0.0).toDouble(),
//       unrealizedPnL: (json['unrealized_pnl'] ?? 0.0).toDouble(),
//     );
//   }
// }
//
// // ============================================================================
// // PERFORMANCE DATA
// // ============================================================================
// class AssetPerformanceData {
//   final double todayLow;
//   final double todayHigh;
//   final double week52Low;
//   final double week52High;
//   final double openPrice;
//   final double prevClose;
//   final String volume;
//   final double lowerCircuit;
//   final double upperCircuit;
//   final FinancialMetrics financialMetrics;
//   final FinancialChartsData financialCharts;
//   final MarketDepthData marketDepth;
//   final ExpandableTilesData expandableTiles;
//
//   AssetPerformanceData({
//     required this.todayLow,
//     required this.todayHigh,
//     required this.week52Low,
//     required this.week52High,
//     required this.openPrice,
//     required this.prevClose,
//     required this.volume,
//     required this.lowerCircuit,
//     required this.upperCircuit,
//     required this.financialMetrics,
//     required this.financialCharts,
//     required this.marketDepth,
//     required this.expandableTiles,
//   });
//
//   factory AssetPerformanceData.fromJson(Map<String, dynamic> json) {
//     return AssetPerformanceData(
//       todayLow: (json['today_low'] ?? 0.0).toDouble(),
//       todayHigh: (json['today_high'] ?? 0.0).toDouble(),
//       week52Low: (json['week_52_low'] ?? 0.0).toDouble(),
//       week52High: (json['week_52_high'] ?? 0.0).toDouble(),
//       openPrice: (json['open_price'] ?? 0.0).toDouble(),
//       prevClose: (json['prev_close'] ?? 0.0).toDouble(),
//       volume: json['volume']?.toString() ?? '0',
//       lowerCircuit: (json['lower_circuit'] ?? 0.0).toDouble(),
//       upperCircuit: (json['upper_circuit'] ?? 0.0).toDouble(),
//       financialMetrics: FinancialMetrics.fromJson(json['financial_metrics'] ?? {}),
//       financialCharts: FinancialChartsData.fromJson(json['financial_charts'] ?? {}),
//       marketDepth: MarketDepthData.fromJson(json['market_depth'] ?? {}),
//       expandableTiles: ExpandableTilesData.fromJson(json['expandable_tiles'] ?? {}),
//     );
//   }
// }
//
// // ============================================================================
// // FINANCIAL METRICS
// // ============================================================================
// class FinancialMetrics {
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
//   FinancialMetrics({
//     this.marketCap = "₹0Cr",
//     this.roe = "0.00%",
//     this.peRatio = "0.00",
//     this.eps = "0.00",
//     this.pbRatio = "0.00",
//     this.divYield = "0.00%",
//     this.industryPE = "0.00",
//     this.bookValue = "0.00",
//     this.debtToEquity = "0.00",
//     this.faceValue = "0",
//   });
//
//   factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
//     return FinancialMetrics(
//       marketCap: json['market_cap']?.toString() ?? "₹0Cr",
//       roe: json['roe']?.toString() ?? "0.00%",
//       peRatio: json['pe_ratio']?.toString() ?? "0.00",
//       eps: json['eps']?.toString() ?? "0.00",
//       pbRatio: json['pb_ratio']?.toString() ?? "0.00",
//       divYield: json['div_yield']?.toString() ?? "0.00%",
//       industryPE: json['industry_pe']?.toString() ?? "0.00",
//       bookValue: json['book_value']?.toString() ?? "0.00",
//       debtToEquity: json['debt_to_equity']?.toString() ?? "0.00",
//       faceValue: json['face_value']?.toString() ?? "0",
//     );
//   }
// }
//
// // ============================================================================
// // FINANCIAL CHARTS DATA
// // ============================================================================
// class FinancialChartsData {
//   final List<ChartDataPoint> revenueQuarterly;
//   final List<ChartDataPoint> revenueYearly;
//   final List<ChartDataPoint> profitQuarterly;
//   final List<ChartDataPoint> profitYearly;
//   final List<ChartDataPoint> netWorthQuarterly;
//   final List<ChartDataPoint> netWorthYearly;
//   final String valueUnit;
//
//   FinancialChartsData({
//     this.revenueQuarterly = const [],
//     this.revenueYearly = const [],
//     this.profitQuarterly = const [],
//     this.profitYearly = const [],
//     this.netWorthQuarterly = const [],
//     this.netWorthYearly = const [],
//     this.valueUnit = "Rs. CR",
//   });
//
//   factory FinancialChartsData.fromJson(Map<String, dynamic> json) {
//     return FinancialChartsData(
//       revenueQuarterly: (json['revenue_quarterly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       revenueYearly: (json['revenue_yearly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       profitQuarterly: (json['profit_quarterly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       profitYearly: (json['profit_yearly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       netWorthQuarterly: (json['net_worth_quarterly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       netWorthYearly: (json['net_worth_yearly'] as List<dynamic>?)
//           ?.map((item) => ChartDataPoint.fromJson(item))
//           .toList() ??
//           [],
//       valueUnit: json['value_unit']?.toString() ?? "Rs. CR",
//     );
//   }
//
//   List<ChartDataPoint> getDataForChart({
//     required FinancialChartType chartType,
//     required FinancialChartPeriod period,
//   }) {
//     switch (chartType) {
//       case FinancialChartType.revenue:
//         return period == FinancialChartPeriod.quarterly
//             ? revenueQuarterly
//             : revenueYearly;
//       case FinancialChartType.profit:
//         return period == FinancialChartPeriod.quarterly
//             ? profitQuarterly
//             : profitYearly;
//       case FinancialChartType.netWorth:
//         return period == FinancialChartPeriod.quarterly
//             ? netWorthQuarterly
//             : netWorthYearly;
//     }
//   }
// }
//
// class ChartDataPoint {
//   final String period;
//   final double value;
//
//   ChartDataPoint({
//     required this.period,
//     required this.value,
//   });
//
//   factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
//     return ChartDataPoint(
//       period: json['period']?.toString() ?? '',
//       value: (json['value'] ?? 0.0).toDouble(),
//     );
//   }
// }
//
// enum FinancialChartType { revenue, profit, netWorth }
// enum FinancialChartPeriod { quarterly, yearly }
//
// // ============================================================================
// // MARKET DEPTH DATA
// // ============================================================================
// class MarketDepthData {
//   final double buyPercentage;
//   final double sellPercentage;
//   final List<OrderData> bidOrders;
//   final List<OrderData> askOrders;
//   final int bidTotal;
//   final int askTotal;
//
//   MarketDepthData({
//     this.buyPercentage = 0.0,
//     this.sellPercentage = 0.0,
//     this.bidOrders = const [],
//     this.askOrders = const [],
//     this.bidTotal = 0,
//     this.askTotal = 0,
//   });
//
//   factory MarketDepthData.fromJson(Map<String, dynamic> json) {
//     return MarketDepthData(
//       buyPercentage: (json['buy_percentage'] ?? 0.0).toDouble(),
//       sellPercentage: (json['sell_percentage'] ?? 0.0).toDouble(),
//       bidOrders: (json['bid_orders'] as List<dynamic>?)
//           ?.map((item) => OrderData.fromJson(item))
//           .toList() ??
//           [],
//       askOrders: (json['ask_orders'] as List<dynamic>?)
//           ?.map((item) => OrderData.fromJson(item))
//           .toList() ??
//           [],
//       bidTotal: json['bid_total'] ?? 0,
//       askTotal: json['ask_total'] ?? 0,
//     );
//   }
// }
//
// class OrderData {
//   final double price;
//   final int quantity;
//
//   const OrderData({
//     required this.price,
//     required this.quantity,
//   });
//
//   factory OrderData.fromJson(Map<String, dynamic> json) {
//     return OrderData(
//       price: (json['price'] ?? 0.0).toDouble(),
//       quantity: json['quantity'] ?? 0,
//     );
//   }
// }
//
// // ============================================================================
// // EXPANDABLE TILES DATA
// // ============================================================================
// class ExpandableTilesData {
//   final String aboutCompany;
//   final MarketDepthData marketDepth;
//   final FinancialMetrics fundamentals;
//   final FinancialChartsData financials;
//   final ShareholdingPatternData shareholdingPattern;
//
//   ExpandableTilesData({
//     this.aboutCompany = "",
//     required this.marketDepth,
//     required this.fundamentals,
//     required this.financials,
//     required this.shareholdingPattern,
//   });
//
//   factory ExpandableTilesData.fromJson(Map<String, dynamic> json) {
//     return ExpandableTilesData(
//       aboutCompany: json['about_company']?.toString() ?? "",
//       marketDepth: MarketDepthData.fromJson(json['market_depth'] ?? {}),
//       fundamentals: FinancialMetrics.fromJson(json['fundamentals'] ?? {}),
//       financials: FinancialChartsData.fromJson(json['financials'] ?? {}),
//       shareholdingPattern:
//       ShareholdingPatternData.fromJson(json['shareholding_pattern'] ?? {}),
//     );
//   }
// }
//
// // ============================================================================
// // SHAREHOLDING PATTERN DATA
// // ============================================================================
// class ShareholdingPatternData {
//   final List<String> timePeriods;
//   final List<Map<String, double>> shareholdingData;
//   final int defaultSelectedIndex;
//
//   ShareholdingPatternData({
//     this.timePeriods = const [],
//     this.shareholdingData = const [],
//     this.defaultSelectedIndex = 0,
//   });
//
//   factory ShareholdingPatternData.fromJson(Map<String, dynamic> json) {
//     final timePeriods = (json['time_periods'] as List<dynamic>?)
//         ?.map((period) => period.toString())
//         .toList() ??
//         [];
//
//     final shareholdingData = <Map<String, double>>[];
//     if (json['shareholding_data'] is List) {
//       for (var periodData in (json['shareholding_data'] as List)) {
//         if (periodData is Map<String, dynamic>) {
//           final Map<String, double> shareholding = {};
//           periodData.forEach((key, value) {
//             shareholding[key] = (value ?? 0.0).toDouble();
//           });
//           shareholdingData.add(shareholding);
//         }
//       }
//     }
//
//     return ShareholdingPatternData(
//       timePeriods: timePeriods,
//       shareholdingData: shareholdingData,
//       defaultSelectedIndex: json['default_selected_index'] ?? 0,
//     );
//   }
//
//   Map<String, double>? getShareholdingForPeriod(int index) {
//     if (index >= 0 && index < shareholdingData.length) {
//       return shareholdingData[index];
//     }
//     return null;
//   }
// }
//
// // ============================================================================
// // FUNDAMENTALS
// // ============================================================================
// class AssetFundamentals {
//   final List<FundamentalData> insights;
//   final String? marketInsight;
//   final ForYouCardData? forYouCard;
//
//   AssetFundamentals({
//     this.insights = const [],
//     this.marketInsight,
//     this.forYouCard,
//   });
//
//   factory AssetFundamentals.fromJson(Map<String, dynamic> json) {
//     return AssetFundamentals(
//       insights: (json['insights'] as List<dynamic>?)
//           ?.map((item) => FundamentalData.fromJson(item))
//           .toList() ??
//           [],
//       marketInsight: json['market_insight'],
//       forYouCard: json['for_you_card'] != null
//           ? ForYouCardData.fromJson(json['for_you_card'])
//           : null,
//     );
//   }
// }
//
// class FundamentalData {
//   final String imageName;
//   final String title;
//   final String description;
//
//   FundamentalData({
//     required this.imageName,
//     required this.title,
//     required this.description,
//   });
//
//   factory FundamentalData.fromJson(Map<String, dynamic> json) {
//     return FundamentalData(
//       imageName: json['image_name'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//     );
//   }
// }
//
// class ForYouCardData {
//   final String title;
//   final String content;
//
//   ForYouCardData({
//     this.title = "For you",
//     this.content = "",
//   });
//
//   factory ForYouCardData.fromJson(Map<String, dynamic> json) {
//     return ForYouCardData(
//       title: json['title']?.toString() ?? "For you",
//       content: json['content']?.toString() ?? "",
//     );
//   }
// }
//
// // ============================================================================
// // TECHNICALS (UPDATED: insights without image)
// // ============================================================================
// class AssetTechnicals {
//   final List<TechnicalInsight> insights;
//   final List<TechnicalIndicator> indicators;
//
//   AssetTechnicals({
//     this.insights = const [],
//     this.indicators = const [],
//   });
//
//   factory AssetTechnicals.fromJson(Map<String, dynamic> json) {
//     return AssetTechnicals(
//       insights: (json['insights'] as List<dynamic>?)
//           ?.map((item) => TechnicalInsight.fromJson(item))
//           .toList() ??
//           [],
//       indicators: (json['indicators'] as List<dynamic>?)
//           ?.map((item) => TechnicalIndicator.fromJson(item))
//           .toList() ??
//           [],
//     );
//   }
// }
//
// class TechnicalInsight {
//   final String title;
//   final String description;
//
//   TechnicalInsight({
//     required this.title,
//     required this.description,
//   });
//
//   factory TechnicalInsight.fromJson(Map<String, dynamic> json) {
//     return TechnicalInsight(
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//     );
//   }
// }
//
// class TechnicalIndicator {
//   final String name;
//   final double value;
//   final String signal;
//   final String description;
//
//   TechnicalIndicator({
//     required this.name,
//     required this.value,
//     required this.signal,
//     required this.description,
//   });
//
//   factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
//     return TechnicalIndicator(
//       name: json['name'] ?? '',
//       value: (json['value'] ?? 0.0).toDouble(),
//       signal: json['signal'] ?? 'HOLD',
//       description: json['description'] ?? '',
//     );
//   }
// }
//
// // ============================================================================
// // NEWS & EVENTS
// // ============================================================================
// class AssetNewsItem {
//   final String title;
//   final String description;
//   final String source;
//   final String timeAgo;
//   final String? imageUrl;
//   final DateTime publishedAt;
//   final String? url;
//
//   AssetNewsItem({
//     required this.title,
//     required this.description,
//     required this.source,
//     required this.timeAgo,
//     this.imageUrl,
//     required this.publishedAt,
//     this.url,
//   });
//
//   factory AssetNewsItem.fromJson(Map<String, dynamic> json) {
//     return AssetNewsItem(
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       source: json['source'] ?? '',
//       timeAgo: json['time_ago'] ?? '',
//       imageUrl: json['image_url'],
//       publishedAt: json['published_at'] != null
//           ? DateTime.parse(json['published_at'])
//           : DateTime.now(),
//       url: json['url'],
//     );
//   }
// }
//
// class AssetEvent {
//   final String title;
//   final String description;
//   final DateTime eventDate;
//   final String eventType;
//   final bool isUpcoming;
//
//   AssetEvent({
//     required this.title,
//     required this.description,
//     required this.eventDate,
//     required this.eventType,
//     required this.isUpcoming,
//   });
//
//   factory AssetEvent.fromJson(Map<String, dynamic> json) {
//     return AssetEvent(
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       eventDate: DateTime.parse(json['event_date']),
//       eventType: json['event_type'] ?? '',
//       isUpcoming: json['is_upcoming'] ?? true,
//     );
//   }
// }
//
// // ============================================================================
// // FUTURES & OPTIONS
// // ============================================================================
// class AssetFuturesOptions {
//   final List<FuturesContract> futures;
//   final List<OptionsContract> options;
//
//   AssetFuturesOptions({
//     this.futures = const [],
//     this.options = const [],
//   });
//
//   factory AssetFuturesOptions.fromJson(Map<String, dynamic> json) {
//     return AssetFuturesOptions(
//       futures: (json['futures'] as List<dynamic>?)
//           ?.map((item) => FuturesContract.fromJson(item))
//           .toList() ??
//           [],
//       options: (json['options'] as List<dynamic>?)
//           ?.map((item) => OptionsContract.fromJson(item))
//           .toList() ??
//           [],
//     );
//   }
// }
//
// class FuturesContract {
//   final String symbol;
//   final DateTime expiry;
//   final double price;
//   final double changeAmount;
//   final double changePercent;
//   final String volume;
//   final String openInterest;
//
//   FuturesContract({
//     required this.symbol,
//     required this.expiry,
//     required this.price,
//     required this.changeAmount,
//     required this.changePercent,
//     required this.volume,
//     required this.openInterest,
//   });
//
//   factory FuturesContract.fromJson(Map<String, dynamic> json) {
//     return FuturesContract(
//       symbol: json['symbol'] ?? '',
//       expiry: DateTime.parse(json['expiry']),
//       price: (json['price'] ?? 0.0).toDouble(),
//       changeAmount: (json['change_amount'] ?? 0.0).toDouble(),
//       changePercent: (json['change_percent'] ?? 0.0).toDouble(),
//       volume: json['volume']?.toString() ?? '0',
//       openInterest: json['open_interest']?.toString() ?? '0',
//     );
//   }
// }
//
// class OptionsContract {
//   final String symbol;
//   final DateTime expiry;
//   final double strikePrice;
//   final String optionType;
//   final double price;
//   final double changeAmount;
//   final double changePercent;
//   final String volume;
//   final String openInterest;
//   final double? impliedVolatility;
//
//   OptionsContract({
//     required this.symbol,
//     required this.expiry,
//     required this.strikePrice,
//     required this.optionType,
//     required this.price,
//     required this.changeAmount,
//     required this.changePercent,
//     required this.volume,
//     required this.openInterest,
//     this.impliedVolatility,
//   });
//
//   factory OptionsContract.fromJson(Map<String, dynamic> json) {
//     return OptionsContract(
//       symbol: json['symbol'] ?? '',
//       expiry: DateTime.parse(json['expiry']),
//       strikePrice: (json['strike_price'] ?? 0.0).toDouble(),
//       optionType: json['option_type'] ?? 'CALL',
//       price: (json['price'] ?? 0.0).toDouble(),
//       changeAmount: (json['change_amount'] ?? 0.0).toDouble(),
//       changePercent: (json['change_percent'] ?? 0.0).toDouble(),
//       volume: json['volume']?.toString() ?? '0',
//       openInterest: json['open_interest']?.toString() ?? '0',
//       impliedVolatility: (json['implied_volatility'] as num?)?.toDouble(),
//     );
//   }
// }
//
// // ============================================================================
// // ADDITIONAL DATA (NEW TYPED MODEL)
// // ============================================================================
// class AdditionalData {
//   final DateTime? dataFreshness;
//   final String marketStatus;
//   final String currencySymbol;
//   final String timezone;
//
//   final List<UserNote> userNotes;
//   final bool userWatchlisted;
//   final List<WatchlistStock> watchlistStocks;
//
//   AdditionalData({
//     this.dataFreshness,
//     this.marketStatus = "CLOSED",
//     this.currencySymbol = "₹",
//     this.timezone = "Asia/Kolkata",
//     this.userNotes = const [],
//     this.userWatchlisted = false,
//     this.watchlistStocks = const [],
//   });
//
//   factory AdditionalData.fromJson(Map<String, dynamic> json) {
//     return AdditionalData(
//       dataFreshness: json['data_freshness'] != null
//           ? DateTime.tryParse(json['data_freshness'])
//           : null,
//       marketStatus: json['market_status']?.toString() ?? "CLOSED",
//       currencySymbol: json['currency_symbol']?.toString() ?? "₹",
//       timezone: json['timezone']?.toString() ?? "Asia/Kolkata",
//       userNotes: (json['user_notes'] as List<dynamic>?)
//           ?.map((n) => UserNote.fromJson(n))
//           .toList() ??
//           [],
//       userWatchlisted: json['user_watchlisted'] ?? false,
//       watchlistStocks: (json['watchlist_stocks'] as List<dynamic>?)
//           ?.map((s) => WatchlistStock.fromJson(s))
//           .toList() ??
//           [],
//     );
//   }
// }
//
// class UserNote {
//   final String id;
//   final String title;
//   final String content;
//   final DateTime createdAt;
//
//   UserNote({
//     required this.id,
//     required this.title,
//     required this.content,
//     required this.createdAt,
//   });
//
//   factory UserNote.fromJson(Map<String, dynamic> json) {
//     return UserNote(
//       id: json['id'] ?? '',
//       title: json['title'] ?? '',
//       content: json['content'] ?? '',
//       createdAt: json['created_at'] != null
//           ? DateTime.parse(json['created_at'])
//           : DateTime.now(),
//     );
//   }
// }
//
// class WatchlistStock {
//   final String symbol;
//   final String name;
//   final String? logoUrl;
//   final double currentPrice;
//   final double changePercent;
//   final bool isPositive;
//
//   WatchlistStock({
//     required this.symbol,
//     required this.name,
//     this.logoUrl,
//     required this.currentPrice,
//     required this.changePercent,
//     required this.isPositive,
//   });
//
//   factory WatchlistStock.fromJson(Map<String, dynamic> json) {
//     return WatchlistStock(
//       symbol: json['symbol'] ?? '',
//       name: json['name'] ?? '',
//       logoUrl: json['logo_url'],
//       currentPrice: (json['current_price'] ?? 0.0).toDouble(),
//       changePercent: (json['change_percent'] ?? 0.0).toDouble(),
//       isPositive: json['is_positive'] ?? true,
//     );
//   }
// }




// ============================================================================
// ASSET MODELS (updated)
// ============================================================================

class AssetData {
  final String assetId;
  final AssetBasicInfo basicInfo;
  final AssetPriceData priceData;
  final AssetChartData chartData;
  final AssetPortfolioData? portfolioData;
  final AssetPerformanceData performanceData;
  final AssetFundamentals fundamentals;
  final AssetTechnicals technicals;
  final List<AssetNewsItem> news;
  final List<AssetEvent> events;
  final AssetFuturesOptions? futuresOptions;
  final AdditionalData? additionalData;

  // NEW: root-level expandable tiles
  final ExpandableTilesData? expandableTiles;

  AssetData({
    required this.assetId,
    required this.basicInfo,
    required this.priceData,
    required this.chartData,
    this.portfolioData,
    required this.performanceData,
    required this.fundamentals,
    required this.technicals,
    this.news = const [],
    this.events = const [],
    this.futuresOptions,
    this.additionalData,
    this.expandableTiles, // NEW
  });

  factory AssetData.fromJson(Map<String, dynamic> json) {
    return AssetData(
      assetId: json['asset_id']?.toString() ?? '',
      basicInfo: AssetBasicInfo.fromJson(json['basic_info'] ?? const {}),
      priceData: AssetPriceData.fromJson(json['price_data'] ?? const {}),
      chartData: AssetChartData.fromJson(json['chart_data'] ?? const {}),
      portfolioData: json['portfolio_data'] != null
          ? AssetPortfolioData.fromJson(json['portfolio_data'] as Map<String, dynamic>)
          : null,
      performanceData: AssetPerformanceData.fromJson(json['performance_data'] ?? const {}),
      fundamentals: AssetFundamentals.fromJson(json['fundamentals'] ?? const {}),
      technicals: AssetTechnicals.fromJson(json['technicals'] ?? const {}),
      news: (json['news'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(AssetNewsItem.fromJson)
          .toList() ??
          const [],
      events: (json['events'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(AssetEvent.fromJson)
          .toList() ??
          const [],
      futuresOptions: json['futures_options'] != null
          ? AssetFuturesOptions.fromJson(json['futures_options'] as Map<String, dynamic>)
          : null,
      additionalData: json['additional_data'] != null
          ? AdditionalData.fromJson(json['additional_data'] as Map<String, dynamic>)
          : null,
      expandableTiles: json['expandable_tiles'] != null
          ? ExpandableTilesData.fromJson(json['expandable_tiles'] as Map<String, dynamic>)
          : null,
    );
  }
}


// ============================================================================
// BASIC INFO (exchange can be String or List -> normalized to String)
// ============================================================================
class AssetBasicInfo {
  final String name;
  final String symbol;
  final String? logoUrl;
  final String? description;
  final String sector;
  final String industry;
  final String exchange; // kept as single string for UI compatibility
  final String currency;

  AssetBasicInfo({
    required this.name,
    required this.symbol,
    this.logoUrl,
    this.description,
    required this.sector,
    required this.industry,
    required this.exchange,
    this.currency = 'INR',
  });

  factory AssetBasicInfo.fromJson(Map<String, dynamic> json) {
    final dynamic ex = json['exchange'];
    final String exchangeStr = ex is List
        ? (ex.isNotEmpty ? ex.map((e) => e.toString()).join(', ') : '')
        : (ex?.toString() ?? '');

    return AssetBasicInfo(
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      description: json['description']?.toString(),
      sector: json['sector']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      exchange: exchangeStr,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}

// ============================================================================
// PRICE DATA
// ============================================================================
class AssetPriceData {
  final double currentPrice;
  final double changeAmount;
  final double changePercent;
  final bool isPositive;
  final double openPrice;
  final double prevClose;
  final double dayHigh;
  final double dayLow;
  final String volume; // formatted or raw -> always string here
  final double? lowerCircuit;
  final double? upperCircuit;
  final DateTime lastUpdated;

  AssetPriceData({
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.isPositive,
    required this.openPrice,
    required this.prevClose,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    this.lowerCircuit,
    this.upperCircuit,
    required this.lastUpdated,
  });

  factory AssetPriceData.fromJson(Map<String, dynamic> json) {
    final changeAmount = (json['change_amount'] is num)
        ? (json['change_amount'] as num).toDouble()
        : double.tryParse(json['change_amount']?.toString() ?? '') ?? 0.0;

    return AssetPriceData(
      currentPrice: _asDouble(json['current_price']),
      changeAmount: changeAmount,
      changePercent: _asDouble(json['change_percent']),
      isPositive: (json['is_positive'] as bool?) ?? (changeAmount >= 0),
      openPrice: _asDouble(json['open_price']),
      prevClose: _asDouble(json['prev_close']),
      dayHigh: _asDouble(json['day_high']),
      dayLow: _asDouble(json['day_low']),
      volume: json['volume']?.toString() ?? '0',
      lowerCircuit: _asNullableDouble(json['lower_circuit']),
      upperCircuit: _asNullableDouble(json['upper_circuit']),
      lastUpdated: _parseDateTime(json['last_updated']),
    );
  }
}

// ============================================================================
// CHART DATA (accepts time_series + top-level periods; builds ALL if missing)
// ============================================================================
class AssetChartData {
  final Map<String, List<ChartPoint>> timeSeriesData;
  final String defaultPeriod;

  AssetChartData({
    required this.timeSeriesData,
    this.defaultPeriod = '1W',
  });

  factory AssetChartData.fromJson(Map<String, dynamic> json) {
    final out = <String, List<ChartPoint>>{};

    // 1) Proper "time_series" map
    final ts = json['time_series'];
    if (ts is Map<String, dynamic>) {
      ts.forEach((period, data) {
        if (data is List) {
          out[period] = data
              .whereType<Map<String, dynamic>>()
              .map(ChartPoint.fromJson)
              .toList();
        }
      });
    }

    // 2) Some VMs accidentally put "1M"/etc at top-level of chart_data
    const known = ['1D', '1W', '1M', '1Y', '5Y', 'ALL'];
    for (final p in known) {
      final v = json[p];
      if (v is List && !out.containsKey(p)) {
        out[p] = v.whereType<Map<String, dynamic>>().map(ChartPoint.fromJson).toList();
      }
    }

    // 3) Ensure ALL exists by merging what we have, then sort & dedupe by timestamp
    if (!out.containsKey('ALL')) {
      final merged = <ChartPoint>[];
      for (final p in ['5Y', '1Y', '1M', '1W', '1D']) {
        final list = out[p];
        if (list != null) merged.addAll(list);
      }
      if (merged.isNotEmpty) {
        merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final unique = <int, ChartPoint>{};
        for (final pt in merged) {
          unique[pt.timestamp.millisecondsSinceEpoch] = pt; // keep last for same ts
        }
        out['ALL'] = unique.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    }

    // 4) Decide default period
    final dp = json['default_period']?.toString();
    final effectiveDefault = (dp != null && out.containsKey(dp))
        ? dp
        : (out.containsKey('ALL')
        ? 'ALL'
        : (out.keys.isNotEmpty ? out.keys.first : 'ALL'));

    return AssetChartData(timeSeriesData: out, defaultPeriod: effectiveDefault);
  }

  List<ChartPoint>? getDataForPeriod(String period) => timeSeriesData[period];
}

class ChartPoint {
  final DateTime timestamp;
  final double price;
  final double? volume;
  final double? high;
  final double? low;
  final double? open;

  ChartPoint({
    required this.timestamp,
    required this.price,
    this.volume,
    this.high,
    this.low,
    this.open,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      timestamp: _parseFlexibleTs(json['timestamp']),
      price: _asDouble(json['price']),
      volume: _asNullableDouble(json['volume']),
      high: _asNullableDouble(json['high']),
      low: _asNullableDouble(json['low']),
      open: _asNullableDouble(json['open']),
    );
  }

  static DateTime _parseFlexibleTs(dynamic v) {
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (v is num) {
      // treat as epoch ms
      return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

// ============================================================================
// PORTFOLIO DATA
// ============================================================================
class AssetPortfolioData {
  final int shares;
  final double avgPrice;
  final double currentValue;
  final double changePercent;
  final double changeAmount;
  final bool isPositive;
  final double investedAmount;
  final double unrealizedPnL;

  AssetPortfolioData({
    required this.shares,
    required this.avgPrice,
    required this.currentValue,
    required this.changePercent,
    required this.changeAmount,
    required this.isPositive,
    required this.investedAmount,
    required this.unrealizedPnL,
  });

  factory AssetPortfolioData.fromJson(Map<String, dynamic> json) {
    final changeAmount = _asDouble(json['change_amount']);
    return AssetPortfolioData(
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      avgPrice: _asDouble(json['avg_price']),
      currentValue: _asDouble(json['current_value']),
      changePercent: _asDouble(json['change_percent']),
      changeAmount: changeAmount,
      isPositive: (json['is_positive'] as bool?) ?? (changeAmount >= 0),
      investedAmount: _asDouble(json['invested_amount']),
      unrealizedPnL: _asDouble(json['unrealized_pnl']),
    );
  }
}

// ============================================================================
// PERFORMANCE DATA
// ============================================================================
class AssetPerformanceData {
  final double todayLow;
  final double todayHigh;
  final double week52Low;
  final double week52High;
  final double openPrice;
  final double prevClose;
  final String volume;
  final double lowerCircuit;
  final double upperCircuit;

  AssetPerformanceData({
    required this.todayLow,
    required this.todayHigh,
    required this.week52Low,
    required this.week52High,
    required this.openPrice,
    required this.prevClose,
    required this.volume,
    required this.lowerCircuit,
    required this.upperCircuit,
  });

  factory AssetPerformanceData.fromJson(Map<String, dynamic> json) {
    return AssetPerformanceData(
      todayLow: _asDouble(json['today_low']),
      todayHigh: _asDouble(json['today_high']),
      week52Low: _asDouble(json['week_52_low']),
      week52High: _asDouble(json['week_52_high']),
      openPrice: _asDouble(json['open_price']),
      prevClose: _asDouble(json['prev_close']),
      volume: json['volume']?.toString() ?? '0',
      lowerCircuit: _asDouble(json['lower_circuit']),
      upperCircuit: _asDouble(json['upper_circuit']),
    );
  }
}


// ============================================================================
// FINANCIAL METRICS
// ============================================================================
class FinancialMetrics {
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

  FinancialMetrics({
    this.marketCap = "₹0Cr",
    this.roe = "0.00%",
    this.peRatio = "0.00",
    this.eps = "0.00",
    this.pbRatio = "0.00",
    this.divYield = "0.00%",
    this.industryPE = "0.00",
    this.bookValue = "0.00",
    this.debtToEquity = "0.00",
    this.faceValue = "0",
  });

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      marketCap: json['market_cap']?.toString() ?? "₹0Cr",
      roe: json['roe']?.toString() ?? "0.00%",
      peRatio: json['pe_ratio']?.toString() ?? "0.00",
      eps: json['eps']?.toString() ?? "0.00",
      pbRatio: json['pb_ratio']?.toString() ?? "0.00",
      divYield: json['div_yield']?.toString() ?? "0.00%",
      industryPE: json['industry_pe']?.toString() ?? "0.00",
      bookValue: json['book_value']?.toString() ?? "0.00",
      debtToEquity: json['debt_to_equity']?.toString() ?? "0.00",
      faceValue: json['face_value']?.toString() ?? "0",
    );
  }
}

// ============================================================================
// FINANCIAL CHARTS DATA
// ============================================================================
class FinancialChartsData {
  final List<ChartDataPoint> revenueQuarterly;
  final List<ChartDataPoint> revenueYearly;
  final List<ChartDataPoint> profitQuarterly; // maps from net_income_quarterly if profit_quarterly missing
  final List<ChartDataPoint> profitYearly;    // maps from net_income_yearly if profit_yearly missing
  final List<ChartDataPoint> netWorthQuarterly;
  final List<ChartDataPoint> netWorthYearly;
  final List<ChartDataPoint> ebitdaQuarterly; // NEW (optional)
  final List<ChartDataPoint> ebitdaYearly;    // NEW (optional)
  final String valueUnit;

  FinancialChartsData({
    this.revenueQuarterly = const [],
    this.revenueYearly = const [],
    this.profitQuarterly = const [],
    this.profitYearly = const [],
    this.netWorthQuarterly = const [],
    this.netWorthYearly = const [],
    this.ebitdaQuarterly = const [],
    this.ebitdaYearly = const [],
    this.valueUnit = "Rs. CR",
  });

  factory FinancialChartsData.fromJson(Map<String, dynamic> json) {
    List<ChartDataPoint> _chart(dynamic v) =>
        (v as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ChartDataPoint.fromJson)
            .toList() ??
            const [];

    // Prefer canonical keys; fallback to aliases from response
    final pq = _chart(json['profit_quarterly']);
    final py = _chart(json['profit_yearly']);

    final niq = _chart(json['net_income_quarterly']);
    final niy = _chart(json['net_income_yearly']);

    return FinancialChartsData(
      revenueQuarterly: _chart(json['revenue_quarterly']),
      revenueYearly: _chart(json['revenue_yearly']),
      profitQuarterly: pq.isNotEmpty ? pq : niq,
      profitYearly:    py.isNotEmpty ? py : niy,
      netWorthQuarterly: _chart(json['net_worth_quarterly']),
      netWorthYearly:    _chart(json['net_worth_yearly']),
      ebitdaQuarterly:   _chart(json['EBITDA_quarterly']),
      ebitdaYearly:      _chart(json['EBITDA_yearly']),
      valueUnit: json['value_unit']?.toString() ?? "Rs. CR",
    );
  }

  List<ChartDataPoint> getDataForChart({
    required FinancialChartType chartType,
    required FinancialChartPeriod period,
  }) {
    switch (chartType) {
      case FinancialChartType.revenue:
        return period == FinancialChartPeriod.quarterly ? revenueQuarterly : revenueYearly;
      case FinancialChartType.profit:
        return period == FinancialChartPeriod.quarterly ? profitQuarterly : profitYearly;
      case FinancialChartType.netWorth:
        return period == FinancialChartPeriod.quarterly ? netWorthQuarterly : netWorthYearly;
    }
  }
}


class ChartDataPoint {
  final String period;
  final double value;

  ChartDataPoint({required this.period, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      period: json['period']?.toString() ?? '',
      value: _asDouble(json['value']),
    );
  }
}

enum FinancialChartType { revenue, profit, netWorth }
enum FinancialChartPeriod { quarterly, yearly }

// ============================================================================
// MARKET DEPTH DATA
// ============================================================================
class MarketDepthData {
  final double buyPercentage;
  final double sellPercentage;
  final List<OrderData> bidOrders;
  final List<OrderData> askOrders;
  final int bidTotal;
  final int askTotal;

  MarketDepthData({
    this.buyPercentage = 0.0,
    this.sellPercentage = 0.0,
    this.bidOrders = const [],
    this.askOrders = const [],
    this.bidTotal = 0,
    this.askTotal = 0,
  });

  factory MarketDepthData.fromJson(Map<String, dynamic> json) {
    return MarketDepthData(
      buyPercentage: _asDouble(json['buy_percentage']),
      sellPercentage: _asDouble(json['sell_percentage']),
      bidOrders: (json['bid_orders'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(OrderData.fromJson)
          .toList() ??
          const [],
      askOrders: (json['ask_orders'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(OrderData.fromJson)
          .toList() ??
          const [],
      bidTotal: (json['bid_total'] as num?)?.toInt() ?? 0,
      askTotal: (json['ask_total'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderData {
  final double price;
  final int quantity;
  final int orders; // NEW

  const OrderData({required this.price, required this.quantity, this.orders = 0});

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      price: _asDouble(json['price']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }
}


// ============================================================================
// EXPANDABLE TILES DATA
// ============================================================================
class ExpandableTilesData {
  final String aboutCompany;
  final MarketDepthData marketDepth;
  final FinancialMetrics fundamentals;
  final FinancialChartsData financials;
  final ShareholdingPatternData shareholdingPattern;

  ExpandableTilesData({
    this.aboutCompany = "",
    required this.marketDepth,
    required this.fundamentals,
    required this.financials,
    required this.shareholdingPattern,
  });

  factory ExpandableTilesData.fromJson(Map<String, dynamic> json) {
    return ExpandableTilesData(
      aboutCompany: json['about_company']?.toString() ?? "",
      marketDepth: MarketDepthData.fromJson(json['market_depth'] ?? const {}),
      fundamentals: FinancialMetrics.fromJson(json['fundamentals'] ?? const {}),
      financials: FinancialChartsData.fromJson(json['financials'] ?? const {}),
      shareholdingPattern:
      ShareholdingPatternData.fromJson(json['shareholding_pattern'] ?? const {}),
    );
  }
}

// ============================================================================
// SHAREHOLDING PATTERN DATA (robust double casting)
// ============================================================================
class ShareholdingPatternData {
  final List<String> timePeriods;
  final List<Map<String, double>> shareholdingData;
  final int defaultSelectedIndex;

  ShareholdingPatternData({
    this.timePeriods = const [],
    this.shareholdingData = const [],
    this.defaultSelectedIndex = 0,
  });

  factory ShareholdingPatternData.fromJson(Map<String, dynamic> json) {
    final periods = (json['time_periods'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        const [];

    final data = <Map<String, double>>[];
    final raw = json['shareholding_data'];
    if (raw is List) {
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final map = <String, double>{};
        item.forEach((k, v) {
          map[k] = (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);
        });
        data.add(map);
      }
    }

    return ShareholdingPatternData(
      timePeriods: periods,
      shareholdingData: data,
      defaultSelectedIndex: (json['default_selected_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, double>? getShareholdingForPeriod(int index) {
    if (index >= 0 && index < shareholdingData.length) {
      return shareholdingData[index];
    }
    return null;
  }
}

// ============================================================================
// FUNDAMENTALS
// ============================================================================
class AssetFundamentals {
  final List<FundamentalData> insights;
  final String? marketInsight;
  final ForYouCardData? forYouCard;

  AssetFundamentals({this.insights = const [], this.marketInsight, this.forYouCard});

  factory AssetFundamentals.fromJson(Map<String, dynamic> json) {
    return AssetFundamentals(
      insights: (json['insights'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(FundamentalData.fromJson)
          .toList() ??
          const [],
      marketInsight: json['market_insight']?.toString(),
      forYouCard: json['for_you_card'] != null
          ? ForYouCardData.fromJson(json['for_you_card'] as Map<String, dynamic>)
          : null,
    );
  }
}

// --- FUNDAMENTALS ITEM ---
class FundamentalData {
  final String imageName;
  final String title;          // UI code unchanged
  final String description;

  FundamentalData({
    required this.imageName,
    required this.title,
    required this.description,
  });

  factory FundamentalData.fromJson(Map<String, dynamic> json) {
    return FundamentalData(
      imageName: json['image_name']?.toString() ?? '',
      title: (json['header'] ?? json['title'] ?? '').toString(),
      description: json['description']?.toString() ?? '',
    );
  }
}


class ForYouCardData {
  final String title;    // keep as 'title' in app
  final String content;

  ForYouCardData({this.title = "For you", this.content = ""});

  factory ForYouCardData.fromJson(Map<String, dynamic> json) {
    return ForYouCardData(
      title: (json['header'] ?? json['title'] ?? "For you").toString(),
      content: json['content']?.toString() ?? "",
    );
  }
}

// ============================================================================
// TECHNICALS
// ============================================================================
class AssetTechnicals {
  final List<TechnicalInsight> insights;
  final List<TechnicalIndicator> indicators;

  AssetTechnicals({this.insights = const [], this.indicators = const []});

  factory AssetTechnicals.fromJson(Map<String, dynamic> json) {
    return AssetTechnicals(
      insights: (json['insights'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(TechnicalInsight.fromJson)
          .toList() ??
          const [],
      indicators: (json['indicators'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(TechnicalIndicator.fromJson)
          .toList() ??
          const [],
    );
  }
}

class TechnicalInsight {
  final String title;         // keep same field for UI
  final String description;

  TechnicalInsight({required this.title, required this.description});

  factory TechnicalInsight.fromJson(Map<String, dynamic> json) {
    return TechnicalInsight(
      title: (json['header'] ?? json['title'] ?? '').toString(),
      description: json['description']?.toString() ?? '',
    );
  }
}

class TechnicalIndicator {
  final String name;
  final double value;
  final String signal;
  final String description;

  TechnicalIndicator({
    required this.name,
    required this.value,
    required this.signal,
    required this.description,
  });

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      name: json['name']?.toString() ?? '',
      value: _asDouble(json['value']),
      signal: json['signal']?.toString() ?? 'HOLD',
      description: json['description']?.toString() ?? '',
    );
  }
}

// ============================================================================
// NEWS & EVENTS
// ============================================================================
class AssetNewsItem {
  final String title;
  final String description;
  final String source;
  final String timeAgo;
  final String? imageUrl;
  final DateTime? publishedAt; // ← nullable
  final String? url;

  AssetNewsItem({
    required this.title,
    required this.description,
    required this.source,
    required this.timeAgo,
    this.imageUrl,
    this.publishedAt,
    this.url,
  });

  factory AssetNewsItem.fromJson(Map<String, dynamic> json) {
    return AssetNewsItem(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      publishedAt: _tryParseDateTime(json['published_at']), // ← keeps null
      url: json['url']?.toString(),
    );
  }
}


class AssetEvent {
  final String title;
  final String description;
  final DateTime eventDate;
  final String eventType;
  final bool isUpcoming;

  AssetEvent({
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventType,
    required this.isUpcoming,
  });

  factory AssetEvent.fromJson(Map<String, dynamic> json) {
    return AssetEvent(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      eventDate: _parseDateTime(json['event_date']),
      eventType: json['event_type']?.toString() ?? '',
      isUpcoming: (json['is_upcoming'] as bool?) ?? true,
    );
  }
}

// ============================================================================
// FUTURES & OPTIONS
// ============================================================================
class AssetFuturesOptions {
  final List<FuturesContract> futures;
  final List<OptionsContract> options;

  AssetFuturesOptions({this.futures = const [], this.options = const []});

  factory AssetFuturesOptions.fromJson(Map<String, dynamic> json) {
    return AssetFuturesOptions(
      futures: (json['futures'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(FuturesContract.fromJson)
          .toList() ??
          const [],
      options: (json['options'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(OptionsContract.fromJson)
          .toList() ??
          const [],
    );
  }
}

class FuturesContract {
  final String symbol;
  final DateTime expiry;
  final double price;
  final double changeAmount;
  final double changePercent;
  final String volume;
  final String openInterest;

  FuturesContract({
    required this.symbol,
    required this.expiry,
    required this.price,
    required this.changeAmount,
    required this.changePercent,
    required this.volume,
    required this.openInterest,
  });

  factory FuturesContract.fromJson(Map<String, dynamic> json) {
    return FuturesContract(
      symbol: json['symbol']?.toString() ?? '',
      expiry: _parseDateTime(json['expiry']),
      price: _asDouble(json['price']),
      changeAmount: _asDouble(json['change_amount']),
      changePercent: _asDouble(json['change_percent']),
      volume: json['volume']?.toString() ?? '0',
      openInterest: json['open_interest']?.toString() ?? '0',
    );
  }
}

class OptionsContract {
  final String symbol;
  final DateTime expiry;
  final double strikePrice;
  final String optionType;
  final double price;
  final double changeAmount;
  final double changePercent;
  final String volume;
  final String openInterest;
  final double? impliedVolatility;

  OptionsContract({
    required this.symbol,
    required this.expiry,
    required this.strikePrice,
    required this.optionType,
    required this.price,
    required this.changeAmount,
    required this.changePercent,
    required this.volume,
    required this.openInterest,
    this.impliedVolatility,
  });

  factory OptionsContract.fromJson(Map<String, dynamic> json) {
    return OptionsContract(
      symbol: json['symbol']?.toString() ?? '',
      expiry: _parseDateTime(json['expiry']),
      strikePrice: _asDouble(json['strike_price']),
      optionType: json['option_type']?.toString() ?? 'CALL',
      price: _asDouble(json['price']),
      changeAmount: _asDouble(json['change_amount']),
      changePercent: _asDouble(json['change_percent']),
      volume: json['volume']?.toString() ?? '0',
      openInterest: json['open_interest']?.toString() ?? '0',
      impliedVolatility: _asNullableDouble(json['implied_volatility']),
    );
  }
}

// ============================================================================
// ADDITIONAL DATA
// ============================================================================
class AdditionalData {
  final DateTime? dataFreshness;
  final String marketStatus;
  final String currencySymbol;
  final String timezone;
  final List<UserNote> userNotes;
  final bool userWatchlisted;
  final List<WatchlistStock> watchlistStocks;

  AdditionalData({
    this.dataFreshness,
    this.marketStatus = "CLOSED",
    this.currencySymbol = "₹",
    this.timezone = "Asia/Kolkata",
    this.userNotes = const [],
    this.userWatchlisted = false,
    this.watchlistStocks = const [],
  });

  factory AdditionalData.fromJson(Map<String, dynamic> json) {
    return AdditionalData(
      dataFreshness: _tryParseDateTime(json['data_freshness']),
      marketStatus: json['market_status']?.toString() ?? "CLOSED",
      currencySymbol: json['currency_symbol']?.toString() ?? "₹",
      timezone: json['timezone']?.toString() ?? "Asia/Kolkata",
      userNotes: (json['user_notes'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(UserNote.fromJson)
          .toList() ??
          const [],
      userWatchlisted: (json['user_watchlisted'] as bool?) ?? false,
      watchlistStocks: (json['watchlist_stocks'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(WatchlistStock.fromJson)
          .toList() ??
          const [],
    );
  }
}

class UserNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  UserNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class WatchlistStock {
  final String symbol;
  final String name;
  final String? logoUrl;
  final double currentPrice;
  final double changePercent;
  final bool isPositive;

  WatchlistStock({
    required this.symbol,
    required this.name,
    this.logoUrl,
    required this.currentPrice,
    required this.changePercent,
    required this.isPositive,
  });

  factory WatchlistStock.fromJson(Map<String, dynamic> json) {
    return WatchlistStock(
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      currentPrice: _asDouble(json['current_price']),
      changePercent: _asDouble(json['change_percent']),
      isPositive: (json['is_positive'] as bool?) ?? true,
    );
  }
}

// ============================================================================
// Helpers
// ============================================================================
double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

double? _asNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime _parseDateTime(String s) {
  final dt = DateTime.tryParse(s);
  if (dt == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final ist = dt.isUtc ? dt.toUtc() : dt; // treat as local naive
  // If you want to force IST → then subtract 5:30 to convert to UTC storage:
  return DateTime.utc(ist.year, ist.month, ist.day, ist.hour - 5, ist.minute - 30, ist.second);
}


DateTime? _tryParseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  if (v is String) return DateTime.tryParse(v)?.toUtc();
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
  return null;
}
