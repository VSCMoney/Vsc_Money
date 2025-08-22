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
import 'package:flutter/services.dart';

import '../../services/theme_service.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final GlobalKey? bubbleKey;
  final bool isLatest;
  final VoidCallback? onHeightMeasured; // Keep your existing signature

  // ✅ NEW: Add callback that actually passes height
  final Function(double)? onHeightMeasuredWithValue;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.bubbleKey,
    this.isLatest = false,
    this.onHeightMeasured,
    this.onHeightMeasuredWithValue, // ✅ NEW: Optional height callback
  }) : super(key: key);

  void _measureBubbleHeight() {
    if (bubbleKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = bubbleKey!.currentContext;
        if (context != null) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final height = box.size.height;

            // ✅ FIXED: Call both callbacks
            onHeightMeasured?.call(); // Your existing callback
            onHeightMeasuredWithValue?.call(height); // New callback with height value

            print("📏 MessageBubble measured height: $height for message: '${message.substring(0, math.min(30, message.length))}...'");
          }
        }
      });
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    // ✅ IMPROVED: Always measure height for user messages (not just latest)
    if (isUser) {
      _measureBubbleHeight();
    }

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
                    key: bubbleKey, // ✅ This key is essential for measurement
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

    // For bot messages, return basic container (will be handled by BotMessageWidget)
    return const SizedBox.shrink();
  }
}