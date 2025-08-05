// class ChatMessage {
//   final String id;
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;
//   final bool isComplete;
//
//   ChatMessage({
//     required this.id,
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//     this.isComplete = true,
//   });
//
//   factory ChatMessage.fromBackend(Map<String, dynamic> json) {
//     return ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: json['text'] ?? '',
//       isUser: json['is_user'] ?? false,
//       timestamp: json['timestamp'] != null
//           ? DateTime.parse(json['timestamp'])
//           : DateTime.now(),
//       isComplete: true,
//     );
//   }
// }








// STEP 1: Add these model classes to your existing code
class StatusUpdate {
  final String id;
  final StatusType type;
  final String message;
  final DateTime timestamp;
  final bool isComplete;

  StatusUpdate({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isComplete,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      id: json['id'],
      type: StatusType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => StatusType.processing,
      ),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isComplete: json['is_complete'] ?? false,
    );
  }
}

enum StatusType {
  thinking,
  searching,
  analyzing,
  processing,
  completed,
}

class ResponsePayload {
  final String id;
  final PayloadType type;
  final dynamic data;
  final String? title;
  final String? description;

  ResponsePayload({
    required this.id,
    required this.type,
    required this.data,
    this.title,
    this.description,
  });

  factory ResponsePayload.fromJson(Map<String, dynamic> json) {
    return ResponsePayload(
      id: json['id'],
      type: PayloadType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => PayloadType.text,
      ),
      data: json['data'],
      title: json['title'],
      description: json['description'],
    );
  }
}

enum PayloadType {
  text,
  json,
  chart,
}

// STEP 2: Update your existing ChatMessage model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isComplete;
  final List<StatusUpdate> statusUpdates;  // ADD THIS
  final List<ResponsePayload> payloads;    // ADD THIS

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isComplete = true,
    this.statusUpdates = const [],  // ADD THIS
    this.payloads = const [],       // ADD THIS
  });

  // ADD THIS copyWith method
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isComplete,
    List<StatusUpdate>? statusUpdates,
    List<ResponsePayload>? payloads,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      payloads: payloads ?? this.payloads,
    );
  }

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
