import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import 'bot_message.dart';
import 'message_bubble.dart';


// Replace your existing MessageRowWidget class with this:


class MessageRowWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isLatest;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final VoidCallback? onHeightMeasured; // ✅ Keep your existing signature
  final Function(double)? onHeightMeasuredWithValue; // ✅ NEW: For actual height value
  final VoidCallback? onBotRenderComplete;

  const MessageRowWidget({
    Key? key,
    required this.message,
    this.isLatest = false,
    this.onAskVitty,
    this.onStockTap,
    this.onHeightMeasured,
    this.onHeightMeasuredWithValue, // ✅ NEW: Optional height callback
    this.onBotRenderComplete
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

    // USER BUBBLE
    if (isUser) {
      return MessageBubble(
        message: messageText,
        isUser: true,
        bubbleKey: bubbleKey,
        isLatest: isLatest,
        onHeightMeasured: onHeightMeasured, // ✅ Your existing callback
        onHeightMeasuredWithValue: onHeightMeasuredWithValue, // ✅ NEW: Height value callback
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
    (messageText.isEmpty && currentStatus == null && !isComplete && tableData == null);

    return Align(
      alignment: Alignment.centerLeft,
      child: shouldShowTypingDots
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
    );
  }
}

// class MessageRowWidget extends StatelessWidget {
//   final Map<String, dynamic> message;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//   final Function(String)? onStockTap;
//   final VoidCallback? onHeightMeasured;
//   final VoidCallback? onBotRenderComplete;
//
//   const MessageRowWidget({
//     Key? key,
//     required this.message,
//     this.isLatest = false,
//     this.onAskVitty,
//     this.onStockTap,
//     this.onHeightMeasured,
//     this.onBotRenderComplete
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isUser = message['role'] == 'user';
//
//     // ✅ CHANGE 1: Look for 'content' first, then 'msg'
//     final String messageText = (message['content']?.toString() ??
//         message['msg']?.toString() ?? '');
//
//     final bool isComplete = message['isComplete'] == true;
//
//     // ✅ CHANGE 2: Get the isHistorical flag
//     final bool isHistorical = message['isHistorical'] == true;
//
//     final String? currentStatus = message['currentStatus'] as String?;
//     final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
//     final bool? forceStop = message['forceStop'] as bool?;
//     final String? stopTs = message['stopTs'] as String?;
//
//     //print('🔍 MessageRowWidget: role=${message['role']}, isHistorical=$isHistorical, content="${messageText.substring(0, math.min(50, messageText.length))}..."');
//
//     // USER BUBBLE
//     if (isUser) {
//       return MessageBubble(
//         message: messageText,
//         isUser: true,
//         bubbleKey: bubbleKey,
//         isLatest: isLatest,
//         onHeightMeasured: onHeightMeasured,
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
//         isHistorical: isHistorical,  // ✅ CHANGE 3: Pass isHistorical flag
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

// class MessageRowWidget extends StatelessWidget {
//   final Map<String, dynamic> message;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//   final Function(String)? onStockTap;
//   final VoidCallback? onHeightMeasured;
//   final VoidCallback? onBotRenderComplete;
//
//   const MessageRowWidget({
//     Key? key,
//     required this.message,
//     this.isLatest = false,
//     this.onAskVitty,
//     this.onStockTap,
//     this.onHeightMeasured,
//     this.onBotRenderComplete
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isUser = message['role'] == 'user';
//
//     // ✅ FIX: Look for 'content' first, then fallback to 'msg'
//     final String messageText = (message['content']?.toString() ??
//         message['msg']?.toString() ?? '');
//
//     final bool isComplete = message['isComplete'] == true;
//     final String? currentStatus = message['currentStatus'] as String?;
//     final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
//     final bool? forceStop = message['forceStop'] as bool?;
//     final String? stopTs = message['stopTs'] as String?;
//
//     print('🔍 MessageRowWidget: role=${message['role']}, content="${messageText.substring(0, math.min(50, messageText.length))}..."');
//
//     // USER BUBBLE
//     if (isUser) {
//       return MessageBubble(
//         message: messageText,
//         isUser: true,
//         bubbleKey: bubbleKey,
//         isLatest: isLatest,
//         onHeightMeasured: onHeightMeasured,
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


