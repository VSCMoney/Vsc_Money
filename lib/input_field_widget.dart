import 'package:flutter/material.dart';
import 'package:vscmoney/services/chat_service.dart';
import 'package:vscmoney/services/locator.dart';






class InputAreaWidget extends StatefulWidget {
  final TextEditingController controller;

  final VoidCallback onSendMessage;
  final VoidCallback onStopMessage;

  const InputAreaWidget({
    Key? key,
    required this.controller,

    required this.onSendMessage,
    required this.onStopMessage,
  }) : super(key: key);

  @override
  State<InputAreaWidget> createState() => _InputAreaWidgetState();
}

class _InputAreaWidgetState extends State<InputAreaWidget> {


  final chatservice = locator<ChatService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InputTextFieldWidget(
              controller: widget.controller,
              isTyping: chatservice.isTyping,
              onSubmitted: widget.onSendMessage,
            ),
          ),
          const SizedBox(width: 8),
          SendStopButtonWidget(
            isTyping: chatservice.isTyping,
            onSendMessage: widget.onSendMessage,
            onStopMessage: widget.onStopMessage,
          ),
        ],
      ),
    );
  }
}

// Input text field widget - pure widget
class InputTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSubmitted;

  const InputTextFieldWidget({
    Key? key,
    required this.controller,
    required this.isTyping,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: !isTyping,
      decoration: InputDecoration(
        hintText: isTyping ? 'Bot is typing...' : 'Type your message...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: isTyping ? Colors.grey[50] : Colors.white,
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

// Send/Stop button widget - pure widget
class SendStopButtonWidget extends StatelessWidget {
  final bool isTyping;
  final VoidCallback onSendMessage;
  final VoidCallback onStopMessage;

  const SendStopButtonWidget({
    Key? key,
    required this.isTyping,
    required this.onSendMessage,
    required this.onStopMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: isTyping
          ? IconButton(
        icon: Icon(Icons.stop_circle, color: Colors.red[600]),
        onPressed: onStopMessage,
      )
          : IconButton(
        icon: Icon(Icons.send, color: Colors.blue[600]),
        onPressed: onSendMessage,
      ),
    );
  }
}