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


import 'dart:convert';

import 'package:flutter/foundation.dart';

/// ---------------------------------------------------------------------------
/// Protocol constants
/// ---------------------------------------------------------------------------
// class ChunkTypes {
//   static const String statusUpdate = 'status_update';
//   static const String response = 'response';
// }
//
// class ResponseTypes {
//   static const String text = 'text';
//   static const String json = 'json';
// }
//
// /// ---------------------------------------------------------------------------
// /// Stream chunk coming from your VM/backend
// /// ---------------------------------------------------------------------------
// class StreamChunk {
//   final String type; // 'status_update' | 'response'
//   final Map<String, dynamic> payload;
//
//   StreamChunk({required this.type, required this.payload});
//
//   factory StreamChunk.fromJson(Map<String, dynamic> json) {
//     return StreamChunk(
//       type: (json['type'] ?? '').toString(),
//       payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
//     );
//   }
//
//   // status_update helpers
//   bool get isStatusUpdate => type == ChunkTypes.statusUpdate;
//   String? get statusReason => isStatusUpdate ? payload['reason']?.toString() : null;
//
//   // response helpers
//   bool get isResponse => type == ChunkTypes.response;
//   String? get responseType => isResponse ? payload['type']?.toString() : null;
//   dynamic get responseData => isResponse ? payload['data'] : null;
// }
//
// /// ---------------------------------------------------------------------------
// /// Strongly-typed JSON payloads (generic, schema-agnostic)
// /// ---------------------------------------------------------------------------
//
// /// Base interface for any structured JSON payload
// abstract class ChatPayload {
//   String get kind; // e.g., 'kv_table' or 'generic'
// }
//
// /// A generic key/value **table-like** payload:
// /// - rows: a list of maps (each map is a row with arbitrary keys)
// /// - heading: optional title/heading
// /// - columnOrder: optional fixed order if the backend ever sends it;
// ///   otherwise you can compute union of keys in UI.
// class KeyValueTablePayload implements ChatPayload {
//   @override
//   String get kind => 'kv_table';
//
//   final String? heading;
//   final List<Map<String, dynamic>> rows;
//   final List<String>? columnOrder;
//
//   KeyValueTablePayload({
//     this.heading,
//     required this.rows,
//     this.columnOrder,
//   });
//
//   /// Try to parse *any* json shape into a KV table:
//   /// Supports:
//   ///   { heading?, list: [ {..}, {..} ], column_order? }
//   ///   [ {..}, {..} ]
//   ///   { key: value, ... }  // single row
//   factory KeyValueTablePayload.tryParse(dynamic data) {
//     // Case A: Map with 'list'
//     if (data is Map) {
//       final map = data.cast<String, dynamic>();
//
//       // If it has a 'list' that is a List of Map -> table
//       final list = map['list'];
//       if (list is List && list.isNotEmpty && list.first is Map) {
//         final rows = list
//             .whereType<Map>()
//             .map((e) => e.cast<String, dynamic>())
//             .toList();
//
//         final heading = map['heading']?.toString();
//         final orderRaw = map['column_order'];
//         final columnOrder = (orderRaw is List)
//             ? orderRaw.map((e) => e.toString()).toList()
//             : null;
//
//         return KeyValueTablePayload(
//           heading: heading,
//           rows: rows,
//           columnOrder: columnOrder,
//         );
//       }
//
//       // If it's a flat map (key/value pairs) -> single row table
//       final isFlat = map.values.every((v) => v is! Map && v is! List);
//       if (isFlat) {
//         return KeyValueTablePayload(
//           heading: map['heading']?.toString(), // harmless if absent
//           rows: [map],
//           columnOrder: null,
//         );
//       }
//     }
//
//     // Case B: List of Map -> table
//     if (data is List && data.isNotEmpty && data.first is Map) {
//       final rows = data
//           .whereType<Map>()
//           .map((e) => e.cast<String, dynamic>())
//           .toList();
//       return KeyValueTablePayload(
//         heading: null,
//         rows: rows,
//         columnOrder: null,
//       );
//     }
//
//     // Not table-shaped -> throw to let caller decide fallback
//     throw const FormatException('Not a key/value table shape');
//   }
// }
//
// /// Catch-all payload when we can't or don't want to coerce into a table yet
// class GenericJsonPayload implements ChatPayload {
//   @override
//   String get kind => 'generic';
//   final Map<String, dynamic> data;
//
//   GenericJsonPayload({required this.data});
// }
//
// /// ---------------------------------------------------------------------------
// /// ChatMessage model: holds text + status + typed JSON payloads
// /// ---------------------------------------------------------------------------
// class ChatMessage {
//   final String id;
//   final String text; // accumulated streamed text
//   final bool isUser;
//   final DateTime timestamp;
//
//   /// true when stream for this message ends
//   final bool isComplete;
//
//   /// transient status like "Thinking…" / "Fetching…"
//   final String? currentStatus;
//
//   /// structured payloads (typed, schema-agnostic)
//   final List<ChatPayload> payloads;
//
//   ChatMessage({
//     required this.id,
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//     this.isComplete = true,
//     this.currentStatus,
//     this.payloads = const [],
//   });
//
//   ChatMessage copyWith({
//     String? id,
//     String? text,
//     bool? isUser,
//     DateTime? timestamp,
//     bool? isComplete,
//     String? currentStatus,
//     List<ChatPayload>? payloads,
//   }) {
//     return ChatMessage(
//       id: id ?? this.id,
//       text: text ?? this.text,
//       isUser: isUser ?? this.isUser,
//       timestamp: timestamp ?? this.timestamp,
//       isComplete: isComplete ?? this.isComplete,
//       currentStatus: currentStatus,
//       payloads: payloads ?? this.payloads,
//     );
//   }
//
//   /// Feed one streaming chunk into this message and get an updated message back.
//   ChatMessage processChunk(StreamChunk chunk) {
//     if (chunk.isStatusUpdate) {
//       return copyWith(
//         currentStatus: chunk.statusReason,
//         isComplete: false,
//       );
//     }
//
//     if (chunk.isResponse) {
//       switch (chunk.responseType) {
//         case ResponseTypes.text:
//           final newText = chunk.responseData?.toString() ?? '';
//           final updatedText = text + newText;
//
//           if (kDebugMode) {
//             print("🔧 Processing text chunk:");
//             print("   Previous text: '$text'");
//             print("   New chunk: '$newText'");
//             print("   Updated text: '$updatedText'");
//           }
//
//           return copyWith(
//             text: updatedText,
//             currentStatus: null,
//             isComplete: false,
//           );
//
//         case ResponseTypes.json:
//           final raw = chunk.responseData;
//
//           // Try to normalize *any* json into a table of key/value pairs.
//           try {
//             final table = KeyValueTablePayload.tryParse(raw);
//             return copyWith(
//               payloads: [...payloads, table],
//               currentStatus: null,
//               isComplete: false,
//             );
//           } catch (_) {
//             // If not table-like, store as generic map (if possible)
//             final map = (raw is Map) ? raw.cast<String, dynamic>() : <String, dynamic>{'data': raw};
//             return copyWith(
//               payloads: [...payloads, GenericJsonPayload(data: map)],
//               currentStatus: null,
//               isComplete: false,
//             );
//           }
//
//         default:
//           return this;
//       }
//     }
//
//     return this;
//   }
//
//   /// Mark message complete when the stream ends.
//   ChatMessage markComplete() {
//     return copyWith(isComplete: true, currentStatus: null);
//   }
// }








// StreamChunk class to handle your API format
// StreamChunk class to handle your API format











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
