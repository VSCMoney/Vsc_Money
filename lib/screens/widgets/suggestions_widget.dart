import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/locator.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // gradient: const LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     Color(0xFFFFFFFE), // Almost white
        //     Color(0xFFFEFCFA), // Barely cream
        //     Color(0xFFFCF9F6), // Very subtle cream
        //     Color(0xFFF9F5F1), // Light cream
        //     Color(0xFFF6F0EC), // Soft cream
        //     Color(0xFFF3EDE8), // Medium cream
        //     Color(0xFFF1EAE4), // Full cream
        //   ],
        //   stops: [0.0, 0.02, 0.06, 0.12, 0.20, 0.32, 1.0],
        // ),
        gradient: appBackgroundGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.12), // ✅ Lighter opacity
            blurRadius: 5,            // ✅ HIGH blur for rounded shadow
            spreadRadius: 0,           // ✅ No spread
            offset: const Offset(0, 4),
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
                  _InlineOdometerTicker(
                    label: 'Nifty50',
                    point: inlinePoint,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.text.withOpacity(0.85),
                fontFamily: "DM Sans",
                fontWeight: FontWeight.w400,
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

  // Widget _buildNormalChip({
  //   required String title,
  //   required String subtitle,
  //   required String suggestionText,
  //   _Point? inlinePoint,
  // }) {
  //   final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
  //
  //   final card = Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //     decoration: BoxDecoration(
  //       gradient:   LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Color(0xFFFFFFFE), // Almost white
  //           Color(0xFFFEFCFA), // Barely cream
  //           Color(0xFFFCF9F6), // Very subtle cream
  //           Color(0xFFF9F5F1), // Light cream
  //           Color(0xFFF6F0EC), // Soft cream
  //           Color(0xFFF3EDE8), // Medium cream
  //           Color(0xFFF1EAE4), // Full cream
  //         ],
  //         stops: [0.0, 0.02, 0.06, 0.12, 0.20, 0.32, 1.0],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Color(0xff000000).withOpacity(0.25), // ✅ Lighter opacity
  //           blurRadius: 2,            // ✅ More blur
  //           spreadRadius: 0,           // ✅ No spread (spread creates rectangle effect)
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: IntrinsicWidth(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           // Title + inline ticker area
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.max,
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   title,
  //                   maxLines: 1,
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontFamily: 'DM Sans',
  //                     color: theme.text,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ),
  //               if (inlinePoint != null) ...[
  //                 const SizedBox(width: 8),
  //                 _InlineOdometerTicker(
  //                   label: 'Nifty50',
  //                   point: inlinePoint,
  //                 ),
  //               ],
  //             ],
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             subtitle,
  //             maxLines: 1,
  //             overflow: TextOverflow.ellipsis,
  //             style: TextStyle(
  //               fontSize: 12,
  //               color: theme.text.withOpacity(0.85),
  //               fontFamily: "DM Sans",
  //               fontWeight: FontWeight.w400,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //
  //   return GestureDetector(
  //     behavior: HitTestBehavior.opaque,
  //     onTap: () => _pickSuggestion(suggestionText),
  //     child: card,
  //   );
  // }


  Widget _buildGhostChip({
    required String title,
    required _Point point,
    required String suggestionText,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    const r = 7.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickSuggestion(suggestionText),
      child: IntrinsicWidth( // ✅ width = content
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  // thinner height
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15), // ✅ slimmer
                  color: theme.background.withOpacity(0.06),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // ✅ shrink-to-fit
                    children: [
                      // no Expanded → let content define width
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DM Sans',
                              color: theme.text.withOpacity(.95),
                              fontSize: 12,
                              height: 1.0, // ✅ tight line-height
                            ),
                          ),
                          const SizedBox(height: 4), // ✅ a bit tighter
                          _ProminentOdometerTicker(point: point),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ---- TOP BORDER (clean, not clipped) ----
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      border: Border.all(
                        color: theme.border.withOpacity(.45),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
            const SizedBox(width: 18),

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








// ✅ REPLACE _InlineOdometerTicker - Now scrolls ENTIRE row
class _InlineOdometerTicker extends StatefulWidget {
  final String label;
  final _Point point;

  const _InlineOdometerTicker({
    Key? key,
    required this.label,
    required this.point
  }) : super(key: key);

  @override
  State<_InlineOdometerTicker> createState() => _InlineOdometerTickerState();
}

class _InlineOdometerTickerState extends State<_InlineOdometerTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  String _previousLabel = '';
  String _previousArrow = '';
  double _previousPct = 0.0;

  String _currentLabel = '';
  String _currentArrow = '';
  double _currentPct = 0.0;

  Color _previousColor = Color(0xFF159947);
  Color _currentColor = Color(0xFF159947);

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.label;
    _currentArrow = widget.point.arrow;
    _currentPct = widget.point.changePct;
    _currentColor = widget.point.up ? Color(0xFF159947) : Color(0xFFD5353A);

    _previousLabel = _currentLabel;
    _previousArrow = _currentArrow;
    _previousPct = _currentPct;
    _previousColor = _currentColor;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(_InlineOdometerTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if data changed
    if (oldWidget.label != widget.label ||
        oldWidget.point.changePct != widget.point.changePct ||
        oldWidget.point.arrow != widget.point.arrow) {
      setState(() {
        _previousLabel = oldWidget.label;
        _previousArrow = oldWidget.point.arrow;
        _previousPct = oldWidget.point.changePct;
        _previousColor = oldWidget.point.up ? Color(0xFF159947) : Color(0xFFD5353A);

        _currentLabel = widget.label;
        _currentArrow = widget.point.arrow;
        _currentPct = widget.point.changePct;
        _currentColor = widget.point.up ? Color(0xFF159947) : Color(0xFFD5353A);
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRow(String label, String arrow, double pct, Color color) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontFamily: 'DM Sans',
      color: color,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textStyle),
        const SizedBox(width: 6),
        Text('$arrow ', style: textStyle),
        Text(pct.abs().toStringAsFixed(2), style: textStyle),
        Text('%', style: textStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = 20.0; // Approximate height

    return SizedBox(
      height: rowHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // ✅ OLD row - slides UP
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildRow(
                    _previousLabel,
                    _previousArrow,
                    _previousPct,
                    _previousColor,
                  ),
                ),

                // ✅ NEW row - comes from BOTTOM
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOutCubic,
                  )),
                  child: Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: _buildRow(
                      _currentLabel,
                      _currentArrow,
                      _currentPct,
                      _currentColor,
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

// ✅ REPLACE _ProminentOdometerTicker - Now scrolls ENTIRE row
class _ProminentOdometerTicker extends StatefulWidget {
  final _Point point;

  const _ProminentOdometerTicker({Key? key, required this.point}) : super(key: key);

  @override
  State<_ProminentOdometerTicker> createState() => _ProminentOdometerTickerState();
}

class _ProminentOdometerTickerState extends State<_ProminentOdometerTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  double _previousValue = 0.0;
  double _previousPct = 0.0;
  bool _previousUp = true;

  double _currentValue = 0.0;
  double _currentPct = 0.0;
  bool _currentUp = true;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.point.value;
    _currentPct = widget.point.changePct;
    _currentUp = widget.point.up;

    _previousValue = _currentValue;
    _previousPct = _currentPct;
    _previousUp = _currentUp;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(_ProminentOdometerTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.point.value != widget.point.value ||
        oldWidget.point.changePct != widget.point.changePct) {
      setState(() {
        _previousValue = oldWidget.point.value;
        _previousPct = oldWidget.point.changePct;
        _previousUp = oldWidget.point.up;

        _currentValue = widget.point.value;
        _currentPct = widget.point.changePct;
        _currentUp = widget.point.up;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Widget _buildRow(double value, double pct, bool isUp) {
    const Color green = Color(0xFF159947);
    const Color red = Color(0xFFD5353A);
    final fg = isUp ? green : red;

    final valueStr = _formatNumber(value);
    final deltaAbs = (value * (pct / 100)).abs();
    final deltaStr = deltaAbs.toStringAsFixed(2);
    final deltaPrefix = isUp ? '+' : '−';
    final pctStr = pct.abs().toStringAsFixed(2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valueStr,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text('  ', style: TextStyle(fontSize: 16, color: fg)),
        Text(
          deltaPrefix,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            color: fg,
          ),
        ),
        Text(
          deltaStr,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(' ($pctStr%)', style: TextStyle(
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w700,
          fontSize: 12.0,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = 20.0;

    return SizedBox(
      height: rowHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // ✅ OLD row - slides UP
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildRow(_previousValue, _previousPct, _previousUp),
                ),

                // ✅ NEW row - comes from BOTTOM
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOutCubic,
                  )),
                  child: _buildRow(_currentValue, _currentPct, _currentUp),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}




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






LinearGradient appBackgroundGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (!isDark) {
    // LIGHT (tumhara wala)
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFE), // Almost white
        Color(0xFFFEFCFA), // Barely cream
        Color(0xFFFCF9F6), // Very subtle cream
        Color(0xFFF9F5F1), // Light cream
        Color(0xFFF6F0EC), // Soft cream
        Color(0xFFF3EDE8), // Medium cream
        Color(0xFFF1EAE4), // Full cream
      ],
      stops: [0.0, 0.02, 0.06, 0.12, 0.20, 0.32, 1.0],
    );
  }

  // DARK — charcoal with a cool tint, denser stops for smoother falloff
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF303030),
      Color(0xFF303030),
    ],
    // Slightly tighter early blend, longer tail in the lows
    stops: [0.0, 0.03],
  );
}

