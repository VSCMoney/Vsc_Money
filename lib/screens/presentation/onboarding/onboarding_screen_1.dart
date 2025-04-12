import 'package:flutter/material.dart';

import '../../widgets/news_card.dart';
import '../../widgets/toggle_button.dart';



class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [Color(0x0DF7F7F7), Colors.transparent],
                                    radius: 0.9,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 340,
                                child: Column(
                                  children: [
                                    ToggleButtonsRow(),
                                    SizedBox(height: 16),
                                    Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: NewsCard(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 130),
                          Column(
                            children: [
                              Text(
                                'Market Alerts That Match Your Goals',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Get real-time updates and AI-curated insights based on your investment objectives.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
