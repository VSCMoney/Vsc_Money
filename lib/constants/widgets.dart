import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';







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
  late AnimationController _revealController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation - continuous wave effect
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Text reveal animation - progressive text visibility
    _revealController = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 30 + 300),
      vsync: this,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );

    if (!widget.isComplete) {
      _shimmerController.repeat();
      _revealController.forward();
    } else {
      _revealController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PremiumShimmerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isComplete != oldWidget.isComplete) {
      if (widget.isComplete) {
        _shimmerController.stop();
        _revealController.forward();
      } else {
        _shimmerController.repeat();
        _revealController.forward();
      }
    }

    if (widget.text != oldWidget.text) {
      _revealController.duration = Duration(seconds: widget.text.length * 30 + 5);
      _revealController.reset();
      _revealController.forward();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnimation, _revealAnimation]),
      builder: (context, child) {
        final revealProgress = _revealAnimation.value;
        final visibleLength = (widget.text.length * revealProgress).round();
        final visibleText = widget.text.substring(0, visibleLength.clamp(0, widget.text.length));
        final hiddenText = widget.text.substring(visibleLength.clamp(0, widget.text.length));

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visible text (normal color)
            if (visibleText.isNotEmpty)
              Text(
                visibleText,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.isComplete ? Color(0xFF374151) : Color(0xFF6B7280),
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            // Hidden text with shimmer effect
            if (hiddenText.isNotEmpty && !widget.isComplete)
              Flexible(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        widget.baseColor.withOpacity(0.3),
                        widget.highlightColor.withOpacity(0.8),
                        widget.baseColor.withOpacity(0.3),
                      ],
                      stops: [
                        (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                        _shimmerAnimation.value.clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    hiddenText,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}













class StatusUpdateWidget extends StatefulWidget {
  final List<StatusUpdate> statusUpdates;
  final dynamic theme;

  const StatusUpdateWidget({
    Key? key,
    required this.statusUpdates,
    required this.theme,
  }) : super(key: key);

  @override
  _StatusUpdateWidgetState createState() => _StatusUpdateWidgetState();
}

class _StatusUpdateWidgetState extends State<StatusUpdateWidget>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));

    _transitionController.forward();
  }

  @override
  void didUpdateWidget(StatusUpdateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.statusUpdates.length != oldWidget.statusUpdates.length ||
        (widget.statusUpdates.isNotEmpty && oldWidget.statusUpdates.isNotEmpty &&
            widget.statusUpdates.last.message != oldWidget.statusUpdates.last.message)) {
      _transitionController.reset();
      _transitionController.forward();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statusUpdates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.statusUpdates.map((status) {
        final isLatest = status == widget.statusUpdates.last;

        return AnimatedSwitcher(
          duration: const Duration(seconds: 5),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey(status.id),
            child: buildStatusItem(status),
          ),
        );
    }      ).toList(),
    );
  }

  // Even simpler usage
  Widget buildStatusItem(StatusUpdate status) {
    return PremiumShimmerWidget(
      text: status.message,
      isComplete: status.isComplete,
      baseColor: const Color(0xFF9CA3AF),
      highlightColor: const Color(0xFF6B7280),
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














class ChatAnimationTracker {
  static final Set<String> _completedAnimations = <String>{};

  static bool hasAnimated(String id) {
    return _completedAnimations.contains(id);
  }

  static void markAsAnimated(String id) {
    _completedAnimations.add(id);
  }

  static void clearAll() {
    _completedAnimations.clear();
  }
}

// FIXED TYPEWRITER TEXT - NO RE-ANIMATION

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  final bool isComplete;
  final String uniqueId; // ADD THIS

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 30),
    required this.isComplete,
    required this.uniqueId, // ADD THIS
  }) : super(key: key);

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  String _displayedText = '';
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    // Check if this text has already animated
    _hasAnimated = ChatAnimationTracker.hasAnimated(widget.uniqueId);

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * widget.speed.inMilliseconds),
      vsync: this,
    );

    _characterCount = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _characterCount.addListener(() {
      if (mounted) {
        setState(() {
          _displayedText = widget.text.substring(0, _characterCount.value);
        });
      }
    });

    if (_hasAnimated) {
      // If already animated, show complete text immediately
      _controller.value = 1.0;
      _displayedText = widget.text;
    } else {
      // First time - animate and mark as completed
      ChatAnimationTracker.markAsAnimated(widget.uniqueId);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: _displayedText, style: widget.style),
          // Only show cursor if actively animating
          if (!_hasAnimated && !widget.isComplete && _characterCount.value < widget.text.length)
            WidgetSpan(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: (_controller.value * 2) % 1 > 0.5 ? 1.0 : 0.0,
                    child: Text('|', style: widget.style),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// FIXED ANIMATED TABLE - NO RE-ANIMATION

class AnimatedPayloadRenderer extends StatelessWidget {
  final ResponsePayload payload;
  final dynamic theme;
  final TextStyle style;
  final Function(String)? onStockTap;
  final Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final String messageId;

  const AnimatedPayloadRenderer({
    Key? key,
    required this.payload,
    required this.theme,
    required this.style,
    this.onStockTap,
    this.contextMenuBuilder,
    required this.messageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final payloadId = '${messageId}_payload_${payload.id}';
    final hasAnimated = ChatAnimationTracker.hasAnimated(payloadId);

    if (!hasAnimated) {
      ChatAnimationTracker.markAsAnimated(payloadId);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (payload.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                payload.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans',
                  color: theme.text,
                ),
              ),
            ),
          if (payload.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                payload.description!,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'DM Sans',
                  color: theme.text.withOpacity(0.7),
                ),
              ),
            ),
          _renderPayloadContent(),
        ],
      ),
    );
  }

  Widget _renderPayloadContent() {
    switch (payload.type) {
      case PayloadType.text:
        return _buildStreamingText(payload.data);
      case PayloadType.json:
        return _buildJsonPayload(payload.data);
      case PayloadType.chart:
        return _buildChartPayload(payload.data);
    }
  }

  Widget _buildStreamingText(String text) {
    final textId = '${messageId}_text_${payload.id}';
    final hasAnimated = ChatAnimationTracker.hasAnimated(textId);

    if (!hasAnimated) {
      ChatAnimationTracker.markAsAnimated(textId);
    }

    return TweenAnimationBuilder<double>(
      duration: hasAnimated ? Duration.zero : Duration(milliseconds: text.length * 20),
      tween: Tween(begin: hasAnimated ? 1.0 : 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        final visibleLength = (text.length * value).round();
        final visibleText = text.substring(0, visibleLength);

        return Text(
          visibleText,
          style: style,
        );
      },
    );
  }

  Widget _buildJsonPayload(Map<String, dynamic> data) {
    final displayType = data['display_type'] as String?;

    if (displayType == 'table') {
      return _buildFadeInWrapper(
        child: AnimatedTable(
          data: data,
          theme: theme,
          onStockTap: onStockTap,
          messageId: messageId,
        ),
      );
    } else {
      return _buildFadeInWrapper(
        child: _buildKeyValueView(data),
      );
    }
  }

  Widget _buildChartPayload(dynamic data) {
    return _buildFadeInWrapper(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                'Chart will be rendered here',
                style: TextStyle(
                  color: theme.text,
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueView(Map<String, dynamic> data) {
    final displayData = Map<String, dynamic>.from(data);
    displayData.remove('display_type');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.text.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayData.entries.map((entry) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                  ),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: entry.value.toString()),
                  ],
                ),
              ),
            ),
        ).toList(),
      ),
    );
  }

  Widget _buildFadeInWrapper({required Widget child}) {
    final fadeId = '${messageId}_fade_${payload.id}';
    final hasAnimated = ChatAnimationTracker.hasAnimated(fadeId);

    if (!hasAnimated) {
      ChatAnimationTracker.markAsAnimated(fadeId);

      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, opacity, _) {
          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
      );
    } else {
      return child;
    }
  }
}

class AnimatedTable extends StatefulWidget {
  final Map<String, dynamic> data;
  final dynamic theme;
  final Function(String)? onStockTap;
  final String messageId;

  const AnimatedTable({
    Key? key,
    required this.data,
    required this.theme,
    this.onStockTap,
    required this.messageId,
  }) : super(key: key);

  @override
  _AnimatedTableState createState() => _AnimatedTableState();
}

class _AnimatedTableState extends State<AnimatedTable>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<AnimationController> _rowControllers;
  late List<Animation<double>> _rowAnimations;

  late final List<List<String>> rows;
  late final List<String> headers;
  late final bool _hasAnimated;
  late final String _tableId;

  @override
  void initState() {
    super.initState();

    headers = widget.data['headers'] as List<String>? ?? [];
    rows = widget.data['rows'] as List<List<String>>? ?? [];

    _tableId = '${widget.messageId}_table';
    _hasAnimated = ChatAnimationTracker.hasAnimated(_tableId);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rowControllers = List.generate(
      rows.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _rowAnimations = _rowControllers
        .map((controller) => CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    ))
        .toList();

    if (_hasAnimated) {
      _fadeController.value = 1.0;
      for (var c in _rowControllers) {
        c.value = 1.0;
      }
    } else {
      ChatAnimationTracker.markAsAnimated(_tableId);
      _fadeController.forward();
      _startRowAnimations();
    }
  }

  void _startRowAnimations() async {
    for (int i = 0; i < _rowControllers.length; i++) {
      _rowControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _rowControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStockTable = headers.isNotEmpty &&
        (headers.first.toLowerCase().contains('stock') ||
            headers.first.toLowerCase().contains('symbol') ||
            headers.first.toLowerCase().contains('ticker'));

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: widget.theme.text.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.theme.text.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Table(
                border: TableBorder(
                  horizontalInside:
                  BorderSide(color: widget.theme.text.withOpacity(0.2)),
                  verticalInside:
                  BorderSide(color: widget.theme.text.withOpacity(0.2)),
                ),
                children: [
                  TableRow(
                    children: headers
                        .map(
                          (header) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          header,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'DM Sans',
                            color: widget.theme.text,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            Table(
              border: TableBorder(
                horizontalInside:
                BorderSide(color: widget.theme.text.withOpacity(0.2)),
                verticalInside:
                BorderSide(color: widget.theme.text.withOpacity(0.2)),
              ),
              children: rows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;

                return TableRow(
                  children: row.asMap().entries.map((cellEntry) {
                    final columnIndex = cellEntry.key;
                    final cellValue = cellEntry.value;

                    return AnimatedBuilder(
                      animation: _rowAnimations[rowIndex],
                      builder: (context, child) {
                        final animation = _rowAnimations[rowIndex];
                        return FadeTransition(
                          opacity: animation,
                          child: Transform.translate(
                            offset: Offset((1 - animation.value) * 50, 0),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _buildTableCell(
                                cellValue,
                                isStockTable && columnIndex == 0,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String value, bool isStock) {
    if (isStock && widget.onStockTap != null) {
      return GestureDetector(
        onTap: () => widget.onStockTap!(value),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'DM Sans',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
           // decoration: TextDecoration.underline,
           // decorationColor: Colors.blue[700],
          ),
        ),
      );
    } else {
      return Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'DM Sans',
          color: widget.theme.text,
        ),
      );
    }
  }
}
