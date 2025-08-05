// Enhanced AuthService with onboarding state management
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../controllers/session_manager.dart';
import 'locator.dart';

enum AuthStatus { idle, loading, error, success }
enum AuthFlow { onboarding, login, nameEntry, home }

class AuthState {
  final AuthStatus status;
  final String? error;
  final UserModel? user;
  final bool hasSeenOnboarding;

  const AuthState({
    this.status = AuthStatus.idle,
    this.error,
    this.user,
    this.hasSeenOnboarding = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    UserModel? user,
    bool? hasSeenOnboarding,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      user: user ?? this.user,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

class AuthService {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _firstLaunchKey = 'is_first_launch';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final EndPointService _api = locator<EndPointService>();
  final _authState = BehaviorSubject<AuthState>.seeded(const AuthState());

 final endPoint =  locator<EndPointService>();


  String? _verificationId;
  int? _resendToken;
  Timer? _otpTimer;
  int _otpCountdown = 30;

  Stream<AuthState> get authStateStream => _authState.stream;
  AuthState get currentState => _authState.value;

  void dispose() {
    _authState.close();
    _otpTimer?.cancel();
  }

  void _setState(AuthState state) => _authState.add(state);
  void _setLoading() => _setState(currentState.copyWith(status: AuthStatus.loading, error: null));
  void _setError(String error) => _setState(currentState.copyWith(status: AuthStatus.error, error: error));
  void _setUser(UserModel user) => _setState(currentState.copyWith(status: AuthStatus.success, user: user));
  void _clearState() => _setState(const AuthState());






  final LocalAuthentication _auth = LocalAuthentication();


  /// Emits true if user authenticated, false if failed
  final BehaviorSubject<bool> _authStateSubject = BehaviorSubject.seeded(false);

  /// Whether user enabled biometric usage manually
  bool _biometricEnabled = false;

  /// Load setting from storage (e.g., SharedPreferences)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
  }

  bool get isBiometricEnabled => _biometricEnabled;




  Future<bool> toggleBiometric(bool enabled, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _authStateSubject.add(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Biometrics not supported on this device')),
        );
        return false;
      }

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (success) {
        _biometricEnabled = true;
        await prefs.setBool('biometric_enabled', true);
        _authStateSubject.add(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Biometric enabled')),
        );
        return true;
      } else {
        _authStateSubject.add(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Biometric auth cancelled')),
        );
        return false;
      }
    } else {
      _biometricEnabled = false;
      await prefs.setBool('biometric_enabled', false);
      _authStateSubject.add(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔒 Biometric disabled')),
      );
      return false;
    }
  }

  Future<bool> isBiometricEnabledAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }


  Future<void> requestBiometricPermission() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        print("Device does not support biometrics");
        return;
      }

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      _authStateSubject.add(success);
    } catch (e) {
      print('Biometric setup error: $e');
      _authStateSubject.add(false);
    }
  }

  Future<bool> authenticate() async {
    try {
      print("🧪 Checking biometric support");
      final support = await _auth.canCheckBiometrics;
      print("✅ canCheckBiometrics: $support");

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      print("🔐 Authentication result: $success");
      _authStateSubject.add(success);
      return success;
    } catch (e) {
      print('❌ Biometric error: $e');
      _authStateSubject.add(false);
      return false;
    }
  }

  // Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLaunchKey) ?? false);
  }

  // Mark first launch as completed
  Future<void> markFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  // Check if user has seen onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _setState(currentState.copyWith(hasSeenOnboarding: true));
  }

  // Initial app flow determination
  Future<void> determineInitialFlow(Function(AuthFlow) onFlow) async {
    _setLoading();

    try {
      // First check if user is already authenticated
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        // User is authenticated, check their profile completion
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          await handleOtpTokenVerification(idToken, onFlow);
          return;
        }
      }

      // User is not authenticated, check if they need onboarding
      final isFirst = await isFirstLaunch();
      final seenOnboarding = await hasSeenOnboarding();

      if (isFirst || !seenOnboarding) {
        // Show onboarding for first-time unauthenticated users
        onFlow(AuthFlow.onboarding);
      } else {
        // Returning user without authentication, go to login
        onFlow(AuthFlow.login);
      }

    } catch (e) {
      debugPrint('❌ Error determining initial flow: $e');
      _setError('Failed to determine app flow: $e');

      // For error cases, check if they've seen onboarding
      final seenOnboarding = await hasSeenOnboarding();
      onFlow(seenOnboarding ? AuthFlow.login : AuthFlow.onboarding);
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }

  // Complete onboarding and proceed to auth
  Future<void> completeOnboarding(Function(AuthFlow) onFlow) async {
    try {
      await markOnboardingCompleted();
      await markFirstLaunchCompleted();

      // After onboarding, check if user is already authenticated
      await handleSessionCheck(onFlow);

    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      onFlow(AuthFlow.login); // Fallback to login
    }
  }

  // Your existing auth methods remain the same...
  Future<void> handleGoogleSignIn(Function(AuthFlow) onFlow) async {
    _setLoading();
    try {
      // Step 1: Google native sign-in
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setState(currentState.copyWith(status: AuthStatus.idle));
        return; // user cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Step 2: Sign-in to Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Step 3: Get ID token from Firebase user
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw "Failed to get Firebase ID token";

      // Step 4: Call your backend for custom JWT session
      final res = await _api.post(
        endpoint: "/api/v1/auth/verify_google_user",
        body: {"id_token": idToken},
      );

      // Step 5: Save tokens, extract UID if needed
      final accessToken = res["token"];
      final refreshToken = res["refresh_token"];
      String? uid = SessionManager.uid;
      uid ??= extractUidFromToken(accessToken);

      await SessionManager.saveTokens(accessToken, refreshToken, uid: uid);

      // Step 6: Fetch user profile, continue flow
      await fetchUserProfile();
      final user = currentState.user;
      if ((user?.firstName?.isEmpty ?? true) || (user?.lastName?.isEmpty ?? true)) {
        onFlow(AuthFlow.nameEntry);
      } else {
        onFlow(AuthFlow.home);
      }
    } catch (e) {
      print("❌ Google Sign-in error: $e");
      _setError("Google Sign-in failed: $e");
      onFlow(AuthFlow.login);
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }

  // Rest of your existing methods...
  Future<void> verifyBackendToken(
      String idToken,
      Function(String route) onSuccess,
      Function onFail,
      ) async {
    _setLoading();
    try {
      final res = await _api.post(endpoint: "/api/v1/auth/verify_user", body: {"id_token": idToken});
      await SessionManager.saveTokens(res['token'], res['refresh_token'], uid: res['uid']);
      await fetchUserProfile();
      final user = currentState.user;

      if ((user?.firstName?.isEmpty ?? true) || (user?.lastName?.isEmpty ?? true)) {
        onSuccess('enter_name');
      } else {
        onSuccess('home');
      }
    } catch (e) {
      _setError(e.toString());
      onFail();
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }

  Future<void> handleOtpTokenVerification(String idToken, Function(AuthFlow) onFlow) async {
    await verifyBackendToken(
      idToken,
          (route) => onFlow(route == 'home' ? AuthFlow.home : AuthFlow.nameEntry),
          () => onFlow(AuthFlow.login),
    );
  }

  Future<void> handleSessionCheck(Function(AuthFlow) onFlow) async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser != null) {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        onFlow(AuthFlow.login);
        return;
      }
      await handleOtpTokenVerification(idToken, onFlow);
    } else {
      onFlow(AuthFlow.login);
    }
  }

  // Continue with your existing methods...
  Future<void> completeUserProfile(String first, String last) async {
    _setLoading();
    try {
      await _api.post(endpoint: "/api/v1/auth/update_profile", body: {
        "first_name": first,
        "last_name": last,
      });
      await fetchUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }

  Future<void> completeUserProfileAndNavigate(Function(AuthFlow) onFlow) async {
    final user = currentState.user;
    if (user == null) {
      onFlow(AuthFlow.login);
    } else if ((user.firstName?.isEmpty ?? true) || (user.lastName?.isEmpty ?? true)) {
      onFlow(AuthFlow.nameEntry);
    } else {
      onFlow(AuthFlow.home);
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final res = await _api.get(endpoint: "/api/v1/auth/get_profile");
      _setUser(UserModel.fromJson(res));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("404") || msg.contains("User not found")) {
        logout();
      } else {
        _setError(msg);
      }
    }
  }

  String? extractUidFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload['uid'];
    } catch (e) {
      debugPrint("UID extract failed: $e");
      return null;
    }
  }

  Future<void> refreshAccessToken() async {
    try {
      final res = await _api.post(endpoint: "/api/v1/auth/refresh_token", body: {
        "refresh_token": SessionManager.refreshToken,
        "uid": SessionManager.uid,
      });

      final newToken = res["access_token"];
      if (newToken != null) {
        String? uid = SessionManager.uid ?? extractUidFromToken(newToken);
        await SessionManager.saveTokens(newToken, SessionManager.refreshToken!, uid: uid);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> autoLogin(Function(AuthFlow) onResult) async {
    await SessionManager.loadTokens();
    final token = SessionManager.token;
    if (token == null || isTokenExpired(token)) {
      final refreshed = await SessionManager.tryRefreshToken();
      if (refreshed) {
        await fetchUserProfile();
        completeUserProfileAndNavigate(onResult);
      } else {
        logout();
        onResult(AuthFlow.login);
      }
    } else {
      await fetchUserProfile();
      completeUserProfileAndNavigate(onResult);
    }
  }

  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= expiry;
    } catch (e) {
      debugPrint("Token parse error: $e");
      return true;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await SessionManager.clearToken();
    _clearState();
  }

  // OTP methods remain the same...
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential) onAutoVerify,
    required void Function(String error) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: onAutoVerify,
        verificationFailed: (e) => onError(e.message ?? "Verification failed"),
        codeSent: (id, token) {
          _verificationId = id;
          _resendToken = token;
          _startOtpTimer();
          onCodeSent(id, token);
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError("Failed to send OTP: $e");
    }
  }

  Future<String?> verifyOtp(String smsCode) async {
    if (_verificationId == null) return null;
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    final userCred = await _firebaseAuth.signInWithCredential(credential);
    return await userCred.user?.getIdToken();
  }

  Future<String?> autoVerifyCredential(PhoneAuthCredential credential) async {
    final userCred = await _firebaseAuth.signInWithCredential(credential);
    return await userCred.user?.getIdToken();
  }

  void _startOtpTimer() {
    _otpCountdown = 30;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        _otpCountdown--;
      } else {
        timer.cancel();
      }
    });
  }

  int get otpCountdown => _otpCountdown;
}