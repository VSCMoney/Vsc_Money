// lib/controllers/session_manager.dart
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/services/locator.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/theme_service.dart';



class SessionManager {
  static String? _token;
  static String? _refreshToken;
  static String? _uid;
  static Completer<bool>? _refreshCompleter; // serialize concurrent refresh
  static String? get token => _token;
  static set token(String? value) => _token = value; // ✅ Added setter
  static String? get refreshToken => _refreshToken;
  static set refreshToken(String? value) => _refreshToken = value; // ✅ Added setter
  static String? get uid => _uid;
  static set uid(String? value) => _uid = value; // ✅ Added setter

  // ✅ Quick check without validation
  static bool hasTokenInPrefs() {
    return _token != null && _uid != null;
  }

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
    _uid = prefs.getString("uid");

    print("📦 Tokens loaded from storage:");
    print("  - access_token: $_token");
    print("  - refresh_token: $_refreshToken");
    print("  - uid: $_uid");

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

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("uid");

    _token = null;
    _refreshToken = null;
    _uid = null;
  }


  // static Future<bool> tryRefreshToken() async {
  //   if (_refreshToken == null) return false;
  //
  //   // If a refresh is already running, just await it
  //   if (_refreshCompleter != null) return _refreshCompleter!.future;
  //
  //   final c = Completer<bool>();
  //   _refreshCompleter = c;
  //   print('🔄 Refresh Called');
  //
  //   try {
  //     final res = await EndPointService().postRawNoRefresh(
  //       endpoint: "/auth/refresh_token", // ensure correct path (see B below)
  //       body: {
  //         "refresh_token": _refreshToken,
  //         "uid": _uid ?? '',
  //       },
  //       attachAuthHeader: false, // refresh should not require access token
  //     );
  //
  //     if (res.statusCode != 200) {
  //       print("❌ Refresh API returned ${res.statusCode}: ${res.body}");
  //       c.complete(false);
  //       return false;
  //     }
  //
  //     final Map<String, dynamic> responseBody = jsonDecode(res.body);
  //     final newToken = responseBody['access_token'];
  //
  //     if (newToken != null) {
  //       final newUid = _extractUidFromToken(newToken);
  //       await saveTokens(newToken, _refreshToken!, uid: newUid);
  //       c.complete(true);
  //       return true;
  //     }
  //
  //     c.complete(false);
  //     return false;
  //   } catch (e) {
  //     print("❌ Refresh token failed: $e");
  //     c.completeError(e);
  //     return false;
  //   } finally {
  //     _refreshCompleter = null;
  //   }
  // }

  // ✅ Non-blocking refresh method
  static Future<bool> tryRefreshToken() async {
    if (_refreshToken == null) return false;
    print('🔄 Refresh Called');

    try {
      // Use a method that doesn't trigger automatic token refresh
      final res = await EndPointService().postRawNoRefresh(  // ← Key change
        endpoint: "/auth/refresh_token",
        body: {
          "refresh_token": _refreshToken,
          "uid": _uid ?? '',
        },
        attachAuthHeader: false, // Don't send access token for refresh requests
      );

      if (res.statusCode != 200) {
        print("❌ Refresh API returned ${res.statusCode}: ${res.body}");
        return false;
      }

      final Map<String, dynamic> responseBody = jsonDecode(res.body);
      final newToken = responseBody['access_token'];

      if (newToken != null) {
        final newUid = _extractUidFromToken(newToken);
        await saveTokens(newToken, _refreshToken!, uid: newUid);
        print("✅ Token refreshed successfully");
        return true;
      }

      print("❌ No access_token in response");
      return false;
    } catch (e) {
      print("❌ Refresh token failed: $e");
      return false;
    }
  }

  // static bool isTokenExpired(String token) {
  //   try {
  //     final parts = token.split('.');
  //     if (parts.length != 3) return true;
  //     final payload = json.decode(
  //       utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  //     );
  //     final expiry = payload['exp'];
  //     final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  //     const skew = 60; // seconds
  //     return currentTime >= (expiry - skew);
  //   } catch (e) {
  //     print("Token decode error: $e");
  //     return true;
  //   }
  // }


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

  // ✅ Keep old methods for backward compatibility
  static Future<bool> isLoggedIn() async {
    await loadTokens();
    print("🔐 Checking login status...");
    print("  - token: $_token");
    print("  - uid: $_uid");
    return _token != null && _uid != null;
  }

  static int _refreshAttempts = 0;

  static Future<bool> checkTokenValidityAndRefresh() async {
    await loadTokens();

    if (_refreshAttempts > 2) {
      print("🚫 Too many refresh attempts — aborting refresh.");
      _refreshAttempts = 0; // Reset for next time
      return false;
    }

    if (_token == null || isTokenExpired(_token!)) {
      _refreshAttempts++;
      final result = await tryRefreshToken();
      if (result) {
        _refreshAttempts = 0; // Reset on success
      }
      return result;
    }

    _refreshAttempts = 0; // Reset if valid token
    return true;
  }
}