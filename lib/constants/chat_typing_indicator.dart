import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vscmoney/services/theme_service.dart';

import '../services/locator.dart';

class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      height: 15,
      width: 65,
      child: Lottie.asset(
       locator<ThemeService>().isDark ? 'assets/images/loader_dark.json' : 'assets/images/typing_loader.json',
        repeat: true,
        fit: BoxFit.contain,
      ),
    );
  }
}