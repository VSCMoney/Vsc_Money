// lib/controllers/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/services/locator.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class SessionManager {
  static String? _token;
  static String? _refreshToken;
  static String? _uid;

  static String? get token => _token;
  static set token(String? value) => _token = value;
  static String? get refreshToken => _refreshToken;
  static String? get uid => _uid;

  /// Load tokens from storage on app start
  // static Future<void> loadTokens() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _token = prefs.getString("access_token");
  //   _refreshToken = prefs.getString("refresh_token");
  //   _uid = prefs.getString("uid");
  // }
  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
    _uid = prefs.getString("uid");

    if (_token != null && (_uid == null || _uid!.isEmpty)) {
      final extracted = _extractUidFromToken(_token!);
      if (extracted != null) {
        _uid = extracted;
        await prefs.setString("uid", _uid!);
        print("✅ UID extracted from token and saved: $_uid");
      } else {
        print("❌ Failed to extract UID from token");
      }
    }
  }


  /// Save tokens after login/refresh
  // static Future<void> saveTokens(String accessToken, String refreshToken, {String? uid}) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _token = accessToken;
  //   _refreshToken = refreshToken;
  //   _uid = uid ?? _uid;
  //
  //   await prefs.setString("access_token", accessToken);
  //   await prefs.setString("refresh_token", refreshToken);
  //   if (uid != null) {
  //     await prefs.setString("uid", uid);
  //   }
  //   final themeService =locator<ThemeService>();
  //   final isDark = themeService.isDark;
  //   await prefs.setBool('is_dark_mode', isDark);
  // }
  static Future<void> saveTokens(String accessToken, String refreshToken, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = accessToken;
    _refreshToken = refreshToken;
    _uid = uid ?? _uid;

    await prefs.setString("access_token", accessToken);
    await prefs.setString("refresh_token", refreshToken);
    if (_uid != null) await prefs.setString("uid", _uid!);

    final themeService = locator<ThemeService>();
    final isDark = themeService.isDark;
    await prefs.setBool('is_dark_mode', isDark);

    print("💾 Tokens saved:");
    print("  - access_token: $accessToken");
    print("  - refresh_token: $refreshToken");
    print("  - uid: $_uid");
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
    // 🌞 Reset theme to default (light)
    final themeService = locator<ThemeService>();
    await themeService.resetTheme();
  }

  /// ✅ Check login state
  // static Future<bool> isLoggedIn() async {
  //   await loadTokens();
  //   return _token != null && _uid != null;
  // }
  static Future<bool> isLoggedIn() async {
    await loadTokens();
    print("🔐 Checking login status...");
    print("  - token: $_token");
    print("  - uid: $_uid");
    return _token != null && _uid != null;
  }


  /// 🔄 Check token validity & refresh if expired
  // static Future<bool> checkTokenValidityAndRefresh() async {
  //   await loadTokens();
  //   // print("🪪 Checking token: $_token");
  //   // print("🔁 Refresh token: $_refreshToken");
  //
  //   if (_token == null || isTokenExpired(_token!)) {
  //     return await tryRefreshToken();
  //   }
  //   return true;
  // }
  static int _refreshAttempts = 0;

  static Future<bool> checkTokenValidityAndRefresh() async {
    await loadTokens();

    if (_refreshAttempts > 2) {
      print("🚫 Too many refresh attempts — aborting refresh.");
      return false;
    }

    if (_token == null || isTokenExpired(_token!)) {
      _refreshAttempts++;
      final result = await tryRefreshToken();
      if (result) {
        _refreshAttempts = 0; // reset counter
      }
      return result;
    }

    _refreshAttempts = 0; // reset if valid token
    return true;
  }



  static String? _extractUidFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print("❌ Invalid token parts");
        return null;
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      print("🔍 Decoded JWT payload: $payload");

      final jsonPayload = json.decode(payload);
      return jsonPayload['uid'];
    } catch (e) {
      print("❌ Failed to extract UID: $e");
      return null;
    }
  }



  /// 🔄 Refresh token logic
  static Future<bool> tryRefreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final res = await ApiService().postRaw(
        endpoint: "/auth/refresh_token",
        body: {
          "refresh_token": _refreshToken,
          "uid": _uid ?? '', // avoid null
        },
      );

      if (res.statusCode != 200) {
        print("❌ Refresh API returned ${res.statusCode}");
        return false;
      }

      final Map<String, dynamic> responseBody = jsonDecode(res.body);
      final newToken = responseBody['access_token'];

      if (newToken != null) {
        final newUid = _extractUidFromToken(newToken);
        await saveTokens(newToken, _refreshToken!, uid: newUid);
        return true;
      }

      return false;
    } catch (e) {
      print("❌ Refresh token failed: $e");
      return false;
    }
  }




  // static Future<bool> tryRefreshToken() async {
  //   if (_refreshToken == null || _uid == null) return false;
  //
  //   try {
  //     final res = await ApiService().postRaw(
  //       endpoint: "/auth/refresh_token",
  //       body: {
  //         "refresh_token": _refreshToken,
  //         "uid": _uid,
  //       },
  //     );
  //
  //     final Map<String, dynamic> responseBody = jsonDecode(res.body);
  //     final newToken = responseBody['access_token'];
  //     if (newToken != null) {
  //       await saveTokens(newToken, _refreshToken!);
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     print("❌ Refresh token failed: $e");
  //     return false;
  //   }
  // }

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
