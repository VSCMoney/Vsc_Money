import 'package:flutter/material.dart';
import 'package:vscmoney/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/mesh_background.dart';
import 'onoarding_page.dart';

class InvestmentPlanScreen extends StatelessWidget {
  const InvestmentPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return
      SafeArea(
        child: AnimatedOnboardingText(
          title: 'Super\nIntelligent',
          subtitle: 'On, alert, and responsive\nwhenever you need financial clarity.',
        ),
      );
  }
}
