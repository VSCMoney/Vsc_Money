import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/helpers/themes.dart';

class VIttyLoader extends StatelessWidget {
  const VIttyLoader({
    super.key,
    required this.theme,
  });

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        color: theme.background,
        child: Lottie.asset(
          'assets/images/vitty_loader.json',
          width: 200, // or any size you want
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}