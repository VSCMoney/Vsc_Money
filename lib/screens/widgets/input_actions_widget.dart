import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/helpers/themes.dart';

class InputActionsBarWidget extends StatelessWidget {
  final bool isTyping;
  final bool hasText;
  final bool isTranscribing;
  final VoidCallback onStartRecording;
  final VoidCallback onSendMessage;
  final VoidCallback onStopResponse;
  final AppTheme theme;

  const InputActionsBarWidget({
    Key? key,
    required this.isTyping,
    required this.hasText,
    required this.isTranscribing,
    required this.onStartRecording,
    required this.onSendMessage,
    required this.onStopResponse,
    required this.theme,
  }) : super(key: key);

  Widget _buildCircleButton({
    IconData? icon,
    Widget? iconWidget,
    VoidCallback? onTap,
    bool isLoading = false,
    Color bgColor = Colors.transparent,
  }) {
    final bool isFilled = bgColor != Colors.transparent;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 1.0, end: isLoading ? 0.95 : 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: isLoading ? null : onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: 1.0,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(
                  color: isFilled ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: isLoading
                  ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
                  : Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 18,
                      color: isFilled ? theme.background : theme.icon,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('normalMode'),
      children: [
        // Attach button
        Image.asset(
          "assets/images/attach_2.png",
          color: theme.icon,
          height: 22,
          width: 25,
          fit: BoxFit.contain,
        ),
        Spacer(),

        Row(
          children: [
            // Mic button
            GestureDetector(
              onTap: onStartRecording,
              child: Image.asset(
                "assets/images/bold_mic.png",
                height: 23,
                color: theme.icon,
              ),
            ),
            SizedBox(width: 18),

            // Send button
            if (isTyping || hasText || isTranscribing)
              _buildCircleButton(
                bgColor: const Color(0xFFF66A00),
                onTap: () {
                  if (isTyping) {
                    onStopResponse();
                  } else {
                    onSendMessage();
                  }
                },
                iconWidget: Icon(
                  isTyping ? Icons.stop : Icons.arrow_upward,
                  key: ValueKey(isTyping),
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ],
    );
  }
}