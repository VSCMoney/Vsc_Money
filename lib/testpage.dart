import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'constants/widgets.dart';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';


import 'dart:math';
import 'package:flutter/material.dart';





class DummyBoxScreen extends StatefulWidget {
  @override
  _DummyBoxScreenState createState() => _DummyBoxScreenState();
}

class _DummyBoxScreenState extends State<DummyBoxScreen> {
  final List<Color> _boxColors = [];
  ScrollController _scrollController = ScrollController();





  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  void jumpTO(){
    setState(() {
      //print("OFFSET: ${_scrollController.offset}");
      var jump = _scrollController.position.maxScrollExtent;
      print("JUMP : $jump");
      _scrollController.jumpTo(jump);
    });
  }

  void _addBox() {
    setState(() {
      _boxColors.add(_getRandomColor());
      //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {

      print("max: ${_scrollController.position.maxScrollExtent}");

      print("min : ${_scrollController.position.minScrollExtent}");
      print("Offset: ${_scrollController.offset}");

    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Dummy Box List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addBox,
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: jumpTO,
          )
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _boxColors.length + 1,
        itemBuilder: (context, index) {
if(index == _boxColors.length){
  return SizedBox(height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 10);
}
          return Container(
            height: 100,
            color: _boxColors[index],
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
              'Box ${index + 1}',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              ),
            ),
          );
        },
      ),
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
        )

      ),
    );
  }
}

class AppleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));

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
        clientId: 'com.vsc.money.signin', // ✅ FIX — THIS PASSES YOUR SERVICE ID
        redirectUri: Uri.parse('https://mystic-primacy-455711-q3.firebaseapp.com/__/auth/handler'),
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
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );

    // Step 3: Firebase Sign-In
    return await _auth.signInWithCredential(oauthCredential);
  }
}




class ColorfulBoxesScreen extends StatefulWidget {
  const ColorfulBoxesScreen({Key? key}) : super(key: key);

  @override
  State<ColorfulBoxesScreen> createState() => _ColorfulBoxesScreenState();
}

class _ColorfulBoxesScreenState extends State<ColorfulBoxesScreen> {
  final List<BoxData> boxes = [];
  final Random _random = Random();

  // Predefined colors for variety
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
  ];

  void _addNewBox() {
    final randomColor = availableColors[_random.nextInt(availableColors.length)];
    final randomHeight = 60.0 + _random.nextDouble() * 140; // 60-200 height range

    setState(() {
      boxes.add(BoxData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        color: randomColor,
        height: randomHeight,
        text: "Box ${boxes.length + 1}",
      ));
    });

    // Add some haptic feedback
    _showSnackBar("Added Box ${boxes.length} with height ${randomHeight.toInt()}px");
  }

  void _removeBox(int index) {
    setState(() {
      boxes.removeAt(index);
    });
    _showSnackBar("Box removed!");
  }

  void _updateBoxHeight(int index, double newHeight) {
    setState(() {
      boxes[index] = boxes[index].copyWith(height: newHeight);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showHeightDialog(int index) {
    final TextEditingController heightController = TextEditingController();
    heightController.text = boxes[index].height.toInt().toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Height - ${boxes[index].text}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Height (px)",
                hintText: "Enter height",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Current: ${boxes[index].height.toInt()}px",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newHeight = double.tryParse(heightController.text);
              if (newHeight != null && newHeight > 0 && newHeight <= 300) {
                _updateBoxHeight(index, newHeight);
                Navigator.pop(context);
                _showSnackBar("Height updated to ${newHeight.toInt()}px");
              } else {
                _showSnackBar("Please enter a valid height (1-300)");
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Colorful Boxes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (boxes.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  boxes.clear();
                });
                _showSnackBar("All boxes cleared!");
              },
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear All",
            ),
        ],
      ),
      body: boxes.isEmpty
          ? _buildEmptyState()
          : _buildBoxesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewBox,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Add New Box",
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            "No boxes yet!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Tap the + button to add colorful boxes",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxesList() {
    return Column(
      children: [
        // Stats Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total Boxes", "${boxes.length}"),
              _buildStatItem("Avg Height", "${_getAverageHeight().toInt()}px"),
              _buildStatItem("Max Height", "${_getMaxHeight().toInt()}px"),
            ],
          ),
        ),

        // Boxes List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: boxes.length,
            itemBuilder: (context, index) {
              final box = boxes[index];
              return _buildBoxItem(box, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBoxItem(BoxData box, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: box.color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: box.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                box.color,
                box.color.withOpacity(0.7),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showHeightDialog(index),
              onLongPress: () => _removeBox(index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          box.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeBox(index),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                        ),
                      ],
                    ),

                    if (box.height > 80) // Show details only if box is tall enough
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Height: ${box.height.toInt()}px",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tap to edit • Long press to delete",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  double _getAverageHeight() {
    if (boxes.isEmpty) return 0;
    return boxes.map((b) => b.height).reduce((a, b) => a + b) / boxes.length;
  }

  double _getMaxHeight() {
    if (boxes.isEmpty) return 0;
    return boxes.map((b) => b.height).reduce((a, b) => a > b ? a : b);
  }
}

// Data Model for Box
class BoxData {
  final String id;
  final Color color;
  final double height;
  final String text;

  const BoxData({
    required this.id,
    required this.color,
    required this.height,
    required this.text,
  });

  BoxData copyWith({
    String? id,
    Color? color,
    double? height,
    String? text,
  }) {
    return BoxData(
      id: id ?? this.id,
      color: color ?? this.color,
      height: height ?? this.height,
      text: text ?? this.text,
    );
  }
}




class ImprovedAppleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = 'http://127.0.0.1:8000';

  // Generate nonce for Apple Sign-In security
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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
      print('   Identity Token Length: ${appleCredential.identityToken?.length ?? 0}');
      print('   Authorization Code Length: ${appleCredential.authorizationCode?.length ?? 0}');

      // Try Firebase authentication
      print('🔍 Testing Firebase authentication...');
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

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
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_token': idToken,
        }),
      );

      print('📡 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Backend verification successful');
        return {
          'success': true,
          'data': data,
          'user': user,
        };
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
        print('   This usually means Firebase Apple provider is not configured correctly');
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
      return {
        'success': false,
        'error': e.toString(),
      };
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
      appBar: AppBar(
        title: Text('Apple Sign-In Debug'),
      ),
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


class ChatDemo {
  final String text;
  final bool isUser;
  final GlobalKey key;

  ChatDemo({required this.text, required this.isUser}) : key = GlobalKey();
}


class ChatDemoPage extends StatefulWidget {
  @override
  _ChatDemoPageState createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  final List<ChatDemo> messages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();

  void _sendMessage() {
    final userMsg = ChatDemo(text: "User message ${messages.length + 1}", isUser: true);
    setState(() {
      messages.add(userMsg);
    });

    Future.delayed(Duration(milliseconds: 100), () {
      _alignMessageTop100pxAboveTextField(userMsg.key);
    });

    // Simulate bot reply
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        messages.add(ChatDemo(text: "Bot reply ${messages.length + 1}", isUser: false));
      });
    });
  }

  void _alignMessageTop100pxAboveTextField(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textFieldContext = _textFieldKey.currentContext;
      final messageContext = key.currentContext;

      if (textFieldContext == null || messageContext == null) {
        Future.delayed(Duration(milliseconds: 100), () {
          _alignMessageTop100pxAboveTextField(key);
        });
        return;
      }

      final textFieldTop = (textFieldContext.findRenderObject() as RenderBox)
          .localToGlobal(Offset.zero)
          .dy;
      final messageTop = (messageContext.findRenderObject() as RenderBox)
          .localToGlobal(Offset.zero)
          .dy;

      final targetY = textFieldTop - 100.0;
      final adjustment = messageTop - targetY;

      print("📍 TextField Top: $textFieldTop");
      print("🧭 Message Top: $messageTop");
      print("🎯 Target Y: $targetY");
      print("↕️ Scroll By: $adjustment");

      _scrollController.animateTo(
        _scrollController.offset + adjustment,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Demo')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                return Container(
                  key: msg.key,
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(msg.text),
                );
              },
            ),
          ),
          Container(
            key: _textFieldKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(hintText: "Type..."))),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}





