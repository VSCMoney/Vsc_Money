import 'package:flutter/material.dart';

class UserMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final int messageIndex;

  const UserMessageWidget({
    Key? key,
    required this.message,
    required this.messageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String? ?? '';
    final calculatedHeight = message['calculatedHeight'] as double?;

    // Debug: Print calculated vs actual height
    if (calculatedHeight != null) {
      print("📏 Message $messageIndex - Calculated height: $calculatedHeight");
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}