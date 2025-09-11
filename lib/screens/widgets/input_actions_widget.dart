import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/colors.dart';
import '../../core/helpers/themes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';






// class InputActionsBarWidget extends StatelessWidget {
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
//   Widget _circleButton({
//     required Widget icon,
//     required VoidCallback onTap,
//     Color bgColor = Colors.transparent,
//     bool disabled = false,
//   }) {
//     final bool isFilled = bgColor != Colors.transparent;
//
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: disabled ? null : () {
//         HapticFeedback.lightImpact();
//         onTap();
//       },
//       child: Container(
//         width: 48, // Expanded tap area
//         height: 48, // Expanded tap area
//         alignment: Alignment.center,
//         child: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: bgColor,
//             border: Border.all(
//               color: isFilled ? Colors.transparent : Colors.grey.shade400,
//               width: 1.2,
//             ),
//           ),
//           child: Center(child: icon),
//         ),
//       ),
//     );
//   }
//
//   Widget _boldArrowIcon() {
//     return Stack(
//       alignment: Alignment.center,
//       children: const [
//         Icon(Icons.arrow_upward, color: Colors.white, size: 20),
//         Positioned(left: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(right: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(left: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(left: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(right: 0.5, top: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//         Positioned(right: 0.5, bottom: 0.5, child: Icon(Icons.arrow_upward, color: Colors.white, size: 20)),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final showSend = isTyping || hasText || isTranscribing;
//
//     return RepaintBoundary(
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         key: const ValueKey('normalMode'),
//         children: [
//           // Attach button with padding below icon
//           MaterialButton(
//             onPressed: () {
//               HapticFeedback.heavyImpact();
//               print("Attach tapped");
//             },
//             minWidth: 0,
//             height: 40,
//             padding: EdgeInsets.zero,
//             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 4.0), // Add padding below icon
//               child: SvgPicture.asset(
//                 "assets/images/attach.svg",
//                 color: theme.icon,
//                 height: 22,
//                 width: 25,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//
//           const Spacer(),
//
//           // Mic button with padding below icon
//           MaterialButton(
//             onPressed: () {
//               HapticFeedback.heavyImpact();
//               onStartRecording();
//             },
//             minWidth: 0,
//             height: 40,
//             padding: EdgeInsets.zero, // Remove the previous padding
//             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 4.0), // Add padding below icon
//               child: SvgPicture.asset(
//                 "assets/images/mic.svg",
//                 height: 22,
//                 width: 25,
//                 color: theme.icon,
//               ),
//             ),
//           ),
//
//           const SizedBox(width: 14),
//
//           // Send/stop button
//           SizedBox(
//             height: 36,
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 140),
//               switchInCurve: Curves.easeOut,
//               switchOutCurve: Curves.easeIn,
//               layoutBuilder: (current, previous) => Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   ...previous,
//                   if (current != null) current,
//                 ],
//               ),
//               child: showSend
//                   ? KeyedSubtree(
//                 key: ValueKey<bool>(isTyping),
//                 child: _circleButton(
//                   bgColor: AppColors.primary,
//                   onTap: () {
//                     HapticFeedback.heavyImpact();
//                     isTyping ? onStopResponse() : onSendMessage();
//                   },
//                   icon: Padding(
//                     padding: const EdgeInsets.only(bottom: 2.0), // Add padding below send/stop icons
//                     child: isTyping
//                         ? const Icon(Icons.stop, color: Colors.white, size: 18)
//                         : _boldArrowIcon(),
//                   ),
//                 ),
//               )
//                   : const SizedBox.shrink(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



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
  // Layout (sizes kept as you had them)
  static const double _kHit = 44;     // square tap target
  static const double _kCircle = 36;  // inner send/stop circle
  static const double _kGap = 6;      // mic↔send gap (tight)
  static const double _kIconH = 22;   // attach/mic svg height
  static const double _kIconW = 25;   // attach/mic svg width
  static const double _kArrow = 20;   // send arrow size
  static const double _kAttachNudge = -6; // shift attach slightly left

  // Optimistic STOP latch: appears instantly on Send, stays until finish/stop.
  bool _showStopLatch = false;
  Timer? _latchTimer;
  Timer? _finishDebounce;

  @override
  void didUpdateWidget(covariant InputActionsBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // While streaming, KEEP stop visible (don’t clear the latch).
    if (widget.isTyping) {
      _latchTimer?.cancel();
      _latchTimer = null;
    }

    // When streaming ends, clear latch after a tiny debounce.
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

  // --- actions ---
  void _onTapSend() {
    HapticFeedback.mediumImpact();

    // Show STOP immediately and keep it until the model finishes or user taps stop.
    setState(() => _showStopLatch = true);

    // Fallback in case backend is slow to flip isTyping.
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

  // --- UI helpers ---
  Widget _squareButton({
    required Widget child,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
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
          child: Center(child: child),
        ),
      ),
    );
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

  // Thick (stacked) arrow like your original
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

    // EXACT logic you want:
    //   - Stop is visible the whole time while streaming (isTyping == true)
    //   - Plus it appears instantly on Send (via latch)
    final bool showStop = widget.isTyping || _showStopLatch;

    // Collapse the trailing space ONLY when there is truly nothing to show.
    final bool showSendSlot = showStop || widget.hasText || widget.isTranscribing;

    return RepaintBoundary(
      child: SizedBox(
        height: _kHit,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ATTACH — slight left nudge
            Transform.translate(
              offset: const Offset(_kAttachNudge, 0),
              child: _squareButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // attach flow
                },
                child: SvgPicture.asset(
                  "assets/images/attach.svg",
                  color: theme.icon,
                  height: _kIconH,
                  width: _kIconW,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Spacer(),

            // MIC
            _squareButton(
              onTap: widget.onStartRecording,
              child: SvgPicture.asset(
                "assets/images/mic.svg",
                height: _kIconH,
                width: _kIconW,
                color: theme.icon,
              ),
            ),

            // Gap + Send/Stop slot — collapses to 0 when hidden
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeInOut,
              width: showSendSlot ? (_kGap + _kHit) : 0,
              height: _kHit,
              alignment: Alignment.centerRight,
              child: showSendSlot
                  ? AnimatedSwitcher(
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
                // Key by "stop vs send" so icon swaps smoothly without killing the slot
                child: showStop
                    ? KeyedSubtree(
                  key: const ValueKey('stop'),
                  child: _circleButton(
                    bgColor: AppColors.primary,
                    onTap: _onTapStop,
                    icon: const Icon(Icons.stop, color: Colors.white, size: 18),
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
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


