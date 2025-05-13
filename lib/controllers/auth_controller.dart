// // lib/controllers/auth_controller.dart
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get_it/get_it.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:vscmoney/controllers/session_manager.dart';
// import 'package:vscmoney/services/locator.dart';
// import '../models/user.dart';
// import '../services/api_service.dart';
// import '../services/auth_service.dart';
//
//
// // TODO: Merge with AuthService
// // TODO: State Subject
// class AuthController {
//   final _loadingSubject = BehaviorSubject<bool>.seeded(false);
//   final _errorSubject = BehaviorSubject<String?>.seeded(null);
//   final _userSubject = BehaviorSubject<UserModel?>.seeded(null);
//
//   Stream<bool> get loadingStream => _loadingSubject.stream;
//   Stream<String?> get errorStream => _errorSubject.stream;
//   Stream<UserModel?> get userStream => _userSubject.stream;
//
//   bool get isLoading => _loadingSubject.value;
//   String? get error => _errorSubject.value;
//   UserModel? get currentUser => _userSubject.value;
//
//   final ApiService _api = locator<ApiService>();
//
//   void setLoading(bool val) => _loadingSubject.add(val);
//   void setError(String? val) => _errorSubject.add(val);
//   void setUser(UserModel? user) => _userSubject.add(user);
//
//
//   Future<void> verifyPhoneOtp(String idToken, Function(String route) onSuccess, Function onFail) async {
//     setLoading(true);
//     try {
//       final res = await _api.post(endpoint: "/auth/verify_user", body: {"id_token": idToken});
//       await SessionManager.saveTokens(res['token'], res['refresh_token']);
//       await fetchUserProfile();
//
//       print(currentUser?.firstName ?? "");
//       print(currentUser?.lastName ?? "");
//
//       if ((currentUser?.firstName?.isEmpty ?? true) || (currentUser?.lastName?.isEmpty ?? true)) {
//         onSuccess('enter_name');
//       } else {
//         onSuccess('home');
//       }
//     } catch (e) {
//       setError(e.toString());
//       onFail();
//     } finally {
//       setLoading(false);
//     }
//   }
//
//
//   Future<void> verifyGoogleUser(String idToken) async {
//     await _verifyGeneric("/auth/verify_google_user", idToken);
//   }
//
//
//   Future<void> verifyEmailOtp(String idToken) async {
//     await _verifyGeneric("/auth/verify_email_otp", idToken);
//   }
//
//   Future<void> _verifyGeneric(String endpoint, String idToken) async {
//     setLoading(true);
//     try {
//       final res = await _api.post(endpoint: endpoint, body: {"id_token": idToken});
//       await SessionManager.saveTokens(res['token'], res['refresh_token']);
//       await fetchUserProfile();
//     } catch (e) {
//       setError(e.toString());
//     } finally {
//       setLoading(false);
//     }
//   }
//
//
//   Future<void> fetchUserProfile() async {
//     try {
//       final res = await _api.get(endpoint: "/auth/get_profile");
//       setUser(UserModel.fromJson(res));
//     } catch (e) {
//       final msg = e.toString();
//       if (msg.contains("404") || msg.contains("User not found")) {
//         logout();
//       } else {
//         setError(msg);
//       }
//     }
//   }
//
//   Future<void> completeUserProfile(String first, String last) async {
//     setLoading(true);
//     try {
//       await _api.post(endpoint: "/auth/update_profile", body: {
//         "first_name": first,
//         "last_name": last,
//       });
//       await fetchUserProfile();
//     } catch (e) {
//       setError(e.toString());
//     } finally {
//       setLoading(false);
//     }
//   }
//
//
//   Future<void> refreshAccessToken() async {
//     try {
//       final res = await _api.post(endpoint: "/auth/refresh_token", body: {
//         "refresh_token": SessionManager.refreshToken,
//         "uid": currentUser?.uid,
//       });
//       if (res["access_token"] != null) {
//         await SessionManager.saveTokens(res["access_token"], SessionManager.refreshToken!);
//       }
//     } catch (e) {
//       setError(e.toString());
//     }
//   }
//
//
//   bool isTokenExpired(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length != 3) return true;
//       final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
//       final expiry = payload['exp'];
//       final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//       return now >= expiry;
//     } catch (e) {
//       print("Token parse error: $e");
//       return true;
//     }
//   }
//
//
//   Future<void> autoLogin(Function(bool isLoggedIn) onResult) async {
//     await SessionManager.loadTokens();
//     final token = SessionManager.token;
//     if (token == null || isTokenExpired(token)) {
//       final refreshed = await SessionManager.tryRefreshToken();
//       if (refreshed) {
//         await fetchUserProfile();
//         onResult(true);
//       } else {
//         logout();
//         onResult(false);
//       }
//     } else {
//       await fetchUserProfile();
//       onResult(true);
//     }
//   }
//
//
//   void logout() {
//     SessionManager.clearToken();
//     setUser(null);
//   }
//
//   void dispose() {
//     _loadingSubject.close();
//     _errorSubject.close();
//     _userSubject.close();
//   }
// }
