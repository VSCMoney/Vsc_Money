// // lib/network/end_point_service.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:rxdart/rxdart.dart';
//
// import '../controllers/session_manager.dart';
//
//
//
//
// enum NetworkStatus { connected, noInternet, slow }
//
// class EndPointService {
//   static final EndPointService _instance = EndPointService._internal();
//   factory EndPointService() => _instance;
//   EndPointService._internal() {
//     _initNetworkMonitoring();
//   }
//
//   final Connectivity _connectivity = Connectivity();
//   final BehaviorSubject<NetworkStatus> _networkStatus =
//   BehaviorSubject.seeded(NetworkStatus.connected);
//   Timer? _speedCheckTimer;
//   Stream<NetworkStatus> get networkStatusStream => _networkStatus.stream;
//   NetworkStatus get currentNetworkStatus => _networkStatus.value;
//
//   bool isDebug = false;
//
//   // Base URL
//   final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
//   //final String _baseUrl = "http://localhost:8000";
//    //final String _baseUrl = 'http://192.168.1.5:8000';
//
//   String? _lastEndpoint;
//   Map<String, dynamic>? _lastBody;
//   String _lastMethod = 'GET';
//
//   void _initNetworkMonitoring() {
//     _checkConnectivity();
//     _connectivity.onConnectivityChanged.listen((_) => _checkConnectivity());
//     _speedCheckTimer =
//         Timer.periodic(const Duration(seconds: 10), (_) => _checkNetworkSpeed());
//   }
//
//   Future<void> _checkConnectivity() async {
//     try {
//       final result = await _connectivity.checkConnectivity();
//       if (result == ConnectivityResult.none) {
//         _updateNetworkStatus(NetworkStatus.noInternet);
//       } else {
//         await _checkNetworkSpeed();
//       }
//     } catch (e) {
//       debugPrint("Connectivity check error: $e");
//     }
//   }
//
//   Future<void> _checkNetworkSpeed() async {
//     if (_networkStatus.value == NetworkStatus.noInternet) return;
//
//     try {
//       final sw = Stopwatch()..start();
//       final response = await http
//           .get(Uri.parse('https://www.google.com'))
//           .timeout(const Duration(seconds: 5));
//       sw.stop();
//
//       if (response.statusCode == 200) {
//         final speed = sw.elapsedMilliseconds;
//         _updateNetworkStatus(speed > 2000 ? NetworkStatus.slow : NetworkStatus.connected);
//       } else {
//         _updateNetworkStatus(NetworkStatus.noInternet);
//       }
//     } on SocketException {
//       _updateNetworkStatus(NetworkStatus.noInternet);
//     } on TimeoutException {
//       _updateNetworkStatus(NetworkStatus.slow);
//     } catch (e) {
//       debugPrint("Network speed check error: $e");
//     }
//   }
//
//   void _updateNetworkStatus(NetworkStatus newStatus) {
//     if (_networkStatus.value != newStatus) {
//       _networkStatus.add(newStatus);
//       _showNetworkStatusToast(newStatus);
//
//       if (newStatus == NetworkStatus.connected && _lastEndpoint != null) {
//         _retryLastRequest();
//       }
//     }
//   }
//
//   void _showNetworkStatusToast(NetworkStatus status) {
//     switch (status) {
//       case NetworkStatus.connected:
//        // Fluttertoast.showToast(msg: "✅ Back online", gravity: ToastGravity.TOP);
//         break;
//       case NetworkStatus.slow:
//        // Fluttertoast.showToast(msg: "⚠️ Internet is slow", gravity: ToastGravity.TOP);
//         break;
//       case NetworkStatus.noInternet:
//        // Fluttertoast.showToast(msg: "❌ No internet connection", gravity: ToastGravity.TOP);
//         break;
//     }
//   }
//
//   Future<void> _checkConnection() async {
//     if (currentNetworkStatus == NetworkStatus.noInternet) {
//       throw const SocketException("No internet connection");
//     }
//   }
//
//   // ==========================
//   // HTTP HELPERS (with logging)
//   // ==========================
//
// // GET with optional query params; logs full request & response
//   Future<dynamic> get({
//     required String endpoint,
//     Map<String, String>? extraHeaders,
//     Map<String, dynamic>? query, // 👈 added
//   }) async {
//     await _checkConnection();
//     await SessionManager.checkTokenValidityAndRefresh();
//     _storeLastRequest(endpoint, null, 'GET');
//
//     final uri = Uri.parse("$_baseUrl$endpoint")
//         .replace(queryParameters: query?.map((k, v) => MapEntry(k, v.toString())));
//
//     final headers = <String, String>{
//       "Content-Type": "application/json",
//       if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}",
//       ...?extraHeaders,
//     };
//
//     // Log exactly what you're sending
//     ConsoleHttpLogger.request(
//       method: 'GET',
//       url: uri,
//       headers: headers,
//       body: query != null ? jsonEncode(query) : null,
//     );
//
//     final sw = Stopwatch()..start();
//     final res = await http.get(uri, headers: headers);
//     sw.stop();
//
//     ConsoleHttpLogger.response(
//       method: 'GET',
//       url: uri,
//       statusCode: res.statusCode,
//       duration: sw.elapsed,
//       headers: res.headers,
//       body: res.body,
//     );
//
//     return _handleResponse(res, method: 'GET', url: uri.toString());
//   }
//
// // POST (json); logs payload
//   Future<dynamic> post({
//     required String endpoint,
//     Map<String, dynamic>? body,
//     Map<String, String>? extraHeaders,
//   }) async {
//     await _checkConnection();
//     await SessionManager.checkTokenValidityAndRefresh();
//     _storeLastRequest(endpoint, body, 'POST');
//
//     final uri = Uri.parse("$_baseUrl$endpoint");
//     final headers = <String, String>{
//       "Content-Type": "application/json",
//       if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}",
//       ...?extraHeaders,
//     };
//
//     final bodyStr = jsonEncode(body ?? {});
//
//     ConsoleHttpLogger.request(
//       method: 'POST',
//       url: uri,
//       headers: headers,
//       body: bodyStr.isNotEmpty ? bodyStr : null,
//     );
//
//     final sw = Stopwatch()..start();
//     final res = await http.post(uri, headers: headers, body: bodyStr);
//     sw.stop();
//
//     ConsoleHttpLogger.response(
//       method: 'POST',
//       url: uri,
//       statusCode: res.statusCode,
//       duration: sw.elapsed,
//       headers: res.headers,
//       body: res.body,
//     );
//
//     return _handleResponse(res, method: 'POST', url: uri.toString());
//   }
//
// // POST raw (json) returning http.Response; logs payload
//   Future<http.Response> postRaw({
//     required String endpoint,
//     Map<String, dynamic>? body,
//   }) async {
//     await _checkConnection();
//     await SessionManager.checkTokenValidityAndRefresh();
//     _storeLastRequest(endpoint, body, 'POST');
//
//     final uri = Uri.parse("$_baseUrl$endpoint");
//     final headers = <String, String>{
//       "Content-Type": "application/json",
//       if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
//     };
//
//     final bodyStr = jsonEncode(body ?? {});
//
//     ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);
//
//     final sw = Stopwatch()..start();
//     final res = await http.post(uri, headers: headers, body: bodyStr);
//     sw.stop();
//
//     ConsoleHttpLogger.response(
//       method: 'POST',
//       url: uri,
//       statusCode: res.statusCode,
//       duration: sw.elapsed,
//       headers: res.headers,
//       body: res.body,
//     );
//
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw ApiException(
//         statusCode: res.statusCode,
//         method: 'POST',
//         url: uri.toString(),
//         responseBody: res.body,
//         responseHeaders: res.headers,
//         message: 'HTTP ${res.statusCode}',
//       );
//     }
//     return res;
//   }
//
// // POST streaming; logs payload + headers; error body captured if non-2xx
//   Future<http.StreamedResponse> postStream({
//     required String endpoint,
//     required Map<String, dynamic> body,
//   }) async {
//     await _checkConnection();
//     await SessionManager.checkTokenValidityAndRefresh();
//     _storeLastRequest(endpoint, body, 'POST');
//
//     final uri = Uri.parse("$_baseUrl$endpoint");
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
//       'Accept': 'text/event-stream',
//     };
//     final bodyStr = jsonEncode(body);
//
//     ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);
//
//     final request = http.Request('POST', uri)
//       ..headers.addAll(headers)
//       ..body = bodyStr;
//
//     final sw = Stopwatch()..start();
//     final streamed = await request.send();
//     sw.stop();
//
//     // We can’t easily print a long stream; we still log headers + status
//     ConsoleHttpLogger.response(
//       method: 'POST',
//       url: uri,
//       statusCode: streamed.statusCode,
//       duration: sw.elapsed,
//       headers: streamed.headers,
//       body: '(streamed response body)',
//     );
//
//     if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
//       final bodyErr = await streamed.stream.bytesToString();
//       throw ApiException(
//         statusCode: streamed.statusCode,
//         method: 'POST',
//         url: uri.toString(),
//         responseBody: bodyErr,
//         responseHeaders: streamed.headers,
//         message: 'HTTP ${streamed.statusCode}',
//       );
//     }
//
//     return streamed;
//   }
//
// // POST without auto refresh; logs payload
//   Future<http.Response> postRawNoRefresh({
//     required String endpoint,
//     required Map<String, dynamic> body,
//     bool attachAuthHeader = false,
//   }) async {
//     final uri = Uri.parse('$_baseUrl$endpoint');
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       if (attachAuthHeader && SessionManager.token != null)
//         'Authorization': 'Bearer ${SessionManager.token}',
//     };
//
//     final bodyStr = jsonEncode(body);
//
//     ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);
//
//     final sw = Stopwatch()..start();
//     final res = await http.post(uri, headers: headers, body: bodyStr);
//     sw.stop();
//
//     ConsoleHttpLogger.response(
//       method: 'POST',
//       url: uri,
//       statusCode: res.statusCode,
//       duration: sw.elapsed,
//       headers: res.headers,
//       body: res.body,
//       note: 'no auto-refresh',
//     );
//
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw ApiException(
//         statusCode: res.statusCode,
//         method: 'POST',
//         url: uri.toString(),
//         responseBody: res.body,
//         responseHeaders: res.headers,
//         message: 'HTTP ${res.statusCode}',
//       );
//     }
//     return res;
//   }
//
//   // ==========================
//   // Internals
//   // ==========================
//
//   void _storeLastRequest(String endpoint, Map<String, dynamic>? body, String method) {
//     _lastEndpoint = endpoint;
//     _lastBody = body;
//     _lastMethod = method;
//   }
//
//   Future<void> _retryLastRequest() async {
//     if (_lastEndpoint == null) return;
//     try {
//       if (_lastMethod == 'POST') {
//         await post(endpoint: _lastEndpoint!, body: _lastBody);
//       } else if (_lastMethod == 'GET') {
//         await get(endpoint: _lastEndpoint!);
//       }
//     } catch (e) {
//       debugPrint("Retry failed: $e");
//     }
//   }
//
//   dynamic _handleResponse(http.Response res, {required String method, required String url}) {
//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       try {
//         return jsonDecode(res.body);
//       } catch (_) {
//         return res.body;
//       }
//     }
//
//     String msg = 'HTTP ${res.statusCode}';
//     try {
//       final parsed = jsonDecode(res.body);
//       if (parsed is Map && parsed['detail'] != null) {
//         msg = parsed['detail'].toString();
//       } else if (parsed is Map && parsed['message'] != null) {
//         msg = parsed['message'].toString();
//       }
//     } catch (_) {
//       // keep default
//     }
//
//     throw ApiException(
//       statusCode: res.statusCode,
//       method: method,
//       url: url,
//       responseBody: res.body,
//       responseHeaders: res.headers,
//       message: msg,
//     );
//   }
//
//   void dispose() {
//     _networkStatus.close();
//     _speedCheckTimer?.cancel();
//   }
// }
//
// // Simple BehaviorSubject (if you’re not already importing rxdart)
//
//
//
//
// class ApiException implements Exception {
//   final int statusCode;
//   final String method;
//   final String url;
//   final String responseBody;
//   final Map<String, String>? responseHeaders;
//   final String? message;
//
//   ApiException({
//     required this.statusCode,
//     required this.method,
//     required this.url,
//     required this.responseBody,
//     this.responseHeaders,
//     this.message,
//   });
//
//   @override
//   String toString() =>
//       "ApiException($statusCode $method $url) ${message ?? ''}\n$responseBody";
// }
//
//
// class ConsoleHttpLogger {
//   /// Toggle ANSI colors in logs
//   static bool useColors = true;
//
//   /// Default limit for printed body size
//   static int defaultBodyMax = 10000000;
//
//   /// Whether to pretty-print JSON responses
//   static bool prettyPrintJson = true;
//
//   /// Pretty-print JSON if possible
//   static String _pretty(String body, {bool forceRaw = false}) {
//     if (forceRaw || !prettyPrintJson) {
//       return body;
//     }
//
//     try {
//       final obj = json.decode(body);
//       return const JsonEncoder.withIndent('  ').convert(obj);
//     } catch (_) {
//       return body;
//     }
//   }
//
//   static String _truncate(String s, int maxLength) {
//     if (s.length <= maxLength) return s;
//     return s.substring(0, maxLength) + ' …(truncated ${s.length - maxLength} chars)…';
//   }
//
//   // Colors
//   static String _green(String s) => useColors ? '\x1B[32m$s\x1B[0m' : s;
//   static String _red(String s)   => useColors ? '\x1B[31m$s\x1B[0m' : s;
//   static String _yellow(String s)=> useColors ? '\x1B[33m$s\x1B[0m' : s;
//   static String _cyan(String s)  => useColors ? '\x1B[36m$s\x1B[0m' : s;
//   static String _bold(String s)  => useColors ? '\x1B[1m$s\x1B[0m'  : s;
//   static String _magenta(String s) => useColors ? '\x1B[35m$s\x1B[0m' : s;
//
//   static String _statusColor(int code, String text) {
//     if (code >= 200 && code < 300) return _green(text);
//     if (code >= 400 && code < 500) return _yellow(text);
//     return _red(text);
//   }
//
//   static Map<String, String> _redactHeaders(Map<String, String> h) {
//     final out = Map<String, String>.from(h);
//     if (out.containsKey('Authorization')) {
//       out['Authorization'] = 'Bearer ***redacted***';
//     }
//     if (out.containsKey('X-Refresh-Token')) {
//       out['X-Refresh-Token'] = '***redacted***';
//     }
//     if (out.containsKey('Cookie')) {
//       out['Cookie'] = '***redacted***';
//     }
//     return out;
//   }
//
//   static void request({
//     required String method,
//     required Uri url,
//     required Map<String, String> headers,
//     String? body,
//     int? maxBodyLength,
//     bool prettyJson = true,
//   }) {
//     final h = _redactHeaders(headers);
//     final hasBody = body != null && body.isNotEmpty;
//     final actualMax = maxBodyLength ?? defaultBodyMax;
//     final usePretty = prettyJson && prettyPrintJson;
//
//     final lines = <String>[
//       '┌───────────────────────── REQUEST ─────────────────────────',
//       '│ ${_bold(method)} ${_cyan(url.toString())}',
//       '│ Headers: ${jsonEncode(h)}',
//     ];
//
//     if (hasBody) {
//       final formattedBody = usePretty ? _pretty(body!, forceRaw: !usePretty) : body!;
//       final truncatedBody = _truncate(formattedBody, actualMax);
//       lines.add('│ Body:');
//       lines.addAll(truncatedBody.split('\n').map((l) => '│   $l'));
//     }
//
//     lines.add('└──────────────────────────────────────────────────────────');
//     debugPrint(lines.join('\n'));
//   }
//
//   static void response({
//     required String method,
//     required Uri url,
//     required int statusCode,
//     required Duration duration,
//     required Map<String, String> headers,
//     required String body,
//     String? note,
//     int? maxBodyLength,
//     bool prettyJson = true,
//   }) {
//     final statusText = _statusColor(statusCode, '$statusCode ${_statusLabel(statusCode)}');
//     final h = _redactHeaders(headers);
//     final actualMax = maxBodyLength ?? defaultBodyMax;
//     final usePretty = prettyJson && prettyPrintJson;
//
//     final lines = <String>[
//       '┌──────────────────────── RESPONSE ────────────────────────',
//       '│ ${_bold(method)} ${_cyan(url.toString())}  •  ${_bold(duration.inMilliseconds.toString())}ms',
//       '│ Status: $statusText',
//       '│ Headers: ${jsonEncode(h)}',
//       if (note != null) '│ Note: $note',
//     ];
//
//     // Add content length info
//     final contentLength = headers['content-length'] ?? headers['Content-Length'];
//     if (contentLength != null) {
//       lines.add('│ Content-Length: ${_magenta(contentLength)} bytes');
//     }
//
//     lines.add('│ Body:');
//
//     final formattedBody = usePretty ? _pretty(body, forceRaw: !usePretty) : body;
//     final truncatedBody = _truncate(formattedBody, actualMax);
//     lines.addAll(truncatedBody.split('\n').map((l) => '│   $l'));
//
//     lines.add('└──────────────────────────────────────────────────────────');
//
//     final out = (statusCode >= 200 && statusCode < 300)
//         ? _green(lines.join('\n'))
//         : (statusCode >= 400 && statusCode < 500)
//         ? _yellow(lines.join('\n'))
//         : _red(lines.join('\n'));
//
//     debugPrint(out);
//   }
//
//   /// Special method for very large responses that should be logged minimally
//   static void responseMinimal({
//     required String method,
//     required Uri url,
//     required int statusCode,
//     required Duration duration,
//     required Map<String, String> headers,
//     required int bodyLength,
//     String? note,
//   }) {
//     final statusText = _statusColor(statusCode, '$statusCode ${_statusLabel(statusCode)}');
//     final h = _redactHeaders(headers);
//
//     final lines = <String>[
//       '┌──────────────────────── RESPONSE ────────────────────────',
//       '│ ${_bold(method)} ${_cyan(url.toString())}  •  ${_bold(duration.inMilliseconds.toString())}ms',
//       '│ Status: $statusText',
//       '│ Headers: ${jsonEncode(h)}',
//       if (note != null) '│ Note: $note',
//       '│ Body: ${_magenta('$bodyLength bytes')} (too large to display)',
//       '└──────────────────────────────────────────────────────────',
//     ];
//
//     final out = (statusCode >= 200 && statusCode < 300)
//         ? _green(lines.join('\n'))
//         : (statusCode >= 400 && statusCode < 500)
//         ? _yellow(lines.join('\n'))
//         : _red(lines.join('\n'));
//
//     debugPrint(out);
//   }
//
//   static String _statusLabel(int code) {
//     if (code >= 200 && code < 300) return 'OK';
//     if (code == 400) return 'Bad Request';
//     if (code == 401) return 'Unauthorized';
//     if (code == 403) return 'Forbidden';
//     if (code == 404) return 'Not Found';
//     if (code == 409) return 'Conflict';
//     if (code == 422) return 'Unprocessable Entity';
//     if (code >= 500 && code < 600) return 'Server Error';
//     return 'HTTP';
//   }
//
//   /// Helper method to detect if response is too large for comfortable logging
//   static bool isResponseTooLarge(String body, [int threshold = 100000]) {
//     return body.length > threshold;
//   }
// }
//
// String handleApiError(dynamic error) {
//   if (error is ApiException) {
//     return "${error.message ?? 'Request failed'} (code ${error.statusCode})";
//   } else if (error is SocketException) {
//     return "No Internet Connection";
//   } else if (error is FormatException) {
//     return "Invalid response format";
//   } else {
//     return "Something went wrong";
//   }
// }




// lib/network/end_point_service.dart
// services/api_service.dart
// Full updated file

// services/api_service.dart
// Full updated file

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import '../controllers/session_manager.dart';

enum NetworkStatus { connected, noInternet, slow }

class EndPointService {
  static final EndPointService _instance = EndPointService._internal();
  factory EndPointService() => _instance;
  EndPointService._internal() {
    _initNetworkMonitoring();
    _initAppLifecycleListener();
  }

  // ---------------------------------------------------------------------------
  // Config
  // ---------------------------------------------------------------------------

  /// Your backend base URL
  final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
  // final String _baseUrl = 'http://192.168.1.5:8000';
  // final String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator → host
   //final String _baseUrl = 'http://localhost:8000'; // iOS simulator → host

  /// Quick, lightweight probes. Success on *any* means “reachable network”.
  List<Uri> get _probeUris => [
    Uri.parse('$_baseUrl/'), // your API root should return quickly (200/404)
    Uri.parse('https://www.gstatic.com/generate_204'),
    Uri.parse('https://clients3.google.com/generate_204'),
  ];

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final Connectivity _connectivity = Connectivity();
  final BehaviorSubject<NetworkStatus> _networkStatus =
  BehaviorSubject.seeded(NetworkStatus.connected);

  Stream<NetworkStatus> get networkStatusStream => _networkStatus.stream;
  NetworkStatus get currentNetworkStatus => _networkStatus.value;

  Timer? _speedCheckTimer;
  bool _isAppInBackground = false;
  DateTime? _lastNetworkCheck;
  final Duration _networkCheckCooldown = const Duration(seconds: 5);

  String? _lastEndpoint;
  Map<String, dynamic>? _lastBody;
  String _lastMethod = 'GET';
  bool _shouldRetryOnReconnect = true;

  // ---------------------------------------------------------------------------
  // Lifecycle glue
  // ---------------------------------------------------------------------------

  void _initAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(
      onResumed: _handleAppResumed,
      onPaused: _handleAppPaused,
    ));
  }

  void _handleAppResumed() {
    _isAppInBackground = false;
    _checkConnectivity(force: true);
  }

  void _handleAppPaused() {
    _isAppInBackground = true;
    _speedCheckTimer?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Connectivity strategy
  // ---------------------------------------------------------------------------

  void _initNetworkMonitoring() {
    // initial snapshot
    _checkConnectivity(force: true);

    // Trust connectivity_plus for "no internet"; mark Connected immediately on wifi/cell.
    _connectivity.onConnectivityChanged.listen((result) {
      if (_isAppInBackground) return;

      if (result == ConnectivityResult.none) {
        _updateNetworkStatus(NetworkStatus.noInternet);
      } else {
        _updateNetworkStatus(NetworkStatus.connected);
        // refine quality in background (don’t block UI)
        _checkNetworkSpeed(); // unawaited
      }
    });

    // periodic quality checks (only ever Connected ↔ Slow)
    _speedCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isAppInBackground) _checkNetworkSpeed();
    });
  }

  Future<void> _checkConnectivity({bool force = false}) async {
    if (!force &&
        _lastNetworkCheck != null &&
        DateTime.now().difference(_lastNetworkCheck!) < _networkCheckCooldown &&
        _networkStatus.value != NetworkStatus.noInternet) {
      return;
    }
    _lastNetworkCheck = DateTime.now();

    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        _updateNetworkStatus(NetworkStatus.noInternet);
      } else {
        _updateNetworkStatus(NetworkStatus.connected);
        _checkNetworkSpeed(); // unawaited
      }
    } catch (_) {
      // keep previous state
    }
  }

  /// Probe several URLs; success on the first reachable target.
  Future<bool> _quickProbe({Duration timeout = const Duration(seconds: 3)}) async {
    for (final u in _probeUris) {
      try {
        final res = await http.get(u).timeout(timeout);
        if (res.statusCode > 0) return true;
      } catch (_) {/* try next */}
    }
    return false;
  }

  /// Only refines Connected → Slow. Never sets NoInternet here.
  Future<void> _checkNetworkSpeed() async {
    if (_networkStatus.value == NetworkStatus.noInternet) return;

    try {
      final sw = Stopwatch()..start();
      final ok = await _quickProbe(timeout: const Duration(seconds: 4));
      sw.stop();

      if (!ok) {
        _updateNetworkStatus(NetworkStatus.slow);
        return;
      }

      final ms = sw.elapsedMilliseconds;
      _updateNetworkStatus(ms > 2000 ? NetworkStatus.slow : NetworkStatus.connected);
    } catch (_) {
      _updateNetworkStatus(NetworkStatus.slow);
    }
  }

  void _updateNetworkStatus(NetworkStatus newStatus) {
    if (_networkStatus.value == newStatus) return;

    _networkStatus.add(newStatus);

    if (newStatus == NetworkStatus.connected &&
        !_isAppInBackground &&
        _shouldRetryOnReconnect) {
      // give radios a moment to settle
      Future.delayed(const Duration(seconds: 2), _retryLastRequest);
    }
  }

  /// Before blocking a request for “no internet”, quickly re-probe once.
  Future<void> _checkConnection() async {
    final status = currentNetworkStatus;

    if (status == NetworkStatus.noInternet) {
      final ok = await _quickProbe(timeout: const Duration(seconds: 2));
      if (ok) {
        _updateNetworkStatus(NetworkStatus.connected);
      } else {
        throw const SocketException("No internet connection");
      }
    }
    // If slow/connected → allow request; timeouts will update status.
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<dynamic> get({
    required String endpoint,
    Map<String, String>? extraHeaders,
    Map<String, dynamic>? query,
    bool requireAuth = true,
  }) async {
    await _checkConnection();

    if (requireAuth) {
      await SessionManager.checkTokenValidityAndRefresh(silent: true);
    }

    _storeLastRequest(endpoint, null, 'GET');

    final uri = Uri.parse("$_baseUrl$endpoint")
        .replace(queryParameters: query?.map((k, v) => MapEntry(k, v.toString())));

    final headers = <String, String>{
      "Content-Type": "application/json",
      if (requireAuth && SessionManager.token != null)
        "Authorization": "Bearer ${SessionManager.token}",
      ...?extraHeaders,
    };

    ConsoleHttpLogger.request(
      method: 'GET',
      url: uri,
      headers: headers,
      body: query != null ? jsonEncode(query) : null,
    );

    final sw = Stopwatch()..start();
    final res = await http.get(uri, headers: headers);
    sw.stop();

    ConsoleHttpLogger.response(
      method: 'GET',
      url: uri,
      statusCode: res.statusCode,
      duration: sw.elapsed,
      headers: res.headers,
      body: res.body,
    );

    final parsed = _handleResponse(res, method: 'GET', url: uri.toString());
    // any successful response proves reachability
    _updateNetworkStatus(NetworkStatus.connected);
    return parsed;
  }

  Future<dynamic> post({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    bool requireAuth = true,
  }) async {
    try {
      await _checkConnection();

      if (requireAuth) {
        await SessionManager.checkTokenValidityAndRefresh(silent: true);
      }

      _storeLastRequest(endpoint, body, 'POST');

      final uri = Uri.parse("$_baseUrl$endpoint");
      final headers = <String, String>{
        "Content-Type": "application/json",
        if (requireAuth && SessionManager.token != null)
          "Authorization": "Bearer ${SessionManager.token}",
        ...?extraHeaders,
      };

      final bodyStr = jsonEncode(body ?? {});
      ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);

      final sw = Stopwatch()..start();
      final client = http.Client();
      try {
        final request = http.Request('POST', uri)
          ..headers.addAll(headers)
          ..body = bodyStr;

        final streamed = await client.send(request)
            .timeout(const Duration(seconds: 15)); // connection timeout
        final res = await http.Response.fromStream(streamed)
            .timeout(const Duration(seconds: 30)); // read timeout
        sw.stop();

        ConsoleHttpLogger.response(
          method: 'POST',
          url: uri,
          statusCode: res.statusCode,
          duration: sw.elapsed,
          headers: res.headers,
          body: res.body,
        );

        final parsed = _handleResponse(res, method: 'POST', url: uri.toString());
        _updateNetworkStatus(NetworkStatus.connected);
        return parsed;
      } finally {
        client.close();
      }
    } on SocketException {
      _updateNetworkStatus(NetworkStatus.noInternet);
      rethrow;
    } on TimeoutException {
      _updateNetworkStatus(NetworkStatus.slow);
      rethrow;
    }
  }

  Future<http.Response> postRaw({
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh(silent: true);

    _storeLastRequest(endpoint, body, 'POST');

    final uri = Uri.parse("$_baseUrl$endpoint");
    final headers = <String, String>{
      "Content-Type": "application/json",
      if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
    };

    final bodyStr = jsonEncode(body ?? {});
    ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);

    final sw = Stopwatch()..start();
    final res = await http.post(uri, headers: headers, body: bodyStr);
    sw.stop();

    ConsoleHttpLogger.response(
      method: 'POST',
      url: uri,
      statusCode: res.statusCode,
      duration: sw.elapsed,
      headers: res.headers,
      body: res.body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        method: 'POST',
        url: uri.toString(),
        responseBody: res.body,
        responseHeaders: res.headers,
        message: 'HTTP ${res.statusCode}',
      );
    }
    _updateNetworkStatus(NetworkStatus.connected);
    return res;
  }

  Future<http.StreamedResponse> postStream({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh(silent: true);

    _storeLastRequest(endpoint, body, 'POST');

    final uri = Uri.parse("$_baseUrl$endpoint");
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
      'Accept': 'text/event-stream',
    };

    final bodyStr = jsonEncode(body);
    ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);

    final sw = Stopwatch()..start();
    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = bodyStr;
    final streamed = await request.send();
    sw.stop();

    ConsoleHttpLogger.response(
      method: 'POST',
      url: uri,
      statusCode: streamed.statusCode,
      duration: sw.elapsed,
      headers: streamed.headers,
      body: '(stream)',
    );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final bodyErr = await streamed.stream.bytesToString();
      throw ApiException(
        statusCode: streamed.statusCode,
        method: 'POST',
        url: uri.toString(),
        responseBody: bodyErr,
        responseHeaders: streamed.headers,
        message: 'HTTP ${streamed.statusCode}',
      );
    }
    _updateNetworkStatus(NetworkStatus.connected);
    return streamed;
  }

  Future<http.Response> postRawNoRefresh({
    required String endpoint,
    required Map<String, dynamic> body,
    bool attachAuthHeader = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (attachAuthHeader && SessionManager.token != null)
        'Authorization': 'Bearer ${SessionManager.token}',
    };

    final bodyStr = jsonEncode(body);
    ConsoleHttpLogger.request(method: 'POST', url: uri, headers: headers, body: bodyStr);

    final sw = Stopwatch()..start();
    final res = await http.post(uri, headers: headers, body: bodyStr);
    sw.stop();

    ConsoleHttpLogger.response(
      method: 'POST',
      url: uri,
      statusCode: res.statusCode,
      duration: sw.elapsed,
      headers: res.headers,
      body: res.body,
      note: 'no auto-refresh',
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        method: 'POST',
        url: uri.toString(),
        responseBody: res.body,
        responseHeaders: res.headers,
        message: 'HTTP ${res.statusCode}',
      );
    }
    _updateNetworkStatus(NetworkStatus.connected);
    return res;
  }

  // ---------------------------------------------------------------------------
  // Retry & response handling
  // ---------------------------------------------------------------------------

  void _storeLastRequest(String endpoint, Map<String, dynamic>? body, String method) {
    _lastEndpoint = endpoint;
    _lastBody = body;
    _lastMethod = method;
  }

  Future<void> _retryLastRequest() async {
    if (_lastEndpoint == null || _isAppInBackground) return;

    _shouldRetryOnReconnect = false;
    try {
      if (_lastMethod == 'POST') {
        await post(endpoint: _lastEndpoint!, body: _lastBody);
      } else if (_lastMethod == 'GET') {
        await get(endpoint: _lastEndpoint!);
      }
    } catch (_) {
      // swallow; next interaction will re-issue anyway
    } finally {
      _shouldRetryOnReconnect = true;
    }
  }

  dynamic _handleResponse(http.Response res, {required String method, required String url}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }

    String msg = 'HTTP ${res.statusCode}';
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['detail'] != null) {
        msg = parsed['detail'].toString();
      } else if (parsed is Map && parsed['message'] != null) {
        msg = parsed['message'].toString();
      }
    } catch (_) {}

    throw ApiException(
      statusCode: res.statusCode,
      method: method,
      url: url,
      responseBody: res.body,
      responseHeaders: res.headers,
      message: msg,
    );
  }

  void dispose() {
    _networkStatus.close();
    _speedCheckTimer?.cancel();
  }
}

// Simple lifecycle observer used above
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;
  final VoidCallback onPaused;

  _AppLifecycleObserver({
    required this.onResumed,
    required this.onPaused,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        onPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}

// -----------------------------------------------------------------------------
// Errors & logging
// -----------------------------------------------------------------------------

class ApiException implements Exception {
  final int statusCode;
  final String method;
  final String url;
  final String responseBody;
  final Map<String, String>? responseHeaders;
  final String? message;

  ApiException({
    required this.statusCode,
    required this.method,
    required this.url,
    required this.responseBody,
    this.responseHeaders,
    this.message,
  });

  @override
  String toString() =>
      "ApiException($statusCode $method $url) ${message ?? ''}\n$responseBody";
}

class ConsoleHttpLogger {
  static bool useColors = true;
  static int defaultBodyMax = 10000000;
  static bool prettyPrintJson = true;

  static String _pretty(String body, {bool forceRaw = false}) {
    if (forceRaw || !prettyPrintJson) return body;
    try {
      final obj = json.decode(body);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return body;
    }
  }

  static String _truncate(String s, int maxLength) =>
      s.length <= maxLength ? s : (s.substring(0, maxLength) + ' …(truncated)…');

  static String _green(String s) => useColors ? '\x1B[32m$s\x1B[0m' : s;
  static String _red(String s) => useColors ? '\x1B[31m$s\x1B[0m' : s;
  static String _yellow(String s) => useColors ? '\x1B[33m$s\x1B[0m' : s;
  static String _cyan(String s) => useColors ? '\x1B[36m$s\x1B[0m' : s;
  static String _bold(String s) => useColors ? '\x1B[1m$s\x1B[0m' : s;
  static String _magenta(String s) => useColors ? '\x1B[35m$s\x1B[0m' : s;

  static String _statusLabel(int code) {
    if (code >= 200 && code < 300) return 'OK';
    if (code == 400) return 'Bad Request';
    if (code == 401) return 'Unauthorized';
    if (code == 403) return 'Forbidden';
    if (code == 404) return 'Not Found';
    if (code == 409) return 'Conflict';
    if (code == 422) return 'Unprocessable Entity';
    if (code >= 500 && code < 600) return 'Server Error';
    return 'HTTP';
  }

  static Map<String, String> _redact(Map<String, String> h) {
    final out = Map<String, String>.from(h);
    if (out.containsKey('Authorization')) out['Authorization'] = 'Bearer ***redacted***';
    if (out.containsKey('X-Refresh-Token')) out['X-Refresh-Token'] = '***redacted***';
    if (out.containsKey('Cookie')) out['Cookie'] = '***redacted***';
    return out;
  }

  static void request({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
    int? maxBodyLength,
    bool prettyJson = true,
  }) {
    final h = _redact(headers);
    final hasBody = body != null && body.isNotEmpty;
    final actualMax = maxBodyLength ?? defaultBodyMax;
    final usePretty = prettyJson && prettyPrintJson;

    final lines = <String>[
      '┌───────────────────────── REQUEST ─────────────────────────',
      '│ ${_bold(method)} ${_cyan(url.toString())}',
      '│ Headers: ${jsonEncode(h)}',
    ];

    if (hasBody) {
      final formatted = usePretty ? _pretty(body!, forceRaw: !usePretty) : body!;
      final truncated = _truncate(formatted, actualMax);
      lines.add('│ Body:');
      lines.addAll(truncated.split('\n').map((l) => '│   $l'));
    }

    lines.add('└──────────────────────────────────────────────────────────');
    debugPrint(lines.join('\n'));
  }

  static void response({
    required String method,
    required Uri url,
    required int statusCode,
    required Duration duration,
    required Map<String, String> headers,
    required String body,
    String? note,
    int? maxBodyLength,
    bool prettyJson = true,
  }) {
    String colored(String s) {
      if (statusCode >= 200 && statusCode < 300) return _green(s);
      if (statusCode >= 400 && statusCode < 500) return _yellow(s);
      return _red(s);
    }

    final h = _redact(headers);
    final actualMax = maxBodyLength ?? defaultBodyMax;
    final usePretty = prettyJson && prettyPrintJson;

    final lines = <String>[
      '┌──────────────────────── RESPONSE ────────────────────────',
      '│ ${_bold(method)} ${_cyan(url.toString())}  •  ${_bold(duration.inMilliseconds.toString())}ms',
      '│ Status: ${colored('$statusCode ${_statusLabel(statusCode)}')}',
      '│ Headers: ${jsonEncode(h)}',
      if (note != null) '│ Note: $note',
      '│ Body:',
    ];

    final formatted = usePretty ? _pretty(body, forceRaw: !usePretty) : body;
    final truncated = _truncate(formatted, actualMax);
    lines.addAll(truncated.split('\n').map((l) => '│   $l'));

    lines.add('└──────────────────────────────────────────────────────────');
    debugPrint(colored(lines.join('\n')));
  }
}

String handleApiError(dynamic error) {
  if (error is ApiException) {
    return "${error.message ?? 'Request failed'} (code ${error.statusCode})";
  } else if (error is SocketException) {
    return "No Internet Connection";
  } else if (error is FormatException) {
    return "Invalid response format";
  } else {
    return "Something went wrong";
  }
}



