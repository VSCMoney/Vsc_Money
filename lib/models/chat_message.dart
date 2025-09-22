














class StreamChunk {
  final String type;
  final Map<String, dynamic> payload;

  StreamChunk({
    required this.type,
    required this.payload,
  });

  factory StreamChunk.fromJson(Map<String, dynamic> json) {
    return StreamChunk(
      type: json['type'] ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  bool get isStatusUpdate => type == 'status_update';
  bool get isResponse => type == 'response';

  String? get responseType => isResponse ? payload['type'] : null;
  dynamic get responseData => isResponse ? payload['data'] : null;

  String? get statusReason => isStatusUpdate ? payload['reason'] : null;

  bool get isTextChunk => isResponse && responseType == 'text';
  bool get isJsonChunk => isResponse && responseType == 'json';
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isComplete;

  // Add these new fields
  final String? currentStatus;
  final bool isTable;
  final Map<String, dynamic>? structuredData;
  final String? messageType;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isComplete = true,
    this.currentStatus,
    this.isTable = false,
    this.structuredData,
    this.messageType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isComplete': isComplete,
      'currentStatus': currentStatus,
      'isTable': isTable,
      'structuredData': structuredData,
      'messageType': messageType,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      isComplete: json['isComplete'] ?? true,
      currentStatus: json['currentStatus'],
      isTable: json['isTable'] ?? false,
      structuredData: json['structuredData'] as Map<String, dynamic>?,
      messageType: json['messageType'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isComplete,
    String? currentStatus,
    bool? isTable,
    Map<String, dynamic>? structuredData,
    String? messageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
      currentStatus: currentStatus ?? this.currentStatus,
      isTable: isTable ?? this.isTable,
      structuredData: structuredData ?? this.structuredData,
      messageType: messageType ?? this.messageType,
    );
  }
}
