import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/theme_service.dart';


import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SuggestionsWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onAskVitty;
  final VoidCallback? onSuggestionSelected;

  /// Parent-controlled: true => show transparent “ghost” cards
  final bool ghost;

  const SuggestionsWidget({
    Key? key,
    required this.controller,
    this.onAskVitty,
    this.onSuggestionSelected,
    required this.ghost,
  }) : super(key: key);

  @override
  State<SuggestionsWidget> createState() => _SuggestionsWidgetState();
}

class _SuggestionsWidgetState extends State<SuggestionsWidget> {
  late Timer _timer;
  int _tick = 0;
  //double _kNormalChipWidth = 242;  // Was 260
  double _kInlineTickerWidth = 130;


  // Dummy streams updating every 2s (Nifty & Sensex)
  final List<_Point> _niftySeries = const [
    _Point(22115.6, 0.56),
    _Point(22102.3, 0.41),
    _Point(22088.4, 0.35),
    _Point(22162.9, 0.72),
    _Point(21960.3, -0.08),
    _Point(22110.7, 0.58),
  ];
  final List<_Point> _sensexSeries = const [
    _Point(72780.9, 0.49),
    _Point(72620.4, 0.22),
    _Point(72491.8, -0.12),
    _Point(72940.2, 0.61),
    _Point(72310.6, -0.28),
    _Point(72830.1, 0.44),
  ];

  _Point get _nifty => _niftySeries[_tick % _niftySeries.length];
  _Point get _sensex => _sensexSeries[_tick % _sensexSeries.length];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _pickSuggestion(String text) {
    widget.controller.text = text;
    widget.controller.selection =
        TextSelection.fromPosition(TextPosition(offset: text.length));
    widget.onSuggestionSelected?.call();
  }

  Widget _buildNormalChip({
    required String title,
    required String subtitle,
    required String suggestionText,
    _Point? inlinePoint,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final card = Container(
      // ✅ FIXED: Tighter padding (10 instead of 19)
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ✅ FIXED: Correct gradient angle (277.26deg)
        gradient: LinearGradient(
          // begin: Alignment(-0.2, -0.35),  // Calculated for 277.26deg
          // end: Alignment(1.0, 0.85),
          colors: theme.gradient,
          stops: const [0, 0.15],  // ✅ Changed from [0, 0.15]
        ),
        color: theme.message,
        // ✅ FIXED: Small radius like Figma
        borderRadius: BorderRadius.circular(7),  // Was 16
        boxShadow: [
          // ✅ FIXED: Proper shadow with blur
          BoxShadow(
            color: Color(0x29000000),  // 16% opacity (#00000029)
            blurRadius: 3,              // Added blur
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + inline ticker area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Sans',
                      color: theme.text,
                      fontSize: 14,
        
                    ),
                  ),
                ),
                if (inlinePoint != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: _kInlineTickerWidth,
                    child: _InlineOdometerTicker(
                      label: 'Nifty50',
                      point: inlinePoint,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),  // ✅ Reduced from 10
            Text(
              subtitle,
              maxLines: 1,  // ✅ Changed from 2 for tighter layout
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,  // ✅ Adjusted
                color: theme.text.withOpacity(0.85),
                fontFamily: "DM Sans",
                fontWeight: FontWeight.w400,  // ✅ Regular weight
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickSuggestion(suggestionText),
      child: card,
    );
  }


  // ---------- GHOST CHIP (glass + compact, different layout) ----------
  Widget _buildGhostChip({
    required String title,
    required _Point point, // show large ticker block inside
    required String suggestionText,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
       // color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border.withOpacity(.45), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 170, maxWidth: 210),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // left: stacked title + prominent ticker line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Smaller title (no inline ticker here)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DM Sans',
                      color: theme.text.withOpacity(.95),
                      fontSize: 13.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ProminentOdometerTicker(point: point), // big value + % change
                ],
              ),
            ),
            // Chevron pill (kept subtle)
            // Container(
            //   height: 28,
            //   width: 28,
            //   decoration: BoxDecoration(
            //     color: Colors.white.withOpacity(.06),
            //     border: Border.all(color: theme.border.withOpacity(.4)),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Icon(Icons.chevron_right,
            //       size: 18, color: theme.text.withOpacity(.85)),
            // ),
          ],
        ),
      ),
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: inner,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickSuggestion(suggestionText),
      child: glass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ghost = widget.ghost;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: SizedBox(
        key: ValueKey(ghost),
        height: ghost ? 96 : 95,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // Card 1
            ghost
                ? _buildGhostChip(
              title: 'Nifty 50',
              point: _nifty,
              suggestionText: 'Show Nifty 50 market overview',
            )
                : _buildNormalChip(
              title: 'Market Overview',
              subtitle: 'What’s happening in the market today?',
              suggestionText: "What’s happening in the market today?",
              inlinePoint: _nifty, // Nifty next to title (as asked)
            ),
            const SizedBox(width: 12),

            // Card 2
            ghost
                ? _buildGhostChip(
              title: 'Sensex',
              point: _sensex,
              suggestionText: 'Show Sensex overview',
            )
                : _buildNormalChip(
              title: 'My Portfolio',
              subtitle: "How’s my portfolio doing?",
              suggestionText: "How’s my portfolio doing?",
            ),
          ],
        ),
      ),
    );
  }
}

// ===== helpers =====

class _Point {
  final double value;
  final double changePct;
  const _Point(this.value, this.changePct);
  bool get up => changePct >= 0;
  String get arrow => up ? '▲' : '▼';
  String get pctStr => '${arrow} ${changePct.abs().toStringAsFixed(2)}%';
}








// ✅ REPLACE _InlineFlipTicker with this new Odometer version
class _InlineOdometerTicker extends StatelessWidget {
  final String label;
  final _Point point;

  const _InlineOdometerTicker({
    Key? key,
    required this.label,
    required this.point
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF159947);
    const Color red = Color(0xFFD5353A);
    final fg = point.up ? green : red;

    final textStyleLabel = TextStyle(
      fontWeight: FontWeight.w700,
      fontFamily: 'DM Sans',
      color: fg,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OdometerNumber(
          value: label,
          textStyle: textStyleLabel,
        ),
        const SizedBox(width: 6),
        // Arrow (static)
        // Text(point.arrow + ' ', style: textStyleLabel),
        _OdometerNumber(
          value: point.arrow + ' ',
          textStyle: textStyleLabel,
        ),
        // ✅ Odometer for percentage value
        _OdometerNumber(
          value: point.changePct.abs().toStringAsFixed(2),
          textStyle: textStyleLabel,
        ),
        Text('%', style: textStyleLabel),
      ],
    );
  }
}

// ✅ REPLACE _ProminentTicker with this odometer version
class _ProminentOdometerTicker extends StatelessWidget {
  final _Point point;

  const _ProminentOdometerTicker({Key? key, required this.point}) : super(key: key);

  String _formatNumber(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts.first;
    final frac = parts.last;
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      buf.write(intPart[i]);
      final remain = intPart.length - i - 1;
      if (remain > 0 && remain % 3 == 0) buf.write(',');
    }
    return '${buf.toString()}.$frac';
  }

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF159947);
    const Color red = Color(0xFFD5353A);
    final fg = point.up ? green : red;

    final valueStr = _formatNumber(point.value);
    final deltaAbs = (point.value * (point.changePct / 100)).abs();
    final deltaStr = deltaAbs.toStringAsFixed(2);
    final deltaPrefix = point.up ? '+' : '−';
    final pctStr = point.changePct.abs().toStringAsFixed(2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main value with odometer
        _OdometerNumber(
          value: valueStr,
          textStyle: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        Text('  ', style: TextStyle(fontSize: 16, color: fg)),

        // Delta change
        Text(
          deltaPrefix,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13.8,
            color: fg,
          ),
        ),
        _OdometerNumber(
          value: deltaStr,
          textStyle: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13.8,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        Text(' ', style: TextStyle(fontSize: 13.8, color: fg)),

        // Percentage
        Text(
          '(',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13.8,
            color: fg,
          ),
        ),
        _OdometerNumber(
          value: pctStr,
          textStyle: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13.8,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '%)',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 13.8,
            color: fg,
          ),
        ),
      ],
    );
  }
}

// ✅ ODOMETER NUMBER - Animates entire number string
class _OdometerNumber extends StatelessWidget {
  final String value;
  final TextStyle textStyle;

  const _OdometerNumber({
    Key? key,
    required this.value,
    required this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chars = value.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: chars.map((char) {
        // Check if it's a digit
        if (RegExp(r'[0-9]').hasMatch(char)) {
          return _RollingDigit(
            digit: char,
            textStyle: textStyle,
          );
        } else {
          // Comma, period, or other character (static)
          return Text(char, style: textStyle);
        }
      }).toList(),
    );
  }
}

// ✅ SINGLE ROLLING DIGIT - Vertical slot machine effect
class _RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle textStyle;

  const _RollingDigit({
    Key? key,
    required this.digit,
    required this.textStyle,
  }) : super(key: key);

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String _previousDigit = '0';
  String _currentDigit = '0';

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _previousDigit = widget.digit;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Smooth roll
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // Slide up
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(_RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.digit != widget.digit) {
      setState(() {
        _previousDigit = oldWidget.digit;
        _currentDigit = widget.digit;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digitHeight = (widget.textStyle.fontSize ?? 14) * 1.5;

    return SizedBox(
      height: digitHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // ✅ OLD digit - slides UP and fades out
                SlideTransition(
                  position: _slideAnimation,
                  child: Opacity(
                    opacity: 1.0 - _controller.value,
                    child: Text(
                      _previousDigit,
                      style: widget.textStyle,
                    ),
                  ),
                ),

                // ✅ NEW digit - comes from BOTTOM and fades in
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1), // Start below
                    end: Offset.zero,           // End at center
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Opacity(
                    opacity: _controller.value,
                    child: Text(
                      _currentDigit,
                      style: widget.textStyle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}





