import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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


  static const String _onboardingCompletedKey = 'onboarding_completed_v1';
  static const String _appInstalledKey = 'app_installed_timestamp';



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


  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }


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
    await prefs.setBool(_onboardingCompletedKey, true);
    // Also record when app was first used
    if (!prefs.containsKey(_appInstalledKey)) {
      await prefs.setInt(_appInstalledKey, DateTime.now().millisecondsSinceEpoch);
    }
    _setState(currentState.copyWith(hasSeenOnboarding: true));
  }

  // Initial app flow determination
  Future<void> determineInitialFlow(Function(AuthFlow) onFlow) async {
    _setLoading();

    try {
      // First, check if onboarding is completed
      final onboardingCompleted = await isOnboardingCompleted();

      if (!onboardingCompleted) {
        // First time user - show onboarding
        debugPrint('🎯 First time user - showing onboarding');
        onFlow(AuthFlow.onboarding);
        return;
      }

      // Onboarding completed - check authentication status
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        // User is authenticated, check their profile completion
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          await handleOtpTokenVerification(idToken, onFlow);
          return;
        }
      }

      // User completed onboarding but not authenticated
      debugPrint('🔑 Returning user - showing login');
      onFlow(AuthFlow.login);

    } catch (e) {
      debugPrint('❌ Error determining initial flow: $e');
      _setError('Failed to determine app flow: $e');

      // Error fallback: check onboarding status again
      final onboardingCompleted = await isOnboardingCompleted();
      onFlow(onboardingCompleted ? AuthFlow.login : AuthFlow.onboarding);

    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }



  // Complete onboarding and proceed to auth
  Future<void> completeOnboarding(Function(AuthFlow) onFlow) async {
    try {
      // Mark as completed first (important!)
      await markOnboardingCompleted();

      debugPrint('✅ Onboarding completed successfully');

      // Check if user is already authenticated (rare case)
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await handleSessionCheck(onFlow);
      } else {
        // Proceed to authentication
        onFlow(AuthFlow.login);
      }

    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      // Even on error, don't show onboarding again
      onFlow(AuthFlow.login);
    }
  }

  
  // Your existing auth methods remain the same...

  Future<void> handleGoogleSignIn(Function(AuthFlow) onFlow) async {
    _setLoading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setState(currentState.copyWith(status: AuthStatus.idle));
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCred.user!;
      final uid = firebaseUser.uid;

      final displayName = googleUser.displayName ?? '';
      final parts = displayName.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final payload = {
        "uid": uid,
        if (firstName.isNotEmpty) "first_name": firstName,
        if (lastName.isNotEmpty)  "last_name": lastName,
        if (googleUser.email.isNotEmpty) "email": googleUser.email,
      };

      try {
        final res = await _api.post(endpoint: "/auth/verify_google_user", body: payload);
        await _handleSuccessfulAuth(res, onFlow);
      } catch (e) {
        // Check if it's the refresh token mismatch error
        if (_isRefreshTokenMismatchError(e)) {
          print("Refresh token mismatch detected. Forcing logout and retrying...");

          // Force logout all sessions for this user
          await _forceLogoutUser(uid);

          // Retry the verification with the same payload
          final res = await _api.post(endpoint: "/auth/verify_google_user", body: payload);
          await _handleSuccessfulAuth(res, onFlow);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _setError("Google Sign-in failed: $e");
      onFlow(AuthFlow.login);
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }


  Future<void> handleAppleSignIn(Function(AuthFlow) onFlow) async {
    _setLoading();
    try {
      // Check if Apple Sign In is available on this device
      if (!await SignInWithApple.isAvailable()) {
        _setError("Apple Sign-In is not available on this device");
        onFlow(AuthFlow.login);
        return;
      }

      // Request Apple Sign In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCred = await _firebaseAuth.signInWithCredential(oAuthCredential);
      final firebaseUser = userCred.user!;
      final uid = firebaseUser.uid;

      // Extract name information from Apple credential
      // Note: Apple only provides name on first sign-in, after that it's null
      final firstName = appleCredential.givenName ?? '';
      final lastName = appleCredential.familyName ?? '';

      // Fallback: try to get name from Firebase display name if available
      String fallbackFirstName = firstName;
      String fallbackLastName = lastName;

      if (firstName.isEmpty && lastName.isEmpty && firebaseUser.displayName != null) {
        final displayName = firebaseUser.displayName!;
        final parts = displayName.trim().split(RegExp(r'\s+'));
        fallbackFirstName = parts.isNotEmpty ? parts.first : '';
        fallbackLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final payload = {
        "uid": uid,
        if (fallbackFirstName.isNotEmpty) "first_name": fallbackFirstName,
        if (fallbackLastName.isNotEmpty) "last_name": fallbackLastName,
        if (appleCredential.email?.isNotEmpty == true) "email": appleCredential.email,
        // Apple-specific fields
        if (appleCredential.userIdentifier?.isNotEmpty == true) "apple_id": appleCredential.userIdentifier,
        // Check if email is Apple's private relay email
        if (appleCredential.email?.contains('@privaterelay.appleid.com') == true) "is_private_email": true,
      };

      try {
        final res = await _api.post(endpoint: "/auth/verify_apple_user", body: payload);
        await _handleSuccessfulAuth(res, onFlow);
      } catch (e) {
        // Check if it's the refresh token mismatch error
        if (_isRefreshTokenMismatchError(e)) {
          print("Refresh token mismatch detected. Forcing logout and retrying...");

          // Force logout all sessions for this user
          await _forceLogoutUser(uid);

          // Retry the verification with the same payload
          final res = await _api.post(endpoint: "/auth/verify_apple_user", body: payload);
          await _handleSuccessfulAuth(res, onFlow);
        } else {
          rethrow;
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle Apple-specific errors
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
        // User canceled the sign-in process
          print("Apple Sign-In was canceled by user");
          break;
        case AuthorizationErrorCode.failed:
          _setError("Apple Sign-In failed: ${e.message}");
          break;
        case AuthorizationErrorCode.invalidResponse:
          _setError("Apple Sign-In received invalid response");
          break;
        case AuthorizationErrorCode.notHandled:
          _setError("Apple Sign-In could not be handled");
          break;
        case AuthorizationErrorCode.unknown:
          _setError("Unknown Apple Sign-In error occurred");
          break;
        default:
          _setError("Apple Sign-In error: ${e.message}");
      }
      onFlow(AuthFlow.login);
    } catch (e) {
      _setError("Apple Sign-in failed: $e");
      onFlow(AuthFlow.login);
    } finally {
      _setState(currentState.copyWith(status: AuthStatus.idle));
    }
  }

  bool _isRefreshTokenMismatchError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('422') &&
        (errorString.contains('refresh token') ||
            errorString.contains('does not match') ||
            errorString.contains('try logging out first'));
  }

  Future<void> _forceLogoutUser(String uid) async {
    try {
      // Call your server's force logout endpoint
      await _api.post(
          endpoint: "/auth/logout",
          body: {"uid": uid}
      );
    } catch (e) {
      print("Failed to force logout user: $e");
      // Don't throw - this is a recovery attempt
    }
  }

  Future<void> _handleSuccessfulAuth(Map<String, dynamic> res, Function(AuthFlow) onFlow) async {
    final accessToken = res["token"] as String;
    final refreshToken = res["refresh_token"] as String;
    final uidFromToken = SessionManager.uid ?? extractUidFromToken(accessToken);
    await SessionManager.saveTokens(accessToken, refreshToken, uid: uidFromToken);

    final needsProfile = res["needs_profile"] == true;
    if (needsProfile) {
      onFlow(AuthFlow.nameEntry);
    } else {
      await fetchUserProfile();
      onFlow(AuthFlow.home);
    }
  }

  // Future<void> handleGoogleSignIn(Function(AuthFlow) onFlow) async {
  //   _setLoading();
  //   try {
  //     // Step 1: Google native sign-in
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) {
  //       _setState(currentState.copyWith(status: AuthStatus.idle));
  //       return; // user cancelled
  //     }
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //
  //     // Step 2: Sign-in to Firebase
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
  //
  //     // Step 3: Get ID token from Firebase user
  //     final idToken = await userCredential.user?.getIdToken();
  //     if (idToken == null) throw "Failed to get Firebase ID token";
  //
  //     // Step 4: Call your backend for custom JWT session
  //     final res = await _api.post(
  //       endpoint: "/api/v1/auth/verify_google_user",
  //       body: {"id_token": idToken},
  //     );
  //
  //     // Step 5: Save tokens, extract UID if needed
  //     final accessToken = res["token"];
  //     final refreshToken = res["refresh_token"];
  //     String? uid = SessionManager.uid;
  //     uid ??= extractUidFromToken(accessToken);
  //
  //     await SessionManager.saveTokens(accessToken, refreshToken, uid: uid);
  //
  //     // Step 6: Fetch user profile, continue flow
  //     await fetchUserProfile();
  //     final user = currentState.user;
  //     if ((user?.firstName?.isEmpty ?? true) || (user?.lastName?.isEmpty ?? true)) {
  //       onFlow(AuthFlow.nameEntry);
  //     } else {
  //       onFlow(AuthFlow.home);
  //     }
  //   } catch (e) {
  //     print("❌ Google Sign-in error: $e");
  //     _setError("Google Sign-in failed: $e");
  //     onFlow(AuthFlow.login);
  //   } finally {
  //     _setState(currentState.copyWith(status: AuthStatus.idle));
  //   }
  // }




  Future<void> verifyBackendToken(
      String idToken,
      Function(String route) onSuccess,
      Function onFail,
      ) async {
    _setLoading();
    try {
      final res = await _api.post(endpoint: "/auth/verify_user", body: {"id_token": idToken});
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
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        // Set timeout for token retrieval
        final idToken = await firebaseUser.getIdToken()
            .timeout(Duration(seconds: 10));

        if (idToken == null) {
          onFlow(AuthFlow.login);
          return;
        }

        await handleOtpTokenVerification(idToken, onFlow);
      } else {
        onFlow(AuthFlow.login);
      }
    } on TimeoutException {
      print('⏰ Token retrieval timed out');
      onFlow(AuthFlow.login);
    } on SocketException {
      print('📡 Network error during session check');
      onFlow(AuthFlow.login);
    } catch (e) {
      print('❌ Session check error: $e');
      onFlow(AuthFlow.login);
    }
  }


  // Future<void> handleSessionCheck(Function(AuthFlow) onFlow) async {
  //   final firebaseUser = _firebaseAuth.currentUser;
  //
  //   if (firebaseUser != null) {
  //     final idToken = await firebaseUser.getIdToken();
  //     if (idToken == null) {
  //       onFlow(AuthFlow.login);
  //       return;
  //     }
  //     await handleOtpTokenVerification(idToken, onFlow);
  //   } else {
  //     onFlow(AuthFlow.login);
  //   }
  // }



  Future<void> completeUserProfile(String first, String last) async {
    _setLoading();
    try {
      // await _api.post(
      //   endpoint: "/auth/update_profile",
      //   body: {
      //     "first_name": first,
      //     "last_name": last,
      //   },
      //   extraHeaders: {"X-Refresh-Token": SessionManager.refreshToken ?? ''},
      // );
      await _api.post(
        endpoint: "/auth/update_profile", // your connector that calls /auth/verify_google_user again WITH names
        body: {"first_name": first, "last_name": last},
        extraHeaders: {"X-Refresh-Token": SessionManager.refreshToken ?? ''}, // if you use this
      );

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


  Future<bool> fetchUserProfile({bool silent = false}) async {
    if (!silent) _setLoading();

    try {
      // Skip if offline
      final endpointService = locator<EndPointService>();
      if (endpointService.currentNetworkStatus == NetworkStatus.noInternet) {
        debugPrint('📡 No internet connection, skipping profile fetch');
        if (!silent) _setState(currentState.copyWith(status: AuthStatus.idle));
        return false;
      }

      // Real call (no isDebug branch)
      final res = await _api.get(
        endpoint: "/auth/get_profile",
        extraHeaders: {"X-Refresh-Token": SessionManager.refreshToken ?? ''},
        requireAuth: true,
      );

      // Ensure we have a Map to work with
      final Map<String, dynamic> resMap =
      res is Map<String, dynamic> ? Map<String, dynamic>.from(res) : <String, dynamic>{};

      // Server may indicate profile completion needed
      if ((resMap['needs_profile'] ?? false) == true) {
        return true; // needs profile
      }

      // Normalize snake_case → camelCase
      if (resMap.containsKey('first_name') && !resMap.containsKey('firstName')) {
        resMap['firstName'] = resMap['first_name'];
      }
      if (resMap.containsKey('last_name') && !resMap.containsKey('lastName')) {
        resMap['lastName'] = resMap['last_name'];
      }
      if (resMap.containsKey('_id') && !resMap.containsKey('uid')) {
        resMap['uid'] = resMap['_id'];
      }

      _setUser(UserModel.fromJson(resMap));
      return false; // profile present & set
    } on SocketException {
      debugPrint('📡 Network error while fetching profile');
      if (!silent) _setState(currentState.copyWith(status: AuthStatus.idle));
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("404") || msg.contains("User not found")) {
        logout();
      } else if (!silent) {
        _setError(msg);
      }
      // Preserve previous semantics (true => needs profile / go to flow)
      return true;
    }
  }


  // Future<bool> fetchUserProfile({bool silent = false}) async {
  //   if (!silent) _setLoading();
  //   try {
  //     var res;
  //     if(_api.isDebug){
  //        res = {
  //        };
  //     }else{
  //        res = await _api.get(
  //         endpoint: "/auth/get_profile",
  //         extraHeaders: {"X-Refresh-Token": SessionManager.refreshToken ?? ''},
  //       );
  //     }
  //
  //     if (res is Map && res["needs_profile"] == true) {
  //       // don’t clear user here; let UI keep fallbacks (email/displayName)
  //       return true;
  //     }
  //
  //     // 🔧 Normalize snake_case → camelCase so UserModel.fromJson can read it
  //     final normalized = Map<String, dynamic>.from(res as Map);
  //     if (normalized.containsKey('first_name') && !normalized.containsKey('firstName')) {
  //       normalized['firstName'] = normalized['first_name'];
  //     }
  //     if (normalized.containsKey('last_name') && !normalized.containsKey('lastName')) {
  //       normalized['lastName'] = normalized['last_name'];
  //     }
  //     if (normalized.containsKey('_id') && !normalized.containsKey('uid')) {
  //       normalized['uid'] = normalized['_id'];
  //     }
  //
  //     _setUser(UserModel.fromJson(normalized));
  //     return false;
  //   } catch (e) {
  //     final msg = e.toString();
  //     if (msg.contains("404") || msg.contains("User not found")) {
  //       logout();
  //     } else {
  //       _setError(msg);
  //     }
  //     return true;
  //   }
  // }


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
      final res = await _api.post(endpoint: "/auth/refresh_token", body: {
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
    try {
      await SessionManager.loadTokens();
      final token = SessionManager.token;

      if (token == null || SessionManager.isTokenExpired(token)) {
        final refreshed = await SessionManager.tryRefreshToken();
        if (refreshed) {
          // Don't block on profile fetch if network is poor
          final needsProfile = await fetchUserProfile(silent: true);
          if (needsProfile) {
            onResult(AuthFlow.nameEntry);
          } else {
            completeUserProfileAndNavigate(onResult);
          }
        } else {
          logout();
          onResult(AuthFlow.login);
        }
      } else {
        // Token is valid, try to fetch profile but don't block
        final needsProfile = await fetchUserProfile(silent: true);
        if (needsProfile) {
          onResult(AuthFlow.nameEntry);
        } else {
          completeUserProfileAndNavigate(onResult);
        }
      }
    } catch (e) {
      print('❌ Auto-login error: $e');
      onResult(AuthFlow.login);
    }
  }

  // Future<void> autoLogin(Function(AuthFlow) onResult) async {
  //   await SessionManager.loadTokens();
  //   final token = SessionManager.token;
  //   if (token == null || isTokenExpired(token)) {
  //     final refreshed = await SessionManager.tryRefreshToken();
  //     if (refreshed) {
  //       await fetchUserProfile();
  //       completeUserProfileAndNavigate(onResult);
  //     } else {
  //       logout();
  //       onResult(AuthFlow.login);
  //     }
  //   } else {
  //     await fetchUserProfile();
  //     completeUserProfileAndNavigate(onResult);
  //   }
  // }




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

  // Future<void> logout() async {
  //   await FirebaseAuth.instance.signOut();
  //   await SessionManager.clearToken();
  //   _clearState();
  // }

  Future<void> logout() async {
    try {
      // Optional: Tell backend to invalidate refresh token
      final uid = SessionManager.uid;
      if (uid != null) {
        await _api.post(endpoint: "/auth/logout", body: {
          "uid": uid,
        });
      }
    } catch (e) {
      debugPrint("⚠️ Logout API failed: $e");
    }

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

  // inside AuthService

  Future<void> ensureProfileLoaded() async {
    // Already have a user? nothing to do.
    if (currentState.user != null) return;

    // If we have a valid token (your SessionManager or state can tell),
    // fetch in background. Wrap in try so UI doesn’t break if it fails.
    try {
      await fetchUserProfile(silent: true); // call your existing method
    } catch (_) {
      // ignore here; stream will emit on failure if you want
    }
  }


  int get otpCountdown => _otpCountdown;
}