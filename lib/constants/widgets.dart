import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vscmoney/services/theme_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/helpers/themes.dart';
import '../models/chat_message.dart';
import 'colors.dart';







class AnimatedComingSoonTooltip extends StatefulWidget {
  @override
  _AnimatedComingSoonTooltipState createState() => _AnimatedComingSoonTooltipState();
}

class _AnimatedComingSoonTooltipState extends State<AnimatedComingSoonTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Coming Soon!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}



class ComingSoonTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Text(
        "Coming soon",
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class StockDetailBottomSheet extends StatelessWidget {
  final String stockName;

  const StockDetailBottomSheet({
    Key? key,
    required this.stockName,
  }) : super(key: key);

  // Dummy stock data
  Map<String, dynamic> _getStockDetails(String stockName) {
    final stockData = {
      'Zomato': {
        'symbol': 'ZOMATO',
        'currentPrice': '₹156.75',
        'dayChange': '+₹2.25 (+1.46%)',
        'dayHigh': '₹159.00',
        'dayLow': '₹154.20',
        'volume': '45,67,890',
        'marketCap': '₹1,38,234 Cr',
        'pe': '64.2',
        'sector': 'Consumer Services',
        'about': 'Zomato is an Indian restaurant aggregator and food delivery company founded in 2008.',
      },
      'TCS': {
        'symbol': 'TCS',
        'currentPrice': '₹3,245.80',
        'dayChange': '+₹45.30 (+1.42%)',
        'dayHigh': '₹3,267.90',
        'dayLow': '₹3,198.50',
        'volume': '12,34,567',
        'marketCap': '₹11,86,789 Cr',
        'pe': '28.5',
        'sector': 'Information Technology',
        'about': 'Tata Consultancy Services is an Indian IT services and consulting company.',
      },
      'Reliance': {
        'symbol': 'RELIANCE',
        'currentPrice': '₹2,678.90',
        'dayChange': '-₹12.50 (-0.46%)',
        'dayHigh': '₹2,698.00',
        'dayLow': '₹2,665.30',
        'volume': '23,45,678',
        'marketCap': '₹18,12,456 Cr',
        'pe': '25.8',
        'sector': 'Oil & Gas',
        'about': 'Reliance Industries is an Indian conglomerate company headquartered in Mumbai.',
      },
      'HDFC Bank': {
        'symbol': 'HDFCBANK',
        'currentPrice': '₹1,567.25',
        'dayChange': '+₹23.75 (+1.54%)',
        'dayHigh': '₹1,578.90',
        'dayLow': '₹1,543.50',
        'volume': '34,56,789',
        'marketCap': '₹11,89,234 Cr',
        'pe': '18.9',
        'sector': 'Banking',
        'about': 'HDFC Bank is one of India\'s leading private sector banks.',
      },
      'Infosys': {
        'symbol': 'INFY',
        'currentPrice': '₹1,389.60',
        'dayChange': '+₹18.90 (+1.38%)',
        'dayHigh': '₹1,402.30',
        'dayLow': '₹1,370.70',
        'volume': '18,67,234',
        'marketCap': '₹5,78,901 Cr',
        'pe': '22.4',
        'sector': 'Information Technology',
        'about': 'Infosys is an Indian IT services and consulting company.',
      },
    };

    return stockData[stockName] ?? {
      'symbol': stockName.toUpperCase(),
      'currentPrice': '₹100.00',
      'dayChange': '+₹0.00 (0.00%)',
      'dayHigh': '₹100.00',
      'dayLow': '₹100.00',
      'volume': '0',
      'marketCap': '₹0 Cr',
      'pe': 'N/A',
      'sector': 'Unknown',
      'about': 'Stock information not available.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final stockData = _getStockDetails(stockName);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    stockData['symbol'].substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stockName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stockData['symbol'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Section
                  _buildPriceSection(stockData),
                  const SizedBox(height: 24),

                  // Key Metrics
                  _buildKeyMetrics(stockData),
                  const SizedBox(height: 24),

                  // About Section
                  _buildAboutSection(stockData),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Map<String, dynamic> stockData) {
    final isPositive = stockData['dayChange'].contains('+');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stockData['currentPrice'],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                stockData['dayChange'],
                style: TextStyle(
                  fontSize: 16,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(Map<String, dynamic> stockData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Day High', stockData['dayHigh'])),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Day Low', stockData['dayLow'])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Volume', stockData['volume'])),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Market Cap', stockData['marketCap'])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('P/E Ratio', stockData['pe'])),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Sector', stockData['sector'])),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> stockData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stockData['about'],
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Buy order placed for ${stockName}')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sell order placed for ${stockName}')),
              );
            },
            icon: const Icon(Icons.remove),
            label: const Text('Sell'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}














class PremiumShimmerWidget extends StatefulWidget {
  final String text;
  final bool isComplete;
  final Color baseColor;        // main text tone
  final Color highlightColor;   // shimmer wave tone

  // NEW: tuning
  final int speedMs;           // full cycle duration
  final double waveWidth;      // 0.10–0.35 good
  final int? maxLines;         // cap lines to avoid layout spikes
  final TextStyle? textStyle;  // override if needed
  final TextAlign textAlign;   // default left

  const PremiumShimmerWidget({
    Key? key,
    required this.text,
    this.isComplete = false,
    this.baseColor = const Color(0xFF6B7280),
    this.highlightColor = const Color(0xFF9CA3AF),
    this.speedMs = 1800,
    this.waveWidth = 0.22,
    this.maxLines,
    this.textStyle,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  State<PremiumShimmerWidget> createState() => _PremiumShimmerWidgetState();
}

class _PremiumShimmerWidgetState extends State<PremiumShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      duration: Duration(milliseconds: widget.speedMs),
      vsync: this,
    );
    _t = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeInOut),
    );
    if (!widget.isComplete) _ac.repeat();
  }

  @override
  void didUpdateWidget(PremiumShimmerWidget old) {
    super.didUpdateWidget(old);
    if (widget.isComplete != old.isComplete || widget.speedMs != old.speedMs) {
      _ac.duration = Duration(milliseconds: widget.speedMs);
      widget.isComplete ? _ac.stop() : _ac.repeat();
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final text = Text(
      widget.text,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
      // Strut locks line height so 1→2 lines pe layout jump minimal
      strutStyle: const StrutStyle(fontSize: 16, height: 1.2, leading: 0),
      style: (widget.textStyle ??
          const TextStyle(
            fontSize: 16,
            fontFamily: 'SF Pro',
            fontWeight: FontWeight.w500,
            color: Colors.white, // srcIn mask uses this alpha
          )),
      softWrap: true,
    );

    // Solid text if complete or user prefers less motion
    if (widget.isComplete || reduceMotion) {
      return DefaultTextStyle(
        style: TextStyle(color: widget.baseColor),
        child: text,
      );
    }

    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        // moving band: stops around _t with configurable width
        final w = widget.waveWidth.clamp(0.08, 0.5);
        final x = _t.value;
        final stops = <double>[
          (x - w * 1.5).clamp(0.0, 1.0),
          (x - w).clamp(0.0, 1.0),
          (x - w * 0.35).clamp(0.0, 1.0),
          (x + w * 0.35).clamp(0.0, 1.0),
          (x + w).clamp(0.0, 1.0),
          (x + w * 1.5).clamp(0.0, 1.0),
        ];

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            // gradient spans full text bounds; we just slide the bright band via stops
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.baseColor,
                widget.highlightColor,
                widget.highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              stops: stops,
            ).createShader(bounds);
          },
          child: RepaintBoundary(child: text),
        );
      },
    );
  }
}









class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
              error = null;
            });
          },
          onPageFinished: (url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (error) {
            setState(() {
              this.error = error.description;
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          if (error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load page',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => error = null);
                      _initializeController();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}










class ComparisonTableWidget extends StatefulWidget {
  final String? heading;
  final List<Map<String, dynamic>> rows;
  final List<String>? columnOrder;
  final Function(String idOrFallback)? onRowTap;
  final int maxColumns;

  // Fade config (optional)
  final Duration fadeDuration;
  final Curve fadeCurve;

  const ComparisonTableWidget({
    Key? key,
    this.heading,
    required this.rows,
    this.columnOrder,
    this.onRowTap,
    this.maxColumns = 6,
    this.fadeDuration = const Duration(milliseconds: 240),
    this.fadeCurve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<ComparisonTableWidget> createState() => _ComparisonTableWidgetState();
}

class _ComparisonTableWidgetState extends State<ComparisonTableWidget>
    with SingleTickerProviderStateMixin {
  static const double _headerH = 50;
  static const double _rowH = 52;
  static const EdgeInsets _cellPad = EdgeInsets.symmetric(horizontal: 12);

  final _hCtrl = ScrollController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  // For vertical divider visibility
  bool _showVerticalDivider = false;

  // Deep comparators (order-sensitive for rows; order-sensitive for columnOrder)
  static const _deep = DeepCollectionEquality();
  static const _listEq = ListEquality<String>();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: widget.fadeDuration);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: widget.fadeCurve);

    // Listen to scroll changes to show/hide vertical divider
    _hCtrl.addListener(_onScrollChanged);

    // Fade once on first mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartFade();
    });
  }

  void _onScrollChanged() {
    final shouldShow = _hCtrl.hasClients && _hCtrl.offset > 0;
    if (_showVerticalDivider != shouldShow) {
      setState(() {
        _showVerticalDivider = shouldShow;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ComparisonTableWidget old) {
    super.didUpdateWidget(old);
    if (_shouldRefade(old)) {
      _restartFade();
    }
  }

  bool _shouldRefade(ComparisonTableWidget old) {
    if (widget.heading != old.heading) return true;
    if (widget.rows.length != old.rows.length) return true;
    // Only refade if row CONTENT changed (not just a new List instance)
    if (!_deep.equals(widget.rows, old.rows)) return true;
    final a = widget.columnOrder ?? const <String>[];
    final b = old.columnOrder ?? const <String>[];
    if (!_listEq.equals(a, b)) return true;
    return false;
  }

  void _restartFade() {
    _fadeCtrl.stop();
    _fadeCtrl.value = 0.0;
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool _hideKey(String k) {
    final lk = k.toLowerCase();
    return lk == '_id' ||
        lk == 'id' ||
        lk == 'name' ||
        lk.startsWith('overview.') ||
        lk.contains('description') ||
        lk.contains('summary');
  }

  String? _getCI(Map<String, dynamic> row, List<String> keys) {
    final lower = {for (final e in row.entries) e.key.toLowerCase(): e.value};
    for (final k in keys) {
      final v = lower[k.toLowerCase()];
      if (v != null) return v.toString();
    }
    return null;
  }

  String _nameOf(Map<String, dynamic> row) {
    final v = _getCI(row, ['name', 'company', 'title', 'symbol', 'ticker']);
    return (v == null || v.trim().isEmpty) ? 'Entity' : v.trim();
  }

  String _idOf(Map<String, dynamic> row) {
    final v = _getCI(row, ['_id', 'id', 'isin', 'symbol', 'ticker']);
    return (v == null || v.trim().isEmpty) ? _nameOf(row) : v.trim();
  }

  String _label(String k) {
    const map = {
      'current_price': 'Current Price',
      'price': 'Price',
      'market_cap': 'Market Cap',
      'pe_ratio': 'P/E',
      'sector': 'Sector',
      'industry': 'Industry',
      'change': 'Change',
      'ratios.returns.1d': '1D Return',
      'ratios.returns.1m': '1M Return',
      'ratios.returns.6m': '6M Return',
      'ratios.returns.1y': '1Y Return',
    };
    final lk = k.toLowerCase();
    if (map.containsKey(lk)) return map[lk]!;
    final last = (k.contains('.')) ? k.split('.').last : k;
    return last
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _fmt(String key, dynamic v) {
    if (v == null) return '—';
    final lk = key.toLowerCase();
    final isPct = lk.contains('return') || lk.contains('change');
    final isRupee = lk.contains('price') || lk.contains('market_cap');
    if (isPct && v is num) return '${v.toStringAsFixed(v > 100 ? 1 : 2)}%';
    if (isRupee && v is num) {
      if (v >= 10_000_000) return '₹${(v / 10_000_000).toStringAsFixed(1)}Cr';
      if (v >= 100_000) return '₹${(v / 100_000).toStringAsFixed(1)}L';
      return '₹${v.toStringAsFixed(2)}';
    }
    if (v is num) {
      if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
      if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(2);
    }
    return v.toString();
  }

  Color _tint(String key, dynamic v, Color base) {
    final lk = key.toLowerCase();
    final looksPct = lk.contains('return') || lk.contains('change');
    num? n;
    if (v is num) n = v;
    if (v is String && v.trim().isNotEmpty) {
      final s = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      if (s.isNotEmpty) n = num.tryParse(s);
    }
    if (looksPct && n != null) {
      if (n > 0) return const Color(0xFF1A7F37);
      if (n < 0) return const Color(0xFFB42318);
    }
    return base;
  }

  List<String> _resolveColumns() {
    if (widget.rows.isEmpty) return const [];
    final keys = <String>{};
    for (final r in widget.rows) {
      r.forEach((k, v) {
        if (_hideKey(k)) return;
        if (v is Map) return;
        keys.add(k);
      });
    }

    final ordered = <String>[];
    for (final c in (widget.columnOrder ?? const [])) {
      if (keys.remove(c)) ordered.add(c);
    }
    ordered.addAll(keys);
    return ordered.take(widget.maxColumns).toList();
  }

  double _colWidth(String key) {
    final lk = key.toLowerCase();
    if (lk.contains('industry') || lk.contains('sector')) return 160;
    if (lk.contains('market') || lk.contains('price')) return 130;
    if (lk.contains('returns') || lk.contains('change')) return 110;
    return 120;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final muted = textColor.withOpacity(0.9);
    final borderColor = Colors.grey.withOpacity(0.2);
    final boxColor = theme.cardColor;

    final cols = _resolveColumns();
    if (cols.isEmpty) {
      return FadeTransition(
        opacity: _fade,
        child: const Padding(
          padding: EdgeInsets.all(16),
        ),
      );
    }

    const nameW = 190.0;
    final colWidths = {for (final c in cols) c: _colWidth(c)};
    final totalWidth = cols.fold<double>(0, (sum, c) => sum + colWidths[c]!);

    final headerStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: muted,
    );
    final cellStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: textColor,
    );

    return FadeTransition(
      opacity: _fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 0, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          if ((widget.heading ?? '').isNotEmpty) ...[
            Row(
              children: [
                const Text('📊 '),
                Expanded(
                  child: Text(
                    widget.heading!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Name column
                      Column(
                        children: [
                          Container(
                            width: nameW,
                            height: _headerH,
                            padding: _cellPad,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: borderColor, width: 0.6),
                              ),
                            ),
                            child: Text("Name", style: headerStyle),
                          ),
                          for (int i = 0; i < widget.rows.length; i++)
                            InkWell(
                              onTap: widget.onRowTap == null
                                  ? null
                                  : () => widget.onRowTap!(_idOf(widget.rows[i])),
                              child: Container(
                                width: nameW,
                                height: _rowH,
                                padding: _cellPad,
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: i.isOdd
                                      ? Colors.black.withOpacity(0.025)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(color: borderColor, width: 0.6),
                                  ),
                                ),
                                child: Text(
                                  _nameOf(widget.rows[i]),
                                  style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Scrollable rest of columns
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _hCtrl,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: totalWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // header
                                Row(
                                  children: [
                                    for (final c in cols)
                                      Container(
                                        width: colWidths[c],
                                        height: _headerH,
                                        padding: _cellPad,
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: borderColor, width: 0.6),
                                          ),
                                        ),
                                        child: Text(_label(c), style: headerStyle),
                                      ),
                                  ],
                                ),
                                // rows
                                for (int i = 0; i < widget.rows.length; i++)
                                  Row(
                                    children: [
                                      for (final c in cols)
                                        Container(
                                          width: colWidths[c],
                                          height: _rowH,
                                          padding: _cellPad,
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: i.isOdd
                                                ? Colors.black.withOpacity(0.025)
                                                : Colors.transparent,
                                            border: Border(
                                              bottom: BorderSide(color: borderColor, width: 0.6),
                                            ),
                                          ),
                                          child: Text(
                                            _fmt(c, widget.rows[i][c]),
                                            style: cellStyle.copyWith(
                                              color: _tint(c, widget.rows[i][c], textColor),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Vertical divider - only visible when scrolling horizontally
                  if (_showVerticalDivider)
                    Positioned(
                      left: nameW - 1.5, // Slightly overlap the name column edge
                      top: 0,
                      bottom: 11,
                      child: Container(
                        width: 0.5,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.025),
                              blurRadius: 4,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}














class KeyValueTableWidget extends StatefulWidget {
  final String? heading;
  final List<Map<String, dynamic>> rows;
  final List<String>? columnOrder;
  final Function(String idOrFallback)? onCardTap;
  final double cardSpacing;
  final double headerBottomSpacing;

  const KeyValueTableWidget({
    Key? key,
    this.heading,
    required this.rows,
    this.columnOrder,
    this.onCardTap,
    this.cardSpacing = 8,
    this.headerBottomSpacing = 8,
  }) : super(key: key);

  @override
  State<KeyValueTableWidget> createState() => _KeyValueTableWidgetState();
}

class _KeyValueTableWidgetState extends State<KeyValueTableWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _fadeControllers;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  bool _shouldHideField(String k) => k.trim().toLowerCase() == '_id';

  bool _isOverviewField(String k) {
    final lk = k.toLowerCase();
    return lk == 'overview.sector' ||
        lk == 'description' ||
        lk == 'summary' ||
        lk == 'overview.desc';
  }

  @override
  void initState() {
    super.initState();
    _initAnims();
    _startAnims();
  }

  void _initAnims() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _headerAnimation =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);

    _fadeControllers = List.generate(
      widget.rows.length,
          (_) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _fadeAnimations = _fadeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();
  }

  void _startAnims() {
    _headerController.forward();
    for (var i = 0; i < _fadeControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) _fadeControllers[i].forward();
      });
    }
  }

  @override
  void didUpdateWidget(KeyValueTableWidget old) {
    super.didUpdateWidget(old);
    if (widget.rows.length != old.rows.length) {
      _disposeAnims();
      _initAnims();
      _startAnims();
    }
  }

  void _disposeAnims() {
    _headerController.dispose();
    for (final c in _fadeControllers) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnims();
    super.dispose();
  }

  // -------------------- data helpers --------------------

  String? _getCaseInsensitive(Map<String, dynamic> row, List<String> keys) {
    final lower = {for (final e in row.entries) e.key.toLowerCase(): e.value};
    for (final k in keys) {
      final v = lower[k.toLowerCase()];
      if (v != null) return v.toString();
    }
    return null;
  }

  String _extractEntityName(Map<String, dynamic> row) {
    final v = _getCaseInsensitive(row, ['name', 'company', 'symbol', 'ticker', 'title']);
    return (v == null || v.trim().isEmpty) ? 'Entity' : v.trim();
  }

  String _extractEntityId(Map<String, dynamic> row) {
    final v = _getCaseInsensitive(row, ['_id', 'id']);
    return v?.trim() ?? '';
  }

  Map<String, String> _processRowData(Map<String, dynamic> row) {
    final processed = <String, String>{};
    processed['name'] = _extractEntityName(row);
    processed.addAll(_extractImportantFields(row));
    return processed;
  }

  Map<String, String> _extractImportantFields(Map<String, dynamic> row) {
    final result = <String, String>{};
    final priority = [
      'price',
      'sector',
      'category',
      'industry',
      'market_cap',
      'pe_ratio',
      'revenue',
      'profit',
      'rating',
      'score',
      'percentage',
      'change',
      'volume',
      'returns',
      'yield',
      'growth',
      // backend sometimes uses spaced labels:
      'current price',
      'market cap',
    ];
    int count = 0;

    // priority (case-insensitive)
    final lower = {for (final e in row.entries) e.key.toLowerCase(): e.value};
    for (final k in priority) {
      if (count >= 4) break;
      if (lower.containsKey(k) && lower[k] != null && !_isOverviewField(k)) {
        result[_label(k)] = _formatRaw(lower[k]); // Show raw data
        count++;
      }
    }

    // nested maps
    if (count < 4) {
      for (final e in row.entries) {
        if (count >= 4) break;
        if (e.value is Map) {
          final nested = Map<String, dynamic>.from(e.value as Map);
          for (final ne in nested.entries) {
            if (count >= 4) break;
            final key = ne.key;
            if (_shouldHideField(key) || _isOverviewField(key)) continue;
            final v = ne.value;
            if (v != null && (v is num || v is String)) {
              result[_label(key)] = _formatRaw(v); // Show raw data
              count++;
            }
          }
        }
      }
    }

    // remaining top-level
    if (count < 4) {
      for (final e in row.entries) {
        if (count >= 4) break;
        final key = e.key;
        if (_shouldHideField(key) || _isOverviewField(key)) continue;
        if (!_isNameField(key) && e.value != null && e.value is! Map) {
          final lab = _label(key);
          if (!result.containsKey(lab)) {
            result[lab] = _formatRaw(e.value); // Show raw data
            count++;
          }
        }
      }
    }
    return result;
  }

  bool _isNameField(String k) {
    final lk = k.toLowerCase();
    return lk == 'name' || lk == 'company' || lk == 'symbol' || lk == 'ticker' || lk == 'title';
  }

  String _label(String k) {
    const map = {
      'price': 'Price',
      'current price': 'Current Price',
      'sector': 'Sector',
      'market_cap': 'Market Cap',
      'market cap': 'Market Cap',
      'pe_ratio': 'P/E',
      'dividend_yield': 'Dividend',
      'revenue': 'Revenue',
      'profit': 'Profit',
      'rating': 'Rating',
      'volume': 'Volume',
      'change': 'Change',
      'returns': 'Returns',
      'yield': 'Yield',
      'growth': 'Growth',
      'industry': 'Industry',
      'category': 'Category',
    };
    final lk = k.toLowerCase();
    if (map.containsKey(lk)) return map[lk]!;
    final cleaned = lk.replaceAll('_', ' ').replaceAll('.', ' ');
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // UPDATED: Show raw data without any formatting
  String _formatRaw(dynamic v) {
    if (v == null) return '—';
    return v.toString();
  }

  String _pickId(Map<String, dynamic> row) {
    final v = _getCaseInsensitive(row, ['_id', 'id', 'isin', 'symbol', 'ticker']);
    return (v == null || v.trim().isEmpty) ? _extractEntityName(row) : v.trim();
  }

  String _extractOverview(Map<String, dynamic> row) {
    final lower = {for (final e in row.entries) e.key.toLowerCase(): e.value};
    for (final k in ['overview.sector', 'description', 'summary']) {
      final v = lower[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    for (final k in ['meta', 'details', 'company']) {
      final obj = row[k];
      if (obj is Map) {
        final lower2 = {for (final e in obj.entries) e.key.toLowerCase(): e.value};
        for (final f in ['overview.sector', 'description', 'summary']) {
          final v = lower2[f];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
        }
      }
    }
    return '';
  }

  // -------------------- NEW: single-row stats helpers --------------------

  Widget _statTile(String label, String value) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.text.withOpacity(0.7),
            fontWeight: FontWeight.w400,
            fontFamily: "DM Sans",
            height: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.text,
            fontFamily: "DM Sans",
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Exactly one horizontal row with up to 3 stats; truncates if tight.
  Widget _statsOneRow(List<MapEntry<String, String>> entries) {
    final shown = entries.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 8), // align under title (avatar offset)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            Expanded(child: _statTile(shown[i].key, shown[i].value)),
            if (i < shown.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  // -------------------- UI --------------------

  Widget _card(Map<String, dynamic> row, Animation<double> anim, int i) {
    final data = _processRowData(row);
    final name = data['name'] ?? 'Entity';
    final fields = Map<String, String>.from(data)..remove('name');
    final entries = fields.entries.toList();
    final overview = _extractOverview(row);
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(anim),
        child: GestureDetector(
          onTap: () => widget.onCardTap?.call(_pickId(row)),
          child: Container(
            margin: EdgeInsets.only(
              bottom: i < widget.rows.length - 1 ? widget.cardSpacing : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.background, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with name and bookmark
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 70),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                                fontFamily: "DM Sans",
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        Icon(Icons.bookmark_border, size: 25, color: theme.icon),
                      ],
                    ),

                    // 🔸 Single-row stats (max 3)
                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _statsOneRow(entries),
                    ],

                    if (overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text(
                          overview,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            height: 1.4,
                            color: theme.text.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Company logo/avatar with transparent background
                Positioned(
                  top: 12,
                  left: 0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent, // ✅ Transparent background
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://i.pinimg.com/736x/6b/ed/12/6bed123accf95b38fb97e32f39df4c2e.jpg",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business,
                              color: theme.icon ?? Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String text) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
            .animate(_headerAnimation),
        child: Row(
          children: [
            const Text('🔰 '),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.justify,
                softWrap: true,
                textWidthBasis: TextWidthBasis.parent,
                style:  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                    color: theme.text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((widget.heading ?? '').isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Divider( thickness: 0, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              _header(widget.heading!),
              const SizedBox(height: 12),
            ],
          ),
        ...widget.rows.asMap().entries.map((e) {
          final i = e.key;
          final anim =
          i < _fadeAnimations.length ? _fadeAnimations[i] : _headerAnimation;
          return Column(
            children: [
              _card(e.value, anim, i),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}






enum MenuSide { left, right }

class IOSPopContextMenu extends StatefulWidget {
  /// The bubble widget you wrap (e.g., your message bubble)
  final Widget child;

  /// Optional small preview text (not rendered by default, kept for parity)
  final String previewText;

  /// Actions
  final VoidCallback onCopy;
  final VoidCallback onEdit;

  /// Which side of the screen the bubble lives on
  final MenuSide side;

  /// Extra horizontal shift of the menu away from the bubble.
  /// Positive values push it further from the bubble.
  final double horizontalNudge;

  /// Small vertical trim for optical alignment (negative -> a bit up)
  final double verticalNudge;

  /// Backdrop blur sigma for the sheet
  final double backdropSigma;

  const IOSPopContextMenu({
    Key? key,
    required this.child,
    required this.previewText,
    required this.onCopy,
    required this.onEdit,
    this.side = MenuSide.left,
    this.horizontalNudge = 24, // tweak 24–32 for “thoda left”
    this.verticalNudge = -4,   // subtle up shift
    this.backdropSigma = 8,
  }) : super(key: key);

  @override
  State<IOSPopContextMenu> createState() => _IOSPopContextMenuState();
}

class _IOSPopContextMenuState extends State<IOSPopContextMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  late final AnimationController _ac;
  late final Animation<double> _scale; // bubble pop
  late final Animation<double> _elev;  // shadow lift
  late final Animation<double> _fade;  // menu fade

  bool _hideOriginal = false; // hide original while ghost bubble is shown

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween(begin: 1.0, end: 1.06)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ac);
    _elev = Tween(begin: 0.0, end: 16.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ac);
    _fade = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ac);
  }

  @override
  void dispose() {
    _removeEntry();
    _ac.dispose();
    super.dispose();
  }

  void _show() {
    HapticFeedback.mediumImpact();
    if (_entry != null) return;

    setState(() => _hideOriginal = true);

    // How far from the bubble edge we place the menu
    const double baseGap = 8;

    final bool bubbleOnRight = widget.side == MenuSide.right;

    // When bubble is on the right, the menu should appear to its LEFT.
    final Alignment targetEdge = bubbleOnRight ? Alignment.centerRight : Alignment.centerLeft;
    final Alignment followerEdge = bubbleOnRight ? Alignment.centerLeft  : Alignment.centerRight;

    // Horizontal nudge — positive moves menu further away from bubble.
    final double dx = bubbleOnRight
        ? -(baseGap + widget.horizontalNudge) // push to LEFT of bubble
        :  (baseGap + widget.horizontalNudge); // push to RIGHT of bubble

    final Offset menuOffset = Offset(dx, widget.verticalNudge);

    _entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Stack(
          children: [
            // Dim/blurred backdrop (tap to dismiss)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hide,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.backdropSigma,
                    sigmaY: widget.backdropSigma,
                  ),
                  child: Container(color: Colors.black.withOpacity(0.12)),
                ),
              ),
            ),

            // Ghost “popped” bubble—exactly over the original
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset.zero,
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _ac,
                  builder: (context, _) {
                    return Transform.scale(
                      alignment: bubbleOnRight ? Alignment.centerRight : Alignment.centerLeft,
                      scale: _scale.value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.18),
                              blurRadius: _elev.value,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: widget.child,
                      ),
                    );
                  },
                ),
              ),
            ),

            // iOS-like floating menu card
            // iOS-like floating menu card
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: targetEdge,
              followerAnchor: followerEdge,
              offset: Offset(
                dx,
                widget.verticalNudge + 10, // ✅ Add constant 10px vertical gap
              ),
              child: FadeTransition(
                opacity: _fade,
                child: _CupertinoMenuCard(
                  preview: const SizedBox.shrink(),
                  actions: [
                    _CupertinoRowAction(
                      label: 'Copy',
                      icon: CupertinoIcons.doc_on_doc,
                      onTap: () { _hide(); widget.onCopy(); },
                    ),
                    _divider,
                    _CupertinoRowAction(
                      label: 'Edit',
                      icon: CupertinoIcons.pencil,
                      onTap: () { _hide(); widget.onEdit(); },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _ac.forward();
  }

  Future<void> _hide() async {
    await _ac.reverse();
    _removeEntry();
    if (mounted) setState(() => _hideOriginal = false);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onLongPress: _show,
        behavior: HitTestBehavior.translucent,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _hideOriginal ? 0.0 : 1.0, // hide original while ghost shows
          child: widget.child,
        ),
      ),
    );
  }
}


class _CupertinoMenuCard extends StatelessWidget {
  final Widget preview;
  final List<Widget> actions;

  const _CupertinoMenuCard({required this.preview, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.withOpacity(.92),
            boxShadow: const [
              BoxShadow(color: Color(0x2E000000), blurRadius: 20, offset: Offset(0, 12)),
              BoxShadow(color: Color(0x10000000), blurRadius: 4,  offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // If you ever want to show `preview`, uncomment the next two lines:
              // Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: preview),
              // _divider,
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

const _divider = Divider(height: 1, thickness: .5, color: Color(0x14000000));

class _CupertinoRowAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CupertinoRowAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            Icon(icon, size: 20, color: CupertinoColors.black),
          ],
        ),
      ),
    );
  }
}







class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size?> onChange;
  const MeasureSize({super.key, required this.child, required this.onChange});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (_oldSize != size) {
        _oldSize = size;
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}




class OverlayContainerClipper extends CustomClipper<Path> {
  final double rms;
  final bool isSpeaking;

  OverlayContainerClipper({required this.rms, required this.isSpeaking});

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final path = Path();

    final animatedRms = isSpeaking ? rms : 0.0;

    final baseHeight = 80.0;
    final additionalHeight = (animatedRms * 210).clamp(0.0, 20.0);
    final curveHeight = baseHeight - additionalHeight;

    final basePeakHeight = 20.0;
    final additionalPeakHeight = (animatedRms * 100).clamp(0.0, 20.0);
    final peakHeight = basePeakHeight - additionalPeakHeight;

    path.moveTo(0, height);
    path.lineTo(0, curveHeight);

    path.quadraticBezierTo(
      width / 2,
      peakHeight,
      width,
      curveHeight,
    );

    path.lineTo(width, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant OverlayContainerClipper oldClipper) {
    return oldClipper.rms != rms || oldClipper.isSpeaking != isSpeaking;
  }
}

class InnerOverlayContainerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final path = Path();

    // Fixed curve values (adjust as per your UI)
    final curveHeight = 90.0;  // Lower value = curve up, higher = curve down
    final peakHeight = 38.0;   // Lower = more dramatic peak

    path.moveTo(0, height);
    path.lineTo(0, curveHeight);

    path.quadraticBezierTo(
      width / 2,
      peakHeight,
      width,
      curveHeight,
    );

    path.lineTo(width, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant InnerOverlayContainerClipper oldClipper) {
    return false; // Static, so never reclip
  }
}

class ChatGPTScrollingWaveform extends StatefulWidget {
  final bool isSpeech;
  final double rms;

  const ChatGPTScrollingWaveform({
    Key? key,
    required this.isSpeech,
    required this.rms,
  }) : super(key: key);

  @override
  State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
}

class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform>
    with SingleTickerProviderStateMixin {
  final int maxBars = 30;
  final Duration frameRate = Duration(milliseconds: 80);
  final double flatHeight = 2;
  final List<double> _waveform = [];

  // ✅ For smooth height transitions
  final List<double> _targetHeights = [];
  final List<double> _currentHeights = [];

  Timer? _waveformTimer;
  late AnimationController _animController;

  // Smooth sliding offset
  double _slideOffset = 0.0;

  bool _wasRecentlySpeaking = false;
  DateTime _lastSpeechTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _waveform.clear();

    _animController = AnimationController(
      vsync: this,
      duration: frameRate,
    )..addListener(() {
      if (mounted) setState(() {});
    });

    _startWaveformLoop();
  }

  void _startWaveformLoop() {
    _waveformTimer = Timer.periodic(frameRate, (_) {
      if (!mounted) return;

      final now = DateTime.now();

      const double minRmsThreshold = 0.005;
      bool actualSpeechDetected = widget.isSpeech && widget.rms > minRmsThreshold;

      if (actualSpeechDetected) {
        _lastSpeechTime = now;
        _wasRecentlySpeaking = true;
      }

      bool withinGracePeriod = now.difference(_lastSpeechTime) < Duration(milliseconds: 300);

      bool hasAnyAudio = widget.rms > 0.003;
      bool shouldShowWaves = actualSpeechDetected ||
          (_wasRecentlySpeaking && withinGracePeriod && hasAnyAudio) ||
          (_wasRecentlySpeaking && withinGracePeriod && widget.isSpeech);

      if (!withinGracePeriod) {
        _wasRecentlySpeaking = false;
      }

      double nextHeight;

      if (shouldShowWaves) {
        double effectiveRms = widget.rms;

        if (!actualSpeechDetected && _wasRecentlySpeaking) {
          effectiveRms = max(effectiveRms, 0.010);
          effectiveRms = effectiveRms * 0.9;
        }

        // PLATFORM-SPECIFIC CALIBRATION
        if (Platform.isIOS) {
          effectiveRms = effectiveRms * 2.5;
          effectiveRms = effectiveRms.clamp(0.0, 1.0);
        }

        // ✅ MUCH MORE SUBTLE HEIGHT RANGES
        if (effectiveRms < 0.05) {
          // Very quiet / whisper
          nextHeight = 6.0 + (effectiveRms * 100);

        } else if (effectiveRms < 0.12) {
          // Quiet speech
          nextHeight = 11.0 + ((effectiveRms - 0.05) * 140); // 11-20.8px

        } else if (effectiveRms < 0.25) {
          // Normal speech (most common range)
          nextHeight = 20.8 + ((effectiveRms - 0.12) * 180); // 20.8-44.2px

        } else if (effectiveRms < 0.40) {
          // Loud speech
          nextHeight = 44.2 + ((effectiveRms - 0.25) * 100); // 44.2-59.2px

        } else {
          // Very loud / shouting
          nextHeight = 59.2 + ((effectiveRms - 0.40) * 60); // 59.2-95.2px
        }

        // ✅ MUCH TIGHTER max clamp - very subtle now
        nextHeight = nextHeight.clamp(6.0, 40.0); // Reduced from 60px to 40px max

      } else {
        nextHeight = flatHeight;
      }

      // Add new bar data
      _targetHeights.insert(0, nextHeight);
      _currentHeights.insert(0, flatHeight);

      if (_targetHeights.length > maxBars) {
        _targetHeights.removeLast();
        _currentHeights.removeLast();
      }

      _animController.forward(from: 0.0);
    });
  }


  @override
  void dispose() {
    _waveformTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Smooth interpolation between current and target heights
    final smoothingFactor = 0.3;

    for (int i = 0; i < _currentHeights.length; i++) {
      _currentHeights[i] += (_targetHeights[i] - _currentHeights[i]) * smoothingFactor;
    }

    // ✅ YOUR ORIGINAL SPACING
    const barWidth = 3.0;
    const barSpacing = 3.4;
    const totalBarWidth = barWidth + (barSpacing * 2);

    // ✅ Calculate slide distance
    _slideOffset = _animController.value * totalBarWidth;

    return SizedBox(
      height: 80, // ✅ Reduced container height from 100 to 80
      child: CustomPaint(
        painter: WaveformPainter(
          heights: _currentHeights,
          slideOffset: _slideOffset,
          barWidth: barWidth,
          barSpacing: totalBarWidth,
          barColor: Color(0xFF8C571F),
        ),
        size: Size.infinite,
      ),
    );
  }
}




class WaveformPainter extends CustomPainter {
  final List<double> heights;
  final double slideOffset;
  final double barWidth;
  final double barSpacing;
  final Color barColor;

  /// Dono edges (left & right) se kitni width me shrink hoga
  final double edgeShrinkWidth;

  WaveformPainter({
    required this.heights,
    required this.slideOffset,
    required this.barWidth,
    required this.barSpacing,
    required this.barColor,
    this.edgeShrinkWidth = 28.0, // tweak: 20–36 looks nice
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final centerY = size.height / 2;

    // visible bars only
    final visibleWidth = size.width + barWidth;
    final maxVisibleBars = (visibleWidth / barSpacing).ceil() + 2;
    final barsToRender = math.min(heights.length, maxVisibleBars);

    for (int i = 0; i < barsToRender; i++) {
      final baseH = heights[i];
      if (baseH <= 0) continue;

      // x: right → left with slide
      final x = size.width - (i * barSpacing) - slideOffset;

      if (x < -barWidth) break;
      if (x > size.width + barWidth) continue;

      // ---- NEW: symmetric edge shrink (height attenuation on both sides) ----
      double factor = 1.0;

      if (edgeShrinkWidth > 0) {
        // distance from both edges
        final distLeft  = x.clamp(0.0, edgeShrinkWidth);
        final distRight = (size.width - x).clamp(0.0, edgeShrinkWidth);

        // 0..1 per edge
        double fLeft  = (distLeft  / edgeShrinkWidth).clamp(0.0, 1.0);
        double fRight = (distRight / edgeShrinkWidth).clamp(0.0, 1.0);

        // easing for smoother taper
        fLeft  = Curves.easeOutCubic.transform(fLeft);
        fRight = Curves.easeOutCubic.transform(fRight);

        // take the MIN → if bar is close to any edge, it shrinks
        factor = math.min(fLeft, fRight);
      }

      final h = (baseH * factor).clamp(0.5, double.infinity);
      if (h < 0.8) continue;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter old) {
    return old.slideOffset != slideOffset ||
        old.heights != heights ||
        old.barWidth != barWidth ||
        old.barSpacing != barSpacing ||
        old.barColor != barColor ||
        old.edgeShrinkWidth != edgeShrinkWidth;
  }
}



class EditingChip extends StatelessWidget {
  final VoidCallback onClose;
  final AppTheme theme;

  const EditingChip({
    required this.onClose,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // color: theme.card,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(12),
        //   topRight: Radius.circular(12),
        // ),
        // boxShadow: [
        //   BoxShadow(
        //     color: theme.shadow,
        //     blurRadius: 4,
        //     offset: const Offset(0, -2),
        //   ),
        // ],
        //  border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 16, color: theme.text),
          const SizedBox(width: 8),
          Text(
            'Editing message',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onClose();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}










