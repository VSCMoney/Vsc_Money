// import 'package:flutter/material.dart';
// import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
//
// import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_1.dart';
// import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_2.dart';
// import '../../widgets/common_button.dart';
// import '../../widgets/dot_indicator.dart';
//
//
//
// class OnboardingPage extends StatefulWidget {
//   const OnboardingPage({super.key});
//
//   @override
//   State<OnboardingPage> createState() => _OnboardingPageState();
// }
//
// class _OnboardingPageState extends State<OnboardingPage> {
//   final PageController _controller = PageController();
//   int _currentPage = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           Expanded(
//             child: PageView.builder(
//               controller: _controller,
//               itemCount: 2,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentPage = index;
//                 });
//               },
//               itemBuilder: (context, index) {
//                 if (index == 0) {
//                   return  InvestmentPlanScreen();
//                 } else if (index == 1) {
//                   return  OnboardingScreen();
//                 }
//                 return null;
//               },
//             ),
//           ),
//           const SizedBox(height: 16),
//           DotsIndicator(currentPage: _currentPage),
//           const SizedBox(height: 24),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: CommonButton(
//               label: 'Continue',
//               onPressed: () {
//                 if (_currentPage < 1) {
//                   _controller.animateToPage(
//                     _currentPage + 1,
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeInOut,
//                   );
//                 }else {
//                   // Navigate to login/auth screen after second onboarding page
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (context) => const AuthScreen()),
//                   );
//                 }
//               },
//             ),
//           ),
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
// }



// Modify your onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_page_3.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_1.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_2.dart';
import '../../widgets/common_button.dart';
import '../../widgets/dot_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return InvestmentPlanScreen();
                    } else if (index == 1) {
                      return GoalsOnbording();
                    }else if(index == 2){
                      return OnboardingScreen();
                    }
                    return null;
                  },
                ),
              ),

              DotsIndicator(currentPage: _currentPage),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CommonButton(
                  label: 'Continue',
                  onPressed: () {
                    if (_currentPage < 2) {
                      _controller.animateToPage(
                        _currentPage + 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to login/auth screen after second onboarding page
                      context.goNamed('auth');
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),

          // Add this destination for the Hero animation
          Positioned(
            top: 60,
            left: 180,
            child: Hero(
              tag: 'penny_logo',
              child: SvgPicture.asset(
                'assets/images/Vitty_logo.svg', // Update with your logo path
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}