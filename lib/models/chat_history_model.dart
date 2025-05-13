class ChatHistoryItem {
  final String question;
  final String answer;
  final DateTime timestamp;

  ChatHistoryItem({
    required this.question,
    required this.answer,
    required this.timestamp,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    try {
      return ChatHistoryItem(
        question: json['question'] ?? '',  // Default to empty string if null
        answer: json['answer'] ?? '',      // Default to empty string if null
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),              // Default to current time if null
      );
    } catch (e) {
      print("Error parsing ChatHistoryItem: $e");
      print("Problematic JSON: $json");
      // Return a default item rather than crashing
      return ChatHistoryItem(
        question: json['question'] ?? 'Error loading question',
        answer: json['answer'] ?? 'Error loading answer',
        timestamp: DateTime.now(),
      );
    }
  }}
