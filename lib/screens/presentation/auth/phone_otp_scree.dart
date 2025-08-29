import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vscmoney/core/helpers/themes.dart';

import '../../../constants/colors.dart';
import '../../../constants/vitty_loader.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../widgets/auth_button.dart';
import 'otp_screen.dart';

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = locator<AuthService>();
  static const String privacyPolicyUrl = 'https://vitty-legal.github.io/vitty-privacy/';



  late StreamSubscription<AuthState> _stateSub;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _stateSub = _authService.authStateStream.listen((state) {
      if (!mounted) return;
      setState(() => isLoading = state.status == AuthStatus.loading);

      if (state.status == AuthStatus.error && state.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }



  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView, // Opens in-app browser
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ),
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    // Collapse Apple section + its spacers on Android/Web
    final bool showApple = !kIsWeb && Platform.isIOS;

    return Scaffold(
      backgroundColor: theme.background,
      body: isLoading
          ? VIttyLoader(theme: theme)
          : Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: screenHeight * 0.3),
              Hero(
                tag: 'penny_logo',
                child: Image.asset(
                  'assets/images/ying yang full.png',
                  width: screenWidth * 0.80,
                  height: screenHeight * 0.2,
                ),
              ),
              SizedBox(height: screenHeight * 0.2),
              Container(
                height: showApple ? 250 : 160,
                decoration: BoxDecoration(
                  color: theme.box,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 30, left: 20, right: 20, bottom: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google
                      googleSignIn(context),

                      // Apple only on iOS, including its own spacer
                      if (showApple) ...[
                        const SizedBox(height: 16),
                        AuthButton(
                          icon: const Icon(Icons.apple,
                              color: Colors.black, size: 24),
                          label: 'Continue with Apple',
                          onTap: () async {
                            await locator<AuthService>()
                                .handleAppleSignIn((flow) {
                              if (!mounted) return;
                              if (flow == AuthFlow.home) {
                                context.go('/home');
                              } else if (flow == AuthFlow.nameEntry) {
                                context.go('/enter_name');
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 25),
                      ] else ...[
                        // Minimal spacing between Google and Terms on Android/Web
                        const SizedBox(height: 8),
                      ],

                      // Terms & Privacy
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                              fontFamily: 'SF Pro',
                              color: theme.text.withOpacity(0.7),
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                  text: "By continuing, you agree to our "),
                              TextSpan(
                                text: "Terms & Conditions",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl(privacyPolicyUrl),
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl(privacyPolicyUrl),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
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




