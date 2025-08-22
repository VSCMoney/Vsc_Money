import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vscmoney/core/helpers/themes.dart';

import '../../../constants/colors.dart';
import '../../../constants/vitty_loader.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../widgets/auth_button.dart';
import 'otp_screen.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = locator<AuthService>();

  late StreamSubscription<AuthState> _stateSub;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _stateSub = _authService.authStateStream.listen((state) {
      if (!mounted) return;
      setState(() => isLoading = state.status == AuthStatus.loading);

      if (state.status == AuthStatus.error && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }


  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _stateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Scaffold(
      backgroundColor: theme.background,
      body:   isLoading
          ?
      VIttyLoader(theme: theme)
          :SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.09),
                  Hero(
                    tag: 'penny_logo',
                    child: Image.asset(
                      'assets/images/auth.png',
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.1,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.07),
                  Text(
                    "Your AI Financial Consultant",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Inter",
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.010),
                  Text(
                    "Super Intelligent. Bias Free. Always Available.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SF Pro Text',
                      color: theme.text,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Container(

                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: Offset(0, 0), // ⬅️ shadow equally in all directions
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20, bottom: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          googleSignIn(context),
                          const SizedBox(height: 16),
                          AuthButton(
                            icon: const Icon(Icons.apple, color: Colors.black, size: 24),
                            label: 'Continue with Apple',
                            onTap: () async {
                              context.go('/enter_name');
                            },
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),

                    SizedBox(height: screenHeight * 0.3),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontFamily: 'SF Pro Text',
                          color: theme.text.withOpacity(0.7),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: "By continuing, you agree to our "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              color: Color(0xFFFF8A00),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: Color(0xFFFF8A00),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  AuthButton googleSignIn(BuildContext context) {
    return AuthButton(
                    icon: Image.asset('assets/images/Group 10.png', height: 18),
                    label: 'Continue with Google',
                    onTap: () async {
                      await locator<AuthService>().handleGoogleSignIn((flow) {
                        if (!mounted) return;
                        if (flow == AuthFlow.home) {
                          context.go('/home');
                        } else if (flow == AuthFlow.nameEntry) {
                          context.go('/enter_name');
                        }
                      });
                    },
                  );
  }
}




