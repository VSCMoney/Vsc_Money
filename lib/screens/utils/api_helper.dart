// lib/utils/api_helpers.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../constants/keys.dart' as ApiConstants;

class ApiHelpers {
  static Future<String> sendToGemini({
    required String prompt,
    required String model,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (ApiConstants.geminiApiKey.isEmpty) {
      return "Error: Gemini API key is missing.";
    }

    final apiUrl = "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=${ApiConstants.geminiApiKey}";

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": temperature,
        "maxOutputTokens": maxTokens,
        "topP": 1.0,
        "topK": 40
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse["candidates"][0]["content"]["parts"][0]["text"] ?? "No response received.";
      } else {
        return "Error: ${response.statusCode} - ${response.reasonPhrase}";
      }
    } catch (e) {
      return "Error: Failed to connect to Gemini API - ${e.toString()}";
    }
  }

  static Future<Map<String, dynamic>> sendStructuredGeminiRequest({
    required List<Map<String, Object>> contents,
    required String model,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (ApiConstants.geminiApiKey.isEmpty) {
      return {"error": "Gemini API key is missing."};
    }

    final apiUrl = "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=${ApiConstants.geminiApiKey}";

    final requestBody = {
      "contents": contents,
      "generationConfig": {
        "temperature": temperature,
        "maxOutputTokens": maxTokens,
        "topP": 1.0,
        "topK": 40,
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": "HTTP Error ${response.statusCode}",
          "message": response.reasonPhrase,
          "body": response.body,
        };
      }
    } catch (e) {
      return {"error": "Network Error", "message": e.toString()};
    }
  }
}