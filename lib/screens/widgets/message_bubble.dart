// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../../services/theme_service.dart';
//
// class MessageBubble extends StatelessWidget {
//   final String message;
//   final bool isUser;
//   final GlobalKey? bubbleKey;
//   final bool isLatest;
//   final VoidCallback? onHeightMeasured;
//
//   const MessageBubble({
//     Key? key,
//     required this.message,
//     required this.isUser,
//     this.bubbleKey,
//     this.isLatest = false,
//     this.onHeightMeasured,
//   }) : super(key: key);
//
//   void _measureBubbleHeight() {
//     if (isLatest && bubbleKey != null && onHeightMeasured != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final context = bubbleKey!.currentContext;
//         if (context != null) {
//           final RenderBox? box = context.findRenderObject() as RenderBox?;
//           if (box != null && box.hasSize) {
//             onHeightMeasured!();
//           }
//         }
//       });
//     }
//   }
//
//   void _copyToClipboard(BuildContext context) {
//     Clipboard.setData(ClipboardData(text: message));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Copied to clipboard')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//
//     // Trigger height measurement
//     _measureBubbleHeight();
//
//     if (isUser) {
//       return Transform.translate(
//         offset: const Offset(0, 10),
//         child: Padding(
//           padding: const EdgeInsets.only(top: 0, bottom: 0),
//           child: Align(
//             alignment: Alignment.centerRight,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 const SizedBox(width: 14),
//                 GestureDetector(
//                   onTap: () => _copyToClipboard(context),
//                   child: const Icon(
//                     Icons.copy,
//                     size: 14,
//                     color: Color(0XFF7E7E7E),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.6,
//                   ),
//                   child: Container(
//                     key: bubbleKey,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     margin: const EdgeInsets.only(bottom: 2),
//                     decoration: BoxDecoration(
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 10,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                       color: theme.message,
//                       borderRadius: BorderRadius.circular(22),
//                     ),
//                     child: Text(
//                       message,
//                       style: TextStyle(
//                         height: 1.9,
//                         fontFamily: 'DM Sans',
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: theme.text,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     // For bot messages, return basic container (will be handled by BotMessageWidget)
//     return const SizedBox.shrink();
//   }
// }


import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../services/theme_service.dart';


// measure_size.dart
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

// measure_size.dart
import 'package:flutter/widgets.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  /// Chhote-chhote layout jitters ignore karne ke liye
  /// (px me). Default 0.5 px.
  final double minDelta;

  /// Kitne post-frame “stable frames” wait karein before notify.
  /// Default 1 (turant). 2-3 rakhoge to flicker aur kam hoga.
  final int stableFrames;

  /// True = child.size measure karo (jaise Container),
  /// False = khud widget ka size (this.size).
  final bool useChildSize;

  const MeasureSize({
    Key? key,
    required this.onChange,
    required Widget child,
    this.minDelta = 0.5,
    this.stableFrames = 1,
    this.useChildSize = true,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(
        onChange: onChange,
        minDelta: minDelta,
        stableFrames: stableFrames,
        useChildSize: useChildSize,
      );

  @override
  void updateRenderObject(
      BuildContext context,
      covariant _RenderMeasureSize renderObject,
      ) {
    renderObject
      ..onChange = onChange
      ..minDelta = minDelta
      ..stableFrames = stableFrames
      ..useChildSize = useChildSize;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize({
    required this.onChange,
    required this.minDelta,
    required this.stableFrames,
    required this.useChildSize,
  });

  OnWidgetSizeChange onChange;
  double minDelta;
  int stableFrames;
  bool useChildSize;

  Size? _lastReportedSize;
  Size? _pendingSize;
  bool _callbackScheduled = false;

  bool _areClose(Size a, Size b, double eps) {
    return (a.width - b.width).abs() < eps &&
        (a.height - b.height).abs() < eps;
  }

  @override
  void performLayout() {
    super.performLayout();

    // Child ka size chahiye to child?.size; warna apna hi size
    final currentSize = useChildSize ? (child?.size ?? Size.zero) : size;

    // Agar first time report kar rahe ya noticeable change hai
    if (_lastReportedSize == null ||
        !_areClose(currentSize, _lastReportedSize!, minDelta)) {
      _pendingSize = currentSize;
      _scheduleCallbackIfNeeded();
    }
  }

  void _scheduleCallbackIfNeeded() {
    if (_callbackScheduled) return;
    _callbackScheduled = true;

    // Post-frame notify; agar stableFrames > 1 hai to kuch extra frames wait
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (stableFrames <= 1) {
        _fire();
        return;
      }

      int remaining = stableFrames - 1;
      void waitMore() {
        if (remaining == 0) {
          _fire();
          return;
        }
        remaining--;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          waitMore();
        });
      }

      waitMore();
    });
  }

  void _fire() {
    _callbackScheduled = false;
    final toReport = _pendingSize;
    if (toReport == null) return;

    // Final guard: agar lastReported ke bahut close hai to skip
    if (_lastReportedSize != null &&
        _areClose(toReport, _lastReportedSize!, minDelta)) {
      return;
    }

    _lastReportedSize = toReport;
    onChange(toReport);
  }
}




// message_bubble.dart
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final GlobalKey? bubbleKey; // kept for compatibility
  final bool isLatest;
  final VoidCallback? onHeightMeasured;
  final Function(double)? onHeightMeasuredWithValue;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.bubbleKey,
    this.isLatest = false,
    this.onHeightMeasured,
    this.onHeightMeasuredWithValue,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    if (isUser) {
      return Transform.translate(
        offset: const Offset(0, 10),
        child: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: const Icon(
                    Icons.copy,
                    size: 14,
                    color: Color(0XFF7E7E7E),
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Container(
                    key: bubbleKey, // optional, safe to keep
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: theme.message,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        height: 1.9,
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.text,
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

    // Bot bubble is rendered elsewhere
    return const SizedBox.shrink();
  }
}


// class MessageBubble extends StatelessWidget {
//   final String message;
//   final bool isUser;
//   final GlobalKey? bubbleKey;
//   final bool isLatest;
//   final VoidCallback? onHeightMeasured; // Keep your existing signature
//
//   // ✅ NEW: Add callback that actually passes height
//   final Function(double)? onHeightMeasuredWithValue;
//
//   const MessageBubble({
//     Key? key,
//     required this.message,
//     required this.isUser,
//     this.bubbleKey,
//     this.isLatest = false,
//     this.onHeightMeasured,
//     this.onHeightMeasuredWithValue, // ✅ NEW: Optional height callback
//   }) : super(key: key);
//
//   void _measureBubbleHeight() {
//     if (bubbleKey != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final context = bubbleKey!.currentContext;
//         if (context != null) {
//           final RenderBox? box = context.findRenderObject() as RenderBox?;
//           if (box != null && box.hasSize) {
//             final height = box.size.height;
//
//             // ✅ FIXED: Call both callbacks
//             onHeightMeasured?.call(); // Your existing callback
//             onHeightMeasuredWithValue?.call(height); // New callback with height value
//
//             print("📏 MessageBubble measured height: $height for message: '${message.substring(0, math.min(30, message.length))}...'");
//           }
//         }
//       });
//     }
//   }
//
//   void _copyToClipboard(BuildContext context) {
//     Clipboard.setData(ClipboardData(text: message));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Copied to clipboard')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//
//     // ✅ IMPROVED: Always measure height for user messages (not just latest)
//     if (isUser) {
//       _measureBubbleHeight();
//     }
//
//     if (isUser) {
//       return Transform.translate(
//         offset: const Offset(0, 10),
//         child: Padding(
//           padding: const EdgeInsets.only(top: 0, bottom: 0),
//           child: Align(
//             alignment: Alignment.centerRight,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 const SizedBox(width: 14),
//                 GestureDetector(
//                   onTap: () => _copyToClipboard(context),
//                   child: const Icon(
//                     Icons.copy,
//                     size: 14,
//                     color: Color(0XFF7E7E7E),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.6,
//                   ),
//                   child: Container(
//                     key: bubbleKey, // ✅ This key is essential for measurement
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     margin: const EdgeInsets.only(bottom: 2),
//                     decoration: BoxDecoration(
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 10,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                       color: theme.message,
//                       borderRadius: BorderRadius.circular(22),
//                     ),
//                     child: Text(
//                       message,
//                       style: TextStyle(
//                         height: 1.9,
//                         fontFamily: 'DM Sans',
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: theme.text,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     // For bot messages, return basic container (will be handled by BotMessageWidget)
//     return const SizedBox.shrink();
//   }
// }