import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/colors.dart';
import '../../core/helpers/themes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class InputActionsBarWidget extends StatefulWidget {
  final bool isTyping;
  final bool hasText;
  final bool isTranscribing;
  final VoidCallback onStartRecording;
  final VoidCallback onSendMessage;
  final VoidCallback onStopResponse;
  final AppTheme theme;

  const InputActionsBarWidget({
    Key? key,
    required this.isTyping,
    required this.hasText,
    required this.isTranscribing,
    required this.onStartRecording,
    required this.onSendMessage,
    required this.onStopResponse,
    required this.theme,
  }) : super(key: key);

  @override
  State<InputActionsBarWidget> createState() => _InputActionsBarWidgetState();
}

class _InputActionsBarWidgetState extends State<InputActionsBarWidget> {
  // Layout - OPTIMIZED SIZES
  static const double _kHit = 32;
  static const double _kCircle = 32;
  static const double _kGap = 16;
  static const double _kIconH = 20;
  static const double _kIconW = 20;
  static const double _kArrow = 18;

  // ✅ Tap area size (standard mobile touch target)
  static const double _kTapArea = 48;

  bool _showStopLatch = false;
  Timer? _latchTimer;
  Timer? _finishDebounce;

  @override
  void didUpdateWidget(covariant InputActionsBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTyping) {
      _latchTimer?.cancel();
      _latchTimer = null;
    }

    if (!widget.isTyping) {
      _finishDebounce?.cancel();
      _finishDebounce = Timer(const Duration(milliseconds: 120), () {
        if (mounted && !widget.isTyping) _clearLatch();
      });
    }
  }

  @override
  void dispose() {
    _latchTimer?.cancel();
    _finishDebounce?.cancel();
    super.dispose();
  }

  void _onTapSend() {
    HapticFeedback.mediumImpact();
    setState(() => _showStopLatch = true);

    _latchTimer?.cancel();
    _latchTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !widget.isTyping) setState(() => _showStopLatch = false);
    });

    widget.onSendMessage();
  }

  void _onTapStop() {
    HapticFeedback.mediumImpact();
    _clearLatch();
    widget.onStopResponse();
  }

  void _clearLatch() {
    _latchTimer?.cancel();
    _finishDebounce?.cancel();
    _latchTimer = null;
    _finishDebounce = null;
    if (_showStopLatch) setState(() => _showStopLatch = false);
  }

  Widget _circleButton({
    required Widget icon,
    required VoidCallback onTap,
    Color bgColor = Colors.transparent,
    bool disabled = false,
  }) {
    final bool isFilled = bgColor != Colors.transparent;
    return SizedBox(
      width: _kHit,
      height: _kHit,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(_kHit / 2),
          child: Center(
            child: Container(
              width: _kCircle,
              height: _kCircle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(
                  color: isFilled ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boldArrowIcon() {
    return SizedBox(
      width: _kArrow,
      height: _kArrow,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow),
          Positioned(left: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(right: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(left: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(left: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(right: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
          Positioned(right: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final bool showStop = widget.isTyping || _showStopLatch;
    final bool showSendSlot = showStop || widget.hasText || widget.isTranscribing;

    return RepaintBoundary(
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ ATTACH ICON - Larger tap area
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 2.5,bottom: 4.5),
                child: SizedBox(
                  width: _kTapArea, // ✅ 48x48 tap area
                  height: _kTapArea,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kTapArea / 2),
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/images/svgattach.svg",
                          height: _kIconH,
                          width: _kIconW,
                          color: theme.icon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ✅ MIC ICON - Larger tap area
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  right: showSendSlot ? 5 : 5,
                  top: 2,
                ),
                child: SizedBox(
                  width: _kTapArea, // ✅ 48x48 tap area
                  height: _kTapArea,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kTapArea / 2),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onStartRecording();
                      },
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/images/mic.svg",
                          height: _kIconH,
                          width: _kIconW,
                          color: theme.icon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Send/Stop - Appears with proper gap
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeInOut,
              width: showSendSlot ? (_kHit + 20) : 0,
              child: showSendSlot
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    ),
                    child: showStop
                        ? KeyedSubtree(
                      key: const ValueKey('stop'),
                      child: _circleButton(
                        bgColor: AppColors.primary,
                        onTap: _onTapStop,
                        icon: const Icon(Icons.stop,
                            color: Colors.white, size: 16),
                      ),
                    )
                        : KeyedSubtree(
                      key: const ValueKey('send'),
                      child: _circleButton(
                        bgColor: AppColors.primary,
                        onTap: _onTapSend,
                        icon: _boldArrowIcon(),
                      ),
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


// class InputActionsBarWidget extends StatefulWidget {
//   final bool isTyping;
//   final bool hasText;
//   final bool isTranscribing;
//   final VoidCallback onStartRecording;
//   final VoidCallback onSendMessage;
//   final VoidCallback onStopResponse;
//   final AppTheme theme;
//
//   const InputActionsBarWidget({
//     Key? key,
//     required this.isTyping,
//     required this.hasText,
//     required this.isTranscribing,
//     required this.onStartRecording,
//     required this.onSendMessage,
//     required this.onStopResponse,
//     required this.theme,
//   }) : super(key: key);
//
//   @override
//   State<InputActionsBarWidget> createState() => _InputActionsBarWidgetState();
// }
//
// class _InputActionsBarWidgetState extends State<InputActionsBarWidget> {
//   // Layout - OPTIMIZED SIZES
//   static const double _kHit = 32;     // ✅ Increased tap target from 30 → 32
//   static const double _kCircle = 32;  // ✅ Reduced circle from 36 → 32
//   static const double _kGap = 16;
//   static const double _kIconH = 20;
//   static const double _kIconW = 20;
//   static const double _kArrow = 18;   // ✅ Reduced arrow from 20 → 18
//
//   bool _showStopLatch = false;
//   Timer? _latchTimer;
//   Timer? _finishDebounce;
//
//   @override
//   void didUpdateWidget(covariant InputActionsBarWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     if (widget.isTyping) {
//       _latchTimer?.cancel();
//       _latchTimer = null;
//     }
//
//     if (!widget.isTyping) {
//       _finishDebounce?.cancel();
//       _finishDebounce = Timer(const Duration(milliseconds: 120), () {
//         if (mounted && !widget.isTyping) _clearLatch();
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _latchTimer?.cancel();
//     _finishDebounce?.cancel();
//     super.dispose();
//   }
//
//   void _onTapSend() {
//     HapticFeedback.mediumImpact();
//     setState(() => _showStopLatch = true);
//
//     _latchTimer?.cancel();
//     _latchTimer = Timer(const Duration(seconds: 10), () {
//       if (mounted && !widget.isTyping) setState(() => _showStopLatch = false);
//     });
//
//     widget.onSendMessage();
//   }
//
//   void _onTapStop() {
//     HapticFeedback.mediumImpact();
//     _clearLatch();
//     widget.onStopResponse();
//   }
//
//   void _clearLatch() {
//     _latchTimer?.cancel();
//     _finishDebounce?.cancel();
//     _latchTimer = null;
//     _finishDebounce = null;
//     if (_showStopLatch) setState(() => _showStopLatch = false);
//   }
//
//   Widget _circleButton({
//     required Widget icon,
//     required VoidCallback onTap,
//     Color bgColor = Colors.transparent,
//     bool disabled = false,
//   }) {
//     final bool isFilled = bgColor != Colors.transparent;
//     return SizedBox(
//       width: _kHit,
//       height: _kHit,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: disabled ? null : () {
//             HapticFeedback.lightImpact();
//             onTap();
//           },
//           borderRadius: BorderRadius.circular(_kHit / 2),
//           child: Center(
//             child: Container(
//               width: _kCircle,
//               height: _kCircle,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: bgColor,
//                 border: Border.all(
//                   color: isFilled ? Colors.transparent : Colors.grey.shade400,
//                   width: 1.2,
//                 ),
//               ),
//               child: Center(child: icon),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _boldArrowIcon() {
//     return SizedBox(
//       width: _kArrow,
//       height: _kArrow,
//       child: Stack(
//         alignment: Alignment.center,
//         children: const [
//           Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow),
//           Positioned(left: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(right: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(left: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(left: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(right: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//           Positioned(right: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: _kArrow)),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.theme;
//
//     final bool showStop = widget.isTyping || _showStopLatch;
//     final bool showSendSlot = showStop || widget.hasText || widget.isTranscribing;
//
//     return RepaintBoundary(
//       child: SizedBox(
//         height: 44,
//         child: Row(
//           mainAxisSize: MainAxisSize.max,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 20),
//                 child: InkWell(
//                   onTap: () {
//                     HapticFeedback.lightImpact();
//                   },
//                   child: SvgPicture.asset(
//                     "assets/images/svgattach.svg",
//                     height: _kIconH,
//                     width: _kIconW,
//                     color: theme.icon,
//                   ),
//                 ),
//               ),
//             ),
//
//             const Spacer(),
//
//             Center(
//               child: Padding(
//                 padding: EdgeInsets.only(right: showSendSlot ? 20 : 20,top: 2), // ✅ Always 16px right padding
//                 child: InkWell(
//                   onTap: () {
//                     HapticFeedback.mediumImpact();
//                     widget.onStartRecording();
//                   },
//                   child: SvgPicture.asset(
//                     "assets/images/mic.svg",
//                     height: _kIconH,
//                     width: _kIconW,
//                     color: theme.icon,
//                   ),
//                 ),
//               ),
//             ),
//
//             // ✅ Send/Stop - Appears with proper gap
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 140),
//               curve: Curves.easeInOut,
//               width: showSendSlot ? (_kHit + 20) : 0, // ✅ Button width + 16px right margin
//               child: showSendSlot
//                   ? Center(
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 20), // ✅ 16px from right edge
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 140),
//                     switchInCurve: Curves.easeOut,
//                     switchOutCurve: Curves.easeIn,
//                     layoutBuilder: (current, previous) => Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         ...previous,
//                         if (current != null) current,
//                       ],
//                     ),
//                     child: showStop
//                         ? KeyedSubtree(
//                       key: const ValueKey('stop'),
//                       child: _circleButton(
//                         bgColor: AppColors.primary,
//                         onTap: _onTapStop,
//                         icon: const Icon(Icons.stop, color: Colors.white, size: 16),
//                       ),
//                     )
//                         : KeyedSubtree(
//                       key: const ValueKey('send'),
//                       child: _circleButton(
//                         bgColor: AppColors.primary,
//                         onTap: _onTapSend,
//                         icon: _boldArrowIcon(),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//                   : const SizedBox.shrink(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




