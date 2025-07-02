import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vscmoney/main.dart';
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


  final List<List<Color>> gradientColors = [
    [const Color(0xFF7F00FF), const Color(0xFFE100FF)], // Page 0
    [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], // Page 1
    [const Color(0xFF2193b0), const Color(0xFF6dd5ed)], // Page 2
  ];


  final List<String> backgroundImages = [
    'assets/images/onboard_animate.png',
    'assets/images/green_bag.png',
    'assets/images/pink.png',
  ];



 // precacheImage(const AssetImage('assets/images/onboard_animate.png'), context);
//     precacheImage(const AssetImage('assets/images/green_bag.png'), context);
//     precacheImage(const AssetImage('assets/images/pink.png'), context);



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// ✅ Butter-smooth background transition using stacked AnimatedOpacity
          Positioned.fill(
            child: MeltImageBackground(
              imagePaths: backgroundImages,
              page: _currentPage,
            ),
          ),



          // Optional: Blurry lottie motion overlay
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.01,
                child: Lottie.asset(
                  'assets/images/onboard.json',
                  fit: BoxFit.cover,
                  animate: true
                ),
              ),
            ),
          ),

          // ImageFiltered(
          //   imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
          //   child: Lottie.asset('assets/images/onboard.json',),
          // ),


          /// Page content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildPage(index),
                  ),
                ),
              ),

              DotsIndicator(currentPage: _currentPage),
              const SizedBox(height: 30),

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
                      context.go('/phone_otp'); // 🔁 go to login/signup
                    }
                  },
                ),
              ),

              const SizedBox(height: 82),
            ],
          ),

          /// Hero logo in center top
          Positioned(
            top: 110,
            left: screenWidth / 2 - (screenWidth * 0.1),
            child: Hero(
              tag: 'penny_logo',
              child: Image.asset(
                'assets/images/auth.png',
                width: screenWidth * 0.2,
                height: screenHeight * 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    if (index == 0) return const InvestmentPlanScreen();
    if (index == 1) return const GoalsOnbording();
    if (index == 2) return const OnboardingScreen();
    return const SizedBox.shrink();
  }
}


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
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     precacheImage(const AssetImage('assets/images/onboard_animate.png'), context);
//     precacheImage(const AssetImage('assets/images/green_bag.png'), context);
//     precacheImage(const AssetImage('assets/images/pink.png'), context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//      final screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//
//
//           // Positioned.fill(
//           //   child: AnimatedSwitcher(
//           //     duration: const Duration(milliseconds: 500),
//           //     switchInCurve: Curves.easeInOut,
//           //     switchOutCurve: Curves.easeInOut,
//           //     transitionBuilder: (child, animation) {
//           //       return FadeTransition(
//           //         opacity: animation,
//           //         child: SlideTransition(
//           //           position: Tween<Offset>(
//           //             begin: const Offset(0.0, 0.02),
//           //             end: Offset.zero,
//           //           ).animate(animation),
//           //           child: child,
//           //         ),
//           //       );
//           //     },
//           //     child: SizedBox.expand(
//           //       key: ValueKey(_currentPage), // very important!
//           //       child: Image.asset(
//           //         _currentPage == 0
//           //             ? 'assets/images/onboard_animate.png'
//           //             : _currentPage == 1
//           //             ? 'assets/images/green_bag.png'
//           //             : 'assets/images/pink.png',
//           //         fit: BoxFit.cover,
//           //       ),
//           //     ),
//           //   ),
//           // ),
//
//
//           Positioned.fill(
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 600),
//               switchInCurve: Curves.easeInOut,
//               switchOutCurve: Curves.easeInOut,
//               transitionBuilder: (child, animation) {
//                 return FadeTransition(
//                   opacity: animation,
//                   child: SlideTransition(
//                     position: Tween<Offset>(
//                       begin: const Offset(0.0, 0.02),
//                       end: Offset.zero,
//                     ).animate(animation),
//                     child: child,
//                   ),
//                 );
//               },
//               child: SizedBox.expand(
//                 key: ValueKey(_currentPage),
//                 child: Image.asset(
//                   _currentPage == 0
//                       ? 'assets/images/onboard_animate.png'
//                       : _currentPage == 1
//                       ? 'assets/images/green_bag.png'
//                       : 'assets/images/pink.png',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//
//
//
//           // 💨 Lottie blurry overlay
//           Positioned.fill(
//             child: Opacity(
//               opacity: 0.01,
//               child: Lottie.asset(
//                 'assets/images/onboard.json',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//
//           Column(
//             children: [
//               Expanded(
//                 child: PageView.builder(
//                   controller: _controller,
//                   itemCount: 3,
//                   onPageChanged: (index) {
//                     setState(() {
//                       _currentPage = index;
//                     });
//                   },
//                   itemBuilder: (context, index) {
//                     if (index == 0) {
//                       return InvestmentPlanScreen();
//                     } else if (index == 1) {
//                       return GoalsOnbording();
//                     }else if(index == 2){
//                       return OnboardingScreen();
//                     }
//                     return null;
//                   },
//                 ),
//               ),
//
//               DotsIndicator(currentPage: _currentPage),
//               const SizedBox(height: 30),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: CommonButton(
//                   label: 'Continue',
//                   onPressed: () {
//                     if (_currentPage < 2) {
//                       _controller.animateToPage(
//                         _currentPage + 1,
//                         duration: const Duration(milliseconds: 400),
//                         curve: Curves.easeInOut,
//                       );
//                     } else {
//                       // Navigate to login/auth screen after second onboarding page
//                       context.go('/phone_otp');
//                     }
//                   },
//                 ),
//               ),
//               const SizedBox(height: 82),
//             ],
//           ),
//
//           // Add this destination for the Hero animation
//           Positioned(
//             top: 110,
//             left: 180,
//             child: Hero(
//               tag: 'penny_logo',
//               child: Image.asset(
//                 'assets/images/auth.png', // Update with your logo path
//                 width: screenWidth * 0.2,
//                 height: screenHeight * 0.1,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class MeltImageBackground extends StatefulWidget {
  final List<String> imagePaths;
  final int page;

  const MeltImageBackground({
    super.key,
    required this.imagePaths,
    required this.page,
  });

  @override
  State<MeltImageBackground> createState() => _MeltImageBackgroundState();
}

class _MeltImageBackgroundState extends State<MeltImageBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  int _prevPage = 0;

  @override
  void initState() {
    super.initState();
    _prevPage = widget.page;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant MeltImageBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page != oldWidget.page) {
      _prevPage = oldWidget.page;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.imagePaths[_prevPage],
          fit: BoxFit.cover,
        ),
        FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            widget.imagePaths[widget.page],
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}


// class MeltGradientBackground extends StatefulWidget {
//   final List<List<Color>> gradients;
//   final int page;
//
//   const MeltGradientBackground({
//     super.key,
//     required this.gradients,
//     required this.page,
//   });
//
//   @override
//   State<MeltGradientBackground> createState() => _MeltGradientBackgroundState();
// }
//
// class _MeltGradientBackgroundState extends State<MeltGradientBackground> with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Color?> _color1;
//   late Animation<Color?> _color2;
//
//   late List<Color> _current;
//   late List<Color> _next;
//
//   @override
//   void initState() {
//     super.initState();
//     _current = widget.gradients[widget.page];
//     _next = _current;
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3), // 🐢 Slow and smooth
//     );
//
//     _setupTweens();
//     _controller.forward();
//   }
//
//   @override
//   void didUpdateWidget(covariant MeltGradientBackground oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.page != oldWidget.page) {
//       _current = _next;
//       _next = widget.gradients[widget.page];
//
//       _setupTweens();
//       _controller.forward(from: 0);
//     }
//   }
//
//   void _setupTweens() {
//     _color1 = ColorTween(begin: _current[0], end: _next[0]).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic), // 🧈 Melt motion
//     );
//     _color2 = ColorTween(begin: _current[1], end: _next[1]).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (_, __) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 _color1.value ?? _next[0],
//                 _color2.value ?? _next[1],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }



