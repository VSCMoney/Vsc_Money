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


class VittyLogoConfig {
  static const double logoWidth = 200.0;
  static const double logoHeight = 200.0;

  // Adjusted heights to fit within 200px container
  static const double yingYangHeight = 80.0;  // Reduced from 90
  static const double vittyTextHeight = 90.0;  // Reduced from 100
  static const double hindiTextHeight = 20.0;  // Keep same
// Total: 80 + 90 + 20 = 190px (leaves 10px buffer)
}




const Alignment kLogoAlignment = Alignment(0.0, -0.10); // reuse on both screens
const String kLogoHeroTag = 'vitty_logo_hero';

class LogoHero extends StatelessWidget {
  const LogoHero({
    Key? key,
    required this.rotation, // pass kLogoFinalAngle on SignIn so positions match
  }) : super(key: key);

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: kLogoHeroTag,
      // keep the child shape identical on both screens
      child: SizedBox(
        width: VittyLogoConfig.logoWidth,
        height: VittyLogoConfig.logoHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: rotation,
              child: Image.asset(
                'assets/images/ying yang.png',
                width: VittyLogoConfig.logoWidth,
                height: VittyLogoConfig.yingYangHeight,
                fit: BoxFit.contain,
              ),
            ),
            Image.asset(
              'assets/images/Vitty.ai2.png',
              width: VittyLogoConfig.logoWidth,
              height: VittyLogoConfig.vittyTextHeight,
              fit: BoxFit.contain,
            ),
            Image.asset(
              'assets/images/वित्तीय2.png',
              width: VittyLogoConfig.logoWidth,
              height: VittyLogoConfig.hindiTextHeight,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

