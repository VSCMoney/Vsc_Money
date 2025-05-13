// lib/services/auth_service.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart'as http;
import '../controllers/session_manager.dart';
import '../models/stock_detail.dart';


import 'dart:async';


import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../models/user.dart';
import '../services/api_service.dart';

import 'locator.dart';

enum AuthStatus { idle, loading, error, success }
enum AuthFlow { login, nameEntry, home }

class AuthState {
  final AuthStatus status;
  final String? error;
  final UserModel? user;

  const AuthState({this.status = AuthStatus.idle, this.error, this.user});

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _api = locator<ApiService>();
  final _authState = BehaviorSubject<AuthState>.seeded(const AuthState());

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

  // 🔐 Verification and Flow Routing
  Future<void> verifyBackendToken(
      String idToken,
      Function(String route) onSuccess,
      Function onFail,
      ) async {
    _setLoading();
    try {
      final res = await _api.post(endpoint: "/api/v1/auth/verify_user", body: {"id_token": idToken});
      //await SessionManager.saveTokens(res['token'], res['refresh_token']);
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
      print("UID extract failed: $e");
      return null;
    }
  }


  Future<void> refreshAccessToken() async {
    try {
      final res = await _api.post(endpoint: "/api/v1/auth/refresh_token", body: {
        "refresh_token": SessionManager.refreshToken,
        "uid": SessionManager.uid, // 👈 use existing UID
      });

      final newToken = res["access_token"];
      if (newToken != null) {
        // 👇 extract UID from token if backend doesn't return it
        String? uid = SessionManager.uid ?? extractUidFromToken(newToken);

        await SessionManager.saveTokens(newToken, SessionManager.refreshToken!, uid: uid);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }


  // Future<void> refreshAccessToken() async {
  //   try {
  //     final res = await _api.post(endpoint: "/api/v1/auth/refresh_token", body: {
  //       "refresh_token": SessionManager.refreshToken,
  //       "uid": currentState.user?.uid,
  //     });
  //     if (res["access_token"] != null) {
  //       await SessionManager.saveTokens(res["access_token"], SessionManager.refreshToken!);
  //     }
  //   } catch (e) {
  //     _setError(e.toString());
  //   }
  // }

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
      print("Token parse error: $e");
      return true;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut(); // clear Firebase session
    await SessionManager.clearToken();     // clear local tokens
    _clearState();                         // clear user & state
  }


  // 🔐 OTP Verification (Firebase)
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

  // 🔁 OTP Timer
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







// class AuthService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static String? _verificationId;
//   static int? _resendToken;
//
//   static Future<void> sendOtp(String phoneNumber) async {
//     try {
//       await _auth.setSettings(appVerificationDisabledForTesting: true);
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         timeout: const Duration(seconds: 60),
//         forceResendingToken: _resendToken, // Add this to reduce reCAPTCHA
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           // Auto-retrieval (only Android sometimes)
//           await _auth.signInWithCredential(credential);
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           // More detailed error handling
//           String errorMessage = 'Verification failed';
//           switch (e.code) {
//             case 'invalid-phone-number':
//               errorMessage = 'Invalid phone number format';
//               break;
//             case 'too-many-requests':
//               errorMessage = 'Too many requests. Please try again later.';
//               break;
//             case 'app-not-authorized':
//               errorMessage = 'App is not authorized for Firebase Authentication';
//               break;
//             default:
//               errorMessage = e.message ?? 'Unknown error occurred';
//           }
//           throw Exception(errorMessage);
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           _verificationId = verificationId;
//           _resendToken = resendToken; // Save for potential future resend
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           _verificationId = verificationId;
//         },
//       );
//     } catch (e) {
//       // Additional error logging or handling
//       print('OTP Send Error: $e');
//       rethrow;
//     }
//   }
//
//   static Future<String> verifyOtp(String otp) async {
//     try {
//       if (_verificationId == null) {
//         throw Exception("Verification ID not found. Please resend OTP.");
//       }
//
//       final credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );
//
//       final userCred = await _auth.signInWithCredential(credential);
//       final idToken = await userCred.user?.getIdToken();
//
//       if (idToken == null) throw Exception("Failed to retrieve ID token");
//
//       // Optional: Clear verification ID after successful login
//       _verificationId = null;
//
//       return idToken;
//     } on FirebaseAuthException catch (e) {
//       // More specific Firebase authentication errors
//       String errorMessage = 'OTP verification failed';
//       switch (e.code) {
//         case 'invalid-verification-code':
//           errorMessage = 'Invalid OTP. Please try again.';
//           break;
//         case 'session-expired':
//           errorMessage = 'OTP session expired. Please resend OTP.';
//           break;
//         default:
//           errorMessage = e.message ?? 'Verification failed';
//       }
//       throw Exception(errorMessage);
//     } catch (e) {
//       print('OTP Verify Error: $e');
//       rethrow;
//     }
//   }
//
//   // Optional: Add a method to resend OTP
//   static Future<void> resendOtp(String phoneNumber) async {
//     try {
//       await sendOtp(phoneNumber);
//     } catch (e) {
//       print('Resend OTP Error: $e');
//       rethrow;
//     }
//   }
// }


