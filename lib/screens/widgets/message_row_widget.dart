import 'package:flutter/material.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../models/chat_message.dart';
import 'bot_message.dart';
import 'message_bubble.dart';

// class MessageRowWidget extends StatelessWidget {
//   final Map<String, Object> message;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//   final Function(String)? onStockTap;
//   final VoidCallback? onHeightMeasured;
//
//   const MessageRowWidget({
//     Key? key,
//     required this.message,
//     this.isLatest = false,
//     this.onAskVitty,
//     this.onStockTap,
//     this.onHeightMeasured,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isUser = message['role'] == 'user';
//     final String messageText = message['msg']?.toString() ?? '';
//     final bool isComplete = message['isComplete'] == true;
//     final GlobalKey? bubbleKey = message['key'] as GlobalKey?;
//
//     // Handle different message types
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
//     // Handle stock messages
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
//     // Handle bot messages
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           messageText.isEmpty
//               ? const TypingIndicatorWidget()
//               : BotMessageWidget(
//             message: messageText,
//             // isComplete: isComplete,
//             // isLatest: isLatest,
//             onAskVitty: onAskVitty,
//           ),
//         ],
//       ),
//     );
//   }
//}



class MessageRowWidget extends StatelessWidget {
  final Map<String, Object> message;
  final bool isLatest;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final VoidCallback? onHeightMeasured;

  const MessageRowWidget({
    Key? key,
    required this.message,
    this.isLatest = false,
    this.onAskVitty,
    this.onStockTap,
    this.onHeightMeasured,
  }) : super(key: key);

  // Helper method to convert Map message to ChatMessage object
  ChatMessage _mapToChatMessage(Map<String, Object> messageMap) {
    print("🔍 UI DEBUG: Converting message map to ChatMessage");

    // Convert statusUpdates from Map format back to StatusUpdate objects
    final statusUpdatesData = messageMap['statusUpdates'] as List<dynamic>? ?? [];
    final payloadsData = messageMap['payloads'] as List<dynamic>? ?? [];

    print("🔍 UI DEBUG: StatusUpdates count: ${statusUpdatesData.length}");
    print("🔍 UI DEBUG: Payloads count: ${payloadsData.length}");

    final statusUpdates = statusUpdatesData
        .cast<Map<String, dynamic>>()
        .map((statusMap) => StatusUpdate(
      id: statusMap['id'] ?? '',
      type: StatusType.values.firstWhere(
            (e) => e.toString().split('.').last == statusMap['type'],
        orElse: () => StatusType.processing,
      ),
      message: statusMap['message'] ?? '',
      timestamp: statusMap['timestamp'] != null
          ? DateTime.parse(statusMap['timestamp'])
          : DateTime.now(),
      isComplete: statusMap['isComplete'] ?? false,
    ))
        .toList();

    final payloads = payloadsData
        .cast<Map<String, dynamic>>()
        .map((payloadMap) => ResponsePayload(
      id: payloadMap['id'] ?? '',
      type: PayloadType.values.firstWhere(
            (e) => e.toString().split('.').last == payloadMap['type'],
        orElse: () => PayloadType.text,
      ),
      data: payloadMap['data'],
      title: payloadMap['title'],
      description: payloadMap['description'],
    ))
        .toList();

    return ChatMessage(
      id: messageMap['id']?.toString() ?? '',
      text: messageMap['msg']?.toString() ?? '',
      isUser: messageMap['role'] == 'user',
      timestamp: DateTime.now(),
      isComplete: messageMap['isComplete'] == true,
      statusUpdates: statusUpdates,
      payloads: payloads,
    );
  }

  // NEW: Helper method to check if message has enhanced content
  bool _hasEnhancedContent(Map<String, Object> messageMap) {
    final statusUpdates = messageMap['statusUpdates'] as List<dynamic>? ?? [];
    final payloads = messageMap['payloads'] as List<dynamic>? ?? [];
    return statusUpdates.isNotEmpty || payloads.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['role'] == 'user';
    final String messageText = message['msg']?.toString() ?? '';
    final bool isComplete = message['isComplete'] == true;
    final GlobalKey? bubbleKey = message['key'] as GlobalKey?;

    print("🔍 UI DEBUG: Building MessageRowWidget - isUser: $isUser, messageText: '$messageText', isComplete: $isComplete");

    // Handle different message types
    if (isUser) {
      print("🔍 UI DEBUG: Rendering user message");
      return MessageBubble(
        message: messageText,
        isUser: true,
        bubbleKey: bubbleKey,
        isLatest: isLatest,
        onHeightMeasured: onHeightMeasured,
      );
    }

    // Handle stock messages
    if (message['type'] == 'stocks' && message['stocks'] is List) {
      print("🔍 UI DEBUG: Rendering stock message");
      final List<dynamic> stocks = message['stocks'] as List<dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: StockTileWidget(
          stocks: stocks,
          onStockTap: onStockTap,
        ),
      );
    }

    // Handle bot messages
    print("🔍 UI DEBUG: Rendering bot message");

    // FIXED LOGIC: Check for enhanced content OR text content
    final hasEnhancedContent = _hasEnhancedContent(message);
    final hasTextContent = messageText.isNotEmpty;

    print("🔍 UI DEBUG: hasEnhancedContent: $hasEnhancedContent, hasTextContent: $hasTextContent");

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show typing indicator ONLY if no content at all AND not complete
          if (!hasEnhancedContent && !hasTextContent && !isComplete) ...[
            const TypingIndicatorWidget(),
          ]
          // Show BotMessageWidget if we have any content OR if complete
          else ...[
            BotMessageWidget(
              message: _mapToChatMessage(message),
              onAskVitty: onAskVitty,
              onStockTap: onStockTap,
            ),
          ],
        ],
      ),
    );
  }
}