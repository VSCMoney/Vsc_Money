import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../controllers/session_manager.dart';

class ApiService {
  final String _baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app/api/v1";
   //final String _baseUrl= 'http://127.0.0.1:8000/api/v1';


  Future<dynamic> post({required String endpoint, Map<String, dynamic>? body}) async {
    final uri = Uri.parse("$_baseUrl$endpoint");
    print(_baseUrl);

    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
        },
        body: jsonEncode(body),
      );

      return _handleResponse(res);
    } catch (e) {
      print("❌ POST error at $endpoint: $e");
      throw Exception("Something went wrong. Please try again.");
    }
  }

  Future<dynamic> get({required String endpoint}) async {
    final uri = Uri.parse("$_baseUrl$endpoint");

    try {
      final res = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (SessionManager.token != null) "Authorization": "Bearer ${SessionManager.token}"
        },
      );

      return _handleResponse(res);
    } catch (e) {
      print("❌ GET error at $endpoint: $e");
      throw Exception("Something went wrong. Please try again.");
    }
  }

  Future<http.Response> postRaw({
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse("$_baseUrl$endpoint");
    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (SessionManager.token != null)
            "Authorization": "Bearer ${SessionManager.token}"
        },
        body: jsonEncode(body),
      );
      return res;
    } catch (e) {
      print("❌ POST RAW Error at $endpoint: $e");
      rethrow;
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
}

/// Unified API exception model
class ApiException implements Exception {
  final String message;
  final dynamic details;

  ApiException(this.message, [this.details]);

  @override
  String toString() => "$message: ${details ?? ''}";
}

/// Central error handler for try-catch blocks
String handleApiError(dynamic error) {
  if (error is ApiException) {
    debugPrint("⚠️ API Exception: ${error.message}");
    return error.message;
  } else if (error is SocketException) {
    debugPrint("📴 No Internet: $error");
    return "No Internet Connection";
  } else if (error is FormatException) {
    debugPrint("❌ Invalid Response Format: $error");
    return "Invalid data format received";
  } else if (error is http.ClientException) {
    debugPrint("🚫 Client Exception: $error");
    return "Request failed";
  } else {
    debugPrint("💥 Unknown Error: $error");
    return "Something went wrong";
  }
}