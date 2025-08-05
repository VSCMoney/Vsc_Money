import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/colors.dart';
import '../../../constants/mesh_background.dart';
import 'onoarding_page.dart';

class GoalsOnbording extends StatelessWidget {
  const GoalsOnbording({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedOnboardingText(
        title: 'Bias\nFree',
        subtitle: 'No commissions. No agenda.\nJust advice that puts you first.',
      ),
    );
  }
}






