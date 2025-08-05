import 'package:flutter/material.dart';

class StockTileWidget extends StatelessWidget {
  final List<dynamic> stocks;
  final Function(String)? onStockTap;

  const StockTileWidget({
    Key? key,
    required this.stocks,
    this.onStockTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stocks.map((stock) {
        return GestureDetector(
          onTap: () => onStockTap?.call(stock['name'] ?? ''),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stock['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${stock['price']}"),
                    Text(
                      stock['change'] ?? '',
                      style: TextStyle(
                        color: (stock['change'] as String).startsWith('+')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}