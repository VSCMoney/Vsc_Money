// lib/services/auth_service.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart'as http;
import '../models/stock_detail.dart';

// class AuthService {
//   static final _auth = FirebaseAuth.instance;
//   static String? _verificationId;
//
//   static Future<void> sendOtp(String phoneNumber) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         // Auto-retrieval (only Android sometimes)
//         await _auth.signInWithCredential(credential);
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         throw Exception(e.message);
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         _verificationId = verificationId;
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }
//
//   static Future<String> verifyOtp(String otp) async {
//     if (_verificationId == null) throw Exception("Verification ID not found");
//
//     final credential = PhoneAuthProvider.credential(
//       verificationId: _verificationId!,
//       smsCode: otp,
//     );
//
//     final userCred = await _auth.signInWithCredential(credential);
//     final idToken = await userCred.user?.getIdToken();
//
//     if (idToken == null) throw Exception("Failed to retrieve ID token");
//
//     return idToken;
//   }
// }



class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;

  static Future<void> sendOtp(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken, // Add this to reduce reCAPTCHA
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval (only Android sometimes)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // More detailed error handling
          String errorMessage = 'Verification failed';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'app-not-authorized':
              errorMessage = 'App is not authorized for Firebase Authentication';
              break;
            default:
              errorMessage = e.message ?? 'Unknown error occurred';
          }
          throw Exception(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken; // Save for potential future resend
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      // Additional error logging or handling
      print('OTP Send Error: $e');
      rethrow;
    }
  }

  static Future<String> verifyOtp(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception("Verification ID not found. Please resend OTP.");
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final idToken = await userCred.user?.getIdToken();

      if (idToken == null) throw Exception("Failed to retrieve ID token");

      // Optional: Clear verification ID after successful login
      _verificationId = null;

      return idToken;
    } on FirebaseAuthException catch (e) {
      // More specific Firebase authentication errors
      String errorMessage = 'OTP verification failed';
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please resend OTP.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('OTP Verify Error: $e');
      rethrow;
    }
  }

  // Optional: Add a method to resend OTP
  static Future<void> resendOtp(String phoneNumber) async {
    try {
      await sendOtp(phoneNumber);
    } catch (e) {
      print('Resend OTP Error: $e');
      rethrow;
    }
  }
}



class StockService {
  static const String baseUrl = "http://localhost:8000";

  static Future<StockDetail?> getStockDetail(String symbol) async {
    try {
      final url = Uri.parse("https://fastapi-chatbot-717280964807.asia-south1.run.app/stocks/detail?symbol=$symbol");
      final res = await http.get(url);
      print("📦 Raw Response: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return StockDetail.fromJson(data);
      } else {
        print("❌ API Error: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception: $e");
      return null;
    }
  }
}