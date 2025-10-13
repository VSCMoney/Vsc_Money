import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:vscmoney/screens/widgets/common_button.dart';

import '../../../constants/colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';


final locator = GetIt.I;

class BiometricEnableScreen extends StatefulWidget {
  const BiometricEnableScreen({
    Key? key,
    required this.onDone, // navigate to next screen
  }) : super(key: key);

  final VoidCallback onDone;

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
    setState(() => _busy = true);

    try {
      // 1) Ask the system to authenticate (your service already wraps this)
      final ok = await _auth.authenticate(); // or requestBiometricPermission()
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Try again.')),
          );
        }
        setState(() => _busy = false);
        return;
      }

      // 2) Persist “biometric enabled” in your service/prefs
      await _auth.toggleBiometric(true, context);

      // 3) Done → next screen
      widget.onDone();
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
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;
    final isIOS = Platform.isIOS;
    final title = 'Your Privacy Matters';
    final subtitle = isIOS
        ? 'Your Face ID data is never shared\nAuthentication happens securely on your device.'
        : 'Your biometric data is never shared\nAuthentication happens securely on your device.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _theme.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme?.background ?? const Color(0xFFFAF7F1),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 236),

            // Top icon (you said you’ll put the image)
            // Put your FaceID / Fingerprint PNG/SVG here
            // Example placeholders:
          isIOS? SvgPicture.asset("assets/images/face_id.svg"):  Icon(
              Icons.fingerprint,
              size: 72,
              color: AppColors.primary,
            ),

            const SizedBox(height: 24),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
                  height: 1.15,
                  color: AppColors.black,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w300,
                  fontSize: 15,
                  height: 1.35,
                  color: theme?.text,
                ),
              ),
            ),

            const Spacer(),

            // Continue button
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 24),
            //   child: SizedBox(
            //     height: 56,
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: _busy ? null : _enableBiometric,
            //       style: ElevatedButton.styleFrom(
            //         elevation: 0,
            //         backgroundColor: AppColors.primary,
            //         foregroundColor: Colors.white,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(16),
            //         ),
            //         textStyle: const TextStyle(
            //           fontFamily: 'DM Sans',
            //           fontWeight: FontWeight.w700,
            //           fontSize: 18,
            //         ),
            //       ),
            //       child: _busy
            //           ? const CupertinoActivityIndicator()
            //           : Text(isIOS ? 'Enable Face ID' : 'Enable Biometrics'),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CommonButton(

                onPressed:_busy ? null : _enableBiometric ,
                 label: isIOS ? 'Enable Face ID' : 'Enable Biometrics',
              ),
            ),

            const SizedBox(height: 12),

            // Skip for now
            TextButton(
              onPressed: _busy ? null : _skip,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme?.text,
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
