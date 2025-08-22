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
    // VM returns: {_id, uid, created_at, title, messages: []}
    final rawId = json['_id'] ?? json['session_id'] ?? json['id'];
    final rawTitle = json['title'];
    final rawCreated = json['created_at'];

    return ChatSession(
      id: (rawId ?? '').toString(),                        // never null
      title: (rawTitle is String && rawTitle.isNotEmpty)
          ? rawTitle
          : 'New Chat',                                    // <- prevent null→String crash
      createdAt: DateTime.tryParse(rawCreated ?? '') ??
          DateTime.now(),                                  // safe parse
      messages: const [],                                  // skip parsing for now
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': id,                 // what your APIs expect when sending
      'title': title,
      'created_at': createdAt.toIso8601String(),
      // omit messages here unless you need to send them
    };
  }
}
