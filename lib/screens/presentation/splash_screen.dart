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





class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final authService = locator<AuthService>();
  bool _navigated = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward().then((_) => _handleNavigation());

    // Safety timeout
    _navigationTimer = Timer(const Duration(seconds: 15), () {
      if (!_navigated && mounted) {
        debugPrint('⏰ Splash timeout - forcing navigation to login');
        _navigateToRoute('/phone_otp');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                width: VittyLogoConfig.logoWidth,
                height: VittyLogoConfig.logoHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ UPDATED: No rotation, simplified Hero
                    Hero(
                      tag: 'penny_logo',
                      transitionOnUserGestures: true,
                      child: Image.asset(
                        'assets/images/ying yang.png',
                        width: VittyLogoConfig.logoWidth,
                        height: VittyLogoConfig.yingYangHeight,
                        fit: BoxFit.contain,
                      ),
                    ),

                    Hero(
                      tag: 'sub_logo',
                      child: Image.asset(
                        'assets/images/Vitty.ai2.png',
                        width: VittyLogoConfig.logoWidth,
                        height: VittyLogoConfig.vittyTextHeight,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Hindi text (no Hero)
                    Image.asset(
                      'assets/images/वित्तीय2.png',
                      width: VittyLogoConfig.logoWidth,
                      height: VittyLogoConfig.hindiTextHeight,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======= UPDATED: Navigation logic with Hero for onboarding AND sign-in =======
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

  void _navigateToRoute(String route) {
    if (_navigated) return;
    _navigated = true;
    _navigationTimer?.cancel();

    // ✅ UPDATED: Hero animation for both onboarding AND phone_otp (sign-in)
    final wantsHeroFlight = (route == '/onboarding' || route == '/phone_otp');

    try {
      if (!mounted) return;

      if (wantsHeroFlight) {
        context.push(route); // push => both pages coexist => Hero flies
        debugPrint('✅ Navigated to: $route (PUSH with Hero animation)');
      } else {
        context.go(route);   // replace for others (no Hero)
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
          final wantsHeroFlight = (route == '/onboarding' || route == '/phone_otp');
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


// ✅ Helper extension for fire-and-forget operations
extension UnawaiteExtension on Future {
  void get unawaited => {};
}


