import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vscmoney/chat_message_row_widget.dart';
import 'package:vscmoney/constants/bottomsheet.dart';
import 'package:vscmoney/constants/chat_typing_indicator.dart';
import 'package:vscmoney/constants/colors.dart';
import 'package:vscmoney/constants/widgets.dart';
import 'package:vscmoney/screens/presentation/home/chat_screen.dart';
import 'package:vscmoney/services/asset_service.dart';
import 'package:vscmoney/services/chat_service.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/services/theme_service.dart';
import 'package:vscmoney/user_message_widget.dart';

import 'bot_response_widget.dart';
import 'input_field_widget.dart';
import 'models/asset_model.dart';
import 'models/chat_message.dart';
import 'models/chat_session.dart';

class PremiumAccessScreen extends StatefulWidget {
  const PremiumAccessScreen({Key? key}) : super(key: key);

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen> {

  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return ChatGPTBottomSheetWrapper(
      key: _sheetKey,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(height: 60),

              // Logo
              Container(
                width: 40,
                height: 40,
                child: Image.asset("assets/images/ying yang.png"),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Full Access Unlocked\nFor 21 Days!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: theme.text,
                  height: 1.2,
                  fontFamily: "DM Sans"
                ),
              ),

              SizedBox(height: 16),

              // Subtitle
              Text(
                'Enjoy full access to your AI financial consultant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),

              SizedBox(height: 30),

              // Features List
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    FeatureItem(
                      icon: Icons.track_changes,
                      iconColor: Color(0xFFFF6B35),
                      title: 'Smart Goal Planning',
                      description:
                          'Unlock powerful tools to define, plan, and track what truly matters to you.',
                    ),

                    SizedBox(height: 32),

                    FeatureItem(
                      icon: Icons.insights,
                      iconColor: Color(0xFFFF6B35),
                      title: 'Deeper Wealth Insights',
                      description:
                          'Access personalised financial insights to grow faster and make informed decisions.',
                    ),

                    SizedBox(height: 32),

                    FeatureItem(
                      icon: Icons.chat_bubble_outline,
                      iconColor: Color(0xFFFF6B35),
                      title: '50 Prompts Per Day',
                      description:
                          'Ask up to 50 questions daily to gain deeper clarity and guidance from your AI advisor.',
                    ),

                    SizedBox(height: 32),

                    FeatureItem(
                      icon: Icons.tune,
                      iconColor: Color(0xFFFF6B35),
                      title: 'Tailored Experience',
                      description:
                          'Customise the app to match your financial needs and preferences.',
                    ),
                  ],
                ),
              ),

              //  SizedBox(height: 14),
              Divider(thickness: 0.1, color: Colors.black),

              // Bottom text
              Text(
                'Enjoy 21 days of full access—upgrade anytime to keep going with your AI advisor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),

              SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Home indicator
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Icon(icon, color: iconColor, size: 20),
        ),

        SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),

              SizedBox(height: 4),

              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                  fontFamily: "DM Sans",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppleSignInButtonWidget extends StatelessWidget {
  const AppleSignInButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SignInWithAppleButton(
          onPressed: () async {
            try {
              final userCred = await AppleSignInService().signInWithApple();
              final user = userCred.user;
              if (user != null) {
                print("✅ Firebase UID: ${user.uid}");
                print("📧 Email: ${user.email}");
              }
            } catch (e) {
              print("❌ Apple sign-in failed: $e");
            }
          },
          style: SignInWithAppleButtonStyle.black,
          height: 50,
        ),
      ),
    );
  }
}

class AppleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Return the sha256 hash of [input]
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Decode the JWT identity token to inspect payload
  void decodeIdentityToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      print("❌ Invalid JWT format");
      return;
    }

    final header = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );

    print("🧩 JWT Header: $header");
    print("📦 JWT Payload: $payload");
  }

  /// Main Apple Sign-In function
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    // Step 1: Request Apple ID Credential
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: 'com.ai.vitty.signin', // ✅ FIX — THIS PASSES YOUR SERVICE ID
        redirectUri: Uri.parse(
          'https://mystic-primacy-455711-q3.firebaseapp.com/__/auth/handler',
        ),
      ),
    );

    final idToken = appleCredential.identityToken;

    print("🔑 Apple identityToken length: ${idToken?.length}");
    print("🧬 Apple userIdentifier: ${appleCredential.userIdentifier}");
    print("🧪 Email: ${appleCredential.email}");
    print("🧬 rawNonce used: $rawNonce");

    if (idToken == null) {
      throw StateError("Apple identityToken is null");
    }

    decodeIdentityToken(idToken); // 🔍 Log decoded JWT

    // Step 2: Create Firebase OAuth Credential
    final oauthCredential = OAuthProvider(
      "apple.com",
    ).credential(idToken: idToken, rawNonce: rawNonce);

    // Step 3: Firebase Sign-In
    return await _auth.signInWithCredential(oauthCredential);
  }
}

class ImprovedAppleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = 'http://127.0.0.1:8000';

  // Generate nonce for Apple Sign-In security
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA256 hash for nonce
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 🔍 Debug method to check configuration
  Future<void> debugConfiguration() async {
    try {
      print('🔍 === APPLE SIGN-IN DEBUG INFO ===');

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      print('✅ Apple Sign-In Available: $isAvailable');

      if (!isAvailable) {
        print('❌ Apple Sign-In not supported on this device/simulator');
        return;
      }

      // Try to get Apple credential without Firebase
      print('🔍 Testing Apple credential request...');
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('✅ Apple credential received successfully:');
      print('   User ID: ${appleCredential.userIdentifier}');
      print('   Email: ${appleCredential.email ?? "Not provided"}');
      print('   Given Name: ${appleCredential.givenName ?? "Not provided"}');
      print('   Family Name: ${appleCredential.familyName ?? "Not provided"}');
      print(
        '   Identity Token Length: ${appleCredential.identityToken?.length ?? 0}',
      );
      print(
        '   Authorization Code Length: ${appleCredential.authorizationCode?.length ?? 0}',
      );

      // Try Firebase authentication
      print('🔍 Testing Firebase authentication...');
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      print('✅ OAuth credential created successfully');
      print('   Provider ID: ${oauthCredential.providerId}');
      print('   Sign-in method: ${oauthCredential.signInMethod}');
    } catch (e) {
      print('❌ Debug failed: $e');
      if (e is FirebaseAuthException) {
        print('   Error Code: ${e.code}');
        print('   Error Message: ${e.message}');
      }
    }
  }

  // 🍎 Improved Apple Sign-In Method with detailed logging
  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      print('🍎 Starting Apple Sign-In process...');

      // Step 1: Check availability
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In not available on this device');
      }
      print('✅ Apple Sign-In is available');

      // Step 2: Generate nonce
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      print('✅ Generated secure nonce');

      // Step 3: Request Apple Sign-In
      print('🔍 Requesting Apple credentials...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      print('✅ Apple credential received');
      print('   User ID: ${appleCredential.userIdentifier}');
      print('   Has Identity Token: ${appleCredential.identityToken != null}');

      // Step 4: Create Firebase OAuth credential
      print('🔍 Creating Firebase OAuth credential...');
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
      print('✅ OAuth credential created');

      // Step 5: Sign in to Firebase
      print('🔍 Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase returned null user');
      }

      print('✅ Firebase sign-in successful');
      print('   User UID: ${user.uid}');
      print('   Email: ${user.email ?? "Not provided"}');
      print('   Display Name: ${user.displayName ?? "Not provided"}');

      // Step 6: Get Firebase ID token
      print('🔍 Getting Firebase ID token...');
      final idToken = await user.getIdToken(true); // Force refresh
      print('✅ Firebase ID token obtained');

      // Step 7: Send to backend
      print('🔍 Sending to backend...');
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify_apple_user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      print('📡 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Backend verification successful');
        return {'success': true, 'data': data, 'user': user};
      } else {
        print('❌ Backend verification failed: ${response.body}');
        throw Exception('Backend verification failed: ${response.body}');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      print('❌ Apple Authorization Error:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      return {
        'success': false,
        'error': 'Apple authorization failed: ${e.message}',
        'errorCode': e.code.toString(),
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.toString()}');

      // Specific handling for invalid-credential
      if (e.code == 'invalid-credential') {
        print('🔧 INVALID CREDENTIAL DETECTED:');
        print(
          '   This usually means Firebase Apple provider is not configured correctly',
        );
        print('   Check: Service ID in Firebase = Bundle Identifier in Xcode');
        print('   Check: Apple Team ID, Key ID, and Private Key in Firebase');
      }

      return {
        'success': false,
        'error': 'Firebase authentication failed: ${e.message}',
        'errorCode': e.code,
      };
    } catch (e) {
      print('❌ General Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if Apple Sign-In is available
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }
}

// 🎨 Debug Apple Sign-In Button Widget
class DebugAppleSignInButton extends StatefulWidget {
  final Function(Map<String, dynamic>) onSignInSuccess;
  final Function(String) onSignInError;

  const DebugAppleSignInButton({
    Key? key,
    required this.onSignInSuccess,
    required this.onSignInError,
  }) : super(key: key);

  @override
  _DebugAppleSignInButtonState createState() => _DebugAppleSignInButtonState();
}

class _DebugAppleSignInButtonState extends State<DebugAppleSignInButton> {
  final ImprovedAppleSignInService _appleService = ImprovedAppleSignInService();
  bool _isLoading = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  void _checkAvailability() async {
    try {
      final available = await _appleService.isAppleSignInAvailable();
      if (mounted) {
        setState(() {
          _isAvailable = available;
        });
      }
    } catch (e) {
      print('Error checking Apple availability: $e');
    }
  }

  void _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _appleService.signInWithApple();

      if (result != null && result['success'] == true) {
        widget.onSignInSuccess(result['data']);
      } else {
        final error = result?['error'] ?? 'Apple Sign-In failed';
        widget.onSignInError(error);
      }
    } catch (e) {
      widget.onSignInError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _runDebugTest() async {
    print('🔧 Running Apple Sign-In debug test...');
    await _appleService.debugConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isAvailable) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Apple Sign-In not available on this device',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Main Apple Sign-In Button
        if (_isAvailable)
          SignInWithAppleButton(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            text: _isLoading ? 'Signing in...' : 'Sign in with Apple',
            height: 50,
            style: SignInWithAppleButtonStyle.black,
          ),

        SizedBox(height: 16),

        // Debug Controls
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Debug Controls',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _runDebugTest,
                  child: Text('Run Debug Test'),
                ),
                SizedBox(height: 8),
                Text(
                  'Check console logs for detailed information',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 📱 Test Screen
class AppleSignInDebugScreen extends StatelessWidget {
  void _onAppleSignInSuccess(Map<String, dynamic> data) {
    print('🎉 SUCCESS: $data');
  }

  void _onAppleSignInError(String error) {
    print('💥 ERROR: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apple Sign-In Debug')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Apple Sign-In Debug Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            DebugAppleSignInButton(
              onSignInSuccess: _onAppleSignInSuccess,
              onSignInError: _onAppleSignInError,
            ),

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Troubleshooting Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Run debug test and check console'),
                  Text('2. Verify Firebase Apple provider config'),
                  Text('3. Check bundle identifier matches'),
                  Text('4. Ensure Xcode has Apple Sign-In capability'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




















//
// class AnimatedOrb extends StatefulWidget {
//   const AnimatedOrb({
//     super.key,
//     this.size = 64.0,
//     this.backgroundColors = const [
//       Color(0xFF814ACD), // purple for base glow
//       Color(0xFFFC5CF5), // pink for base glow
//     ],
//     this.orbColors = const [
//       Color(0xFFFC5CF5), // pink inside the orb
//       Color(0xFF814ACD), // purple at the edge of the orb
//     ],
//     this.duration = const Duration(seconds: 6),
//   });
//
//   final double size;
//   final List<Color> backgroundColors;
//   final List<Color> orbColors;
//   final Duration duration;
//
//   @override
//   State<AnimatedOrb> createState() => _AnimatedOrbState();
// }
//
// class _AnimatedOrbState extends State<AnimatedOrb>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     // AnimationController produces values between 0 and 1 during its duration:contentReference[oaicite:2]{index=2}.
//     _controller = AnimationController(vsync: this, duration: widget.duration)
//       ..repeat(); // loop forever
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
//     final double baseSize = widget.size;
//     final double orbSize = baseSize * 0.6;
//
//     return SizedBox(
//       width: baseSize,
//       height: baseSize,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // 1. Static diffused circle (the glow).
//           Container(
//             width: baseSize,
//             height: baseSize,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               // A radial gradient can specify its centre and radius in fractions:contentReference[oaicite:3]{index=3}.
//               gradient: RadialGradient(
//                 center: Alignment.center,
//                 radius: 0.9,
//                 colors: [
//                   widget.backgroundColors[0].withOpacity(0.3),
//                   widget.backgroundColors[1].withOpacity(0.3),
//                   Colors.transparent,
//                 ],
//                 stops: const [0.0, 0.6, 1.0],
//               ),
//               // Box shadows create the soft edges of the diffused glow.
//               boxShadow: [
//                 BoxShadow(
//                   color: widget.backgroundColors[0].withOpacity(0.5),
//                   blurRadius: baseSize * 0.6,
//                   spreadRadius: baseSize * 0.1,
//                 ),
//                 BoxShadow(
//                   color: widget.backgroundColors[1].withOpacity(0.5),
//                   blurRadius: baseSize * 0.6,
//                   spreadRadius: baseSize * 0.1,
//                 ),
//               ],
//             ),
//           ),
//           // 2. Animated orb on top.
//           AnimatedBuilder(
//             animation: _controller,
//             builder: (_, __) {
//               // Compute an angle from 0 to 2π based on the controller value.
//               final double angle = _controller.value * 2 * math.pi;
//               // Move the gradient’s centre around a circle (0.0–1.0 range).
//               final double dx = 0.35 * math.cos(angle);
//               final double dy = 0.35 * math.sin(angle);
//               return Container(
//                 width: orbSize,
//                 height: orbSize,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     // The animated centre causes the pink highlight to “orbit”.
//                     center: Alignment(dx, dy),
//                     radius: 0.8,
//                     colors: widget.orbColors,
//                     stops: const [0.0, 1.0],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }













class AnimatedYinYangLogo extends StatefulWidget {
  final double size;
  final Color lightColor;
  final Color darkColor;

  const AnimatedYinYangLogo({
    Key? key,
    this.size = 200.0,
    this.lightColor = Colors.white,
    this.darkColor = Colors.black,
  }) : super(key: key);

  @override
  State<AnimatedYinYangLogo> createState() => _AnimatedYinYangLogoState();
}

class _AnimatedYinYangLogoState extends State<AnimatedYinYangLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(); // Infinite rotation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: YinYangPainter(
          lightColor: widget.lightColor,
          darkColor: widget.darkColor,
        ),
      ),
    );
  }
}








class YinYangLogo extends StatelessWidget {
  final double size;
  final Color lightColor;
  final Color darkColor;

  const YinYangLogo({
    Key? key,
    this.size = 200.0,
    this.lightColor = Colors.white,
    this.darkColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: YinYangPainter(
        lightColor: lightColor,
        darkColor: darkColor,
      ),
    );
  }
}

class YinYangPainter extends CustomPainter {
  final Color lightColor;
  final Color darkColor;

  YinYangPainter({
    required this.lightColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Static positions (no animation)
    final outerCenter = center;
    final darkCenter = center;
    final upperSmallCenter = Offset(center.dx, center.dy - radius / 2);
    final lowerSmallCenter = Offset(center.dx, center.dy + radius / 2);

    // Create paints with boundary blur only
    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Simple boundary blur - just soft edges, no multiple layers
    final boundaryBlurRadius = radius * 0.10;
    final lightBlurPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, boundaryBlurRadius);

    final darkBlurPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, boundaryBlurRadius);

    // Draw outer circle background - clean with just boundary blur (WHITE ELEMENT)
    canvas.drawCircle(outerCenter, radius + boundaryBlurRadius, lightBlurPaint);
    canvas.drawCircle(outerCenter, radius, lightPaint);

    // Draw the main dark semicircle - clean with just boundary blur (BLACK ELEMENT)
    final darkSemiCirclePath = Path();
    darkSemiCirclePath.addArc(
      Rect.fromCenter(center: darkCenter, width: size.width + boundaryBlurRadius * 2, height: size.height + boundaryBlurRadius * 2),
      math.pi / 2,
      math.pi,
    );
    darkSemiCirclePath.close();
    canvas.drawPath(darkSemiCirclePath, darkBlurPaint);

    final darkSemiCircleMainPath = Path();
    darkSemiCircleMainPath.addArc(
      Rect.fromCenter(center: darkCenter, width: size.width, height: size.height),
      math.pi / 2,
      math.pi,
    );
    darkSemiCircleMainPath.close();
    canvas.drawPath(darkSemiCircleMainPath, darkPaint);

    // Draw upper small circle - clean with just boundary blur (BLACK ELEMENT)
    canvas.drawCircle(upperSmallCenter, radius / 2 + boundaryBlurRadius, darkBlurPaint);
    canvas.drawCircle(upperSmallCenter, radius / 2, darkPaint);

    // Draw lower small circle - clean with just boundary blur (WHITE ELEMENT)
    canvas.drawCircle(lowerSmallCenter, radius / 2 + boundaryBlurRadius, lightBlurPaint);
    canvas.drawCircle(lowerSmallCenter, radius / 2, lightPaint);

    // // Draw small dots - no blur, clean and simple
    // final upperDotCenter = upperSmallCenter;
    // canvas.drawCircle(upperDotCenter, radius / 6, lightPaint);
    //
    // final lowerDotCenter = lowerSmallCenter;
    // canvas.drawCircle(lowerDotCenter, radius / 6, darkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No animation, no need to repaint
  }
}

// Example usage in your app
class YinYangDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Added MaterialApp wrapper
      home: Scaffold(
        appBar: AppBar(
          title: Text('Yin Yang Logo'),
          backgroundColor: Colors.grey[200],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated yin yang - this should be moving!
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   padding: EdgeInsets.all(20),
              //   child: AnimatedYinYangLogo(),
              // ),
              // SizedBox(height: 40),
              //
              // Text(
              //   'The yin yang above should be animating!',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // SizedBox(height: 20),

              // Custom colored animated yin yang
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.blue[50],
              //     borderRadius: BorderRadius.circular(15),
              //   ),
              //   padding: EdgeInsets.all(15),
              //   child: AnimatedYinYangLogo(
              //     size: 150,
              //     lightColor: Colors.cyan[100]!,
              //     darkColor: Colors.indigo[900]!,
              //   ),
              // ),
              // SizedBox(height: 40),

              // Small animated yin yang
              AnimatedYinYangLogo(
                size: 200,
                lightColor: Color(0xFFFDBD45),
                darkColor: Color(0xffC9611A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}









class YinYangInnerSpinSphere extends StatefulWidget {
  final double size;
  final Color lightColor; // white side
  final Color darkColor;  // black side
  final Duration yinYangPeriod; // time for one full inner rotation
  final bool animate;     // turn on/off inner motion

  const YinYangInnerSpinSphere({
    super.key,
    this.size = 220,
    this.lightColor = const Color(0xFFFFFFFF),
    this.darkColor  = const Color(0xFF111114),
    this.yinYangPeriod = const Duration(seconds: 8),
    this.animate = true,
  });

  @override
  State<YinYangInnerSpinSphere> createState() => _YinYangInnerSpinSphereState();
}

class _YinYangInnerSpinSphereState extends State<YinYangInnerSpinSphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: widget.yinYangPeriod)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final angle = widget.animate ? _c.value * 2 * math.pi : 0.0;
          return CustomPaint(
            painter: _YYSphereFixedLightPainter(
              lightColor: widget.lightColor,
              darkColor: widget.darkColor,
              innerAngle: angle, // rotate ONLY the yin-yang
            ),
            size: Size.square(size),
          );
        },
      ),
    );
  }
}

class _YYSphereFixedLightPainter extends CustomPainter {
  final Color lightColor;
  final Color darkColor;
  final double innerAngle; // radians, rotation of yin-yang only

  _YYSphereFixedLightPainter({
    required this.lightColor,
    required this.darkColor,
    required this.innerAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final bigRect = Rect.fromCircle(center: c, radius: r);

    // 1) Draw the *fixed* 3D sphere lighting first (no rotation here)
    _paintSphereLighting(canvas, c, r, bigRect);

    // 2) Clip to the sphere and draw the Yin-Yang rotated INSIDE
    final circleClip = Path()..addOval(bigRect);
    canvas.save();
    canvas.clipPath(circleClip);

    // Translate to center, rotate only the pattern, translate back
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(innerAngle);
    canvas.translate(-c.dx, -c.dy);

    _paintFlatYinYang(canvas, c, r, lightColor, darkColor);

    canvas.restore(); // end inner rotation
    canvas.restore(); // end circle clip

    // 3) Optional thin rim (kept fixed)
    final rimPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.08),
          Colors.black.withOpacity(0.25),
          Colors.white.withOpacity(0.45),
        ],
        stops: const [0.05, 0.35, 0.70, 0.95],
      ).createShader(bigRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r, rimPaint);
  }

  void _paintFlatYinYang(Canvas canvas, Offset c, double r, Color light, Color dark) {
    // Classic Yin-Yang construction (no shading here)
    final baseDark = Paint()..color = dark;
    canvas.drawCircle(c, r, baseDark);

    final bigRect = Rect.fromCircle(center: c, radius: r);
    final upperPaint = Paint()..color = light;
    canvas.drawArc(bigRect, -math.pi / 2, math.pi, true, upperPaint);

    final r2 = r / 2;
    final topCenter = Offset(c.dx, c.dy - r2);
    final bottomCenter = Offset(c.dx, c.dy + r2);

    // Top lobe dark on light
    canvas.drawCircle(topCenter, r2, Paint()..color = dark);
    // Bottom lobe light on dark
    canvas.drawCircle(bottomCenter, r2, Paint()..color = light);

    // Small dots
    final dotR = r / 8;
    canvas.drawCircle(topCenter, dotR, Paint()..color = light);
    canvas.drawCircle(bottomCenter, dotR, Paint()..color = dark);
  }

  void _paintSphereLighting(Canvas canvas, Offset c, double r, Rect bigRect) {
    // Draw a neutral base to sell curvature
    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.08, -0.10),
        radius: 1.02,
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.black.withOpacity(0.12),
        ],
      ).createShader(bigRect);
    canvas.drawCircle(c, r, base);

    // Save layer so blend modes stay inside the circle
    canvas.saveLayer(bigRect.inflate(2), Paint());

    // Specular highlight (fixed top-left)
    final highlight = Paint()
      ..blendMode = BlendMode.softLight
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.8,
        colors: [Colors.white.withOpacity(0.55), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(bigRect);
    canvas.drawCircle(c, r * 1.05, highlight);

    // Rim shadow (fixed bottom-right)
    final shadow = Paint()
      ..blendMode = BlendMode.multiply
      ..shader = RadialGradient(
        center: const Alignment(0.45, 0.45),
        radius: 1.25,
        colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
        stops: const [0.35, 1.0],
      ).createShader(bigRect);
    canvas.drawRect(bigRect.inflate(3), shadow);

    // Vignette
    final vignette = Paint()
      ..blendMode = BlendMode.multiply
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.05,
        colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
        stops: const [0.65, 1.0],
      ).createShader(bigRect);
    canvas.drawRect(bigRect.inflate(3), vignette);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _YYSphereFixedLightPainter old) =>
      old.lightColor != lightColor ||
          old.darkColor != darkColor ||
          old.innerAngle != innerAngle;
}








class OrangeShadedOrb extends StatelessWidget {
  final double size;

  const OrangeShadedOrb({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: OrangeYinYangPainter(),
    );
  }
}

class OrangeYinYangPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Subtle outer glow to simulate lighting
    final glowShader = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 1.0,
      colors: [
        Colors.orange.withOpacity(0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, Paint()..shader = glowShader);

    // Main orb gradient
    final shader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: [
        Colors.orange.shade300,
        Colors.brown.shade900,
      ],
      stops: [0.1, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    final paint = Paint()..shader = shader;
    canvas.drawCircle(center, radius, paint);

    // --- YinYangPainter logic below ---
    final lightColor = Colors.orange.shade100;
    final darkColor = Colors.deepOrange.shade900;

    final outerCenter = center;
    final darkCenter = center;
    final upperSmallCenter = Offset(center.dx, center.dy - radius / 2);
    final lowerSmallCenter = Offset(center.dx, center.dy + radius / 2);

    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final boundaryBlurRadius = radius * 0.08;
    final lightBlurPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, boundaryBlurRadius);

    final darkBlurPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, boundaryBlurRadius);

    // Outer circle blurred white
    canvas.drawCircle(outerCenter, radius + boundaryBlurRadius, lightBlurPaint);
    canvas.drawCircle(outerCenter, radius, lightPaint);

    // Main dark semicircle with blur
    final darkSemiCirclePath = Path();
    darkSemiCirclePath.addArc(
      Rect.fromCenter(
        center: darkCenter,
        width: size.width + boundaryBlurRadius * 2,
        height: size.height + boundaryBlurRadius * 2,
      ),
      math.pi / 2,
      math.pi,
    );
    darkSemiCirclePath.close();
    canvas.drawPath(darkSemiCirclePath, darkBlurPaint);

    final darkSemiCircleMainPath = Path();
    darkSemiCircleMainPath.addArc(
      Rect.fromCenter(center: darkCenter, width: size.width, height: size.height),
      math.pi / 2,
      math.pi,
    );
    darkSemiCircleMainPath.close();
    canvas.drawPath(darkSemiCircleMainPath, darkPaint);

    // Upper small circle - dark with blur
    canvas.drawCircle(upperSmallCenter, radius / 2 + boundaryBlurRadius, darkBlurPaint);
    canvas.drawCircle(upperSmallCenter, radius / 2, darkPaint);

    // Lower small circle - light with blur
    canvas.drawCircle(lowerSmallCenter, radius / 2 + boundaryBlurRadius, lightBlurPaint);
    canvas.drawCircle(lowerSmallCenter, radius / 2, lightPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}









/// Demo that positions an animated orb above a prompt line.
class AnimatedOrbDemo extends StatelessWidget {
  const AnimatedOrbDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The orb itself (you can adjust size here).
            const AnimatedOrb(size: 100.0),
            const SizedBox(height: 24),
            // A simple label suggesting user interaction.
          ],
        ),
      ),
    );
  }
}








// class AnimatedOrb extends StatefulWidget {
//   final double size;
//   final Duration duration;
//
//   const AnimatedOrb({
//     super.key,
//     this.size = 34.0,
//     this.duration = const Duration(seconds: 8),
//   });
//
//   @override
//   State<AnimatedOrb> createState() => _AnimatedOrbState();
// }
//
// class _AnimatedOrbState extends State<AnimatedOrb>
//     with TickerProviderStateMixin {
//   late final AnimationController _controller1;
//   late final AnimationController _controller2;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller1 = AnimationController(
//       vsync: this,
//       duration: widget.duration,
//     )..repeat();
//
//     _controller2 = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.85).round()),
//     )..repeat();
//   }
//
//   @override
//   void dispose() {
//     _controller1.dispose();
//     _controller2.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double haloSize = widget.size * 2.2;
//
//     return SizedBox(
//       width: haloSize,
//       height: haloSize,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Outer halo
//           AnimatedBuilder(
//             animation: Listenable.merge([_controller1, _controller2]),
//             builder: (context, _) {
//               final double rotation1 = _controller1.value * 2 * math.pi;
//               final double rotation2 = _controller2.value * 2 * math.pi;
//
//               return Container(
//                 width: haloSize,
//                 height: haloSize,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     center: Alignment.center,
//                     radius: 1.0,
//                     colors: [
//                       const Color(0xFFE249FF).withOpacity(0.06),
//                       const Color(0xFF3B2DFF).withOpacity(0.04),
//                       Colors.transparent,
//                     ],
//                     stops: const [0.0, 0.5, 1.0],
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Base orb
//           Container(
//             width: widget.size,
//             height: widget.size,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white,
//             ),
//           ),
//
//           // Pink gradient region - distinct and separate
//           AnimatedBuilder(
//             animation: _controller1,
//             builder: (context, _) {
//               final double rotation = _controller1.value * 2 * math.pi;
//
//               return ClipOval(
//                 child: Container(
//                   width: widget.size,
//                   height: widget.size,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       center: Alignment(
//                         math.cos(rotation) * 0.45,
//                         math.sin(rotation) * 0.45,
//                       ),
//                       radius: 0.8,
//                       colors: [
//                         const Color(0xFFE249FF).withOpacity(0.9), // Strong pink center
//                         const Color(0xFFE249FF).withOpacity(0.7),
//                         const Color(0xFFE249FF).withOpacity(0.4),
//                         const Color(0xFFE249FF).withOpacity(0.15),
//                         const Color(0xFFE249FF).withOpacity(0.05),
//                         Colors.transparent,
//                       ],
//                       stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 1.0],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Blue gradient region - distinct and separate
//           AnimatedBuilder(
//             animation: _controller2,
//             builder: (context, _) {
//               final double rotation = _controller2.value * 2 * math.pi;
//
//               return ClipOval(
//                 child: Container(
//                   width: widget.size,
//                   height: widget.size,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       center: Alignment(
//                         math.cos(rotation + math.pi * 0.7) * 0.45, // Different offset to create separation
//                         math.sin(rotation + math.pi * 0.7) * 0.45,
//                       ),
//                       radius: 0.9,
//                       colors: [
//                         const Color(0xFF3B2DFF).withOpacity(0.9), // Strong blue center
//                         const Color(0xFF3B2DFF).withOpacity(0.7),
//                         const Color(0xFF3B2DFF).withOpacity(0.4),
//                         const Color(0xFF3B2DFF).withOpacity(0.15),
//                         const Color(0xFF3B2DFF).withOpacity(0.05),
//                         Colors.transparent,
//                       ],
//                       stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 1.0],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Subtle highlight to maintain glassy effect
//           AnimatedBuilder(
//             animation: _controller1,
//             builder: (context, _) {
//               return ClipOval(
//                 child: Container(
//                   width: widget.size,
//                   height: widget.size,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       center: const Alignment(-0.3, -0.3),
//                       radius: 0.4,
//                       colors: [
//                         Colors.white.withOpacity(0.2),
//                         Colors.white.withOpacity(0.05),
//                         Colors.transparent,
//                       ],
//                       stops: const [0.0, 0.3, 1.0],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }





class AnimatedYinYangOrb extends StatefulWidget {
  final double size;
  final Duration duration;

  const AnimatedYinYangOrb({
    super.key,
    this.size = 120.0,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedYinYangOrb> createState() => _AnimatedYinYangOrbState();
}

class _AnimatedYinYangOrbState extends State<AnimatedYinYangOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children:[
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ),
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedYinYangPainter(
              animationValue: _controller.value,
              blurSigma: 1
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
        ],
      ),
    );
  }
}



// class YinYangPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2;
//
//     // Outer circle bounds
//     final outerCircleRect = Rect.fromCircle(center: center, radius: radius);
//
//     // Left gradient
//     final leftGradient = RadialGradient(
//       center: Alignment(-0.3, -0.3),
//       radius: 1.2,
//       colors: [
//         const Color(0xFFC06622),
//         const Color(0xFFC06622),
//        // const Color(0xFF3B0764),
//       ],
//       stops: [0.0, 0.6],
//     );
//
//     // Right gradient
//     final rightGradient = RadialGradient(
//       center: Alignment(0.3, 0.3),
//       radius: 1.2,
//       colors: [
//         const Color(0xFF6A3F36),
//         const Color(0xFF6A3F36),
//         //const Color(0xFF831843),
//       ],
//       stops: [0.0, 0.5,],
//     );
//
//     final leftPaint = Paint()
//       ..shader = leftGradient.createShader(outerCircleRect);
//     final rightPaint = Paint()
//       ..shader = rightGradient.createShader(outerCircleRect);
//
//     // Draw entire circle in left gradient
//     canvas.drawCircle(center, radius, leftPaint);
//
//     // Draw right half-circle in right gradient to overlap
//     final path = Path()
//       ..moveTo(center.dx, center.dy - radius)
//       ..arcTo(
//         Rect.fromCircle(center: center, radius: radius),
//         -math.pi / 2,
//         math.pi,
//         false,
//       )
//       ..arcTo(
//         Rect.fromCircle(center: Offset(center.dx, center.dy + radius / 2), radius: radius / 2),
//         math.pi / 2,
//         -math.pi,
//         false,
//       )
//       ..arcTo(
//         Rect.fromCircle(center: Offset(center.dx, center.dy - radius / 2), radius: radius / 2),
//         math.pi / 2,
//         math.pi,
//         false,
//       )
//       ..close();
//
//     canvas.drawPath(path, rightPaint);
//
//     // Small circles (dots)
//     final smallRadius = radius / 6;
//     final upperDotCenter = Offset(center.dx, center.dy - radius / 2);
//     final lowerDotCenter = Offset(center.dx, center.dy + radius / 2);
//
//     // Top small circle (right gradient)
//     canvas.drawCircle(upperDotCenter, smallRadius, rightPaint);
//
//     // Bottom small circle (left gradient)
//     canvas.drawCircle(lowerDotCenter, smallRadius, leftPaint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }


class AnimatedYinYangPainter extends CustomPainter {
  final double animationValue;
  final double blurSigma;
  final double edgeBlur;

  AnimatedYinYangPainter({
    required this.animationValue,
    this.blurSigma = 3.0,
    this.edgeBlur = 6.0, // Controls the blurring between colors
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate rotation angle based on animation
    final rotationAngle = animationValue * 2 * math.pi;

    // Outer circle bounds
    final outerCircleRect = Rect.fromCircle(center: center, radius: radius);

    // Animate gradient centers by rotating them
    final leftGradientCenter = Offset(
      math.cos(rotationAngle - math.pi / 4) * 0.3,
      math.sin(rotationAngle - math.pi / 4) * 0.3,
    );

    final rightGradientCenter = Offset(
      math.cos(rotationAngle + math.pi / 2) * 0.3,
      math.sin(rotationAngle + math.pi / 2) * 0.3,
    );

    // Left gradient with animated center
    final leftGradient = RadialGradient(
      center: Alignment(leftGradientCenter.dx, leftGradientCenter.dy),
      radius: 1.2,
      colors: [
        Colors.transparent,
        const Color(0xFFC06622),
        const Color(0xFFC06622),
      ],
      stops: [0.0,0.0, 0.5,],
    );

    // Right gradient with animated center
    final rightGradient = RadialGradient(
      center: Alignment(rightGradientCenter.dx, rightGradientCenter.dy),
      radius: 1.2,
      colors: [
        const Color(0xFF6A3F36),
        const Color(0xFF6A3F36),
      ],
      stops: [0.0, 0.5],
    );

    // Create paints with standard blur
    final leftPaint = Paint()
      ..shader = leftGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurSigma);

    final rightPaint = Paint()
      ..shader = rightGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurSigma);

    // Create paints with heavy blur for edges
    final leftEdgePaint = Paint()
      ..shader = leftGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, edgeBlur);

    final rightEdgePaint = Paint()
      ..shader = rightGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, edgeBlur);

    // Draw base layers with standard blur
    canvas.drawCircle(center, radius, leftPaint);

    // Create animated yin-yang path
    final path = Path();

    // Start point rotated by animation
    final startX = center.dx + math.cos(rotationAngle - math.pi / 2) * radius;
    final startY = center.dy + math.sin(rotationAngle - math.pi / 2) * radius;

    path.moveTo(startX, startY);

    // Main arc (half circle) - rotated
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      rotationAngle - math.pi / 2,
      math.pi,
      false,
    );

    // Upper small arc - position rotated
    final upperArcCenter = Offset(
      center.dx + math.cos(rotationAngle + math.pi / 2) * radius / 2,
      center.dy + math.sin(rotationAngle + math.pi / 2) * radius / 2,
    );

    path.arcTo(
      Rect.fromCircle(center: upperArcCenter, radius: radius / 2),
      rotationAngle + math.pi / 2,
      -math.pi,
      false,
    );

    // Lower small arc - position rotated
    final lowerArcCenter = Offset(
      center.dx + math.cos(rotationAngle - math.pi / 2) * radius / 2,
      center.dy + math.sin(rotationAngle - math.pi / 2) * radius / 2,
    );

    path.arcTo(
      Rect.fromCircle(center: lowerArcCenter, radius: radius / 2),
      rotationAngle + math.pi / 2,
      math.pi,
      false,
    );

    path.close();

    // Draw the main path with standard blur
    canvas.drawPath(path, rightPaint);

    // Draw blurred edge layers for smoother transitions
    // Create a thinner path for the edge blur effect
    final edgePath = Path();
    edgePath.addPath(path, Offset.zero);

    // Draw the edge with heavy blur for soft transitions
    canvas.drawPath(edgePath, rightEdgePaint);

    // Create stroke paths for the boundaries to add more blur
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, edgeBlur * 1.5);

    // Left stroke (orange)
    final leftStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..shader = leftGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, edgeBlur);



    // Right stroke (copper)
    final rightStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..shader = rightGradient.createShader(outerCircleRect)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, edgeBlur);

    // Draw strokes along the path edges for blurred boundaries
    canvas.drawPath(path, leftStrokePaint);
   // canvas.drawPath(path, rightStrokePaint);

    // Animated small circles (dots) with edge blur
    final smallRadius = radius / 6;

    // Upper dot position - rotated
    final upperDotCenter = Offset(
      center.dx + math.cos(rotationAngle - math.pi / 2) * radius / 2,
      center.dy + math.sin(rotationAngle - math.pi / 2) * radius / 2,
    );

    // Lower dot position - rotated
    final lowerDotCenter = Offset(
      center.dx + math.cos(rotationAngle + math.pi / 2) * radius / 2,
      center.dy + math.sin(rotationAngle + math.pi / 2) * radius / 2,
    );

    // Draw dots with both standard and edge blur
    canvas.drawCircle(upperDotCenter, smallRadius, rightPaint);
    canvas.drawCircle(upperDotCenter, smallRadius, rightEdgePaint);

    canvas.drawCircle(lowerDotCenter, smallRadius, leftPaint);
    canvas.drawCircle(lowerDotCenter, smallRadius, leftEdgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AnimatedYinYangPainter &&
        oldDelegate.animationValue != animationValue;
  }
}



class AnimatedOrb extends StatefulWidget {
  final double size;
  final Duration duration;



  const AnimatedOrb({
    super.key,
    this.size = 34.0,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double haloSize = widget.size * 1.2;

    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [

          Container(
            width: haloSize,
            height: haloSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE249FF).withOpacity(0.1), // soft pink
                  const Color(0xFF3B2DFF).withOpacity(0.15), // soft blue
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                radius: 0.6,
                colors: [
                 // const Color(0xFFB8C0FF), // glassy purple-blue
                 // const Color(0xFF8E9DFF),
                  const Color(0xFFEEF1FF),
                  const Color(0xFFCCD5FF),
                  const Color(0xFFB5C7FF),
                ],
                stops: const [  0.5, 0.0, 0.0],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double rotation = _controller.value * 2 * math.pi;
              final Alignment highlightCenter1 = Alignment(
                math.cos(rotation + math.pi) * 0.35,
                math.sin(rotation + math.pi) * 0.35,
              );

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: highlightCenter1,
                    radius: 0.6,
                    colors: [
                      const Color(0xFFFDBD45),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 1.9],
                  ),
                ),
              );
            },
          ),

          //--- Highlight layer 2 (different angle & color) ---
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double rotation = _controller.value * 2 * math.pi;
              final Alignment highlightCenter2 = Alignment(
                math.cos(rotation + math.pi / 2) * 0.5,
                math.sin(rotation + math.pi / 2) * 0.5,
              );

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: highlightCenter2,
                    radius: 0.4,
                    colors: [
                      const Color(0xFFC9611A), // vibrant purple
                      Colors.transparent,
                    ],
                    stops: const [0.1, 1.9],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}





class HalfCircleClipper extends CustomClipper<Path> {
  final bool isTop;

  HalfCircleClipper({required this.isTop});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isTop) {
      path.moveTo(0, size.height / 2);
      path.arcToPoint(
        Offset(size.width, size.height / 2),
        radius: Radius.circular(size.width / 2),
        clockwise: false,
      );
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(0, size.height / 2);
      path.arcToPoint(
        Offset(size.width, size.height / 2),
        radius: Radius.circular(size.width / 2),
        clockwise: true,
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}









class VPCMiddlewareDemoPage extends StatefulWidget {
  const VPCMiddlewareDemoPage({Key? key}) : super(key: key);

  @override
  State<VPCMiddlewareDemoPage> createState() => _VPCMiddlewareDemoPageState();
}

class _VPCMiddlewareDemoPageState extends State<VPCMiddlewareDemoPage> {
  final nameController = TextEditingController();
  String greetResult = '';
  String submitResult = '';
  bool isLoadingGreet = false;
  bool isLoadingSubmit = false;

  final String baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';


  Future<void> callGreet() async {
    setState(() => isLoadingGreet = true);
    final url = Uri.parse('$baseUrl/greet');
    final payload = {"name": nameController.text};

    print('🟡 Sending /greet payload: $payload to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // ✅ FIXED
        body: jsonEncode(payload),
      );

      print('📨 Received status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          greetResult = data['message'] ?? 'No message';
        });
      } else {
        setState(() {
          greetResult = '❌ Server error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e, stack) {
      print('❌ Exception in /greet: $e');
      print('🪵 StackTrace:\n$stack');
      setState(() => greetResult = 'Error: $e');
    } finally {
      setState(() => isLoadingGreet = false);
    }
  }

  Future<void> callSubmit() async {
    setState(() => isLoadingSubmit = true);
    final url = Uri.parse('$baseUrl/submit');

    final payload = {
      "name": nameController.text,
      "age": 30,
      "interests": ["flutter", "finance", "ai"],
      "preferences": {"newsletter": true, "notifications": false}
    };

    print('🟡 Sending /submit payload: $payload to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // ✅ FIXED
        body: jsonEncode(payload),
      );

      print('📨 Received status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          submitResult = const JsonEncoder.withIndent('  ').convert(data);
        });
      } else {
        setState(() {
          submitResult = '❌ Server error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e, stack) {
      print('❌ Exception in /submit: $e');
      print('🪵 StackTrace:\n$stack');
      setState(() => submitResult = 'Error: $e');
    } finally {
      setState(() => isLoadingSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VPC Middleware Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoadingGreet ? null : callGreet,
              child: isLoadingGreet
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Call /api/v1/greet'),
            ),
            const SizedBox(height: 8),
            Text(
              greetResult,
              style: const TextStyle(fontSize: 16,color: Colors.white),
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: isLoadingSubmit ? null : callSubmit,
              child: isLoadingSubmit
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Call /api/v1/submit'),
            ),
            const SizedBox(height: 8),
            Text(
              submitResult,
              style: const TextStyle(fontSize: 14,color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}










class DummyChatInput extends StatelessWidget {
  const DummyChatInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Button (Cancel/Cross) - TAP AREA EXTENDED
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => print('Cancel tapped'),
            child: Container(
              color: Colors.red.withOpacity(0.3), // Shows FULL tap area
              padding: const EdgeInsets.symmetric(
                horizontal: 15, // ✅ Left/Right tap area
                vertical: 12,   // ✅ Top/Bottom tap area
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.brown, width: 1),
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.brown),
              ),
            ),
          ),

          const SizedBox(width: 30),

          // Center Content (Waveform area)
          Container(
            width: 150,
            height: 10,
            color: Colors.blue.withOpacity(0.2),
            alignment: Alignment.center,
            child: const Text(
              'Waveform Area',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),

          const SizedBox(width: 30),

          // Right Button (Check/Done) - TAP AREA EXTENDED
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => print('Check tapped'),
            child: Container(
              color: Colors.green.withOpacity(0.3), // Shows FULL tap area
              padding: const EdgeInsets.symmetric(
                horizontal: 15, // ✅ Left/Right tap area
                vertical: 12,   // ✅ Top/Bottom tap area
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}














class TestOrb extends StatefulWidget {
  const TestOrb({super.key});
  @override
  State<TestOrb> createState() => _TestOrbState();
}

class _TestOrbState extends State<TestOrb> {
  static const double orbSize = 50;
  static const double lottieSize = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1) Background
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/orb_back.webp',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // 2) Lottie BELOW the orb (so rim stays visible)
                  ClipOval(
                    child: SizedBox(
                      width: lottieSize,
                      height: lottieSize,
                      child: Lottie.asset(
                        'assets/images/retry1.json',
                        fit: BoxFit.cover,
                        repeat: true,
                      ),
                    ),
                  ),

                  // 3) Glass orb (blur INSIDE only)
                  const GlassOrb(
                    size: orbSize,
                    blur: 10,
                    edgeWidth: 2.0,
                  ),

                ],
              ),
            ),
          ),
          // SizedBox(
          //   height: 50,
          // ),
          // Expanded(
          //   child: PremiumShimmerWidget(
          //     text: "Hello",
          //     isComplete: false,
          //    // baseColor: const Color(0xFF9CA3AF),
          //    // highlightColor: const Color(0xFF6B7280),
          //     baseColor: const Color(0xFF6B7280),
          //     highlightColor: Color(0xFF9CA3AF)
          //     ,
          //   ),
          // ),
        ],
      ),
    );
  }
}

/// Truly transparent glass orb with proper 3D cues.
class GlassOrb extends StatelessWidget {
  final double size;
  final double blur;
  final double edgeWidth;

  const GlassOrb({
    super.key,
    required this.size,
    this.blur = 24,
    this.edgeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    final r = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ground shadow for depth
          Positioned(
            bottom: -r * 0.28,
            child: Container(
              width: r * 1.5,
              height: r * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Blur only inside the circle (no tint)
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: const SizedBox.expand(),
            ),
          ),

          // Inner shadow (bottom-right) — gives spherical volume
          CustomPaint(painter: _InnerShadowPainter()),

          // Fresnel rim (soft edge glow)
          CustomPaint(painter: _FresnelRimPainter()),

          // Crisp edge line (subtle)
          CustomPaint(painter: _EdgePainter(edgeWidth)),

          // Soft highlight (top-left), gradient (no boxShadow hot-spot)
          CustomPaint(painter: _HighlightPainter()),
        ],
      ),
    );
  }
}

/// Subtle inner shadow bottom-right (vignette) for 3D volume
class _InnerShadowPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final center = Offset(s.width / 2, s.height / 2);

    final rect = Rect.fromCircle(center: center, radius: r * 0.95);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.35, 0.35), // bottom-right bias
        radius: 1.0,
        colors: [
          const Color(0xFF000000).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.srcOver;

    c.drawCircle(center, r * 0.95, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft Fresnel rim (edge brighter than center)
class _FresnelRimPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final center = Offset(s.width / 2, s.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    final paint = Paint()
      ..shader = RadialGradient(
        // Slight top-left bias so it feels lit
        center: const Alignment(-0.2, -0.2),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.18), // inner edge glow
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.72, 0.86, 0.95, 1.0],
      ).createShader(rect);

    c.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crisp, subtle edge stroke so the boundary is always readable on white
class _EdgePainter extends CustomPainter {
  final double w;
  _EdgePainter(this.w);

  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final center = Offset(s.width / 2, s.height / 2);

    // faint dark halo for separation on bright backgrounds
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w + 1
      ..color = Colors.black.withOpacity(0.06);
    c.drawCircle(center, r - (w / 2), shadow);

    // main edge
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = Colors.white.withOpacity(0.6);
    c.drawCircle(center, r - (w / 2), edge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft elliptical highlight (no boxShadow hot-spot → no random white dot)
class _HighlightPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final center = Offset(s.width / 2, s.height / 2);

    final highlightCenter =
    Offset(center.dx - r * 0.28, center.dy - r * 0.28);

    final rect = Rect.fromCenter(
      center: highlightCenter,
      width: r * 0.8,
      height: r * 0.6,
    );

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.30),
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.screen; // gentle additive look

    c.save();
    // squash into ellipse
    c.translate(highlightCenter.dx, highlightCenter.dy);
    c.scale(1.15, 0.9);
    c.translate(-highlightCenter.dx, -highlightCenter.dy);
    c.drawOval(rect, paint);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}












class OrbIcon extends StatelessWidget {
  final double size;        // e.g. 28–40 for prefix
  final double blur;        // scale with size (size * 0.22 is a good start)
  final double edgeWidth;
  final String? lottie;     // optional Lottie under the glass

  const OrbIcon({
    super.key,
    this.size = 32,
    double? blur,
    this.edgeWidth = 1.4,
    this.lottie,
  }) : blur = blur ?? (32 * 0.22);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optional: animated energy beneath the glass
          if (lottie != null)
            ClipOval(
              child: SizedBox.square(
                dimension: size,
                child: Lottie.asset(lottie!, fit: BoxFit.cover, repeat: true),
              ),
            ),

          // Ground shadow for separation (very subtle for tiny sizes)
          Positioned(
            bottom: -size * 0.14,
            child: Container(
              width: size * 0.72,
              height: size * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                boxShadow: const [
                  BoxShadow(color: Colors.transparent, blurRadius: 0, spreadRadius: 0),
                ],
              ),
            ),
          ),

          // Glass blur (clips to the circle)
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}









class ShimmerStatusPill extends StatefulWidget {
  final String label;                 // e.g. "Searching the internet"
  final Duration sweepDuration;       // shimmer speed
  const ShimmerStatusPill({
    super.key,
    required this.label,
    this.sweepDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerStatusPill> createState() => _ShimmerStatusPillState();
}

class _ShimmerStatusPillState extends State<ShimmerStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.sweepDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // base text style (SF Pro / Inter vibe)
    const baseStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.2,
      fontFamily: "DM Sans"
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 8),

                // TEXT + SHIMMER
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    // shimmer sweep position (−1 → 2) so it fully crosses text
                    final t = _ctrl.value;                  // 0..1
                    final x0 = -1.0 + 3.0 * t;              // -1 → 2
                    final shimmerGradient = LinearGradient(
                      begin: Alignment(-1 + x0, 0), end: Alignment(x0, 0),
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.55), // bright band
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.25, 0.5, 0.75],
                    );

                    return ShaderMask(
                      shaderCallback: (rect) => shimmerGradient
                          .createShader(Rect.fromLTWH(0, 0, rect.width, rect.height)),
                      blendMode: BlendMode.srcATop, // apply highlight over base text
                      child: _DotsText(
                        text: '${widget.label}',
                        style: baseStyle.copyWith(color: Colors.black.withOpacity(0.78)),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated dots: "", ".", "..", "..." (slow, subtle)
class _DotsText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _DotsText({required this.text, required this.style});

  @override
  State<_DotsText> createState() => _DotsTextState();
}

class _DotsTextState extends State<_DotsText> with SingleTickerProviderStateMixin {
  late final AnimationController _dotsCtrl;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _step = (_step + 1) % 4);
          _dotsCtrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _step;
    return Text('${widget.text}', style: widget.style);
  }
}

