// lib/services/chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../controllers/session_manager.dart';
import '../models/chat_history_model.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

// class ChatService {
//   List<ChatSession> _sessions = [];
//   late SharedPreferences _prefs;
//   String? _apiKey;
//   bool _initialized = false; // Track initialization status
//
//   final StreamingService _streamingService = StreamingService();
//
//   // Streams for reactive updates
//   final _sessionsStreamController = StreamController<List<ChatSession>>.broadcast();
//   Stream<List<ChatSession>> get sessions => _sessionsStreamController.stream;
//
//   // Stream for current message updates
//   final _currentMessageStreamController = StreamController<ChatMessage>.broadcast();
//   Stream<ChatMessage> get currentMessageStream => _currentMessageStreamController.stream;
//
//   Future<void> initialize() async {
//     if (_initialized) return; // Prevent duplicate initialization
//
//     _prefs = await SharedPreferences.getInstance();
//     await _loadSessions();
//     _loadApiKey();
//     _initialized = true;
//   }
//
//   void _loadApiKey() {
//     _apiKey = _prefs.getString('api_key');
//   }
//
//   Future<void> setApiKey(String apiKey) async {
//     if (!_initialized) {
//       await initialize();
//     }
//
//     _apiKey = apiKey;
//     await _prefs.setString('api_key', apiKey);
//   }
//
//   Future<void> _loadSessions() async {
//     try {
//       final sessionsJson = _prefs.getStringList('chat_sessions') ?? [];
//       _sessions = sessionsJson
//           .map((json) => ChatSession.fromJson(jsonDecode(json)))
//           .toList();
//       _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//       _notifySessions();
//     } catch (e) {
//       print('Error loading sessions: $e');
//       _sessions = [];
//     }
//   }
//
//   Future<void> _saveSessions() async {
//     if (!_initialized) {
//       await initialize();
//     }
//
//     final sessionsJson = _sessions.map((session) => jsonEncode(session.toJson())).toList();
//     await _prefs.setStringList('chat_sessions', sessionsJson);
//     _notifySessions();
//   }
//
//   void _notifySessions() {
//     _sessionsStreamController.add(_sessions);
//   }
//
//   ChatSession createNewSession() {
//     final newSession = ChatSession(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: 'New Chat',
//       createdAt: DateTime.now(),
//       messages: [
//         ChatMessage(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           text: AppConstants.welcomeMessage,
//           isUser: false,
//           timestamp: DateTime.now(),
//         ),
//       ],
//     );
//
//     _sessions.insert(0, newSession);
//     _saveSessions(); // Ensure sessions are saved
//     _notifySessions();
//     return newSession;
//   }
//
//   ChatSession? getSession(String id) {
//     try {
//       return _sessions.firstWhere((session) => session.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   List<ChatSession> getAllSessions() {
//     return List.from(_sessions);
//   }
//
//   Future<void> updateSessionTitle(String sessionId, String newTitle) async {
//     if (!_initialized) {
//       await initialize();
//     }
//
//     final index = _sessions.indexWhere((session) => session.id == sessionId);
//     if (index != -1) {
//       _sessions[index] = _sessions[index].copyWith(title: newTitle);
//       await _saveSessions();
//     }
//   }
//
//   Future<void> deleteSession(String sessionId) async {
//     if (!_initialized) {
//       await initialize();
//     }
//
//     _sessions.removeWhere((session) => session.id == sessionId);
//     await _saveSessions(); // Ensure deleted session is saved
//   }
//
//   Future<Stream<ChatMessage>> sendMessageWithStreaming({
//     required String sessionId,
//     required String message,
//     File? attachedFile,
//   }) async {
//     if (!_initialized) {
//       await initialize();
//     }
//
//     // Create and commit the user message immediately
//     final userMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: message,
//       isUser: true,
//       timestamp: DateTime.now(),
//     );
//
//     final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
//     if (sessionIndex == -1) {
//       throw Exception('Session not found');
//     }
//
//     // Add user message to the session right away
//     _sessions[sessionIndex] = _sessions[sessionIndex]
//         .copyWith(messages: [..._sessions[sessionIndex].messages, userMessage]);
//     await _saveSessions();
//
//     // Update session title based on first user message if it's still "New Chat"
//     if (_sessions[sessionIndex].title == 'New Chat' &&
//         _sessions[sessionIndex].messages.length == 2) {
//       final truncatedTitle =
//       message.length > 30 ? message.substring(0, 27) + '...' : message;
//       _sessions[sessionIndex] =
//           _sessions[sessionIndex].copyWith(title: truncatedTitle);
//       await _saveSessions();
//     }
//
//     // Now prepare AI's placeholder message
//     final aiResponseId = DateTime.now().millisecondsSinceEpoch.toString();
//     final aiPlaceholder = ChatMessage(
//       id: aiResponseId,
//       text: "",
//       isUser: false,
//       timestamp: DateTime.now(),
//       isComplete: false,
//     );
//
//     _sessions[sessionIndex] = _sessions[sessionIndex]
//         .copyWith(messages: [..._sessions[sessionIndex].messages, aiPlaceholder]);
//     await _saveSessions();
//
//     // Start AI streaming response here
//     try {
//       final responseStreamController = StreamController<ChatMessage>();
//       _streamingService.getStreamingAiResponse(message, _sessions[sessionIndex].messages)
//           .listen((responseText) {
//         final updatedAI = aiPlaceholder.copyWith(text: responseText);
//
//         final msgIndex = _sessions[sessionIndex]
//             .messages
//             .indexWhere((m) => m.id == aiResponseId);
//
//         if (msgIndex != -1) {
//           final updatedMessages = [..._sessions[sessionIndex].messages];
//           updatedMessages[msgIndex] = updatedAI;
//           _sessions[sessionIndex] =
//               _sessions[sessionIndex].copyWith(messages: updatedMessages);
//
//           _currentMessageStreamController.add(updatedAI);
//           responseStreamController.add(updatedAI);
//         }
//       }, onDone: () async {
//         final msgIndex = _sessions[sessionIndex]
//             .messages
//             .indexWhere((m) => m.id == aiResponseId);
//
//         if (msgIndex != -1) {
//           final finalAI = _sessions[sessionIndex]
//               .messages[msgIndex]
//               .copyWith(isComplete: true);
//
//           final updatedMessages = [..._sessions[sessionIndex].messages];
//           updatedMessages[msgIndex] = finalAI;
//           _sessions[sessionIndex] =
//               _sessions[sessionIndex].copyWith(messages: updatedMessages);
//           await _saveSessions();
//
//           responseStreamController.add(finalAI);
//           responseStreamController.close();
//         }
//       });
//
//       return responseStreamController.stream;
//     } catch (e) {
//       throw Exception("AI streaming failed: $e");
//     }
//   }
//
//   void stopResponse(String sessionId, String aiMessageId) {
//     _streamingService.stopResponse();
//
//     // Immediately mark AI placeholder as complete
//     final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
//     if (sessionIndex != -1) {
//       final messageIndex = _sessions[sessionIndex]
//           .messages
//           .indexWhere((m) => m.id == aiMessageId);
//       if (messageIndex != -1) {
//         final updatedMessages = [..._sessions[sessionIndex].messages];
//         updatedMessages[messageIndex] =
//             updatedMessages[messageIndex].copyWith(isComplete: true);
//         _sessions[sessionIndex] =
//             _sessions[sessionIndex].copyWith(messages: updatedMessages);
//         _currentMessageStreamController.add(updatedMessages[messageIndex]);
//       }
//     }
//   }
//
//   void dispose() {
//     _sessionsStreamController.close();
//     _currentMessageStreamController.close();
//   }
// }



// lib/services/chat_service.dart
import 'package:http/http.dart' as http;

import 'api_service.dart';


// class ChatService {
//   List<ChatSession> _sessions = [];
//   late SharedPreferences _prefs;
//
//   final _apiUrl = 'https://fastapi-app-717280964807.asia-south1.run.app/ask'; // Your Cloud Run API
//
//   Future<void> initialize() async {
//     _prefs = await SharedPreferences.getInstance();
//     await _loadSessions();
//   }
//
//   Future<void> _loadSessions() async {
//     final data = _prefs.getStringList('chat_sessions') ?? [];
//     _sessions = data.map((s) => ChatSession.fromJson(jsonDecode(s))).toList();
//   }
//
//   Future<void> _saveSessions() async {
//     final data = _sessions.map((s) => jsonEncode(s.toJson())).toList();
//     await _prefs.setStringList('chat_sessions', data);
//   }
//
//   List<ChatSession> getAllSessions() => _sessions;
//
//   Stream<List<ChatSession>> get sessions async* {
//     yield _sessions;
//   }
//
//   ChatSession createNewSession() {
//     final session = ChatSession(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: 'New Chat',
//       createdAt: DateTime.now(),
//       messages: [],
//     );
//     _sessions.insert(0, session);
//     _saveSessions();
//     return session;
//   }
//
//   Future<Stream<ChatMessage>> sendMessageWithStreaming({
//     required String sessionId,
//     required String message,
//   }) async {
//     final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
//     if (sessionIndex == -1) throw Exception('Session not found');
//
//     // Save user message locally
//     final userMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: message,
//       isUser: true,
//       timestamp: DateTime.now(),
//     );
//     _sessions[sessionIndex].messages.add(userMessage);
//     await _saveSessions();
//
//     final response = await http.post(
//       Uri.parse(_apiUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'question': message}),
//     );
//
//     if (response.statusCode != 200) throw Exception("API failed");
//
//     final decoded = jsonDecode(response.body);
//     final botText = decoded['answer'] ?? '...';
//
//     final botMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: botText,
//       isUser: false,
//       timestamp: DateTime.now(),
//       isComplete: true,
//     );
//
//     _sessions[sessionIndex].messages.add(botMessage);
//     await _saveSessions();
//
//     final controller = StreamController<ChatMessage>();
//     controller.add(botMessage);
//     controller.close();
//     return controller.stream;
//   }
//
//   void dispose() {}
// }




// class ChatService {
//
//   final String baseUrl = 'https://fastapi-chatbot-717280964807.asia-south1.run.app/chat'; // ✅ include /chat
//   // Replace with deployed URL
//   //final String baseUrl= 'http://127.0.0.1:8000/chat';
//   final String authToken;
//
//   ChatService({required this.authToken});
//
//   Future<ChatSession> createSession(String title) async {
//     print("📡 Calling createSessions...");
//     print(authToken);
//     print("Create Session Called");
//     final res = await http.post(
//       Uri.parse('$baseUrl/createSession'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $authToken',
//       },
//       body: jsonEncode({'title': title}),
//     );
//     if (res.statusCode != 200) throw Exception('Failed to create session');
//     final data = jsonDecode(res.body);
//     return ChatSession(id: data['session_id'], title: title, createdAt: DateTime.now(), messages: []);
//   }
//
//   Future<List<ChatSession>> fetchSessions() async {
//     print("📡 Calling fetchSessions...");
//     final res = await http.get(
//       Uri.parse('$baseUrl/sessions'),  // Make sure baseUrl ends with /chat
//       headers: {
//         'Authorization': 'Bearer $authToken',
//       },
//     );
//
//     debugPrint("📩 Sessions Response [${res.statusCode}]: ${res.body}");
//
//     if (res.statusCode != 200) throw Exception('Failed to load sessions');
//
//     final List data = jsonDecode(res.body);
//     return data.map((json) => ChatSession.fromJson(json)).toList();
//   }
//
//   Future<List<ChatHistoryItem>> fetchMessages(String sessionId) async {
//     final res = await http.get(
//       Uri.parse('$baseUrl/history/$sessionId'),
//       headers: {'Authorization': 'Bearer $authToken'},
//     );
//     print("Fetch Message Body");
//     print(res.body);
//     if (res.statusCode != 200) throw Exception('Failed to load messages');
//     final List data = jsonDecode(res.body);
//     return data.map((m) => ChatHistoryItem.fromJson(m)).toList();
//   }
//
//
//   Future<void> stopResponse(String sessionId, String messageId) async {
//     try {
//       await http.post(
//         Uri.parse('$baseUrl/message/stop'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken',
//         },
//         body: jsonEncode({
//           'session_id': sessionId,
//           'message_id': messageId,
//         }),
//       );
//     } catch (e) {
//       debugPrint("❌ Error sending stop request: $e");
//     }
//   }
//
//
//   // 🔥 Add this method
//   Future<void> updateSessionTitle(String sessionId, String newTitle) async {
//     final response = await http.patch(
//       Uri.parse('$baseUrl/session/$sessionId/title'),
//       headers: {
//         'Authorization': 'Bearer $authToken',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'title': newTitle}),
//     );
//
//     if (response.statusCode != 200) {
//       print("❌ Failed to update session title: ${response.body}");
//     } else {
//       print("✅ Session title updated");
//     }
//   }
//
//   Future<Stream<ChatMessage>> sendMessageWithStreaming({
//     required String sessionId,
//     required String message,
//   }) async {
//     final request = http.Request(
//       'POST',
//       Uri.parse('$baseUrl/message/stream'),
//     );
//
//     request.headers.addAll({
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $authToken',
//     });
//
//     request.body = jsonEncode({'session_id': sessionId ?? "", 'question': utf8.decode(message.codeUnits),});
//     debugPrint("📤 Sending request to stream message: $message");
//
//     final response = await request.send();
//     debugPrint("📥 Stream response status: ${response.statusCode}");
//
//     if (response.statusCode != 200) {
//       final errorBody = await response.stream.bytesToString();
//       debugPrint("❌ Streaming error body: $errorBody");
//       throw Exception("Streaming failed");
//     }
//
//     final controller = StreamController<ChatMessage>();
//     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     response.stream.transform(utf8.decoder).listen(
//           (chunk) {
//         debugPrint("📩 Raw chunk received: ${chunk.length} chars");
//
//         // Process the SSE format
//         for (var line in chunk.split('\n')) {
//           if (line.startsWith('data:')) {
//             try {
//               final jsonText = line.substring(5).trim();
//               final decoded = jsonDecode(jsonText);
//               final text = decoded['text'] ?? '';
//
//               debugPrint("🔄 Processed text: ${text.length} chars");
//
//               controller.add(ChatMessage(
//                 id: messageId,
//                 text: text,
//                 isUser: false,
//                 timestamp: DateTime.now(),
//                 isComplete: false,
//               ));
//             } catch (e) {
//               debugPrint("❌ Error parsing JSON from line: $line");
//               debugPrint("❌ Error: $e");
//             }
//           }
//         }
//       },
//       onDone: () {
//         debugPrint("✅ Stream complete");
//         controller.add(ChatMessage(
//           id: messageId,
//           text: '',
//           isUser: false,
//           timestamp: DateTime.now(),
//           isComplete: true,
//         ));
//         controller.close();
//       },
//       onError: (e) {
//         debugPrint("❌ Stream error: $e");
//         controller.addError(e);
//         controller.close();
//       },
//     );
//
//     return controller.stream;
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import 'api_service.dart';
import '../controllers/session_manager.dart';

class ChatService {
  final ApiService _apiService = GetIt.instance<ApiService>();
  final String baseUrl = 'https://fastapi-chatbot-717280964807.asia-south1.run.app/chat';

  final BehaviorSubject<ChatMessage> _messageSubject = BehaviorSubject<ChatMessage>();
  Stream<ChatMessage> get messageStream => _messageSubject.stream;

  ChatService({required String authToken}) {
    SessionManager.token = authToken;
  }

  Future<ChatSession> createSession(String title) async {
    final data = await _apiService.post(
      endpoint: '/chat/createSession',
      body: {'title': title},
    );
    return ChatSession(
      id: data['session_id'],
      title: title,
      createdAt: DateTime.now(),
      messages: [],
    );
  }

  Future<List<ChatSession>> fetchSessions() async {
    final data = await _apiService.get(endpoint: '/chat/sessions');
    return (data as List)
        .map((json) => ChatSession.fromJson(json))
        .toList();
  }

  Future<List<ChatHistoryItem>> fetchMessages(String sessionId) async {
    final data = await _apiService.get(endpoint: '/chat/history/$sessionId');
    return (data as List).map((m) => ChatHistoryItem.fromJson(m)).toList();
  }

  Future<void> stopResponse(String sessionId, String messageId) async {
    try {
      await _apiService.post(
        endpoint: '/chat/message/stop',
        body: {
          'session_id': sessionId,
          'message_id': messageId,
        },
      );
    } catch (e) {
      debugPrint("❌ Error sending stop request: $e");
    }
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      await _apiService.postStream(
        endpoint: '/chat/session/$sessionId/title',
        body: {'title': newTitle},
      );
      debugPrint("✅ Session title updated");
    } catch (e) {
      debugPrint("❌ Failed to update session title: $e");
    }
  }

  Future<Stream<ChatMessage>> sendMessageWithStreaming({
    required String sessionId,
    required String message,
  }) async {
    debugPrint("📤 Sending request to stream message: $message");

    final response = await _apiService.postStream(
      endpoint: '/chat/message/stream',
      body: {
        'session_id': sessionId,
        'question': utf8.decode(message.codeUnits),
      },
    );

    debugPrint("📥 Stream response status: ${response.statusCode}");

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      debugPrint("❌ Streaming error body: $errorBody");
      throw Exception("Streaming failed");
    }

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    response.stream.transform(utf8.decoder).listen(
          (chunk) {
        //debugPrint("📩 Raw chunk received: ${chunk.length} chars");

        for (var line in chunk.split('\n')) {
          if (line.startsWith('data:')) {
            try {
              final jsonText = line.substring(5).trim();
              final decoded = jsonDecode(jsonText);
              final text = decoded['text'] ?? '';

             // debugPrint("🔄 Processed text: ${text.length} chars");

              _messageSubject.add(ChatMessage(
                id: messageId,
                text: text,
                isUser: false,
                timestamp: DateTime.now(),
                isComplete: false,
              ));
            } catch (e) {
              debugPrint("❌ Error parsing JSON from line: $line");
              debugPrint("❌ Error: $e");
            }
          }
        }
      },
      onDone: () {
        debugPrint("✅ Stream complete");
        _messageSubject.add(ChatMessage(
          id: messageId,
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isComplete: true,
        ));
      },
      onError: (e) {
        debugPrint("❌ Stream error: $e");
        _messageSubject.addError(e);
      },
    );

    return messageStream;
  }

  void dispose() {
    _messageSubject.close();
  }
}






