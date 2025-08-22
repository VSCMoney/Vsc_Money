import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/mesh_background.dart';
import '../../widgets/common_button.dart';
import '../../widgets/dot_indicator.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../auth/auth_screen.dart';
import 'onboarding_page_3.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final AuthService _authService = locator<AuthService>();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _imagesPreloaded = false;
  bool _onboardingMarkedComplete = false;

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

  @override
  void initState() {
    super.initState();
    _markOnboardingAsStarted();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPreloaded) {
      _preloadImages();
      _imagesPreloaded = true;
    }
  }

  Future<void> _markOnboardingAsStarted() async {
    if (!_onboardingMarkedComplete) {
      await _authService.markOnboardingCompleted();
      _onboardingMarkedComplete = true;
      debugPrint('✅ Onboarding marked as completed (early)');
    }
  }

  void _preloadImages() {
    for (final imagePath in backgroundImages) {
      precacheImage(AssetImage(imagePath), context);
    }
  }

  Future<void> _handleContinue() async {
    if (_currentPage < 2) {
      // Navigate to next onboarding page
      await _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding and navigate to auth
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.completeOnboarding((flow) {
        if (!mounted) return;

        switch (flow) {
          case AuthFlow.login:
            context.go('/phone_otp');
            break;
          case AuthFlow.nameEntry:
            context.go('/enter_name');
            break;
          case AuthFlow.home:
            context.go('/home');
            break;
          case AuthFlow.onboarding:
          // Should never happen since we already marked it complete
            debugPrint('⚠️ Unexpected onboarding flow');
            context.go('/phone_otp');
            break;
        }
      });
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      // Fallback to auth screen
      if (mounted) {
        context.go('/phone_otp');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Smooth background transition
          Positioned.fill(
            child: MeltImageBackground(
              imagePaths: backgroundImages,
              page: _currentPage,
            ),
          ),

          // Subtle lottie animation overlay
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.01,
                child: Lottie.asset(
                  'assets/images/onboard.json',
                  fit: BoxFit.cover,
                  animate: true,
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double opacity = 1.0;

                        if (_controller.position.haveDimensions) {
                          num difference = (_controller.page ?? _controller.initialPage) - index;
                          opacity = (1.0 - difference.abs()).clamp(0.0, 1.0);
                        }

                        return Opacity(
                          opacity: opacity,
                          child: child,
                        );
                      },
                      child: _buildPage(index),
                    );
                  },
                ),
              ),

              // Dots indicator
              DotsIndicator(currentPage: _currentPage),
              const SizedBox(height: 30),

              // Continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CommonButton(
                  label: _currentPage < 2 ? 'Continue' : 'Get Started',
                  onPressed: _isLoading ? null : _handleContinue,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 82),
            ],
          ),

          // Hero logo
          Positioned(
            top: 90,
            left: screenWidth / 2 - (screenWidth * 0.09),
            child: Column(
              children: [
                Hero(
                  tag: 'penny_logo',
                  child: Image.asset(
                    'assets/images/new_app_logo.png',
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.06,
                  ),
                ),
                Hero(
                  tag: 'sub_logo',
                  child: Image.asset(
                    'assets/images/Vitty.ai.png',
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.05,
                  ),
                ),
              ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// App startup coordinator
class AppStartupCoordinator extends StatefulWidget {
  const AppStartupCoordinator({super.key});

  @override
  State<AppStartupCoordinator> createState() => _AppStartupCoordinatorState();
}

class _AppStartupCoordinatorState extends State<AppStartupCoordinator> {
  final AuthService _authService = locator<AuthService>();
  bool _isLoading = true;
  String _debugInfo = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      setState(() => _debugInfo = 'Checking onboarding status...');

      await _authService.determineInitialFlow((flow) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        final route = switch (flow) {
          AuthFlow.onboarding => '/onboarding',
          AuthFlow.login => '/phone_otp',
          AuthFlow.nameEntry => '/enter_name',
          AuthFlow.home => '/home',
        };

        debugPrint('🚀 Navigating to: $route (flow: $flow)');
        context.go(route);
      });
    } catch (e) {
      debugPrint('❌ Error determining initial route: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _debugInfo = 'Error occurred, using fallback...';
        });

        // Safe fallback - check onboarding one more time
        final onboardingCompleted = await _authService.isOnboardingCompleted();
        final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';

        context.go(fallbackRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _debugInfo,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // Navigation handled by GoRouter
  }
}