import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' show lerpDouble;
import '../../../constants/colors.dart';
import '../../../constants/mesh_background.dart';
import '../../widgets/common_button.dart';
import '../../widgets/dot_indicator.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';


import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class TransitioningCopy extends StatelessWidget {
  final PageController controller;
  final List<String> titles;
  final List<String> subtitles;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final double titleHeight;

  const TransitioningCopy({
    super.key,
    required this.controller,
    required this.titles,
    required this.subtitles,
    required this.titleStyle,
    required this.subtitleStyle,
    this.titleHeight = 116,
  }) : assert(titles.length == subtitles.length);

  double get _page {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final page = _page;
        final base = page.floor().clamp(0, titles.length - 1);
        final frac = (page - base).abs().clamp(0.0, 1.0);
        final neighbor = (base + 1).clamp(0, titles.length - 1);

        // Two-phase animation: fade first (0.0 to 0.5), then slide (0.5 to 1.0)
        final fadePhase = (frac * 2).clamp(0.0, 1.0); // 0-0.5 becomes 0-1
        final slidePhase = ((frac - 0.5) * 2).clamp(0.0, 1.0); // 0.5-1.0 becomes 0-1

        final isInFadePhase = frac <= 0.5;
        final isInSlidePhase = frac > 0.5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with two-phase animation: fade then slide
            SizedBox(
              height: titleHeight,
              child: ClipRect(
                child: Stack(
                  children: [
                    // Current title - fades out in first phase
                    if (frac < 0.001 || isInFadePhase)
                      Opacity(
                        opacity: frac < 0.001 ? 1.0 : (1.0 - Curves.easeInQuart.transform(fadePhase)).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titles[base],
                            textAlign: TextAlign.left,
                            style: titleStyle,
                          ),
                        ),
                      ),

                    // Next title - slides in from left to right during second phase
                    if (isInSlidePhase && base < titles.length - 1)
                      Transform.translate(
                        offset: Offset(
                          -(1 - slidePhase) * MediaQuery.of(context).size.width,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titles[neighbor],
                            textAlign: TextAlign.left,
                            style: titleStyle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle with fade and slide (separate from title)
            SizedBox(
              height: subtitleStyle.fontSize! * (subtitleStyle.height ?? 1.5) * 3,
              child: frac < 0.001
                  ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitles[base],
                  textAlign: TextAlign.left,
                  style: subtitleStyle,
                ),
              )
                  : Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Current subtitle fading out
                  Opacity(
                    opacity: (1.0 - frac).clamp(0.0, 1.0),
                    child: Text(
                      subtitles[base],
                      textAlign: TextAlign.left,
                      style: subtitleStyle,
                    ),
                  ),
                  // Next subtitle sliding in
                  if (base < titles.length - 1)
                    Opacity(
                      opacity: frac.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - frac) * 28),
                        child: Text(
                          subtitles[neighbor],
                          textAlign: TextAlign.left,
                          style: subtitleStyle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}



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
  bool _preloaded = false;
  bool _marked = false;

  // Add timer for auto-changing background
  Timer? _backgroundTimer;
  int _backgroundIndex = 0;

  // Tune this if you want stronger/weaker blur
  static const double _blurSigma = 04;

  final _bgImages = const [
    'assets/images/new_mesh.png',
    'assets/images/red_mesh.png',
    'assets/images/purple.png',
  ];

  final _titles = const [
    'Super\nIntelligent',
    'Bias\nFree',
    'Always\nAvailable',
  ];

  final _subtitles = const [
    'Thinks faster, learns deeper, and\nplans smarter—so you don\'t have to.',
    'No commissions. No agenda.\nJust advice that puts you first.',
    'On, alert, and responsive\nwhenever you need financial clarity.',
  ];

  @override
  void initState() {
    super.initState();
    _markOnboardingAsStarted();
    _startBackgroundTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloaded) {
      for (final p in _bgImages) {
        precacheImage(AssetImage(p), context);
      }
      _preloaded = true;
    }
  }

  // Start the automatic background changing timer
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _backgroundIndex = (_backgroundIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  // Stop the background timer
  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  Future<void> _markOnboardingAsStarted() async {
    if (_marked) return;
    await _authService.markOnboardingCompleted();
    _marked = true;
  }

  Future<void> _handleContinue() async {
    if (_currentPage < _titles.length - 1) {
      await _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
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
            context.go('/phone_otp');
            break;
        }
      });
    } catch (_) {
      if (mounted) context.go('/phone_otp');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔵 Blurred background (mesh + subtle lottie) - now uses _backgroundIndex
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MeltImageBackground(
                        imagePaths: _bgImages,
                        page: _backgroundIndex, // Changed from _currentPage to _backgroundIndex
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: ClipRect(
                          child: Opacity(
                            opacity: 0.020,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 8,
                                sigmaY: 08,
                              ),
                              child: Lottie.asset(
                                'assets/images/onboard.json',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.06),

                // Logo section
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'penny_logo',
                        child: Image.asset(
                          'assets/images/ying yang.png',
                          width: size.width * 0.18,
                          height: size.height * 0.055,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Hero(
                        tag: 'sub_logo',
                        child: Image.asset(
                          'assets/images/Vitty.ai2.png',
                          width: size.width * 0.2,
                          height: size.height * 0.045,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content area
                Expanded(
                  child: Stack(
                    children: [
                      // Single PageView for gesture handling
                      PageView.builder(
                        controller: _controller,
                        itemCount: _titles.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, __) => const SizedBox.shrink(),
                      ),

                      // Text content positioned on left
                      Positioned(
                        left: 28,
                        right: 28,
                        top: size.height * 0.12,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width * 0.72,
                          ),
                          child: TransitioningCopy(
                            controller: _controller,
                            titles: _titles,
                            subtitles: _subtitles,
                            titleHeight: 120,
                            titleStyle: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                              fontFamily: "DM Sans"
                            ),
                            subtitleStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                                fontFamily: "DM Sans"
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom section
                DotsIndicator(currentPage: _currentPage),
                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CommonButton(
                    label: _currentPage < _titles.length - 1
                        ? 'Continue'
                        : 'Get Started',
                    onPressed: (){
                      HapticFeedback.mediumImpact();
                      _isLoading ? null : _handleContinue();
                    },
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopBackgroundTimer(); // Clean up the timer
    super.dispose();
  }
}


class DotsIndicator extends StatelessWidget {
  final int currentPage;

  const DotsIndicator({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentPage == index ? AppColors.primary : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

















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