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
    return ChatHistoryItem(
      question: json['question'],
      answer: json['answer'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
