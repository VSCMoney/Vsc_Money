import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants/colors.dart';



class GoalsOnbording extends StatefulWidget {
  const GoalsOnbording({super.key});

  @override
  State<GoalsOnbording> createState() => _GoalsOnbordingState();
}

class _GoalsOnbordingState extends State<GoalsOnbording> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SvgPicture.asset(
                          'assets/images/goal_onboarding.svg',
                          fit: BoxFit.contain,
                          height: 270,
                        ),
                      ),
                      const SizedBox(height: 100),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Turn Your Dreams into Financial Goals',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 26),
                            Text(
                              'Just tell your AI what you’re saving for — it’ll turn it into a plan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // for padding at the bottom
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
