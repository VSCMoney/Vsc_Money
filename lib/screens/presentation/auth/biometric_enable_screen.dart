import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/widgets/common_button.dart';

import '../../../constants/colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';


final locator = GetIt.I;

class BiometricEnableScreen extends StatefulWidget {
  const BiometricEnableScreen({Key? key, required this.nextRoute}) : super(key: key);
  final String nextRoute;

  @override
  State<BiometricEnableScreen> createState() => _BiometricEnableScreenState();
}

class _BiometricEnableScreenState extends State<BiometricEnableScreen> {
  final _auth = locator<AuthService>();
  final _theme = locator<ThemeService>();
  bool _busy = false;

  Future<void> _enableBiometric() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _busy = true);

    try {
      final ok = await _auth.authenticate();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Try again.')),
          );
          setState(() => _busy = false);
        }
        return;
      }

      await _auth.toggleBiometric(true, context);

      // ✅ navigate using our own (fresh) context
      if (!mounted) return;
      context.go(widget.nextRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enabling biometrics: $e')),
      );
      setState(() => _busy = false);
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    context.go(widget.nextRoute);

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;
    final isIOS = Platform.isIOS;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme?.background ?? const Color(0xFFFAF7F1),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 306),

            // top icon (aap apni asset laga do)
            isIOS
                ? SvgPicture.asset("assets/images/face_id.svg", height: 72)
                : Icon(Icons.fingerprint, size: 72, color: AppColors.primary),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Your Privacy Matters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans', fontWeight: FontWeight.w500,
                  fontSize: 25, height: 1.15, color: AppColors.black,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                isIOS
                    ? 'Your Face ID data is never shared\nAuthentication happens securely on your device.'
                    : 'Your biometric data is never shared\nAuthentication happens securely on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans', fontWeight: FontWeight.w300,
                  fontSize: 15, height: 1.35, color: theme?.text,
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CommonButton(
                onPressed: _busy ? null : _enableBiometric,
                label: isIOS ? 'Enable Face ID' : 'Enable Biometrics',
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _busy ? null : _skip,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 14,
                  fontWeight: FontWeight.w500, color: theme?.text,
                ),
              ),
            ),

            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

