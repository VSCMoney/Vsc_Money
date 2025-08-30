import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import 'bot_message.dart';
import 'message_bubble.dart';


class MessageRowWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isLatest;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final VoidCallback? onHeightMeasured;
  final Function(double)? onHeightMeasuredWithValue;
  final VoidCallback? onBotRenderComplete;
  final Function(String)? onRetryMessage; // NEW: Retry callback

  const MessageRowWidget({
    Key? key,
    required this.message,
    this.isLatest = false,
    this.onAskVitty,
    this.onStockTap,
    this.onHeightMeasured,
    this.onHeightMeasuredWithValue,
    this.onBotRenderComplete,
    this.onRetryMessage, // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['role'] == 'user';

    final String messageText = (message['content']?.toString() ??
        message['msg']?.toString() ?? '');

    final bool isComplete = message['isComplete'] == true;
    final bool isHistorical = message['isHistorical'] == true;
    final String? currentStatus = message['currentStatus'] as String?;
    final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
    final bool? forceStop = message['forceStop'] as bool?;
    final String? stopTs = message['stopTs'] as String?;

    // Check if this is a retry message
    final bool shouldShowRetry = message['retry'] == true;
    final String originalMessage = message['originalMessage']?.toString() ?? '';

    // Check if this is in connecting state
    final bool isConnecting = message['isConnecting'] == true;

    // USER BUBBLE
    if (isUser) {
      return MessageBubble(
        message: messageText,
        isUser: true,
        bubbleKey: bubbleKey,
        isLatest: isLatest,
        onHeightMeasured: onHeightMeasured,
        onHeightMeasuredWithValue: onHeightMeasuredWithValue,
      );
    }

    // STOCKS HANDLING (separate widget)
    if (message['type'] == 'stocks' && message['stocks'] is List) {
      final List<dynamic> stocks = message['stocks'] as List<dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: StockTileWidget(
          stocks: stocks,
          onStockTap: onStockTap,
        ),
      );
    }

    final String? messageType = message['type'] as String?;
    final Map<String, dynamic>? tableData =
    (message['tableData'] is Map) ? (message['tableData'] as Map).cast<String, dynamic>() : null;

    final bool shouldShowTypingDots =
    (messageText.isEmpty && currentStatus == null && !isComplete && tableData == null && !shouldShowRetry);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shouldShowTypingDots
              ? const TypingIndicatorWidget()
              : BotMessageWidget(
            message: messageText,
            isComplete: isComplete,
            isLatest: isLatest,
            isHistorical: isHistorical,
            currentStatus: currentStatus,
            onAskVitty: onAskVitty,
            tableData: tableData,
            onRenderComplete: onBotRenderComplete,
            forceStop: forceStop,
            stopTs: stopTs,
            onStockTap: onStockTap,
          ),

          // Show retry button if needed, but not while connecting
          if (shouldShowRetry && originalMessage.isNotEmpty && !isConnecting)
            _buildRetrySection(context, originalMessage),
        ],
      ),
    );
  }

  // NEW: Build retry section
  Widget _buildRetrySection(BuildContext context, String originalMessage) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              onRetryMessage?.call(originalMessage);
            },
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

// class MessageRowWidget extends StatelessWidget {
//   final Map<String, dynamic> message;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//   final Function(String)? onStockTap;
//   final VoidCallback? onHeightMeasured; // ✅ Keep your existing signature
//   final Function(double)? onHeightMeasuredWithValue; // ✅ NEW: For actual height value
//   final VoidCallback? onBotRenderComplete;
//
//   const MessageRowWidget({
//     Key? key,
//     required this.message,
//     this.isLatest = false,
//     this.onAskVitty,
//     this.onStockTap,
//     this.onHeightMeasured,
//     this.onHeightMeasuredWithValue, // ✅ NEW: Optional height callback
//     this.onBotRenderComplete
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isUser = message['role'] == 'user';
//
//     final String messageText = (message['content']?.toString() ??
//         message['msg']?.toString() ?? '');
//
//     final bool isComplete = message['isComplete'] == true;
//     final bool isHistorical = message['isHistorical'] == true;
//     final String? currentStatus = message['currentStatus'] as String?;
//     final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
//     final bool? forceStop = message['forceStop'] as bool?;
//     final String? stopTs = message['stopTs'] as String?;
//
//     // USER BUBBLE
//     if (isUser) {
//       return MessageBubble(
//         message: messageText,
//         isUser: true,
//         bubbleKey: bubbleKey,
//         isLatest: isLatest,
//         onHeightMeasured: onHeightMeasured, // ✅ Your existing callback
//         onHeightMeasuredWithValue: onHeightMeasuredWithValue, // ✅ NEW: Height value callback
//       );
//     }
//
//     // STOCKS HANDLING (separate widget)
//     if (message['type'] == 'stocks' && message['stocks'] is List) {
//       final List<dynamic> stocks = message['stocks'] as List<dynamic>;
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: StockTileWidget(
//           stocks: stocks,
//           onStockTap: onStockTap,
//         ),
//       );
//     }
//
//     final String? messageType = message['type'] as String?;
//     final Map<String, dynamic>? tableData =
//     (message['tableData'] is Map) ? (message['tableData'] as Map).cast<String, dynamic>() : null;
//
//     final bool shouldShowTypingDots =
//     (messageText.isEmpty && currentStatus == null && !isComplete && tableData == null);
//
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: shouldShowTypingDots
//           ? const TypingIndicatorWidget()
//           : BotMessageWidget(
//         message: messageText,
//         isComplete: isComplete,
//         isLatest: isLatest,
//         isHistorical: isHistorical,
//         currentStatus: currentStatus,
//         onAskVitty: onAskVitty,
//         tableData: tableData,
//         onRenderComplete: onBotRenderComplete,
//         forceStop: forceStop,
//         stopTs: stopTs,
//         onStockTap: onStockTap,
//       ),
//     );
//   }
// }




