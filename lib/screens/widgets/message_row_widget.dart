import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import 'bot_message.dart';
import 'message_bubble.dart';


import 'package:flutter/material.dart';


class MessageRowWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final int index;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final Function(String)? onRetryMessage;

  const MessageRowWidget({
    Key? key,
    required this.message,
    required this.index,
    this.onAskVitty,
    this.onStockTap,
    this.onRetryMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['role'] == 'user';
    final String messageText = message['content']?.toString() ?? message['msg']?.toString() ?? '';

    final String rowId = message['id']?.toString() ??
        message['messageId']?.toString() ??
        message['ts']?.toString() ??
        'msg_$index';

    // USER BUBBLE - keeping existing MessageBubble
    if (isUser) {
      return KeyedSubtree(
        key: ValueKey('row_$rowId'),
        child: MessageBubble(
          message: messageText,
          isUser: true,
        ),
      );
    }

    // STOCKS - keeping existing StockTileWidget
    if (message['type'] == 'stocks' && message['stocks'] is List) {
      final List<dynamic> stocks = message['stocks'] as List<dynamic>;
      return KeyedSubtree(
        key: ValueKey('row_$rowId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: StockTileWidget(
            stocks: stocks,
            onStockTap: onStockTap,
          ),
        ),
      );
    }

    // Check if should show typing indicator
    final bool isComplete = message['isComplete'] == true || message['backendComplete'] == true;
    final bool shouldShowTyping = messageText.isEmpty && !isComplete && message['isTyping'] != false;

    // BOT MESSAGE - with typing and status support
    return KeyedSubtree(
      key: ValueKey('row_$rowId'),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shouldShowTyping)
              const TypingIndicatorWidget()
            else
              BotMessageWidget(
                key: ValueKey('bot_$rowId'),
                message: messageText,
                tableData: message['tableData'],
                currentStatus: message['currentStatus']?.toString(),
                isComplete: isComplete,
                onAskVitty: onAskVitty,
                onStockTap: onStockTap,
              ),

            // Retry section if needed
            if (message['retry'] == true && message['originalMessage'] != null)
              _buildRetrySection(context, message['originalMessage'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrySection(BuildContext context, String originalMessage) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => onRetryMessage?.call(originalMessage),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blue.shade200),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection failed',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Check your internet connection',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// // message_row_widget.dart
// class MessageRowWidget extends StatefulWidget {
//   final Map<String, dynamic> message;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//   final Function(String)? onStockTap;
//   final VoidCallback? onHeightMeasured;
//   final Function(double)? onHeightMeasuredWithValue;
//   final VoidCallback? onBotRenderComplete;
//   final Function(String)? onRetryMessage;
//
//   const MessageRowWidget({
//     Key? key,
//     required this.message,
//     this.isLatest = false,
//     this.onAskVitty,
//     this.onStockTap,
//     this.onHeightMeasured,
//     this.onHeightMeasuredWithValue,
//     this.onBotRenderComplete,
//     this.onRetryMessage,
//   }) : super(key: key);
//
//   @override
//   State<MessageRowWidget> createState() => _MessageRowWidgetState();
// }
//
// class _MessageRowWidgetState extends State<MessageRowWidget> {
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isUser = widget.message['role'] == 'user';
//     final String messageText =
//     (widget.message['content']?.toString() ?? widget.message['msg']?.toString() ?? '');
//
//     // Conservative completion rules (unchanged)
//     final bool backendComplete = widget.message['backendComplete'] == true;
//     final bool userComplete    = widget.message['isComplete'] == true;
//     final bool forceStop       = widget.message['forceStop'] == true;
//     final bool isComplete      = forceStop || (!widget.isLatest && (backendComplete || userComplete));
//
//     final bool isHistorical = widget.message['isHistorical'] == true;
//
//     String? currentStatus = widget.message['currentStatus']?.toString();
//     if (currentStatus == 'null' || currentStatus == 'undefined' || currentStatus?.isEmpty == true) {
//       currentStatus = null;
//     }
//
//     final GlobalKey? bubbleKey = widget.message['key'] as GlobalKey?;
//     final String? stopTs       = widget.message['stopTs'] as String?;
//     final bool shouldShowRetry = widget.message['retry'] == true;
//     final String originalMessage = widget.message['originalMessage']?.toString() ?? '';
//     final bool isConnecting = widget.message['isConnecting'] == true;
//
//     final String rowId =
//         widget.message['id']?.toString() ??
//             widget.message['messageId']?.toString() ??
//             widget.message['ts']?.toString() ??
//             'h${(widget.message['content'] ?? widget.message['msg'] ?? '').hashCode}';
//
//     // USER BUBBLE
//     if (isUser) {
//       return KeyedSubtree(
//         key: ValueKey('row_$rowId'),
//         child: MessageBubble(
//           message: messageText,
//           isUser: true,
//           bubbleKey: bubbleKey,
//           isLatest: widget.isLatest,
//           onHeightMeasured: widget.onHeightMeasured,
//           onHeightMeasuredWithValue: widget.onHeightMeasuredWithValue, // <- passes height up
//         ),
//       );
//     }
//
//
//
//     final Map<String, dynamic>? tableData =
//     (widget.message['tableData'] is Map) ? (widget.message['tableData'] as Map).cast<String, dynamic>() : null;
//
//     final bool shouldShowTypingDots = messageText.isEmpty &&
//         currentStatus == null &&
//         !isComplete &&
//         tableData == null &&
//         !shouldShowRetry &&
//         !isHistorical;
//
//     return KeyedSubtree(
//       key: ValueKey('row_$rowId'),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             shouldShowTypingDots
//                  ? _TypingIndicatorWithHaptics()
//         //   ?                  // Image.asset('assets/images/orb.gif',height: 50,width: 50,)
//         // Lottie.asset(
//         // 'assets/images/orb2.json',
//         //     height: 50,width: 50
//         // )
//
//           :
//             BotMessageWidget(
//               key: ValueKey('bot_$rowId'),
//               message: messageText,
//               // isComplete: isComplete,
//               // isLatest: widget.isLatest,
//               // isHistorical: isHistorical,
//               // currentStatus: currentStatus,
//               onAskVitty: widget.onAskVitty,
//               tableData: tableData,
//               onRenderComplete: widget.onBotRenderComplete,
//               forceStop: forceStop,
//               stopTs: stopTs,
//               onStockTap: widget.onStockTap,
//             ),
//             //: Image.asset('assets/images/orb.gif',height: 60,width: 60,),
//             if (shouldShowRetry && originalMessage.isNotEmpty && !isConnecting)
//               _buildRetrySection(context, originalMessage),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRetrySection(BuildContext context, String originalMessage) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
//       child: Row(
//         children: [
//           ElevatedButton.icon(
//             onPressed: () => widget.onRetryMessage?.call(originalMessage),
//             icon: const Icon(Icons.refresh, size: 16),
//             label: const Text('Try Again'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade50,
//               foregroundColor: Colors.blue.shade700,
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//                 side: BorderSide(color: Colors.blue.shade200),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Connection failed',
//                   style: TextStyle(
//                     color: Colors.red.shade600,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Check your internet connection',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class TypingIndicatorWithHaptics extends StatefulWidget {
  const TypingIndicatorWithHaptics({Key? key}) : super(key: key);

  @override
  State<TypingIndicatorWithHaptics> createState() => TypingIndicatorWithHapticsState();
}

class TypingIndicatorWithHapticsState extends State<TypingIndicatorWithHaptics> {
  @override
  void initState() {
    super.initState();
    // Loader just started for this bot message
    HapticFeedback.mediumImpact(); // subtle
  }

  @override
  Widget build(BuildContext context) => const TypingIndicatorWidget();
}









