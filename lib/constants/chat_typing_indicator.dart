import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      height: 15,
      width: 65,
      child: Lottie.asset(
        'assets/images/typing_loader.json',
        repeat: true,
        fit: BoxFit.contain,
      ),
    );
  }
}