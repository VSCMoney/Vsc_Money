// lib/controllers/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class SessionManager {
  static String? _token;
  static String? _refreshToken;
  static String? _uid;

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static String? get uid => _uid;

  /// Load tokens from storage on app start
  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
    _uid = prefs.getString("uid");
  }

  /// Save tokens after login/refresh
  static Future<void> saveTokens(String accessToken, String refreshToken, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = accessToken;
    _refreshToken = refreshToken;
    _uid = uid ?? _uid;

    await prefs.setString("access_token", accessToken);
    await prefs.setString("refresh_token", refreshToken);
    if (uid != null) {
      await prefs.setString("uid", uid);
    }
  }

  /// Clear session on logout
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("uid");

    _token = null;
    _refreshToken = null;
    _uid = null;
  }

  /// ✅ Check login state
  static Future<bool> isLoggedIn() async {
    await loadTokens();
    return _token != null && _uid != null;
  }

  /// 🔄 Check token validity & refresh if expired
  static Future<bool> checkTokenValidityAndRefresh() async {
    await loadTokens();
    if (_token == null || isTokenExpired(_token!)) {
      return await tryRefreshToken();
    }
    return true;
  }

  /// 🔄 Refresh token logic
  static Future<bool> tryRefreshToken() async {
    if (_refreshToken == null || _uid == null) return false;

    try {
      final res = await ApiService().postRaw(
        endpoint: "/auth/refresh_token",
        body: {
          "refresh_token": _refreshToken,
          "uid": _uid,
        },
      );

      final Map<String, dynamic> responseBody = jsonDecode(res.body);
      final newToken = responseBody['access_token'];
      if (newToken != null) {
        await saveTokens(newToken, _refreshToken!);
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Refresh token failed: $e");
      return false;
    }
  }

  /// ⏱️ JWT expiry check
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiry = payload['exp'];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return currentTime >= expiry;
    } catch (e) {
      print("Token decode error: $e");
      return true;
    }
  }
}
