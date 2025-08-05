import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../controllers/session_manager.dart';
import 'locator.dart';
import 'theme_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
enum NetworkStatus { connected, noInternet, slow }

class EndPointService {
  static final EndPointService _instance = EndPointService._internal();
  factory EndPointService() => _instance;
  EndPointService._internal() {
    _initNetworkMonitoring();
  }

  final Connectivity _connectivity = Connectivity();
  final BehaviorSubject<NetworkStatus> _networkStatus = BehaviorSubject.seeded(NetworkStatus.connected);
  Timer? _speedCheckTimer;
  Stream<NetworkStatus> get networkStatusStream => _networkStatus.stream;
  NetworkStatus get currentNetworkStatus => _networkStatus.value;

  //final String _baseUrl = 'http://127.0.0.1:8000';
  final String _baseUrl = 'http://192.168.1.2:8000';

  String? _lastEndpoint;
  Map<String, dynamic>? _lastBody;
  String _lastMethod = 'GET';

  void _initNetworkMonitoring() {
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((_) => _checkConnectivity());
    _speedCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkNetworkSpeed());
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        _updateNetworkStatus(NetworkStatus.noInternet);
      } else {
        await _checkNetworkSpeed();
      }
    } catch (e) {
      debugPrint("Connectivity check error: $e");
    }
  }

  Future<void> _checkNetworkSpeed() async {
    if (_networkStatus.value == NetworkStatus.noInternet) return;

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final speed = stopwatch.elapsedMilliseconds;
        _updateNetworkStatus(speed > 2000 ? NetworkStatus.slow : NetworkStatus.connected);
      } else {
        _updateNetworkStatus(NetworkStatus.noInternet);
      }
    } on SocketException {
      _updateNetworkStatus(NetworkStatus.noInternet);
    } on TimeoutException {
      _updateNetworkStatus(NetworkStatus.slow);
    } catch (e) {
      debugPrint("Network speed check error: $e");
    }
  }

  void _updateNetworkStatus(NetworkStatus newStatus) {
    if (_networkStatus.value != newStatus) {
      _networkStatus.add(newStatus);
      _showNetworkStatusToast(newStatus);

      if (newStatus == NetworkStatus.connected && _lastEndpoint != null) {
        _retryLastRequest();
      }
    }
  }

  void _showNetworkStatusToast(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        Fluttertoast.showToast(msg: "✅ Back online", gravity: ToastGravity.TOP);
        break;
      case NetworkStatus.slow:
        Fluttertoast.showToast(msg: "⚠️ Internet is slow", gravity: ToastGravity.TOP);
        break;
      case NetworkStatus.noInternet:
        Fluttertoast.showToast(msg: "❌ No internet connection", gravity: ToastGravity.TOP);
        break;
    }
  }

  Future<void> _checkConnection() async {
    if (currentNetworkStatus == NetworkStatus.noInternet) {
      throw SocketException("No internet connection");
    }
  }

  Future<http.StreamedResponse> postStream({required String endpoint, required Map<String, dynamic> body}) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh();
    _storeLastRequest(endpoint, body, 'POST');

    final uri = Uri.parse("$_baseUrl$endpoint");
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}'
    });
    request.body = jsonEncode(body);
    return await request.send();
  }

  Future<dynamic> post({required String endpoint, Map<String, dynamic>? body}) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh();
    _storeLastRequest(endpoint, body, 'POST');

    final uri = Uri.parse("$_baseUrl$endpoint");
    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
      },
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<dynamic> get({required String endpoint}) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh();
    _storeLastRequest(endpoint, null, 'GET');

    final uri = Uri.parse("$_baseUrl$endpoint");
    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
      },
    );
    return _handleResponse(res);
  }

  Future<http.Response> postRaw({required String endpoint, Map<String, dynamic>? body}) async {
    await _checkConnection();
    await SessionManager.checkTokenValidityAndRefresh();
    _storeLastRequest(endpoint, body, 'POST');

    final uri = Uri.parse("$_baseUrl$endpoint");
    return await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
      },
      body: jsonEncode(body),
    );
  }

  void _storeLastRequest(String endpoint, Map<String, dynamic>? body, String method) {
    _lastEndpoint = endpoint;
    _lastBody = body;
    _lastMethod = method;
  }

  Future<void> _retryLastRequest() async {
    if (_lastEndpoint == null) return;

    try {
      if (_lastMethod == 'POST') {
        await post(endpoint: _lastEndpoint!, body: _lastBody);
      } else if (_lastMethod == 'GET') {
        await get(endpoint: _lastEndpoint!);
      }
    } catch (e) {
      debugPrint("Retry failed: $e");
    }
  }

  dynamic _handleResponse(http.Response res) {
    print("📩 Response [${res.statusCode}] from ${res.request?.url}: ${res.body}");

    switch (res.statusCode) {
      case 200:
      case 201:
        return jsonDecode(res.body);
      case 400:
        throw Exception("Bad Request");
      case 401:
        throw Exception("Unauthorized");
      case 403:
        throw Exception("Forbidden");
      case 404:
        throw Exception("Not Found");
      case 500:
        throw Exception("Server Error");
      default:
        throw Exception("Unexpected error [${res.statusCode}]");
    }
  }

  void dispose() {
    _networkStatus.close();
    _speedCheckTimer?.cancel();
  }
}

class ApiException implements Exception {
  final String message;
  final dynamic details;

  ApiException(this.message, [this.details]);

  @override
  String toString() => "$message: \${details ?? ''}";
}

String handleApiError(dynamic error) {
  if (error is ApiException) {
    debugPrint("⚠️ API Exception: \${error.message}");
    return error.message;
  } else if (error is SocketException) {
    debugPrint("📴 No Internet: \$error");
    return "No Internet Connection";
  } else if (error is FormatException) {
    debugPrint("❌ Invalid Response Format: \$error");
    return "Invalid data format received";
  } else if (error is http.ClientException) {
    debugPrint("🚫 Client Exception: \$error");
    return "Request failed";
  } else {
    debugPrint("💥 Unknown Error: \$error");
    return "Something went wrong";
  }
}