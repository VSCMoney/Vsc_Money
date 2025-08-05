import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import '../controllers/session_manager.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../models/chat_history_model.dart';
import '../services/api_service.dart';
import 'auth_service.dart';
import 'locator.dart';

class ChatService{
  final EndPointService _apiService = locator<EndPointService>();

  final _messagesSubject = BehaviorSubject<List<Map<String, Object>>>.seeded([]);
  final _isTypingSubject = BehaviorSubject<bool>.seeded(false);
  final _hasLoadedMessagesSubject = BehaviorSubject<bool>.seeded(false);
  final _firstMessageCompleteSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<ChatSession>> _sessionsController =
  BehaviorSubject<List<ChatSession>>.seeded([]);
  Stream<List<ChatSession>> get sessionsStream => _sessionsController.stream;



  ChatSession? _currentSession;
  bool _isInitialized = false;
  bool _showNewChatButton = false;
  bool _isLoadingSession = false;
  String? _error;
  List<ChatSession> _sessions = [];

  Stream<List<Map<String, Object>>> get messagesStream => _messagesSubject.stream;
  Stream<bool> get isTypingStream => _isTypingSubject.stream;
  Stream<bool> get hasLoadedMessagesStream => _hasLoadedMessagesSubject.stream;
  Stream<bool> get firstMessageCompleteStream => _firstMessageCompleteSubject.stream;

  List<Map<String, Object>> get messages => _messagesSubject.value;
  bool get hasLoadedMessages => _hasLoadedMessagesSubject.value;
  bool get isTyping => _isTypingSubject.value;
  bool get firstMessageComplete => _firstMessageCompleteSubject.value;

  String _currentStreamingId = '';
  StreamSubscription<ChatMessage>? _streamSubscription;


  // Dashboard state getters
  ChatSession? get currentSession => _currentSession;
  bool get isInitialized => _isInitialized;
  bool get showNewChatButton => _showNewChatButton;
  bool get isLoadingSession => _isLoadingSession;
  String? get error => _error;
  List<ChatSession> get sessions => _sessions;


  Future<void> initializeForDashboard({ChatSession? initialSession}) async {
    if (_isInitialized) return;

    _setLoadingSession(true);
    _clearError();

    try {
      print("🔄 Initializing ChatService for dashboard...");
      final authService = locator<AuthService>();
      final token = SessionManager.token;

      if (token == null || token.isEmpty) {
        throw Exception("No authentication token found");
      }

      // Load all sessions
      await _loadSessions();

      // 🧠 Use the initial session if provided
      if (initialSession != null) {
        print("📥 Using initial session: ${initialSession.id}");
        await switchToSession(initialSession);
      } else {
        print("🆕 No session passed, creating a new one...");
        final session = await createSession('New Chat');
        await switchToSession(session);
      }

      _isInitialized = true;
      print("✅ ChatService initialized successfully");
    } catch (e) {
      _setError("Failed to initialize chat service: $e");
      print("❌ ChatService initialization error: $e");
    } finally {
      _setLoadingSession(false);
    }
  }





  // Switch to a different session
  Future<void> switchToSession(ChatSession session) async {
    if (_currentSession?.id == session.id) return;

    _setLoadingSession(true);
    _clearError();

    try {
      // Clear current messages and reset state
      clear();

      _currentSession = session;

      // Load messages for this session
      await loadMessages(session.id);

      // Check if this session has completed messages to show new chat button
      await _updateNewChatButtonState();

      print("✅ Switched to session: ${session.title}");
    } catch (e) {
      _setError("Failed to switch session: $e");
      print("❌ Error switching session: $e");
    } finally {
      _setLoadingSession(false);
    }
  }


  // Create a new chat session
  Future<ChatSession> createNewChatSession() async {
    if (!_isInitialized) {
      throw Exception("ChatService not initialized");
    }

    _setLoadingSession(true);
    _clearError();

    try {
      print("🆕 Creating new chat session...");
      final newSession = await createSession('New Chat');

      // Add to sessions list
      _sessions.insert(0, newSession);

      // Switch to the new session
      await switchToSession(newSession);

      print("✅ New chat session created");
      return newSession;
    } catch (e) {
      _setError("Failed to create new chat: $e");
      print("❌ Error creating new chat session: $e");
      rethrow;
    } finally {
      _setLoadingSession(false);
    }
  }

  // Load all sessions
  Future<void> _loadSessions() async {
    try {
      _sessions = await fetchSessions();
      print("✅ Loaded ${_sessions.length} sessions");
    } catch (e) {
      print("❌ Failed to load sessions: $e");
      _sessions = [];
    }
  }

  // Update new chat button state
  Future<void> _updateNewChatButtonState() async {
    if (_currentSession == null) {
      _showNewChatButton = false;
      return;
    }

    try {
      final sessionMessages = await fetchMessages(_currentSession!.id);
      final hasCompletedMessages = sessionMessages.isNotEmpty &&
          sessionMessages.any((m) => m.answer != null && m.answer!.isNotEmpty);

      _showNewChatButton = hasCompletedMessages;
    } catch (e) {
      print("❌ Error checking session messages: $e");
      _showNewChatButton = false;
    }
  }

  void onFirstMessageComplete(String newTitle) {
    _showNewChatButton = true;

    if (_currentSession != null) {
      _currentSession!.title = newTitle.trim();

      // 🔄 Also update in the list if visible elsewhere (like Conversations screen)
      final sessions = _sessionsController.value;
      final index = sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (index != -1) {
        sessions[index] = _currentSession!;
        _sessionsController.add([...sessions]);
      }
    }
  }


  // Private helper methods
  void _setLoadingSession(bool loading) {
    _isLoadingSession = loading;
  }

  void _setError(String? error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }




  Future<void> loadMessages(String sessionId) async {
    _messagesSubject.add([]);
    try {
      final fetched = await fetchMessages(sessionId);

      final loaded = <Map<String, Object>>[];
      for (final message in fetched) {
        loaded.add({'role': 'user', 'msg': message.question});
        loaded.add({'role': 'bot', 'msg': message.answer});
      }

      _messagesSubject.add(loaded);
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();
    } catch (e) {
      debugPrint("❌ Failed to load messages: $e");
      _hasLoadedMessagesSubject.add(true);
    }
  }

  Future<List<ChatHistoryItem>> fetchMessages(String sessionId) async {
    final data = await _apiService.get(endpoint: '/chat/history/$sessionId');
    return (data as List).map((m) => ChatHistoryItem.fromJson(m)).toList();
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
    return (data as List).map((json) => ChatSession.fromJson(json)).toList();
  }

  // Future<void> sendMessage(String sessionId, String text) async {
  //   final userMessage = sanitizeMessage(text);
  //   final isFirstMessage = !messages.any((m) => m['role'] == 'user');
  //   final userMessageId = UniqueKey().toString();
  //   final botMessageId = UniqueKey().toString();
  //
  //   _isTypingSubject.add(true);
  //   _messagesSubject.add([
  //     ...messages,
  //     {
  //       'id': userMessageId,
  //       'role': 'user',
  //       'msg': userMessage,
  //       'isComplete': true,
  //     },
  //     {
  //       'id': botMessageId,
  //       'role': 'bot',
  //       'msg': '',
  //       'isComplete': false,
  //     }
  //   ]);
  //
  //   try {
  //     if (isFirstMessage) {
  //       await updateSessionTitle(sessionId, userMessage);
  //     }
  //
  //     final responseStream = await sendMessageWithStreaming(
  //       sessionId: sessionId,
  //       message: userMessage,
  //     );
  //
  //     String streamedText = '';
  //     _currentStreamingId = '';
  //     int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  //
  //     _streamSubscription = responseStream.listen((message) {
  //       if (_currentStreamingId.isEmpty) {
  //         _currentStreamingId = message.id;
  //       }
  //
  //       streamedText += message.text;
  //       final currentTime = DateTime.now().millisecondsSinceEpoch;
  //       final timeSinceLastUpdate = currentTime - lastUpdateTime;
  //
  //       if (timeSinceLastUpdate > 50 || message.isComplete) {
  //         final updated = [..._messagesSubject.value];
  //         final lastIndex = updated.length - 1;
  //         if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //           updated[lastIndex] = {
  //             'id': botMessageId,
  //             'role': 'bot',
  //             'msg': streamedText,
  //             'isComplete': message.isComplete,
  //           };
  //           _messagesSubject.add(updated);
  //         }
  //         lastUpdateTime = currentTime;
  //       }
  //
  //       if (message.isComplete) {
  //         final updated = [..._messagesSubject.value];
  //         final lastIndex = updated.length - 1;
  //         if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //           updated[lastIndex] = {
  //             'id': botMessageId,
  //             'role': 'bot',
  //             'msg': streamedText,
  //             'isComplete': true,
  //           };
  //           _messagesSubject.add(updated);
  //         }
  //
  //         _isTypingSubject.add(false);
  //         _checkAndNotifyFirstMessageComplete();
  //
  //         if (streamedText.contains('"stocks":')) {
  //           try {
  //             final cleaned = streamedText.replaceAll("```json", "").replaceAll("```", "").trim();
  //             final data = jsonDecode(cleaned);
  //             final List<dynamic> stocks = data['stocks'];
  //             final updated = [..._messagesSubject.value];
  //             updated.removeLast();
  //             updated.add({
  //               'id': UniqueKey().toString(),
  //               'role': 'bot',
  //               'msg': '',
  //               'type': 'stocks',
  //               'stocks': stocks,
  //             });
  //             _messagesSubject.add(updated);
  //           } catch (e) {
  //             debugPrint('❌ Error parsing stock JSON: $e');
  //           }
  //         }
  //       }
  //     }, onError: (e) {
  //       _isTypingSubject.add(false);
  //       final updated = [..._messagesSubject.value];
  //       final lastIndex = updated.length - 1;
  //       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //         updated[lastIndex] = {
  //           'id': botMessageId,
  //           'role': 'bot',
  //           'msg': '❌ Failed to respond.',
  //           'isComplete': true,
  //           'retry': true,
  //           'originalMessage': userMessage,
  //         };
  //         _messagesSubject.add(updated);
  //       }
  //     });
  //   } catch (e) {
  //     _isTypingSubject.add(false);
  //     final updated = [..._messagesSubject.value];
  //     final lastIndex = updated.length - 1;
  //     if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //       updated[lastIndex] = {
  //         'id': botMessageId,
  //         'role': 'bot',
  //         'msg': '❌ Failed to send.',
  //         'isComplete': true,
  //         'retry': true,
  //         'originalMessage': userMessage,
  //       };
  //       _messagesSubject.add(updated);
  //     }
  //   }
  // }
  //
  // Future<void> stopResponse(String sessionId) async {
  //   _streamSubscription?.cancel();
  //   if (_currentStreamingId.isNotEmpty) {
  //     try {
  //       await _apiService.post(endpoint: '/chat/message/stop', body: {
  //         'session_id': sessionId,
  //         'message_id': _currentStreamingId,
  //       });
  //     } catch (e) {
  //       debugPrint('❌ Stop failed: $e');
  //     }
  //   }
  //   final updated = [..._messagesSubject.value];
  //   final lastIndex = updated.length - 1;
  //   if (lastIndex >= 0) {
  //     updated[lastIndex] = {
  //       ...updated[lastIndex],
  //       'isComplete': true,
  //     };
  //     _messagesSubject.add(updated);
  //   }
  //   _isTypingSubject.add(false);
  //   _checkAndNotifyFirstMessageComplete();
  // }







  Future<void> sendMessage(String sessionId, String text) async {
    final userMessage = sanitizeMessage(text);
    final isFirstMessage = !messages.any((m) => m['role'] == 'user');
    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    _isTypingSubject.add(true);
    _messagesSubject.add([
      ...messages,
      {
        'id': userMessageId,
        'role': 'user',
        'msg': userMessage,
        'isComplete': true,
      },
      {
        'id': botMessageId,
        'role': 'bot',
        'msg': '',
        'isComplete': false,
        // NEW: Add enhanced fields
        'statusUpdates': <Map<String, dynamic>>[],
        'payloads': <Map<String, dynamic>>[],
      }
    ]);

    try {
      if (isFirstMessage) {
        await updateSessionTitle(sessionId, userMessage);
      }

      final responseStream = await sendMessageWithStreaming(
        sessionId: sessionId,
        message: userMessage,
      );

      String streamedText = '';
      _currentStreamingId = '';
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      _streamSubscription = responseStream.listen((chatMessage) {
        if (_currentStreamingId.isEmpty) {
          _currentStreamingId = chatMessage.id;
        }

        // Handle legacy text streaming (for backward compatibility)
        if (chatMessage.text.isNotEmpty) {
          streamedText += chatMessage.text;
        }

        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final timeSinceLastUpdate = currentTime - lastUpdateTime;

        // Update UI at reasonable intervals or when complete
        if (timeSinceLastUpdate > 50 || chatMessage.isComplete) {
          final updated = [..._messagesSubject.value];
          final lastIndex = updated.length - 1;

          if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
            updated[lastIndex] = {
              'id': botMessageId,
              'role': 'bot',
              'msg': streamedText,
              'isComplete': chatMessage.isComplete,
              // NEW: Convert enhanced fields to Map format
              'statusUpdates': chatMessage.statusUpdates.map((status) => {
                'id': status.id,
                'type': status.type.toString().split('.').last,
                'message': status.message,
                'timestamp': status.timestamp.toIso8601String(),
                'isComplete': status.isComplete,
              }).toList(),
              'payloads': chatMessage.payloads.map((payload) => {
                'id': payload.id,
                'type': payload.type.toString().split('.').last,
                'data': payload.data,
                'title': payload.title,
                'description': payload.description,
              }).toList(),
            };
            _messagesSubject.add(updated);
          }
          lastUpdateTime = currentTime;
        }

        if (chatMessage.isComplete) {
          final updated = [..._messagesSubject.value];
          final lastIndex = updated.length - 1;

          if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
            updated[lastIndex] = {
              'id': botMessageId,
              'role': 'bot',
              'msg': streamedText,
              'isComplete': true,
              // NEW: Final enhanced fields
              'statusUpdates': chatMessage.statusUpdates.map((status) => {
                'id': status.id,
                'type': status.type.toString().split('.').last,
                'message': status.message,
                'timestamp': status.timestamp.toIso8601String(),
                'isComplete': status.isComplete,
              }).toList(),
              'payloads': chatMessage.payloads.map((payload) => {
                'id': payload.id,
                'type': payload.type.toString().split('.').last,
                'data': payload.data,
                'title': payload.title,
                'description': payload.description,
              }).toList(),
            };
            _messagesSubject.add(updated);
          }

          _isTypingSubject.add(false);
          _checkAndNotifyFirstMessageComplete();

          // Keep your existing stock parsing logic
          if (streamedText.contains('"stocks":')) {
            try {
              final cleaned = streamedText.replaceAll("```json", "").replaceAll("```", "").trim();
              final data = jsonDecode(cleaned);
              final List<dynamic> stocks = data['stocks'];
              final updated = [..._messagesSubject.value];
              updated.removeLast();
              updated.add({
                'id': UniqueKey().toString(),
                'role': 'bot',
                'msg': '',
                'type': 'stocks',
                'stocks': stocks,
              });
              _messagesSubject.add(updated);
            } catch (e) {
              debugPrint('❌ Error parsing stock JSON: $e');
            }
          }
        }
      }, onError: (e) {
        _isTypingSubject.add(false);
        final updated = [..._messagesSubject.value];
        final lastIndex = updated.length - 1;
        if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
          updated[lastIndex] = {
            'id': botMessageId,
            'role': 'bot',
            'msg': '❌ Failed to respond.',
            'isComplete': true,
            'retry': true,
            'originalMessage': userMessage,
            'statusUpdates': <Map<String, dynamic>>[],
            'payloads': <Map<String, dynamic>>[],
          };
          _messagesSubject.add(updated);
        }
      });
    } catch (e) {
      _isTypingSubject.add(false);
      final updated = [..._messagesSubject.value];
      final lastIndex = updated.length - 1;
      if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
        updated[lastIndex] = {
          'id': botMessageId,
          'role': 'bot',
          'msg': '❌ Failed to send.',
          'isComplete': true,
          'retry': true,
          'originalMessage': userMessage,
          'statusUpdates': <Map<String, dynamic>>[],
          'payloads': <Map<String, dynamic>>[],
        };
        _messagesSubject.add(updated);
      }
    }
  }

// Keep your existing stopResponse method unchanged - it works perfectly
  Future<void> stopResponse(String sessionId) async {
    _streamSubscription?.cancel();
    if (_currentStreamingId.isNotEmpty) {
      try {
        await _apiService.post(endpoint: '/chat/message/stop', body: {
          'session_id': sessionId,
          'message_id': _currentStreamingId,
        });
      } catch (e) {
        debugPrint('❌ Stop failed: $e');
      }
    }
    final updated = [..._messagesSubject.value];
    final lastIndex = updated.length - 1;
    if (lastIndex >= 0) {
      updated[lastIndex] = {
        ...updated[lastIndex],
        'isComplete': true,
      };
      _messagesSubject.add(updated);
    }
    _isTypingSubject.add(false);
    _checkAndNotifyFirstMessageComplete();
  }

// NEW: Helper method to convert Map message to ChatMessage object for UI
  ChatMessage mapToChatMessage(Map<String, dynamic> messageMap) {
    // Convert statusUpdates from Map format back to StatusUpdate objects
    final statusUpdates = (messageMap['statusUpdates'] as List<Map<String, dynamic>>? ?? [])
        .map((statusMap) => StatusUpdate(
      id: statusMap['id'],
      type: StatusType.values.firstWhere(
            (e) => e.toString().split('.').last == statusMap['type'],
        orElse: () => StatusType.processing,
      ),
      message: statusMap['message'],
      timestamp: DateTime.parse(statusMap['timestamp']),
      isComplete: statusMap['isComplete'],
    ))
        .toList();

    // Convert payloads from Map format back to ResponsePayload objects
    final payloads = (messageMap['payloads'] as List<Map<String, dynamic>>? ?? [])
        .map((payloadMap) => ResponsePayload(
      id: payloadMap['id'],
      type: PayloadType.values.firstWhere(
            (e) => e.toString().split('.').last == payloadMap['type'],
        orElse: () => PayloadType.text,
      ),
      data: payloadMap['data'],
      title: payloadMap['title'],
      description: payloadMap['description'],
    ))
        .toList();

    return ChatMessage(
      id: messageMap['id'],
      text: messageMap['msg'] ?? '',
      isUser: messageMap['role'] == 'user',
      timestamp: DateTime.now(), // You might want to store actual timestamp in the map
      isComplete: messageMap['isComplete'] ?? true,
      statusUpdates: statusUpdates,
      payloads: payloads,
    );
  }


  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      await _apiService.postStream(
        endpoint: '/chat/session/$sessionId/title',
        body: {'title': newTitle},
      );
    } catch (e) {
      debugPrint("❌ Failed to update session title: $e");
    }
  }

  // Future<Stream<ChatMessage>> sendMessageWithStreaming({
  //   required String sessionId,
  //   required String message,
  // }) async {
  //   final response = await _apiService.postStream(
  //     endpoint: '/chat/message/stream',
  //     body: {
  //       'session_id': sessionId,
  //       'question': utf8.decode(message.codeUnits),
  //     },
  //   );
  //
  //   if (response.statusCode != 200) {
  //     final errorBody = await response.stream.bytesToString();
  //     throw Exception("Streaming failed: $errorBody");
  //   }
  //
  //   final controller = StreamController<ChatMessage>();
  //   final messageId = DateTime.now().millisecondsSinceEpoch.toString();
  //
  //   response.stream.transform(utf8.decoder).listen(
  //         (chunk) {
  //       for (var line in chunk.split('\n')) {
  //         if (line.startsWith('data:')) {
  //           final jsonText = line.substring(5).trim();
  //           try {
  //             final decoded = jsonDecode(jsonText);
  //             final text = decoded['text'] ?? '';
  //             controller.add(ChatMessage(
  //               id: messageId,
  //               text: text,
  //               isUser: false,
  //               timestamp: DateTime.now(),
  //               isComplete: false,
  //             ));
  //           } catch (e) {
  //             debugPrint("❌ Error parsing streamed line: $e");
  //           }
  //         }
  //       }
  //     },
  //     onDone: () {
  //       controller.add(ChatMessage(
  //         id: messageId,
  //         text: '',
  //         isUser: false,
  //         timestamp: DateTime.now(),
  //         isComplete: true,
  //       ));
  //       controller.close();
  //     },
  //     onError: (e) {
  //       controller.addError(e);
  //       controller.close();
  //     },
  //   );
  //
  //   return controller.stream;
  // }









  Future<Stream<ChatMessage>> sendMessageWithStreaming({
    required String sessionId,
    required String message,
  }) async {

    // DEBUG: Add this to confirm the method is being called
    print("🔍 DEBUG: sendMessageWithStreaming called with message: '$message'");

    // FOR NOW: Return hardcoded enhanced responses
    // LATER: Simply uncomment the backend call and remove hardcoded logic

    // ============= HARDCODED SECTION (REMOVE WHEN BACKEND IS READY) =============
    final controller = StreamController<ChatMessage>();
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    print("🔍 DEBUG: Generated messageId: $messageId");

    // Check if message matches our test scenarios
    if (_shouldReturnEnhancedResponse(message)) {
      print("🔍 DEBUG: Message matches enhanced response");
      _simulateEnhancedResponse(controller, messageId, message);
      return controller.stream;
    }

    print("🔍 DEBUG: Message doesn't match, returning default response");

    // Default simple response for other messages
    controller.add(ChatMessage(
      id: messageId,
      text: 'I can help you with portfolio analysis, expense analysis, account summary, or weather updates. Try asking about any of these!',
      isUser: false,
      timestamp: DateTime.now(),
      isComplete: true,
    ));
    controller.close();
    return controller.stream;
    // ============= END HARDCODED SECTION =============
  }

// Helper method to check if we should return enhanced response
  bool _shouldReturnEnhancedResponse(String message) {
    final lowerMessage = message.toLowerCase();
    print("🔍 DEBUG: Checking message: '$lowerMessage'");

    final hasPortfolio = lowerMessage.contains('portfolio');
    final hasExpense = lowerMessage.contains('expense');
    final hasAccount = lowerMessage.contains('account');
    final hasWeather = lowerMessage.contains('weather');

    print("🔍 DEBUG: Contains portfolio: $hasPortfolio, expense: $hasExpense, account: $hasAccount, weather: $hasWeather");

    return hasPortfolio || hasExpense || hasAccount || hasWeather;
  }

// Simulate enhanced response with hardcoded data
  void _simulateEnhancedResponse(
      StreamController<ChatMessage> controller,
      String messageId,
      String message
      ) async {
    print("🔍 DEBUG: _simulateEnhancedResponse started");

    final lowerMessage = message.toLowerCase();

    // Determine which scenario to simulate
    Map<String, dynamic> scenarioData;

    if (lowerMessage.contains('portfolio')) {
      print("🔍 DEBUG: Using portfolio data");
      scenarioData = _getPortfolioData();
    } else if (lowerMessage.contains('expense')) {
      print("🔍 DEBUG: Using expense data");
      scenarioData = _getExpenseData();
    } else if (lowerMessage.contains('account')) {
      print("🔍 DEBUG: Using account data");
      scenarioData = _getAccountData();
    } else if (lowerMessage.contains('weather')) {
      print("🔍 DEBUG: Using weather data");
      scenarioData = _getWeatherData();
    } else {
      print("🔍 DEBUG: Using simple data");
      scenarioData = _getSimpleData();
    }

    final statusUpdates = scenarioData['statusUpdates'] as List;
    final payloads = scenarioData['payloads'] as List;

    print("🔍 DEBUG: Status updates: ${statusUpdates.length}, Payloads: ${payloads.length}");

    List<StatusUpdate> allStatusUpdates = [];
    List<ResponsePayload> allPayloads = [];

    // Simulate status updates
    for (int i = 0; i < statusUpdates.length; i++) {
      final statusData = statusUpdates[i];
      print("🔍 DEBUG: Processing status update $i: ${statusData['message']}");

      final statusUpdate = StatusUpdate(
        id: '${messageId}_status_$i',
        type: _parseStatusType(statusData['type']),
        message: statusData['message'],
        timestamp: DateTime.now(),
        isComplete: false,
      );
      allStatusUpdates.add(statusUpdate);

      controller.add(ChatMessage(
        id: messageId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isComplete: false,
        statusUpdates: List.from(allStatusUpdates),
        payloads: List.from(allPayloads),
      ));

      await Future.delayed(Duration(milliseconds: statusData['duration']));

      // Mark status as complete
      allStatusUpdates[i] = StatusUpdate(
        id: statusUpdate.id,
        type: statusUpdate.type,
        message: statusUpdate.message,
        timestamp: statusUpdate.timestamp,
        isComplete: true,
      );

      controller.add(ChatMessage(
        id: messageId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isComplete: false,
        statusUpdates: List.from(allStatusUpdates),
        payloads: List.from(allPayloads),
      ));

      await Future.delayed(Duration(milliseconds: 500));
    }

    // Simulate payloads
    for (int i = 0; i < payloads.length; i++) {
      final payloadData = payloads[i];
      print("🔍 DEBUG: Processing payload $i: ${payloadData['title']}");

      final payload = ResponsePayload(
        id: '${messageId}_payload_$i',
        type: _parsePayloadType(payloadData['type']),
        data: payloadData['data'],
        title: payloadData['title'],
        description: payloadData['description'],
      );
      allPayloads.add(payload);

      controller.add(ChatMessage(
        id: messageId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isComplete: false,
        statusUpdates: List.from(allStatusUpdates),
        payloads: List.from(allPayloads),
      ));

      await Future.delayed(Duration(milliseconds: 800));
    }

    // Final complete message
    print("🔍 DEBUG: Sending final complete message");
    controller.add(ChatMessage(
      id: messageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isComplete: true,
      statusUpdates: List.from(allStatusUpdates),
      payloads: List.from(allPayloads),
    ));

    controller.close();
  }



// Hardcoded data scenarios
  Map<String, dynamic> _getPortfolioData() {
    return {
      'statusUpdates': [
        {'type': 'thinking', 'message': 'Analyzing your portfolio', 'duration': 2000},
        {'type': 'searching', 'message': 'Fetching latest market data', 'duration': 3000},
        {'type': 'analyzing', 'message': 'Calculating performance metrics', 'duration': 2000},
      ],
      'payloads': [
        {
          'type': 'text',
          'data': 'Here\'s your comprehensive portfolio analysis:',
          'title': 'Portfolio Overview',
          'description': null,
        },
        {
          'type': 'json',
          'data': {
            'display_type': 'table',
            'headers': ['Stock', 'Current Price', 'Holdings', 'P&L', 'Performance'],
            'rows': [
              ['Zomato', '₹156.75', '50 shares', '+₹2,337.50', '+15.2%'],
              ['TCS', '₹3,245.80', '10 shares', '+₹1,458.00', '+4.7%'],
              ['Reliance', '₹2,678.90', '5 shares', '-₹567.50', '-4.1%'],
              ['HDFC Bank', '₹1,567.25', '15 shares', '+₹3,456.75', '+17.3%'],
              ['Infosys', '₹1,389.60', '20 shares', '+₹2,792.00', '+11.2%'],
            ]
          },
          'title': 'Stock Holdings',
          'description': 'Your current stock positions and performance',
        },
        {
          'type': 'text',
          'data': '**Summary**: Portfolio gained ₹9,476.75 (8.9%) this quarter. **Top performers**: Zomato and HDFC Bank. **Recommendation**: Consider rebalancing Reliance position.',
          'title': null,
          'description': null,
        },
      ],
    };
  }

  Map<String, dynamic> _getExpenseData() {
    return {
      'statusUpdates': [
        {'type': 'thinking', 'message': 'Processing your expense data...', 'duration': 2500},
        {'type': 'analyzing', 'message': 'Categorizing transactions...', 'duration': 2000},
      ],
      'payloads': [
        {
          'type': 'text',
          'data': 'Your expense breakdown for this month:',
          'title': 'Monthly Expenses',
          'description': null,
        },
        {
          'type': 'json',
          'data': {
            'display_type': 'table',
            'headers': ['Category', 'Amount', 'Percentage', 'Budget Status'],
            'rows': [
              ['Food & Dining', '₹12,450', '35%', 'Over Budget'],
              ['Transportation', '₹5,670', '16%', 'Within Budget'],
              ['Entertainment', '₹8,230', '23%', 'Within Budget'],
              ['Shopping', '₹6,890', '19%', 'Over Budget'],
              ['Utilities', '₹2,560', '7%', 'Within Budget'],
            ]
          },
          'title': 'Expense Categories',
          'description': 'Breakdown of your monthly spending',
        },
        {
          'type': 'text',
          'data': '**Total**: ₹35,800. Over budget by ₹5,800 due to **food and shopping**. **Tip**: Try meal planning to reduce costs.',
          'title': null,
          'description': null,
        },
      ],
    };
  }

  Map<String, dynamic> _getAccountData() {
    return {
      'statusUpdates': [
        {'type': 'searching', 'message': 'Retrieving account information...', 'duration': 1500},
      ],
      'payloads': [
        {
          'type': 'text',
          'data': 'Here\'s your current account summary:',
          'title': 'Account Overview',
          'description': null,
        },
        {
          'type': 'json',
          'data': {
            'account_number': '****7891',
            'account_type': 'Savings Account',
            'current_balance': '₹1,25,450.75',
            'available_balance': '₹1,20,450.75',
            'last_transaction': 'July 28, 2025',
            'interest_rate': '3.5% per annum',
            'status': 'Active'
          },
          'title': 'Account Details',
          'description': 'Your primary savings account information',
        },
      ],
    };
  }

  Map<String, dynamic> _getWeatherData() {
    return {
      'statusUpdates': [
        {'type': 'searching', 'message': 'Fetching current weather data...', 'duration': 1500},
      ],
      'payloads': [
        {
          'type': 'text',
          'data': '**Current Weather**: 28°C in Jaipur, partly cloudy with 65% humidity. **Forecast**: High 32°C, low 24°C with evening showers possible.',
          'title': "Weather",
          'description': null,
        },
      ],
    };
  }

  Map<String, dynamic> _getSimpleData() {
    return {
      'statusUpdates': [],
      'payloads': [
        {
          'type': 'text',
          'data': 'I can help you with various financial queries and analysis!',
          'title': null,
          'description': null,
        },
      ],
    };
  }

// Helper methods for parsing (needed for backend integration later)
  StatusType _parseStatusType(String type) {
    switch (type.toLowerCase()) {
      case 'thinking': return StatusType.thinking;
      case 'searching': return StatusType.searching;
      case 'analyzing': return StatusType.analyzing;
      case 'processing': return StatusType.processing;
      case 'completed': return StatusType.completed;
      default: return StatusType.processing;
    }
  }

  PayloadType _parsePayloadType(String type) {
    switch (type.toLowerCase()) {
      case 'text': return PayloadType.text;
      case 'json': return PayloadType.json;
      case 'chart': return PayloadType.chart;
      default: return PayloadType.text;
    }
  }






  String sanitizeMessage(String input) {
    return input
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .trim();
  }

  void _checkAndNotifyFirstMessageComplete() {
    int userCount = 0;
    int botCount = 0;
    for (var m in messages) {
      if (m['role'] == 'user') userCount++;
      if (m['role'] == 'bot' && (m['isComplete'] == true)) botCount++;
    }
    if (userCount >= 1 && botCount >= 1) {
      _firstMessageCompleteSubject.add(true);
    }
  }

  void clear() {
    _messagesSubject.add([]);
    _firstMessageCompleteSubject.add(false);
    _hasLoadedMessagesSubject.add(false);
    _isTypingSubject.add(false);
    _streamSubscription?.cancel();
    _currentStreamingId = '';
  }

  void dispose() {
    _messagesSubject.close();
    _isTypingSubject.close();
    _hasLoadedMessagesSubject.close();
    _firstMessageCompleteSubject.close();
    _streamSubscription?.cancel();
  }
}
