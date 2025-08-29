import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/controllers/session_manager.dart';

import '../../constants/app_bar.dart';
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

    // ✅ Animate to the SAME final angle used by the AppBar
    _rotationAnimation = Tween<double>(begin: 0.0, end: kLogoFinalAngle).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) {
      _handleNavigation();
    });
  }

  void _handleNavigation() async {
    if (_navigated) return;

    try {
      final futures = await Future.wait([
        SharedPreferences.getInstance(),
        locator<ThemeService>().loadThemeFromPrefs(),
      ]);
      final prefs = futures[0] as SharedPreferences;

      // Biometrics
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (isBiometricEnabled) {
        final success = await authService.authenticate();
        if (!success) {
          exit(0);
          return;
        }
      }

      // Quick token check
      final token = prefs.getString("access_token");
      final uid = prefs.getString("uid");

      if (token != null && uid != null) {
        // Rotate once, then go home
        await _rotationController.forward();
        _navigateToRoute('/home');
        _validateTokenInBackground();
        return;
      }

      // No valid session
      await _determineFlowForUnauthenticatedUser();
    } catch (e) {
      debugPrint('Error in splash navigation: $e');
      await _determineFlowForUnauthenticatedUser();
    }
  }

  Future<void> _determineFlowForUnauthenticatedUser() async {
    try {
      await authService.determineInitialFlow((flow) async {
        if (!mounted || _navigated) return;

        final route = switch (flow) {
          AuthFlow.onboarding => '/onboarding',
          AuthFlow.login => '/phone_otp',
          AuthFlow.nameEntry => '/enter_name',
          AuthFlow.home => '/home',
        };

        // Rotate only if we’re going home
        if (route == '/home') {
          await _rotationController.forward();
        }

        debugPrint('Splash navigating to: $route (flow: $flow)');
        _navigateToRoute(route);
      });
    } catch (e) {
      debugPrint('Error determining flow from splash: $e');
      final onboardingCompleted = await authService.isOnboardingCompleted();
      final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';
      _navigateToRoute(fallbackRoute);
    }
  }

  void _navigateToRoute(String route) {
    if (_navigated) return;
    _navigated = true;
    if (mounted) context.go(route);
  }

  void _validateTokenInBackground() async {
    try {
      await SessionManager.loadTokens();
      final token = SessionManager.token;

      if (token != null && !authService.isTokenExpired(token)) {
        try {
          await locator<AuthService>().fetchUserProfile();
        } catch (_) {}
        return;
      }

      final refreshed = await SessionManager.tryRefreshToken();
      if (refreshed) {
        try {
          await locator<AuthService>().fetchUserProfile();
        } catch (_) {}
      } else {
        await SessionManager.clearToken();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/phone_otp');
      }
    } catch (e) {
      debugPrint("Background validation error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _rotationController]),
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Splash rotates to kLogoFinalAngle
                  Hero(
                    tag: 'penny_logo',
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Image.asset(
                        'assets/images/ying yang.png',
                        width: screenWidth * 0.4,
                        height: screenHeight * 0.09,
                      ),
                    ),
                  ),
                  Hero(
                    tag: 'sub_logo',
                    child: Image.asset(
                      'assets/images/Vitty.ai2.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.1,
                    ),
                  ),
                  Image.asset(
                    'assets/images/वित्तीय2.png',
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.020,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacityAnimation;
//   late Animation<double> _scaleAnimation;
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
//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
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
//       // ✅ Load theme and prefs in parallel
//       final futures = await Future.wait([
//         SharedPreferences.getInstance(),
//         locator<ThemeService>().loadThemeFromPrefs(),
//       ]);
//
//       final prefs = futures[0] as SharedPreferences;
//
//       // ✅ Handle biometrics if enabled
//       final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
//       if (isBiometricEnabled) {
//         final success = await authService.authenticate();
//         if (!success) {
//           exit(0);
//           return;
//         }
//       }
//
//       // ✅ Quick token check for immediate home navigation
//       final token = prefs.getString("access_token");
//       final uid = prefs.getString("uid");
//
//       if (token != null && uid != null) {
//         // ✅ User has valid session - go straight to home
//         _navigateToRoute('/home');
//
//         // ✅ Background token validation (non-blocking)
//         _validateTokenInBackground();
//         return;
//       }
//
//       // ✅ No valid session - use proper flow determination
//       await _determineFlowForUnauthenticatedUser();
//
//     } catch (e) {
//       debugPrint('❌ Error in splash navigation: $e');
//       // ✅ Fallback to proper flow determination
//       await _determineFlowForUnauthenticatedUser();
//     }
//   }
//
//   // ✅ Use AuthService logic for unauthenticated users
//   Future<void> _determineFlowForUnauthenticatedUser() async {
//     try {
//       await authService.determineInitialFlow((flow) {
//         if (!mounted || _navigated) return;
//
//         final route = switch (flow) {
//           AuthFlow.onboarding => '/onboarding',
//           AuthFlow.login => '/phone_otp',
//           AuthFlow.nameEntry => '/enter_name',
//           AuthFlow.home => '/home',
//         };
//
//         debugPrint('🚀 Splash navigating to: $route (flow: $flow)');
//         _navigateToRoute(route);
//       });
//     } catch (e) {
//       debugPrint('❌ Error determining flow from splash: $e');
//
//       // ✅ Safe fallback - check onboarding status
//       final onboardingCompleted = await authService.isOnboardingCompleted();
//       final fallbackRoute = onboardingCompleted ? '/phone_otp' : '/onboarding';
//       _navigateToRoute(fallbackRoute);
//     }
//   }
//
//   // ✅ Safe navigation with duplicate check
//   void _navigateToRoute(String route) {
//     if (_navigated) return;
//     _navigated = true;
//
//     if (mounted) {
//       context.go(route);
//     }
//   }
//
//   // ✅ Background token validation - won't block UI (unchanged)
//   void _validateTokenInBackground() async {
//     try {
//       print("🔄 Starting background token validation...");
//
//       await SessionManager.loadTokens();
//       final token = SessionManager.token;
//
//       if (token != null && !authService.isTokenExpired(token)) {
//         print("✅ Token is valid - no refresh needed");
//
//         try {
//           await locator<AuthService>().fetchUserProfile();
//           print("✅ User profile loaded in background");
//         } catch (e) {
//           print("⚠️ Profile fetch failed: $e");
//         }
//         return;
//       }
//
//       print("🔄 Token expired, attempting refresh...");
//       final refreshed = await SessionManager.tryRefreshToken();
//
//       if (refreshed) {
//         print("✅ Background token refresh successful");
//
//         try {
//           await locator<AuthService>().fetchUserProfile();
//           print("✅ User profile loaded after refresh");
//         } catch (e) {
//           print("⚠️ Profile fetch failed after refresh: $e");
//         }
//       } else {
//         print("❌ Background token refresh failed");
//         _handleSilentLogout();
//       }
//     } catch (e) {
//       print("❌ Background validation error: $e");
//     }
//   }
//
//   // ✅ Handle silent logout without disrupting UX (unchanged)
//   void _handleSilentLogout() async {
//     try {
//       await SessionManager.clearToken();
//       await Future.delayed(Duration(seconds: 2));
//
//       if (mounted) {
//         print("🚪 Redirecting to login due to invalid session");
//         context.go('/phone_otp');
//       }
//     } catch (e) {
//       print("❌ Silent logout error: $e");
//     }
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
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _controller,
//           builder: (context, child) => Opacity(
//             opacity: _opacityAnimation.value,
//             child: Transform.scale(
//               scale: _scaleAnimation.value,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Hero(
//                     tag: 'penny_logo',
//                     child: Image.asset(
//                       'assets/images/ying yang.png',
//                       width: screenWidth * 0.4,
//                       height: screenHeight * 0.09,
//                     ),
//                   ),
//                   Hero(
//                     tag: 'sub_logo',
//                     child: Image.asset(
//                       'assets/images/Vitty.ai2.png',
//                       width: screenWidth * 0.4,
//                       height: screenHeight * 0.1,
//                     ),
//                   ),
//                   Image.asset(
//                     'assets/images/वित्तीय2.png',
//                     width: screenWidth * 0.2,
//                     height: screenHeight * 0.020,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }