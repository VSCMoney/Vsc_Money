import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/stock_detail.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({required this.symbol});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockDetail? stock;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final result = await StockService.getStockDetail(widget.symbol);
    setState(() {
      stock = result;
      loading = false;
    });
    print(stock?.price);
    print("Parsed JSON: ${stock?.name} | ${stock?.symbol} | ${stock?.price}");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : stock == null
          ? const Center(child: Text("Stock data not found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stock!),
            const SizedBox(height: 20),
            _buildSection("Stock Overview", stock!.details),
            const SizedBox(height: 20),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StockDetail data) {
    final isNegative = data.change.contains('-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.symbol,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(data.price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isNegative ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.change,
                style: TextStyle(
                  color: isNegative ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSection(String title, Map details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: details.entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(flex: 3, child: Text(entry.value.toString(), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      "Note: Data sourced from Google Finance and may be delayed or approximate.",
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    );
  }
}