class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isComplete;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isComplete = true,
  });

  factory ChatMessage.fromBackend(Map<String, dynamic> json) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isComplete: true,
    );
  }
}
