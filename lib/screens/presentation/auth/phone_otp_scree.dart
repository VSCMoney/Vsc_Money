import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vscmoney/core/helpers/themes.dart';

import '../../../constants/app_bar.dart';
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

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = locator<AuthService>();

  late StreamSubscription<AuthState> _stateSub;
  bool isLoading = false;

  late final AnimationController _optionsCtrl;
  late final Animation<double> _optionsOpacity;
  late final Animation<Offset> _optionsSlide;

  static const String privacyPolicyUrl = 'https://vitty-legal.github.io/vitty-privacy/';

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

    _optionsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _optionsOpacity = CurvedAnimation(
      parent: _optionsCtrl,
      curve: Curves.easeOut,
    );

    _optionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _optionsCtrl,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _optionsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _stateSub.cancel();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final bool showApple = !kIsWeb && Platform.isIOS;

    return Scaffold(
      backgroundColor: theme.background,
      body: isLoading
          ? VIttyLoader(theme: theme)
          : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: screenHeight * 0.25),

          // ✅ SMALLER LOGO - Reduced size
          SizedBox(
            width: 200,  // Reduced from VittyLogoConfig.logoWidth
            height: 200, // Reduced from VittyLogoConfig.logoHeight
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ HERO with smaller dimensions
                Hero(
                  tag: 'penny_logo',
                  transitionOnUserGestures: true,
                  child: Image.asset(
                    'assets/images/ying yang.png',
                    width: 150,   // Reduced logo size
                    height: 90,  // Reduced logo size
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 4), // Small gap

                Image.asset(
                  'assets/images/Vitty.ai2.png',
                  width: 140,  // Reduced text width
                  height: 58,  // Reduced text height
                  fit: BoxFit.contain,
                ),

                Image.asset(
                  'assets/images/वित्तीय2.png',
                  width: 120,  // Reduced text width
                  height: 20,  // Reduced text height
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.15),

          // Animated options card (unchanged)
          FadeTransition(
            opacity: _optionsOpacity,
            child: SlideTransition(
              position: _optionsSlide,
              child: Container(
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
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      googleSignIn(context),

                      if (showApple) ...[
                        const SizedBox(height: 20),
                        AuthButton(
                          icon: Image.asset('assets/images/apple.png', height: 20),
                          label: 'Continue with Apple',
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await locator<AuthService>().handleAppleSignIn((flow) {
                              if (!mounted) return;
                              if (flow == AuthFlow.home) {
                                context.go('/home');
                              } else if (flow == AuthFlow.nameEntry) {
                                context.go('/enter_name');
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                              fontFamily: 'DM Sans',
                              color: theme.text.withOpacity(0.7),
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: "By continuing, you agree to our "),
                              TextSpan(
                                text: "Terms & Conditions",
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    fontFamily: "DM Sans"
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
                                    fontFamily: "DM Sans"
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
            ),
          ),
        ],
      ),
    );
  }

  AuthButton googleSignIn(BuildContext context) {
    return AuthButton(
      icon: Image.asset('assets/images/Group 10.png', height: 20),
      label: 'Continue with Google',
      onTap: () async {
        HapticFeedback.mediumImpact();
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

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}





