import 'dart:io';

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


// Updated SplashScreen with rotation controller
// splash_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers/themes.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';
import '../../controllers/session_manager.dart';
import '../../services/auth_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late AnimationController _rotationController;
//   late Animation<double> _opacityAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotationAnimation;
//
//   final authService = locator<AuthService>();
//   bool _navigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 900),
//       vsync: this,
//     );
//
//     _rotationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
//     );
//
//     // ✅ Animate to the SAME final angle used by the AppBar
//     _rotationAnimation = Tween<double>(begin: 0.0, end: kLogoFinalAngle).animate(
//       CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
//     );
//
//     _controller.forward().then((_) {
//       _handleNavigation();
//     });
//   }
//
//   void _handleNavigation() async {
//     if (_navigated) return;
//
//     try {
//       final futures = await Future.wait([
//         SharedPreferences.getInstance(),
//         locator<ThemeService>().loadThemeFromPrefs(),
//       ]);
//       final prefs = futures[0] as SharedPreferences;
//
//       // Biometrics
//       final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
//       if (isBiometricEnabled) {
//         final success = await authService.authenticate();
//         if (!success) {
//           exit(0);
//           return;
//         }
//       }
//
//       // Quick token check
//       final token = prefs.getString("access_token");
//       final uid = prefs.getString("uid");
//
//       if (token != null && uid != null) {
//         // Rotate once, then go home
//         await _rotationController.forward();
//         _navigateToRoute('/home');
//         _validateTokenInBackground();
//         return;
//       }
//
//       // No valid session
//       await _determineFlowForUnauthenticatedUser();
//     } catch (e) {
//       debugPrint('Error in splash navigation: $e');
//       await _determineFlowForUnauthenticatedUser();
//     }
//   }
//
//   Future<void> _determineFlowForUnauthenticatedUser() async {
//     try {
//       await authService.determineInitialFlow((flow) async {
//         if (!mounted || _navigated) return;
//
//         final route = switch (flow) {
//           AuthFlow.onboarding => '/onboarding',
//           AuthFlow.login => '/phone_otp',
//           AuthFlow.nameEntry => '/enter_name',
//           AuthFlow.home => '/home',
//         };
//
//         // Rotate only if we’re going home
//         if (route == '/home') {
//           await _rotationController.forward();
//         }
//
//         debugPrint('Splash navigating to: $route (flow: $flow)');
//         _navigateToRoute(route);
//       });
//     } catch (e) {
//       debugPrint('Error determining flow from splash: $e');
//       final onboardingCompleted = await authService.isOnboardingCompleted();
//       final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';
//       _navigateToRoute(fallbackRoute);
//     }
//   }
//
//   void _navigateToRoute(String route) {
//     if (_navigated) return;
//     _navigated = true;
//     if (mounted) context.go(route);
//   }
//
//   void _validateTokenInBackground() async {
//     try {
//       await SessionManager.loadTokens();
//       final token = SessionManager.token;
//
//       if (token != null && !authService.isTokenExpired(token)) {
//         try {
//           await locator<AuthService>().fetchUserProfile();
//         } catch (_) {}
//         return;
//       }
//
//       final refreshed = await SessionManager.tryRefreshToken();
//       if (refreshed) {
//         try {
//           await locator<AuthService>().fetchUserProfile();
//         } catch (_) {}
//       } else {
//         await SessionManager.clearToken();
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) context.go('/phone_otp');
//       }
//     } catch (e) {
//       debugPrint("Background validation error: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _rotationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: Listenable.merge([_controller, _rotationController]),
//           builder: (context, child) => Opacity(
//             opacity: _opacityAnimation.value,
//             child: Transform.scale(
//               scale: _scaleAnimation.value,
//               child: SizedBox(
//                 width: VittyLogoConfig.logoWidth,
//                 height: VittyLogoConfig.logoHeight,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Ying Yang with reduced height
//                     Hero(
//                       tag: 'penny_logo',
//                       child: Transform.rotate(
//                         angle: _rotationAnimation.value,
//                         child: Image.asset(
//                           'assets/images/ying yang.png',
//                           width: VittyLogoConfig.logoWidth,
//                           height: VittyLogoConfig.yingYangHeight,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                     // Vitty.ai text with reduced height
//                     Hero(
//                       tag: 'sub_logo',
//                       child: Image.asset(
//                         'assets/images/Vitty.ai2.png',
//                         width: VittyLogoConfig.logoWidth,
//                         height: VittyLogoConfig.vittyTextHeight,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                     // Hindi text with same height
//                     Image.asset(
//                       'assets/images/वित्तीय2.png',
//                       width: VittyLogoConfig.logoWidth,
//                       height: VittyLogoConfig.hindiTextHeight,
//                       fit: BoxFit.contain,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final authService = locator<AuthService>();
  bool _navigated = false;
  Timer? _navigationTimer; // Add timeout for navigation

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: kLogoFinalAngle).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) {
      _handleNavigation();
    });

    // ✅ Add safety timeout to prevent infinite splash screen
    _navigationTimer = Timer(const Duration(seconds: 15), () {
      if (!_navigated && mounted) {
        debugPrint('⏰ Splash timeout - forcing navigation to login');
        _navigateToRoute('/phone_otp');
      }
    });
  }

  void _handleNavigation() async {
    if (_navigated) return;

    try {
      // ✅ Add timeout to preferences loading
      final futures = await Future.wait([
        SharedPreferences.getInstance(),
        locator<ThemeService>().loadThemeFromPrefs(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Preferences loading timed out'),
      );

      final prefs = futures[0] as SharedPreferences;

      // ✅ Check network status before proceeding with network-dependent operations
      final endPointService = EndPointService();
      final hasNetwork = endPointService.currentNetworkStatus != NetworkStatus.noInternet;

      // Biometrics (doesn't require network)
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (isBiometricEnabled) {
        try {
          final success = await authService.authenticate()
              .timeout(const Duration(seconds: 10));
          if (!success) {
            exit(0);
            return;
          }
        } catch (e) {
          debugPrint('Biometric authentication failed: $e');
          // Continue without biometric auth
        }
      }

      // Quick token check (local storage only)
      final token = prefs.getString("access_token");
      final uid = prefs.getString("uid");

      if (token != null && uid != null) {
        // We have tokens - check if they're valid
        if (!SessionManager.isTokenExpired(token)) {
          // Valid token exists
          await _rotationController.forward();
          _navigateToRoute('/home');

          // ✅ Only validate in background if we have network
          if (hasNetwork) {
            _validateTokenInBackground();
          }
          return;
        } else {
          // Token expired - try refresh if we have network
          if (hasNetwork) {
            final refreshed = await SessionManager.tryRefreshToken()
                .timeout(const Duration(seconds: 8));
            if (refreshed) {
              await _rotationController.forward();
              _navigateToRoute('/home');
              _validateTokenInBackground();
              return;
            }
          }
          // If no network or refresh failed, proceed as unauthenticated
        }
      }

      // No valid session or network issues
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
      // ✅ If no network, use cached preferences for flow determination
      if (!hasNetwork) {
        debugPrint('📡 No network - using cached flow determination');
        final onboardingCompleted = await authService.isOnboardingCompleted();
        final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';
        _navigateToRoute(fallbackRoute);
        return;
      }

      // ✅ Network available - use full flow determination with timeout
      await authService.determineInitialFlow((flow) async {
        if (!mounted || _navigated) return;

        final route = switch (flow) {
          AuthFlow.onboarding => '/onboarding',
          AuthFlow.login => '/phone_otp',
          AuthFlow.nameEntry => '/enter_name',
          AuthFlow.home => '/home',
        };

        if (route == '/home') {
          await _rotationController.forward();
        }

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

    // Use cached onboarding status for fallback
    authService.isOnboardingCompleted().then((completed) {
      final fallbackRoute = completed ? '/phone_otp' : '/onboarding';
      _navigateToRoute(fallbackRoute);
    }).catchError((e) {
      // Ultimate fallback - assume onboarding is needed
      debugPrint('❌ Fallback error: $e');
      _navigateToRoute('/onboarding');
    });
  }

  void _navigateToRoute(String route) {
    if (_navigated) return;
    _navigated = true;
    _navigationTimer?.cancel(); // Cancel timeout timer

    if (mounted) {
      try {
        context.go(route);
        debugPrint('✅ Navigated to: $route');
      } catch (e) {
        debugPrint('❌ Navigation error: $e');
        // Try again with a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            try {
              context.go(route);
            } catch (e) {
              debugPrint('❌ Second navigation attempt failed: $e');
            }
          }
        });
      }
    }
  }

  void _validateTokenInBackground() async {
    // ✅ Make background validation completely non-blocking
    unawaited(_performBackgroundValidation());
  }

  Future<void> _performBackgroundValidation() async {
    try {
      await SessionManager.loadTokens();
      final token = SessionManager.token;

      if (token != null && !authService.isTokenExpired(token)) {
        // Token is valid, try to fetch profile
        try {
          await authService.fetchUserProfile(silent: true)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Background profile fetch failed: $e');
        }
        return;
      }

      // Token expired or invalid, try refresh
      final refreshed = await SessionManager.tryRefreshToken()
          .timeout(const Duration(seconds: 8));

      if (refreshed) {
        try {
          await authService.fetchUserProfile(silent: true)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Background profile fetch after refresh failed: $e');
        }
      } else {
        // Background refresh failed - clear tokens but don't force navigation
        // Let the user's next action trigger proper authentication
        await SessionManager.clearToken();
        debugPrint('Background validation failed - tokens cleared');
      }
    } catch (e) {
      debugPrint("Background validation error: $e");
      // Don't navigate on background errors - let user continue
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
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
          animation: Listenable.merge([_controller, _rotationController]),
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
                    // Ying Yang with reduced height
                    Hero(
                      tag: 'penny_logo',
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Image.asset(
                          'assets/images/ying yang.png',
                          width: VittyLogoConfig.logoWidth,
                          height: VittyLogoConfig.yingYangHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Vitty.ai text with reduced height
                    Hero(
                      tag: 'sub_logo',
                      child: Image.asset(
                        'assets/images/Vitty.ai2.png',
                        width: VittyLogoConfig.logoWidth,
                        height: VittyLogoConfig.vittyTextHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Hindi text with same height
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
}

// ✅ Helper extension for fire-and-forget operations
extension UnawaiteExtension on Future {
  void get unawaited => {};
}


