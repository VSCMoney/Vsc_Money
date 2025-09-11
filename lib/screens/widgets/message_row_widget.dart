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


// message_row_widget.dart
class MessageRowWidget extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isLatest;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final VoidCallback? onHeightMeasured;
  final Function(double)? onHeightMeasuredWithValue;
  final VoidCallback? onBotRenderComplete;
  final Function(String)? onRetryMessage;

  const MessageRowWidget({
    Key? key,
    required this.message,
    this.isLatest = false,
    this.onAskVitty,
    this.onStockTap,
    this.onHeightMeasured,
    this.onHeightMeasuredWithValue,
    this.onBotRenderComplete,
    this.onRetryMessage,
  }) : super(key: key);

  @override
  State<MessageRowWidget> createState() => _MessageRowWidgetState();
}

class _MessageRowWidgetState extends State<MessageRowWidget> {




  @override
  Widget build(BuildContext context) {
    final bool isUser = widget.message['role'] == 'user';
    final String messageText =
    (widget.message['content']?.toString() ?? widget.message['msg']?.toString() ?? '');

    // Conservative completion rules (unchanged)
    final bool backendComplete = widget.message['backendComplete'] == true;
    final bool userComplete    = widget.message['isComplete'] == true;
    final bool forceStop       = widget.message['forceStop'] == true;
    final bool isComplete      = forceStop || (!widget.isLatest && (backendComplete || userComplete));

    final bool isHistorical = widget.message['isHistorical'] == true;

    String? currentStatus = widget.message['currentStatus']?.toString();
    if (currentStatus == 'null' || currentStatus == 'undefined' || currentStatus?.isEmpty == true) {
      currentStatus = null;
    }

    final GlobalKey? bubbleKey = widget.message['key'] as GlobalKey?;
    final String? stopTs       = widget.message['stopTs'] as String?;
    final bool shouldShowRetry = widget.message['retry'] == true;
    final String originalMessage = widget.message['originalMessage']?.toString() ?? '';
    final bool isConnecting = widget.message['isConnecting'] == true;

    final String rowId =
        widget.message['id']?.toString() ??
            widget.message['messageId']?.toString() ??
            widget.message['ts']?.toString() ??
            'h${(widget.message['content'] ?? widget.message['msg'] ?? '').hashCode}';

    // USER BUBBLE
    if (isUser) {
      return KeyedSubtree(
        key: ValueKey('row_$rowId'),
        child: MessageBubble(
          message: messageText,
          isUser: true,
          bubbleKey: bubbleKey,
          isLatest: widget.isLatest,
          onHeightMeasured: widget.onHeightMeasured,
          onHeightMeasuredWithValue: widget.onHeightMeasuredWithValue, // <- passes height up
        ),
      );
    }

    // STOCKS
    if (widget.message['type'] == 'stocks' && widget.message['stocks'] is List) {
      final List<dynamic> stocks = widget.message['stocks'] as List<dynamic>;
      return KeyedSubtree(
        key: ValueKey('row_$rowId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: StockTileWidget(
            stocks: stocks,
            onStockTap: widget.onStockTap,
          ),
        ),
      );
    }

    final Map<String, dynamic>? tableData =
    (widget.message['tableData'] is Map) ? (widget.message['tableData'] as Map).cast<String, dynamic>() : null;

    final bool shouldShowTypingDots = messageText.isEmpty &&
        currentStatus == null &&
        !isComplete &&
        tableData == null &&
        !shouldShowRetry &&
        !isHistorical;

    return KeyedSubtree(
      key: ValueKey('row_$rowId'),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shouldShowTypingDots
                 ? _TypingIndicatorWithHaptics()
        //   ?                  // Image.asset('assets/images/orb.gif',height: 50,width: 50,)
        // Lottie.asset(
        // 'assets/images/orb2.json',
        //     height: 50,width: 50
        // )

          : BotMessageWidget(
              key: ValueKey('bot_$rowId'),
              message: messageText,
              isComplete: isComplete,
              isLatest: widget.isLatest,
              isHistorical: isHistorical,
              currentStatus: currentStatus,
              onAskVitty: widget.onAskVitty,
              tableData: tableData,
              onRenderComplete: widget.onBotRenderComplete,
              forceStop: forceStop,
              stopTs: stopTs,
              onStockTap: widget.onStockTap,
            ),
            //: Image.asset('assets/images/orb.gif',height: 60,width: 60,),
            if (shouldShowRetry && originalMessage.isNotEmpty && !isConnecting)
              _buildRetrySection(context, originalMessage),
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
            onPressed: () => widget.onRetryMessage?.call(originalMessage),
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

class _TypingIndicatorWithHaptics extends StatefulWidget {
  const _TypingIndicatorWithHaptics({Key? key}) : super(key: key);

  @override
  State<_TypingIndicatorWithHaptics> createState() => _TypingIndicatorWithHapticsState();
}

class _TypingIndicatorWithHapticsState extends State<_TypingIndicatorWithHaptics> {
  @override
  void initState() {
    super.initState();
    // Loader just started for this bot message
    HapticFeedback.mediumImpact(); // subtle
  }

  @override
  Widget build(BuildContext context) => const TypingIndicatorWidget();
}


// class MessageRowWidget extends StatelessWidget {
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
//   Widget build(BuildContext context) {
//     final bool isUser = message['role'] == 'user';
//     final String messageText =
//     (message['content']?.toString() ?? message['msg']?.toString() ?? '');
//
//     // Conservative completion: latest message should still typewriter even if backendComplete flipped.
//     final bool backendComplete = message['backendComplete'] == true;
//     final bool userComplete    = message['isComplete'] == true;
//     final bool forceStop       = message['forceStop'] == true;
//     final bool isComplete      = forceStop || (!isLatest && (backendComplete || userComplete));
//
//     final bool isHistorical = message['isHistorical'] == true;
//
//     String? currentStatus = message['currentStatus']?.toString();
//     if (currentStatus == 'null' || currentStatus == 'undefined' || currentStatus?.isEmpty == true) {
//       currentStatus = null;
//     }
//
//     final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
//     final String? stopTs       = message['stopTs'] as String?;
//     final bool shouldShowRetry = message['retry'] == true;
//     final String originalMessage = message['originalMessage']?.toString() ?? '';
//     final bool isConnecting = message['isConnecting'] == true;
//
//     // Build a stable row id for keys (prefer real backend ids if present)
//     final String rowId =
//         message['id']?.toString() ??
//             message['messageId']?.toString() ??
//             message['ts']?.toString() ??
//             'h${(message['content'] ?? message['msg'] ?? '').hashCode}';
//
//     // USER BUBBLE
//     if (isUser) {
//       return KeyedSubtree(
//         key: ValueKey('row_$rowId'),
//         child: MessageBubble(
//           message: messageText,
//           isUser: true,
//           bubbleKey: bubbleKey,
//           isLatest: isLatest,
//           onHeightMeasured: onHeightMeasured,
//           onHeightMeasuredWithValue: onHeightMeasuredWithValue,
//         ),
//       );
//     }
//
//     // STOCKS HANDLING
//     if (message['type'] == 'stocks' && message['stocks'] is List) {
//       final List<dynamic> stocks = message['stocks'] as List<dynamic>;
//       return KeyedSubtree(
//         key: ValueKey('row_$rowId'),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: StockTileWidget(
//             stocks: stocks,
//             onStockTap: onStockTap,
//           ),
//         ),
//       );
//     }
//
//     final Map<String, dynamic>? tableData =
//     (message['tableData'] is Map) ? (message['tableData'] as Map).cast<String, dynamic>() : null;
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
//                 ? const TypingIndicatorWidget()
//                 : BotMessageWidget(
//               key: ValueKey('bot_$rowId'),
//               message: messageText,
//               isComplete: isComplete,
//               isLatest: isLatest,
//               isHistorical: isHistorical,
//               currentStatus: currentStatus,
//               onAskVitty: onAskVitty,
//               tableData: tableData,
//               onRenderComplete: onBotRenderComplete,
//               forceStop: forceStop,
//               stopTs: stopTs,
//               onStockTap: onStockTap,
//             ),
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
//             onPressed: () => onRetryMessage?.call(originalMessage),
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






