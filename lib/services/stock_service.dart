import 'dart:convert';

import '../models/stock_detail.dart';
import 'package:http/http.dart' as http;

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