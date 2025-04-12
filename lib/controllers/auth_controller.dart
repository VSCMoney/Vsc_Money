import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vscmoney/controllers/session_manager.dart';
import '../models/user_model.dart';
import '../screens/presentation/auth/profile_screen.dart';
import '../screens/presentation/home/home_screen.dart';
import '../services/api_service.dart';

class AuthController with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String? error;
  UserModel? currentUser;

  // PHONE OTP
  // Future<void> verifyPhoneOtp(String idToken) async {
  //   _setLoading(true);
  //   try {
  //     final response = await _apiService.post(
  //       endpoint: "/auth/verify_user",
  //       body: {"id_token": idToken},
  //     );
  //
  //     if (response['token'] != null && response['refresh_token'] != null) {
  //       await SessionManager.saveTokens(response['token'], response['refresh_token']);
  //       await fetchUserProfile();
  //     }
  //   } catch (e) {
  //     error = e.toString();
  //   }
  //   _setLoading(false);
  // }

  Future<void> verifyPhoneOtp(String idToken,BuildContext context) async {
    _setLoading(true);
    try {
      final response = await _apiService.post(
        endpoint: "/auth/verify_user",
        body: {"id_token": idToken},
      );

      if (response['token'] != null && response['refresh_token'] != null) {
        await SessionManager.saveTokens(response['token'], response['refresh_token']);

        await fetchUserProfile();

        if (currentUser?.firstName == null || currentUser?.lastName == null) {
          // 👉 Navigate to EnterNameScreen if user is new
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EnterNameScreen()),
          );
        } else {
          // ✅ User already has name → go to Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        error = "Invalid response from server";
      }
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }


  // GOOGLE SIGN-IN
  Future<void> verifyGoogleUser(String idToken) async {
    await _verifyAndLogin("/auth/verify_google_user", idToken);
  }

  // EMAIL OTP
  Future<void> verifyEmailOtp(String idToken) async {
    await _verifyAndLogin("/auth/verify_email_otp", idToken);
  }

  // Common verify logic
  Future<void> _verifyAndLogin(String endpoint, String idToken) async {
    _setLoading(true);
    try {
      final res = await _apiService.post(
        endpoint: endpoint,
        body: {"id_token": idToken},
      );

      if (res['token'] != null && res['refresh_token'] != null) {
        await SessionManager.saveTokens(res['token'], res['refresh_token']);
        await fetchUserProfile();
      } else {
        error = "Invalid response from server";
      }
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  // // Fetch user profile
  // Future<void> fetchUserProfile() async {
  //   try {
  //     final res = await _apiService.get(endpoint: "/auth/get_profile");
  //     currentUser = UserModel.fromJson(res);
  //     notifyListeners();
  //   } catch (e) {
  //     error = e.toString();
  //   }
  // }



  Future<void> fetchUserProfile() async {
    try {
      final res = await _apiService.get(endpoint: "/auth/get_profile");
      currentUser = UserModel.fromJson(res);
      notifyListeners();
    } catch (e) {
      final errorString = e.toString();
      debugPrint("❌ Error in fetchUserProfile: $errorString");

      if (errorString.contains("User not found") || errorString.contains("404")) {
        // 🧹 Force logout if user not found in DB (deleted manually)
        logout();

        // Optional: show snackbar or redirect to login
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Session expired")));
      } else {
        error = errorString;
      }
    }
  }


  Future<void> completeUserProfile(String firstName, String lastName) async {
    _setLoading(true);
    try {
      await _apiService.post(
        endpoint: "/auth/update_profile",
        body: {
          "first_name": firstName,
          "last_name": lastName,
        },
      );
      await fetchUserProfile(); // Refresh the user info
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }


  // Refresh access token
  Future<void> refreshAccessToken() async {
    try {
      final res = await _apiService.post(
        endpoint: "/auth/refresh_token",
        body: {
          "refresh_token": SessionManager.refreshToken,
          "uid": currentUser?.uid,
        },
      );

      if (res["access_token"] != null) {
        await SessionManager.saveTokens(res["access_token"], SessionManager.refreshToken!);
      }
    } catch (e) {
      error = e.toString();
    }
  }

  // Token expiry checker
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = payload['exp'];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return currentTime >= expiry;
    } catch (e) {
      print("Token decode error: $e");
      return true;
    }
  }

  // Auto-login with refresh logic
  Future<bool> checkTokenValidityAndRefresh() async {
    await SessionManager.loadTokens();
    final token = SessionManager.token;

    if (token == null || isTokenExpired(token)) {
      final refreshed = await SessionManager.tryRefreshToken();
      if (refreshed) await fetchUserProfile();
      return refreshed;
    } else {
      await fetchUserProfile();
      return true;
    }
  }

  // Auto login on app start
  Future<void> autoLogin() async {
    final success = await checkTokenValidityAndRefresh();
    if (!success) logout();
  }

  // Logout
  void logout() {
    SessionManager.clearToken();
    currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    error = null;
    notifyListeners();
  }
}
