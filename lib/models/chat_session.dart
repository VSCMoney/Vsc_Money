// lib/models/chat_session.dart
import 'chat_message.dart';

class ChatSession {
  final String id;
   String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['session_id'] ?? json['id'],
      title: json['title'] ?? "New Chat",
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      messages: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
