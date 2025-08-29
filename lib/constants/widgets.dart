import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vscmoney/services/theme_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final Color baseColor;
  final Color highlightColor;

  const PremiumShimmerWidget({
    Key? key,
    required this.text,
    this.isComplete = false,
    this.baseColor = const Color(0xFF9CA3AF),
    this.highlightColor = const Color(0xFF6B7280),
  }) : super(key: key);

  @override
  _PremiumShimmerWidgetState createState() => _PremiumShimmerWidgetState();
}

class _PremiumShimmerWidgetState extends State<PremiumShimmerWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation - continuous wave effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Faster shimmer cycle
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start continuous shimmer for status
    if (!widget.isComplete) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumShimmerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isComplete != oldWidget.isComplete) {
      if (widget.isComplete) {
        _shimmerController.stop();
      } else {
        _shimmerController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor.withOpacity(0.4),
                widget.highlightColor.withOpacity(0.9),
                widget.baseColor.withOpacity(0.4),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white, // White color for shader mask
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w500,
            ),
          ),
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








class ComparisonTableWidget extends StatelessWidget {
  final String? heading;
  final List<Map<String, dynamic>> rows;
  final List<String>? columnOrder;
  final Function(String idOrFallback)? onRowTap;
  final int maxColumns;

  const ComparisonTableWidget({
    Key? key,
    this.heading,
    required this.rows,
    this.columnOrder,
    this.onRowTap,
    this.maxColumns = 6,
  }) : super(key: key);

  bool _isOverviewField(String k) {
    final lk = k.toLowerCase();
    return lk.startsWith('overview.') || lk.contains('description') || lk.contains('summary');
  }

  bool _shouldHide(String k) {
    final lk = k.toLowerCase();
    return lk == '_id' || lk == 'id' || _isOverviewField(lk);
  }

  String? _getCI(Map<String, dynamic> row, List<String> keys) {
    final lower = {for (final e in row.entries) e.key.toLowerCase(): e.value};
    for (final k in keys) {
      final v = lower[k.toLowerCase()];
      if (v != null) return v.toString();
    }
    return null;
  }

  String _extractName(Map<String, dynamic> row) {
    final v = _getCI(row, ['name','company','title','symbol','ticker']);
    return (v == null || v.trim().isEmpty) ? 'Entity' : v.trim();
  }

  String _extractId(Map<String, dynamic> row) {
    final v = _getCI(row, ['_id','id','isin','symbol','ticker']);
    return (v == null || v.trim().isEmpty) ? _extractName(row) : v.trim();
  }

  String _label(String k) {
    const map = {
      'current_price': 'Current Price',
      'current price': 'Current Price',
      'price': 'Price',
      'market_cap': 'Market Cap',
      'market cap': 'Market Cap',
      'pe_ratio': 'P/E',
      'sector': 'Sector',
      'industry': 'Industry',
      'change': 'Change',
      'ratios.returns.1d': '1D Return',
      'ratios.returns.1m': '1M Return',
      'ratios.returns.6m': '6M Return',
      'ratios.returns.1y': '1Y Return',
      'ratios.returns.1y_excess_over_nifty': '1Y vs Nifty',
      'overview.sector': 'Sector',
    };

    final lk = k.toLowerCase();
    if (map.containsKey(lk)) return map[lk]!;

    if (k.contains('.')) {
      final parts = k.split('.');
      final lastPart = parts.last;
      final cleaned = lastPart.replaceAll('_', ' ');
      return cleaned
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }

    final cleaned = lk.replaceAll('_', ' ').replaceAll('.', ' ');
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatValue(String key, dynamic v) {
    if (v == null) return '—';
    final lk = key.toLowerCase();

    final isPct = lk.contains('return') || lk.contains('change') ||
        lk.contains('yield') || lk.contains('growth') ||
        lk.contains('1d') || lk.contains('1m') ||
        lk.contains('6m') || lk.contains('1y');

    final isRupee = lk.contains('price') || lk.contains('market_cap') || lk.contains('market cap');

    if (isPct && v is num) {
      if (v > 100) return '${v.toStringAsFixed(1)}%';
      return '${v.toStringAsFixed(2)}%';
    }

    if (isRupee && v is num) {
      if (v >= 10_000_000) return '₹${(v / 10_000_000).toStringAsFixed(1)}Cr';
      if (v >= 100_000) return '₹${(v / 100_000).toStringAsFixed(1)}L';
      return '₹${v.toStringAsFixed(2)}';
    }

    if (lk.contains('volume') && v is num) {
      return v.toStringAsFixed(2);
    }

    if (v is num) {
      if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
      if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(2);
    }

    return v.toString();
  }

  List<String> _inferColumnOrder(List<Map<String, dynamic>> rows, int cap) {
    if (rows.isEmpty) return const [];

    final keys = <String>{};
    for (final r in rows) {
      r.forEach((k, v) {
        if (_shouldHide(k)) return;
        if (v is Map) return;
        keys.add(k);
      });
    }

    // prefer both snake_case and human labels
    const preferred = [
      'price','current_price','current price',
      'change',
      'market_cap','market cap',
      'sector','industry',
      'ratios.returns.1d','ratios.returns.1m','ratios.returns.6m','ratios.returns.1y','ratios.returns.1y_excess_over_nifty',
    ];

    final ordered = <String>[];
    for (final p in preferred) {
      if (keys.remove(p)) ordered.add(p);
    }
    ordered.addAll(keys);

    return ordered.take(cap).toList();
  }

  List<String> _resolveColumns() {
    final provided = (columnOrder ?? [])
        .where((c) => rows.any((r) => r.containsKey(c)))
        .toList();
    if (provided.isNotEmpty) {
      return provided.take(maxColumns).toList();
    }
    return _inferColumnOrder(rows, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final themeExt = Theme.of(context).extension<AppThemeExtension>();
    final theme = themeExt?.theme;
    final textColor = theme?.text ?? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    final columns = _resolveColumns();
    if (columns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text("No displayable columns found"),
      );
    }

    final table = DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 56,
      headingTextStyle: TextStyle(
        fontFamily: 'SF Pro',
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: textColor.withOpacity(0.9),
      ),
      dataTextStyle: TextStyle(
        fontFamily: 'SF Pro',
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: textColor,
        height: 1.4,
      ),
      columns: <DataColumn>[
        const DataColumn(label: Text('Entity')),
        ...columns.map((c) => DataColumn(label: Text(_label(c)))),
      ],
      rows: rows.map((row) {
        final id = _extractId(row);
        final name = _extractName(row);

        final cells = <DataCell>[
          DataCell(Text(name)),
          ...columns.map((c) {
            final value = row[c];
            return DataCell(Text(_formatValue(c, value)));
          }),
        ];

        return DataRow(
          cells: cells,
          onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(id),
        );
      }).toList(),
      dividerThickness: 0.6,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: (theme?.border ?? Colors.grey.withOpacity(0.2)),
          width: 0.6,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((heading ?? '').isNotEmpty) ...[
          Row(
            children: [
              const Text('📊 '),
              Expanded(
                child: Text(
                  heading!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme?.box ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme?.box ?? Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: table,
              ),
            ),
          ),
        ),
      ],
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
        result[_label(k)] = _format(k, lower[k]);
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
              result[_label(key)] = _format(key, v);
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
            result[lab] = _format(key, e.value);
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

  String _format(String k, dynamic v) {
    if (v == null) return '—';
    final lk = k.toLowerCase();

    if (lk.contains('price') || lk.contains('market_cap') || lk.contains('market cap')) {
      if (v is num) {
        if (v > 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
        if (v > 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
        return '₹${v.toStringAsFixed(2)}';
      }
    }
    if (lk.contains('return') || lk.contains('change') || lk.contains('growth') || lk.contains('yield')) {
      if (v is num) return '${v.toStringAsFixed(1)}%';
    }
    if (lk.contains('rating') || lk.contains('score')) {
      if (v is num) return '${v.toStringAsFixed(1)}/5';
    }
    if (v is String) return v;
    if (v is num) {
      if (v > 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v > 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(1);
    }
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
            fontFamily: "SF Pro",
            height: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.text,
            fontFamily: "SF Pro",
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
              color: theme.box,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFAF9F7), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                                fontFamily: "SF Pro",
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
                      const SizedBox(height: 10),
                      _statsOneRow(entries),
                    ],

                    // Overview line
                    if (overview.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text(
                          overview,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 13,
                            height: 1.45,
                            color: theme.text.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Company logo/avatar
                Positioned(
                  top: 12,
                  left: 0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRCvh-j7HsTHJ8ZckknAoiZMx9VcFmsFkv72g&s",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: Colors.black,
                            child: Icon(Icons.business, color: Colors.white, size: 24),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro',
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
        if ((widget.heading ?? '').isNotEmpty) Column(
          children: [
            Divider(
              thickness: 0.0,
              color: Colors.grey,
            ),
            SizedBox(height: 5,),
            _header(widget.heading!),
            SizedBox(height: 20,)
          ],
        ),
        ...widget.rows.asMap().entries.map((e) {
          final i = e.key;
          final anim =
          i < _fadeAnimations.length ? _fadeAnimations[i] : _headerAnimation;
          return _card(e.value, anim, i);
        }),
      ],
    );
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

  Timer? _waveformTimer;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // 🔄 Speech continuity tracking
  bool _wasRecentlySpeaking = false;
  DateTime _lastSpeechTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Start with empty waveform
    _waveform.clear();

    // Setup slide animation for smooth right-to-left movement
    _slideController = AnimationController(
      duration: frameRate,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0, // Distance each bar slides (width + padding)
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.linear,
    ));

    _startWaveformLoop();
  }

  void _startWaveformLoop() {
    _waveformTimer = Timer.periodic(frameRate, (_) {
      if (!mounted) return;

      final now = DateTime.now();

      // 🎯 LOWER threshold for better continuity
      const double minRmsThreshold = 0.005; // Reduced from 0.015 for better detection
      bool actualSpeechDetected = widget.isSpeech && widget.rms > minRmsThreshold;

      // 🔄 Update speech tracking
      if (actualSpeechDetected) {
        _lastSpeechTime = now;
        _wasRecentlySpeaking = true;
      }

      // 📏 LONGER grace period for better continuity
      bool withinGracePeriod = now.difference(_lastSpeechTime) < Duration(milliseconds: 300); // Increased from 150ms

      // 🌊 More lenient continuity check
      bool hasAnyAudio = widget.rms > 0.003; // Very low threshold for minimal audio
      bool shouldShowWaves = actualSpeechDetected ||
          (_wasRecentlySpeaking && withinGracePeriod && hasAnyAudio) ||
          (_wasRecentlySpeaking && withinGracePeriod && widget.isSpeech); // Keep going if isSpeech is still true

      if (!withinGracePeriod) {
        _wasRecentlySpeaking = false;
      }

      double nextHeight;

      if (shouldShowWaves) {
        double effectiveRms = widget.rms;

        // During grace period, maintain minimum wave height
        if (!actualSpeechDetected && _wasRecentlySpeaking) {
          effectiveRms = max(effectiveRms, 0.010); // Guarantee minimum during gaps
          effectiveRms = effectiveRms * 0.9; // Slight fade during gap
        }

        nextHeight = (pow(effectiveRms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0);
      } else {
        // 🔇 IMMEDIATE FLAT - no background waves
        nextHeight = flatHeight;
      }

      setState(() {
        // Add new bar on the LEFT side (index 0)
        _waveform.insert(0, nextHeight);
        // Remove from RIGHT side when max capacity reached
        if (_waveform.length > maxBars) {
          _waveform.removeLast();
        }
      });

      // Always animate the sliding motion
      _slideController.forward().then((_) {
        _slideController.reset();
      });
    });
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55, // Accommodates up to 50px waves
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            // Buttery smooth slide with custom curve
            offset: Offset(_slideAnimation.value.clamp(-300.0, 0.0), 0),

            child: ListView.builder(
              reverse: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),

              // Performance optimizations
              cacheExtent: 500, // Cache more items for smooth scroll
              addRepaintBoundaries: false, // Reduce repaint boundaries
              addAutomaticKeepAlives: false, // Don't keep items alive

              itemCount: _waveform.length,
              itemBuilder: (context, index) {
                final barHeight = _waveform[index];
                final isActive = barHeight > flatHeight;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.4),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      // Smooth height animation with custom curve
                      duration: const Duration(milliseconds: 80), // Faster response
                      curve: Curves.easeOutCubic, // Smooth easing
                      tween: Tween(begin: flatHeight, end: barHeight),
                      builder: (context, animatedHeight, child) {
                        return Container(
                          width: 3,
                          height: animatedHeight,
                          decoration: BoxDecoration(
                            color: Color(0xFF8C571F),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}














// class ChatAnimationTracker {
//   static final Set<String> _completedAnimations = <String>{};
//
//   static bool hasAnimated(String id) {
//     return _completedAnimations.contains(id);
//   }
//
//   static void markAsAnimated(String id) {
//     _completedAnimations.add(id);
//   }
//
//   static void clearAll() {
//     _completedAnimations.clear();
//   }
// }
//
// // FIXED TYPEWRITER TEXT - NO RE-ANIMATION
//
// class TypewriterText extends StatefulWidget {
//   final String text;
//   final TextStyle style;
//   final Duration speed;
//   final bool isComplete;
//   final String uniqueId; // ADD THIS
//
//   const TypewriterText({
//     Key? key,
//     required this.text,
//     required this.style,
//     this.speed = const Duration(milliseconds: 30),
//     required this.isComplete,
//     required this.uniqueId, // ADD THIS
//   }) : super(key: key);
//
//   @override
//   _TypewriterTextState createState() => _TypewriterTextState();
// }
//
// class _TypewriterTextState extends State<TypewriterText>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<int> _characterCount;
//   String _displayedText = '';
//   bool _hasAnimated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Check if this text has already animated
//     _hasAnimated = ChatAnimationTracker.hasAnimated(widget.uniqueId);
//
//     _controller = AnimationController(
//       duration: Duration(milliseconds: widget.text.length * widget.speed.inMilliseconds),
//       vsync: this,
//     );
//
//     _characterCount = IntTween(
//       begin: 0,
//       end: widget.text.length,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOut,
//     ));
//
//     _characterCount.addListener(() {
//       if (mounted) {
//         setState(() {
//           _displayedText = widget.text.substring(0, _characterCount.value);
//         });
//       }
//     });
//
//     if (_hasAnimated) {
//       // If already animated, show complete text immediately
//       _controller.value = 1.0;
//       _displayedText = widget.text;
//     } else {
//       // First time - animate and mark as completed
//       ChatAnimationTracker.markAsAnimated(widget.uniqueId);
//       _controller.forward();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SelectableText.rich(
//       TextSpan(
//         children: [
//           TextSpan(text: _displayedText, style: widget.style),
//           // Only show cursor if actively animating
//           if (!_hasAnimated && !widget.isComplete && _characterCount.value < widget.text.length)
//             WidgetSpan(
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   return Opacity(
//                     opacity: (_controller.value * 2) % 1 > 0.5 ? 1.0 : 0.0,
//                     child: Text('|', style: widget.style),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// //FIXED ANIMATED TABLE - NO RE-AnimationController
//
// // Since your current ChatMessage model doesn't use payloads,
// // here's a simplified version that works with your structured data
//
// // Since your current ChatMessage model doesn't use payloads,
// // here's a simplified version that works with your structured data
//
// class AnimatedTableRenderer extends StatefulWidget {
//   final Map<String, dynamic> structuredData;
//   final String messageId;
//   final Function(String)? onStockTap;
//   final EditableTextContextMenuBuilder? contextMenuBuilder;
//
//   const AnimatedTableRenderer({
//     Key? key,
//     required this.structuredData,
//     required this.messageId,
//     this.onStockTap,
//     this.contextMenuBuilder,
//   }) : super(key: key);
//
//   @override
//   State<AnimatedTableRenderer> createState() => _AnimatedTableRendererState();
// }
//
// class _AnimatedTableRendererState extends State<AnimatedTableRenderer>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
//
//     // Start animations
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         _fadeController.forward();
//         _slideController.forward();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
//       builder: (context, child) {
//         return FadeTransition(
//           opacity: _fadeAnimation,
//           child: SlideTransition(
//             position: _slideAnimation,
//             child: _buildTableContent(),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildTableContent() {
//     final heading = widget.structuredData['heading']?.toString();
//     final rowsRaw = widget.structuredData['rows'] as List?;
//     final columnOrderRaw = widget.structuredData['columnOrder'] as List?;
//     final captionRaw = widget.structuredData['caption']?.toString();
//
//     final rows = rowsRaw?.map((e) {
//       if (e is Map) {
//         return Map<String, dynamic>.from(e);
//       }
//       return <String, dynamic>{};
//     }).toList() ?? <Map<String, dynamic>>[];
//
//     final columnOrder = columnOrderRaw?.map((e) => e?.toString() ?? '').toList();
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Heading
//           if (heading != null && heading.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: Text(
//                 heading,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'SF Pro',
//                 ),
//               ),
//             ),
//
//           // Table
//           _buildAnimatedTable(rows, columnOrder),
//
//           // Caption (if any)
//           if (captionRaw != null && captionRaw.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 captionRaw,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontStyle: FontStyle.italic,
//                   color: Colors.grey[600],
//                   fontFamily: 'SF Pro',
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnimatedTable(List<Map<String, dynamic>> rows, List<String>? columnOrder) {
//     if (rows.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         child: const Text('No data available'),
//       );
//     }
//
//     // Determine columns
//     final allKeys = <String>{};
//     for (final row in rows) {
//       allKeys.addAll(row.keys);
//     }
//
//     final columns = columnOrder ?? allKeys.toList();
//
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           // Header row
//           _buildHeaderRow(columns),
//
//           // Data rows with staggered animation
//           ...rows.asMap().entries.map((entry) {
//             final index = entry.key;
//             final row = entry.value;
//
//             return _buildAnimatedDataRow(row, columns, index);
//           }),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeaderRow(List<String> columns) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(8),
//           topRight: Radius.circular(8),
//         ),
//       ),
//       child: Row(
//         children: columns.map((column) {
//           return Expanded(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               child: Text(
//                 column,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   fontFamily: 'SF Pro',
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildAnimatedDataRow(Map<String, dynamic> row, List<String> columns, int index) {
//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 200 + (index * 100)), // Staggered timing
//       tween: Tween(begin: 0.0, end: 1.0),
//       curve: Curves.easeOutCubic,
//       builder: (context, value, child) {
//         return Transform.translate(
//           offset: Offset(0, 20 * (1 - value)),
//           child: Opacity(
//             opacity: value,
//             child: Container(
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!),
//                 ),
//               ),
//               child: Row(
//                 children: columns.map((column) {
//                   final cellValue = row[column]?.toString() ?? '';
//                   final isStockCell = _isStockColumn(column);
//
//                   return Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                       child: _buildSelectableCell(cellValue, isStockCell),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   bool _isStockColumn(String columnName) {
//     // Determine if this column contains stock names/symbols
//     final stockColumnNames = [
//       'name', 'company', 'stock', 'symbol', 'ticker',
//       'company name', 'stock name', 'security'
//     ];
//     return stockColumnNames.contains(columnName.toLowerCase());
//   }
//
//   Widget _buildSelectableCell(String cellValue, bool isStockCell) {
//     if (isStockCell && widget.onStockTap != null) {
//       // Stock cell - tappable and styled
//       return GestureDetector(
//         onTap: () {
//           print("🔍 Stock tapped from animated table: $cellValue");
//           widget.onStockTap!(cellValue);
//         },
//         child: SelectableText(
//           cellValue,
//           style: TextStyle(
//             fontSize: 14,
//             fontFamily: 'SF Pro',
//             color: Colors.blue[700],
//             fontWeight: FontWeight.w600,
//             decoration: TextDecoration.underline,
//             decorationColor: Colors.blue[700],
//           ),
//           contextMenuBuilder: widget.contextMenuBuilder,
//         ),
//       );
//     } else {
//       // Regular cell
//       return SelectableText(
//         cellValue,
//         style: const TextStyle(
//           fontSize: 14,
//           fontFamily: 'SF Pro',
//         ),
//         contextMenuBuilder: widget.contextMenuBuilder,
//       );
//     }
//   }
// }
//
// // Simple animation tracker to prevent re-animations
//
// // Updated KeyValueTableWidget to use animation (optional)
// class AnimatedKeyValueTableWidget extends StatelessWidget {
//   final String? heading;
//   final List<Map<String, dynamic>> rows;
//   final List<String>? columnOrder;
//   final Function(String)? onStockTap;
//
//   const AnimatedKeyValueTableWidget({
//     Key? key,
//     this.heading,
//     required this.rows,
//     this.columnOrder,
//     this.onStockTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     return AnimatedTableRenderer(
//       structuredData: {
//         'heading': heading,
//         'rows': rows,
//         'columnOrder': columnOrder,
//       },
//       messageId: messageId,
//       onStockTap: onStockTap,
//       contextMenuBuilder: _buildContextMenu,
//     );
//   }
//
//   Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
//     final value = editableTextState.textEditingValue;
//     final selection = value.selection;
//
//     if (!selection.isValid || selection.isCollapsed) {
//       return const SizedBox.shrink();
//     }
//
//     final selectedText = value.text.substring(selection.start, selection.end);
//
//     return AdaptiveTextSelectionToolbar(
//       anchors: editableTextState.contextMenuAnchors,
//       children: [
//         TextButton(
//           onPressed: () {
//             Clipboard.setData(ClipboardData(text: selectedText));
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Copied!')),
//             );
//             ContextMenuController.removeAny();
//           },
//           child: const Text('Copy', style: TextStyle(color: Colors.black)),
//         ),
//       ],
//     );
//   }
// }
//
//
//
//
// class AnimatedTable extends StatefulWidget {
//   final Map<String, dynamic> data;
//   final dynamic theme;
//   final Function(String)? onStockTap;
//   final String messageId;
//
//   const AnimatedTable({
//     Key? key,
//     required this.data,
//     required this.theme,
//     this.onStockTap,
//     required this.messageId,
//   }) : super(key: key);
//
//   @override
//   _AnimatedTableState createState() => _AnimatedTableState();
// }
//
// class _AnimatedTableState extends State<AnimatedTable>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late List<AnimationController> _rowControllers;
//   late List<Animation<double>> _rowAnimations;
//
//   late final List<List<String>> rows;
//   late final List<String> headers;
//   late final bool _hasAnimated;
//   late final String _tableId;
//
//   @override
//   void initState() {
//     super.initState();
//
//     headers = widget.data['headers'] as List<String>? ?? [];
//     rows = widget.data['rows'] as List<List<String>>? ?? [];
//
//     _tableId = '${widget.messageId}_table';
//     _hasAnimated = ChatAnimationTracker.hasAnimated(_tableId);
//
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _rowControllers = List.generate(
//       rows.length,
//           (index) => AnimationController(
//         duration: Duration(milliseconds: 300 + (index * 100)),
//         vsync: this,
//       ),
//     );
//
//     _rowAnimations = _rowControllers
//         .map((controller) => CurvedAnimation(
//       parent: controller,
//       curve: Curves.easeOutBack,
//     ))
//         .toList();
//
//     if (_hasAnimated) {
//       _fadeController.value = 1.0;
//       for (var c in _rowControllers) {
//         c.value = 1.0;
//       }
//     } else {
//       ChatAnimationTracker.markAsAnimated(_tableId);
//       _fadeController.forward();
//       _startRowAnimations();
//     }
//   }
//
//   void _startRowAnimations() async {
//     for (int i = 0; i < _rowControllers.length; i++) {
//       _rowControllers[i].forward();
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     for (var controller in _rowControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isStockTable = headers.isNotEmpty &&
//         (headers.first.toLowerCase().contains('stock') ||
//             headers.first.toLowerCase().contains('symbol') ||
//             headers.first.toLowerCase().contains('ticker'));
//
//     return FadeTransition(
//       opacity: _fadeController,
//       child: Container(
//         decoration: BoxDecoration(
//           border: Border.all(color: widget.theme.text.withOpacity(0.2)),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: widget.theme.text.withOpacity(0.05),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(8),
//                   topRight: Radius.circular(8),
//                 ),
//               ),
//               child: Table(
//                 border: TableBorder(
//                   horizontalInside:
//                   BorderSide(color: widget.theme.text.withOpacity(0.2)),
//                   verticalInside:
//                   BorderSide(color: widget.theme.text.withOpacity(0.2)),
//                 ),
//                 children: [
//                   TableRow(
//                     children: headers
//                         .map(
//                           (header) => Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Text(
//                           header,
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                             fontFamily: 'SF Pro',
//                             color: widget.theme.text,
//                           ),
//                         ),
//                       ),
//                     )
//                         .toList(),
//                   ),
//                 ],
//               ),
//             ),
//             Table(
//               border: TableBorder(
//                 horizontalInside:
//                 BorderSide(color: widget.theme.text.withOpacity(0.2)),
//                 verticalInside:
//                 BorderSide(color: widget.theme.text.withOpacity(0.2)),
//               ),
//               children: rows.asMap().entries.map((entry) {
//                 final rowIndex = entry.key;
//                 final row = entry.value;
//
//                 return TableRow(
//                   children: row.asMap().entries.map((cellEntry) {
//                     final columnIndex = cellEntry.key;
//                     final cellValue = cellEntry.value;
//
//                     return AnimatedBuilder(
//                       animation: _rowAnimations[rowIndex],
//                       builder: (context, child) {
//                         final animation = _rowAnimations[rowIndex];
//                         return FadeTransition(
//                           opacity: animation,
//                           child: Transform.translate(
//                             offset: Offset((1 - animation.value) * 50, 0),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: _buildTableCell(
//                                 cellValue,
//                                 isStockTable && columnIndex == 0,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }).toList(),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTableCell(String value, bool isStock) {
//     if (isStock && widget.onStockTap != null) {
//       return GestureDetector(
//         onTap: () => widget.onStockTap!(value),
//         child: Text(
//           value,
//           style: TextStyle(
//             fontSize: 14,
//             fontFamily: 'SF Pro',
//             color: Colors.black87,
//             fontWeight: FontWeight.w600,
//            // decoration: TextDecoration.underline,
//            // decorationColor: Colors.blue[700],
//           ),
//         ),
//       );
//     } else {
//       return Text(
//         value,
//         style: TextStyle(
//           fontSize: 14,
//           fontFamily: 'SF Pro',
//           color: widget.theme.text,
//         ),
//       );
//     }
//   }
// }
