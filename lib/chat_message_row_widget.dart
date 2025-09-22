import 'package:flutter/material.dart';
import 'package:vscmoney/screens/widgets/message_row_widget.dart';
import 'package:vscmoney/services/chat_service.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/user_message_widget.dart';

import 'bot_response_widget.dart';




class ChatMessageRowWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final int messageIndex;

  const ChatMessageRowWidget({
    Key? key,
    required this.message,
    required this.messageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final role = message['role'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: role == 'user'
          ? UserMessageWidget(message: message, messageIndex: messageIndex)
          : BotMessageWidget(message: message),
    );
  }
}

