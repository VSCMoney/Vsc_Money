import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/colors.dart';
import '../../core/helpers/themes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Assumes you already have these types in your project:
// - AppTheme (from your AppThemeExtension.theme)
// - AppColors.primary

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

  Widget _circleButton({
    required Widget icon,
    required VoidCallback onTap,
    Color bgColor = Colors.transparent,
    bool disabled = false,
  }) {
    final bool isFilled = bgColor != Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: disabled ? null : onTap,
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
        child: Center(child: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSend = isTyping || hasText || isTranscribing;

    return RepaintBoundary(
      child: Row(
        key: const ValueKey('normalMode'),
        children: [
          // Attach icon (kept as-is)
          Image.asset(
            "assets/images/attach_2.png",
            color: theme.icon,
            height: 22,
            width: 25,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // Mic button
          GestureDetector(
            onTap: onStartRecording,
            child: Image.asset(
              "assets/images/bold_mic.png",
              height: 23,
              color: theme.icon,
            ),
          ),
          const SizedBox(width: 14),

          // -------- Fixed-size SEND SLOT (prevents layout jump) --------
          SizedBox(
           // width: 36,
            height: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.center,
                children: [
                  ...previous,
                  if (current != null) current,
                ],
              ),
              child: showSend
                  ? KeyedSubtree(
                key: ValueKey<bool>(isTyping), // only animates icon swap
                child: _circleButton(
                  bgColor: AppColors.primary,
               //   onTap: () => isTyping ? onStopResponse() : onSendMessage(),
                  onTap: (){
                    HapticFeedback.vibrate();
                    isTyping ? onStopResponse() : onSendMessage();
                  },
                  icon: Icon(
                    isTyping ? Icons.stop : Icons.arrow_upward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
