import 'package:flutter/material.dart';

import '../../../constants/mesh_background.dart';
import '../../widgets/news_card.dart';
import '../../widgets/toggle_button.dart';
import 'onoarding_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedOnboardingText(
        title: 'Always\nAvailable',
        subtitle: 'On, alert, and responsive\nwhenever you need financial clarity.',
      ),
    );
  }
}


