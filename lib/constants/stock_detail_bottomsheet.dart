import 'package:flutter/material.dart';

class StockDetailBottomSheet extends StatelessWidget {
  final String stockName;
  final String price;
  final String change;
  final String exchange;
  final String volume;
  final String dayLow;
  final String dayHigh;
  final String weekLow;
  final String weekHigh;
  final String open;
  final String close;
  final String lowerCircuit;
  final String upperCircuit;

  const StockDetailBottomSheet({
    super.key,
    required this.stockName,
    required this.price,
    required this.change,
    required this.exchange,
    required this.volume,
    required this.dayLow,
    required this.dayHigh,
    required this.weekLow,
    required this.weekHigh,
    required this.open,
    required this.close,
    required this.lowerCircuit,
    required this.upperCircuit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(stockName, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Eternal", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      '₹$price',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    Text(change, style: const TextStyle(color: Colors.green)),
                  ],
                ),
                const Image(height: 40, image: AssetImage('assets/images/zomato_logo.png')),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              color: Colors.green[50], // Replace with actual chart
              child: const Center(child: Text("[Chart Placeholder]")),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["1D", "1W", "1M", "1Y", "5Y", "All"].map((e) {
                final isSelected = e == "1D";
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e, style: TextStyle(color: isSelected ? Colors.orange : Colors.black)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text("Performance", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Today's low"), Text("Today's high")],
            ),
            Row(
              children: [
                Text(dayLow),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 4, color: Colors.purple[300]),
                      Positioned(
                        left: screenWidth * 0.5,
                        child: const Icon(Icons.arrow_drop_up, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(dayHigh),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("52 week low"), Text("52 week high")],
            ),
            Row(
              children: [
                Text(weekLow),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 4, color: Colors.purple[300]),
                      Positioned(
                        left: screenWidth * 0.5,
                        child: const Icon(Icons.arrow_drop_up, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(weekHigh),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildMetric("Open Price", open),
                _buildMetric("Prev. close", close),
                _buildMetric("Volume", volume),
                _buildMetric("Lower circuit", lowerCircuit),
                _buildMetric("Upper circuit", upperCircuit),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9B21),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ask follow up', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: const Icon(Icons.currency_rupee, color: Colors.deepOrange),
                )
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
