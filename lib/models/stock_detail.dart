class StockDetail {
  final String name;
  final String symbol;
  final String price;
  final String change;
  final Map<String, dynamic> details;

  StockDetail({
    required this.name,
    required this.symbol,
    required this.price,
    required this.change,
    required this.details,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];

    Map<String, dynamic> parsedDetails = {};

    if (rawDetails is Map) {
      rawDetails.forEach((key, value) {
        parsedDetails[key.toString()] = value.toString();
      });
    } else {
      print("❗ 'details' is not a Map. Type: ${rawDetails.runtimeType}");
    }

    return StockDetail(
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      change: json['change']?.toString() ?? '',
      details: parsedDetails,
    );
  }
}
