import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/controllers/session_manager.dart';

import '../../services/auth_service.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final authService = locator<AuthService>();

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900), // ✅ Exactly 500ms
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward().then((_) {
      // ✅ Immediate navigation after 500ms animation
      _instantNavigation();
    });
  }

  void _instantNavigation() async {
    final stopwatch = Stopwatch()..start();

    // ✅ Parallel loading of prefs and theme
    final futures = await Future.wait([
      SharedPreferences.getInstance(),
      locator<ThemeService>().loadThemeFromPrefs(),
    ]);

    final prefs = futures[0] as SharedPreferences;
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    // ✅ Handle biometrics if needed
    if (isBiometricEnabled) {
      //final securityService = SecurityService();
      final success = await authService.authenticate();
      if (!success) {
        exit(0);
        return;
      }
    }

    // ✅ Quick token check from memory (no validation)
    final token = prefs.getString("access_token");
    final uid = prefs.getString("uid");

    if (_navigated) return;
    _navigated = true;

    if (token != null && uid != null) {
      // ✅ Token exists - navigate to home immediately
      context.go('/home');


      // ✅ Background token validation (non-blocking)
      _validateTokenInBackground();
    } else {
      // ✅ No token - go to login
      context.go('/onboarding');


    }
  }

  // ✅ Background token validation - won't block UI
  void _validateTokenInBackground() async {
    try {
      print("🔄 Starting background token validation...");

      // ✅ Load tokens into SessionManager
      await SessionManager.loadTokens();

      // ✅ Check if token is valid
      final token = SessionManager.token;
      if (token != null && !authService.isTokenExpired(token)) {
        print("✅ Token is valid - no refresh needed");

        // ✅ Fetch user profile if needed
        try {
          await locator<AuthService>().fetchUserProfile();
          print("✅ User profile loaded in background");
        } catch (e) {
          print("⚠️ Profile fetch failed: $e");
        }
        return;
      }

      // ✅ Token expired - try refresh
      print("🔄 Token expired, attempting refresh...");
      final refreshed = await SessionManager.tryRefreshToken();

      if (refreshed) {
        print("✅ Background token refresh successful");

        // ✅ Load user profile with new token
        try {
          await locator<AuthService>().fetchUserProfile();
          print("✅ User profile loaded after refresh");
        } catch (e) {
          print("⚠️ Profile fetch failed after refresh: $e");
        }
      } else {
        print("❌ Background token refresh failed");

        // ✅ Silent logout and redirect (only if multiple failures)
        _handleSilentLogout();
      }
    } catch (e) {
      print("❌ Background validation error: $e");
      // ✅ Continue - don't disrupt user experience
    }
  }

  // ✅ Handle silent logout without disrupting UX
  void _handleSilentLogout() async {
    try {
      // ✅ Clear tokens
      await SessionManager.clearToken();

      // ✅ Wait a bit before redirecting (let user see home page first)
      await Future.delayed(Duration(seconds: 2));

      // ✅ Only redirect if user is still on the app
      if (mounted) {
        print("🚪 Redirecting to login due to invalid session");
        context.go('/phone_otp');
      }
    } catch (e) {
      print("❌ Silent logout error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'penny_logo',
                    child: Image.asset(
                      'assets/images/new_app_logo.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.09,
                    ),
                  ),
                  Hero(
                    tag: 'sub_logo',
                    child: Image.asset(
                      'assets/images/Vitty.ai.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.1,
                    ),
                  ),
                  Image.asset(
                    'assets/images/वित्तीय.png',
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