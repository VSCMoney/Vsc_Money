import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/controllers/session_manager.dart';

import '../../constants/app_bar.dart';
import '../../constants/vitty_loader.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';
import 'onboarding/onoarding_page.dart';



class HeroRotateScope extends InheritedWidget {
  final bool rotateDuringFlight;
  const HeroRotateScope({
    super.key,
    required this.rotateDuringFlight,
    required Widget child,
  }) : super(child: child);

  static HeroRotateScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HeroRotateScope>();
  }

  @override
  bool updateShouldNotify(HeroRotateScope oldWidget) =>
      oldWidget.rotateDuringFlight != rotateDuringFlight;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController; // Exit animation controller

  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeOut; // Text fade-out

  final authService = locator<AuthService>();
  bool _navigated = false;
  bool _isExiting = false;
  Timer? _navigationTimer;

  // 🔁 NEW: control rotation & text fade per target route
  bool _rotateDuringFlight = true;
  bool _fadeTextsOnExit = true;

  @override
  void initState() {
    super.initState();

    // Main splash animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Text exit fade controller
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    // Texts only fade out on exit (unless disabled)
    _textFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    _controller.forward().then((_) => _handleNavigation());

    // Hard timeout fallback
    _navigationTimer = Timer(const Duration(seconds: 15), () {
      if (!_navigated && mounted) {
        debugPrint('⏰ Splash timeout - forcing navigation to login');
        _navigateToRoute('/phone_otp');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optional: precache to avoid flicker during hero
    precacheImage(const AssetImage('assets/images/ying yang.png'), context);
    precacheImage(const AssetImage('assets/images/Vitty.ai2.png'), context);
    precacheImage(const AssetImage('assets/images/वित्तीय2.png'), context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: IgnorePointer(
          ignoring: _isExiting,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _exitController]),
            builder: (context, child) => Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: 200,  // ✅ Same as SignInPage
                  height: 200, // ✅ Same as SignInPage
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Hero
                      Hero(
                        tag: 'penny_logo',
                        transitionOnUserGestures: true,
                        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                          final fromHero = fromHeroContext.widget as Hero;
                          final toHero   = toHeroContext.widget as Hero;
                          final shuttleChild = (flightDirection == HeroFlightDirection.push)
                              ? fromHero.child
                              : toHero.child;

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) => RepaintBoundary(child: shuttleChild),
                          );
                        },
                        child: Image.asset(
                          'assets/images/ying yang.png',
                          width: 150,  // ✅ Same as SignInPage
                          height: 90,  // ✅ Same as SignInPage
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 4), // ✅ Same gap as SignInPage

                      // Texts: fade OUT only when _fadeTextsOnExit=true
                      FadeTransition(
                        opacity: _fadeTextsOnExit ? _textFadeOut : const AlwaysStoppedAnimation(1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/Vitty.ai2.png',
                              width: 140,  // ✅ Same as SignInPage
                              height: 58,  // ✅ Same as SignInPage
                              fit: BoxFit.contain,
                            ),
                            Image.asset(
                              'assets/images/वित्तीय2.png',
                              width: 120,  // ✅ Same as SignInPage
                              height: 20,  // ✅ Same as SignInPage
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- NAVIGATION ----------
  void _handleNavigation() async {
    if (_navigated) return;

    try {
      final futures = await Future.wait([
        SharedPreferences.getInstance(),
        locator<ThemeService>().loadThemeFromPrefs(),
      ]).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Preferences loading timed out');
      });

      final prefs = futures[0] as SharedPreferences;
      final endPointService = EndPointService();
      final hasNetwork = endPointService.currentNetworkStatus != NetworkStatus.noInternet;

      // Biometrics (optional)
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (isBiometricEnabled) {
        try {
          final success = await authService.authenticate().timeout(const Duration(seconds: 10));
          if (!success) return;
        } catch (_) {/* ignore biometric errors */}
      }

      // Token check
      final token = prefs.getString("access_token");
      final uid = prefs.getString("uid");

      if (token != null && uid != null) {
        if (!SessionManager.isTokenExpired(token)) {
          _navigateToRoute('/home');
          if (hasNetwork) _validateTokenInBackground();
          return;
        } else if (hasNetwork) {
          final refreshed = await SessionManager.tryRefreshToken().timeout(const Duration(seconds: 8));
          if (refreshed) {
            _navigateToRoute('/home');
            _validateTokenInBackground();
            return;
          }
        }
      }

      await _determineFlowForUnauthenticatedUser(hasNetwork);
    } on TimeoutException catch (e) {
      debugPrint('⏰ Splash navigation timeout: $e');
      _navigateToFallback();
    } catch (e) {
      debugPrint('❌ Error in splash navigation: $e');
      _navigateToFallback();
    }
  }

  Future<void> _determineFlowForUnauthenticatedUser(bool hasNetwork) async {
    try {
      if (!hasNetwork) {
        debugPrint('📡 No network - using cached flow determination');
        final onboardingCompleted = await authService.isOnboardingCompleted();
        final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';
        _navigateToRoute(fallbackRoute);
        return;
      }

      await authService.determineInitialFlow((flow) async {
        if (!mounted || _navigated) return;

        final route = switch (flow) {
          AuthFlow.onboarding => '/onboarding',
          AuthFlow.login => '/phone_otp',
          AuthFlow.nameEntry => '/enter_name',
          AuthFlow.home => '/home',
        };

        debugPrint('Splash navigating to: $route (flow: $flow)');
        _navigateToRoute(route);
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('⏰ Flow determination timed out');
      _navigateToFallback();
    } catch (e) {
      debugPrint('❌ Error determining flow from splash: $e');
      _navigateToFallback();
    }
  }

  void _navigateToFallback() {
    if (_navigated) return;

    authService.isOnboardingCompleted().then((completed) {
      final fallbackRoute = completed ? '/phone_otp' : '/onboarding';
      _navigateToRoute(fallbackRoute);
    }).catchError((e) {
      debugPrint('❌ Fallback error: $e');
      _navigateToRoute('/onboarding');
    });
  }

  // 🔑 Wait for text fade *only if enabled* before pushing
  Future<void> _navigateToRoute(String route) async {
    if (_navigated) return;
    _navigated = true;
    _navigationTimer?.cancel();

    final wantsHeroFlight = (route == '/onboarding' || route == '/phone_otp' || route == '/home');
    final isSignIn = route == '/phone_otp';

    // Set behavior flags per route
    _rotateDuringFlight = !isSignIn;   // 🚫 no rotation for sign-in
    _fadeTextsOnExit    = !isSignIn;   // 🚫 no text fade for sign-in

    try {
      if (!mounted) return;

      if (wantsHeroFlight) {
        // Block taps only if we are playing a fade
        setState(() => _isExiting = _fadeTextsOnExit);

        if (_fadeTextsOnExit) {
          await _exitController.forward(); // texts fade out (not for sign-in)
        }

        if (!mounted) return;
        context.push(route); // Hero starts now
        debugPrint('✅ Navigated to: $route (PUSH with Hero; rotate=$_rotateDuringFlight, fadeTexts=$_fadeTextsOnExit)');
      } else {
        if (!mounted) return;
        context.go(route);
        debugPrint('✅ Navigated to: $route (GO replace, no Hero)');
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      _retryNavigation(route);
    }
  }

  void _retryNavigation(String route) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        try {
          final wantsHeroFlight = (route == '/onboarding' || route == '/phone_otp' || route == '/home');
          if (wantsHeroFlight) {
            context.push(route);
          } else {
            context.go(route);
          }
        } catch (_) {}
      }
    });
  }

  void _validateTokenInBackground() {
    unawaited(_performBackgroundValidation());
  }

  Future<void> _performBackgroundValidation() async {
    try {
      await SessionManager.loadTokens();
      final token = SessionManager.token;

      if (token != null && !authService.isTokenExpired(token)) {
        try {
          await authService.fetchUserProfile(silent: true).timeout(const Duration(seconds: 10));
        } catch (_) {}
        return;
      }

      final refreshed = await SessionManager.tryRefreshToken().timeout(const Duration(seconds: 8));

      if (refreshed) {
        try {
          await authService.fetchUserProfile(silent: true).timeout(const Duration(seconds: 10));
        } catch (_) {}
      } else {
        await SessionManager.clearToken();
        debugPrint('Background validation failed - tokens cleared');
      }
    } catch (e) {
      debugPrint("Background validation error: $e");
    }
  }
}







extension UnawaiteExtension on Future {
  void get unawaited => {};
}


