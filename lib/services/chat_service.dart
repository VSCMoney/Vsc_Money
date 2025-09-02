import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
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
import 'package:http/http.dart'as http;

class ChatService{
  final EndPointService _apiService = locator<EndPointService>();

  final _messagesSubject = BehaviorSubject<List<Map<String, Object>>>.seeded([]);
  final _isTypingSubject = BehaviorSubject<bool>.seeded(false);
  final _hasLoadedMessagesSubject = BehaviorSubject<bool>.seeded(false);
  final _firstMessageCompleteSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<ChatSession>> _sessionsController =
  BehaviorSubject<List<ChatSession>>.seeded([]);
  Stream<List<ChatSession>> get sessionsStream => _sessionsController.stream;


  Future<String>? _creatingSessionFuture;
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


  void _adoptServerSession(String sid) {
    if (_currentSession?.id == sid) return;

    // If we don't have a current session, create a lightweight one
    _currentSession ??= ChatSession(
      id: sid,
      title: 'New Chat',
      createdAt: DateTime.now(),
      messages: const [],
    );

    // Ensure sessions list contains it (at top)
    final exists = _sessions.any((s) => s.id == sid);
    if (!exists) {
      _sessions.insert(0, _currentSession!);
      _sessionsController.add([..._sessions]);
    }
  }




  void resetForNewChat() {
    print("🧹 Resetting ChatService for new chat");

    // Clear all streams and state
    clear();

    // Reset session state
    _currentSession = null;
    _showNewChatButton = false;

    // Reset initialization flags if needed
    // _isInitialized stays true so we don't re-initialize

    print("✅ ChatService reset complete");
  }

  void clearCurrentSession() {
    _currentSession = null;
    _showNewChatButton = false;
  }

  void hideNewChatButton() {
    _showNewChatButton = false;
  }



  // Future<void> initializeForDashboard({ChatSession? initialSession}) async {
  //   if (_isInitialized) return;
  //
  //   _setLoadingSession(true);
  //   _clearError();
  //
  //   try {
  //     print("🔄 Initializing ChatService for dashboard...");
  //
  //     final token = SessionManager.token;
  //     if (token == null || token.isEmpty) {
  //       throw Exception("No authentication token found");
  //     }
  //
  //     // 1) Sirf sessions list load karo
  //     await _loadSessions();
  //
  //     // 2) Agar conversations se aaye ho (initialSession != null) to load messages
  //     if (initialSession != null) {
  //       print("📥 Using initial session: ${initialSession.id}");
  //       await switchToSession(initialSession);  // yeh loadMessages karega
  //     } else {
  //       // 3) Nahi to blank state — koi session create/load nahi hoga
  //       _currentSession = null;
  //       clear(); // streams ko blank state me reset karta hai (hasLoadedMessages=false)
  //       print("🧼 Blank dashboard state (no session, no messages)");
  //     }
  //
  //     _isInitialized = true;
  //     print("✅ ChatService initialized successfully");
  //   } catch (e) {
  //     _setError("Failed to initialize chat service: $e");
  //     print("❌ ChatService initialization error: $e");
  //   } finally {
  //     _setLoadingSession(false);
  //   }
  // }

  void addLocalMessage(Map<String, Object> msg) {
    final updated = [..._messagesSubject.value, msg];
    _messagesSubject.add(updated);
  }

  Future<void> initializeForDashboard({String? initialSessionId}) async {
    print('🔄 Initializing ChatService for dashboard...');
    _isInitialized = false;

    try {
      // Load all sessions first
    await _loadSessions();

      if (initialSessionId != null && initialSessionId.isNotEmpty) {
        print('🎯 Looking for session with ID: $initialSessionId');

        // ✅ FIX: Add better error handling for session lookup
        try {
          final targetSession = _sessions.firstWhere(
                (session) => session.id == initialSessionId,
          );

          print('✅ Found target session: ${targetSession.title}');

          // Switch to this session
          await switchToSession(targetSession);
        } catch (e) {
          print('❌ Session not found: $initialSessionId, creating new session');
          // If session not found, create new one
          await createNewChatSession();
        }
      } else {
        print('🧼 No initial session ID provided, creating blank state');
        // Create blank state for new chat
        _currentSession = null;
        _messagesSubject.add([]);
        _hasLoadedMessagesSubject.add(true);
      }

      _isInitialized = true;
      print('✅ ChatService initialized successfully');

    } catch (e) {
      print('❌ Failed to initialize ChatService: $e');
      _isInitialized = true; // Still mark as initialized to prevent hanging
      // Create a new session as fallback
      await createNewChatSession();
    }
  }



  Future<String> _ensureActiveSessionId([String? sessionId]) async {
    // No-op now. We don't pre-create. If null, /respond will create and stream session_created.
    return sessionId ?? (_currentSession?.id ?? '');
  }


  Future<String> _createAndStoreNewSession() async {
    final newSession = await createSession('New Chat');

    // set as current
    _currentSession = newSession;

    // add to list if missing
    if (!_sessions.any((s) => s.id == newSession.id)) {
      _sessions.insert(0, newSession);
      _sessionsController.add([..._sessions]);
    }

    debugPrint("🆕 Created session on-demand: ${newSession.id}");
    return newSession.id;
  }

  // Switch to a different session
  // Future<void> switchToSession(ChatSession session) async {
  //   if (_currentSession?.id == session.id) return;
  //
  //   _setLoadingSession(true);
  //   _clearError();
  //
  //   try {
  //     // Clear current messages and reset state
  //     clear();
  //
  //     _currentSession = session;
  //
  //     // Load messages for this session
  //     await loadMessages(session.id);
  //
  //     // Check if this session has completed messages to show new chat button
  //     await _updateNewChatButtonState();
  //
  //     print("✅ Switched to session: ${session.title}");
  //   } catch (e) {
  //     _setError("Failed to switch session: $e");
  //     print("❌ Error switching session: $e");
  //   } finally {
  //     _setLoadingSession(false);
  //   }
  // }


  Future<void> switchToSession(ChatSession session) async {
    if (_currentSession?.id == session.id) {
      print('⚠️ Already on session ${session.id}, skipping');
      return;
    }

    _setLoadingSession(true);
    _clearError();

    try {
      print('🔄 Switching to session: ${session.id} (${session.title})');

      // Clear current messages and reset state
      clear();

      // Set current session
      _currentSession = session;

      // ✅ CRITICAL: Actually load messages for this session
      await loadMessages(session.id);

      // Check if this session has completed messages to show new chat button
      await _updateNewChatButtonState();

      print("✅ Successfully switched to session: ${session.title}");
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

    print("🆕 Creating new chat session - UI only");

    // Clear current state
    clear();

    // Reset session state - don't create via API
    _currentSession = null;
    _showNewChatButton = false;

    print("✅ New chat session ready - will be created on first message");

    // Return a temporary session object that will be replaced when real session is created
    return ChatSession(
      id: '', // Empty - will be filled when /respond creates the session
      title: 'New Chat',
      createdAt: DateTime.now(),
      messages: const [],
    );
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




  // Future<void> loadMessages(String sessionId) async {
  //   print('🔍 CHAT: Loading messages for session: $sessionId');
  //   _messagesSubject.add([]);
  //
  //   try {
  //     final fetched = await fetchMessages(sessionId);
  //     print('🔍 CHAT: Fetched ${fetched.length} message pairs from API');
  //
  //     final loaded = <Map<String, Object>>[];
  //
  //     for (int i = 0; i < fetched.length; i++) {
  //       final message = fetched[i];
  //       print('🔍 CHAT: Processing message pair $i:');
  //       print('  - Question: ${message.question.substring(0, min(50, message.question.length))}...');
  //       print('  - Answer: ${message.answer.substring(0, min(50, message.answer.length))}...');
  //
  //       // ✅ CRITICAL FIX: Use 'content' instead of 'msg'
  //       loaded.add({
  //         'role': 'user',
  //         'content': message.question,  // ✅ Changed from 'msg' to 'content'
  //         'timestamp': DateTime.now().toIso8601String(), // Add timestamp if needed
  //       });
  //
  //       loaded.add({
  //         'role': 'assistant',  // ✅ Changed from 'bot' to 'assistant' for consistency
  //         'content': message.answer,   // ✅ Changed from 'msg' to 'content'
  //         'timestamp': DateTime.now().toIso8601String(), // Add timestamp if needed
  //       });
  //     }
  //
  //     print('✅ CHAT: Successfully processed ${loaded.length} messages');
  //     _messagesSubject.add(loaded);
  //     _hasLoadedMessagesSubject.add(true);
  //     _checkAndNotifyFirstMessageComplete();
  //
  //   } catch (e) {
  //     debugPrint("❌ Failed to load messages: $e");
  //     _hasLoadedMessagesSubject.add(true);
  //   }
  // }




  // Future<void> loadMessages(String sessionId) async {
  //   print('🔍 CHAT: Loading messages for session: $sessionId');
  //   _messagesSubject.add([]);
  //
  //   try {
  //     print("Messages: }");
  //     final fetched = await fetchMessages(sessionId);
  //     print('🔍 CHAT: Fetched ${fetched.length} message pairs from API');
  //
  //     final loaded = <Map<String, Object>>[];
  //
  //     for (int i = 0; i < fetched.length; i++) {
  //       final pair = fetched[i];
  //
  //       // Add user message
  //       if (pair.question.isNotEmpty) {
  //         loaded.add({
  //           'role': 'user',
  //           'content': pair.question,
  //           'timestamp': DateTime.now().toIso8601String(),
  //         });
  //       }
  //
  //       // Add bot message
  //       if (pair.answer.isNotEmpty) {
  //         loaded.add({
  //           'role': 'bot', // ✅ Consistent with ChatScreen expectation
  //           'content': pair.answer,
  //           'timestamp': DateTime.now().toIso8601String(),
  //         });
  //       }
  //     }
  //
  //     print('✅ CHAT: Successfully processed ${loaded.length} messages');
  //     _messagesSubject.add(loaded);
  //     _hasLoadedMessagesSubject.add(true);
  //     _checkAndNotifyFirstMessageComplete();
  //
  //   } catch (e) {
  //     debugPrint("❌ Failed to load messages: $e");
  //     _hasLoadedMessagesSubject.add(true);
  //   }
  // }


// Replace your existing loadMessages method with this:

  Future<void> loadMessages(String sessionId) async {
    print('🔍 CHAT: Loading messages for session: $sessionId');
    _messagesSubject.add([]); // Clear current messages

    try {
      final data = await _apiService.get(endpoint: '/chat/history/$sessionId');
      print('🔍 CHAT: Raw API response type: ${data.runtimeType}');

      if (data is! List) {
        print('❌ Expected List but got ${data.runtimeType}');
        _hasLoadedMessagesSubject.add(true);
        return;
      }

      final loaded = <Map<String, Object>>[];

      for (int i = 0; i < data.length; i++) {
        final msg = data[i];

        final author = msg['author']?.toString() ?? '';

        // ✅ Extract content from message_text field
        final content = msg['message_text']?.toString() ??
            msg['Content']?.toString() ??
            msg['content']?.toString() ?? '';

        if (content.isEmpty) {
          print('⚠️ Empty content for message $i, skipping');
          continue;
        }

        // Map author to role
        String role;
        final authorLower = author.toLowerCase();

        if (authorLower == 'user') {
          role = 'user';
        } else if (authorLower.contains('vitty') ||
            authorLower.contains('bot') ||
            authorLower.contains('system') ||
            authorLower == 'tbd') {
          role = 'bot';
        } else {
          role = 'bot';
        }

        print('📝 Adding message: role=$role, content=${content.substring(0, min(50, content.length))}...');

        // ✅ KEY CHANGE: Add isHistorical flag for loaded messages
        loaded.add({
          'role': role,
          'content': content,
          'isComplete': true,        // Historical messages are complete
          'isHistorical': true,      // ✅ NEW: Mark as historical
          'timestamp': msg['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
          'author': author,
        });
      }

      print('✅ CHAT: Successfully processed ${loaded.length} messages');
      _messagesSubject.add(loaded);
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();

    } catch (e) {
      debugPrint("❌ Failed to load messages: $e");
      _hasLoadedMessagesSubject.add(true);
    }
  }



  // Future<List<ChatHistoryItem>> fetchMessages(String sessionId) async {
  //   final data = await _apiService.get(endpoint: '/chat/history/$sessionId');
  //   return (data as List).map((m) => ChatHistoryItem.fromJson(m)).toList();
  // }

  Future<List<ChatHistoryItem>> fetchMessages(String sessionId) async {
    print('🔍 API: Fetching messages for session: $sessionId');

    try {
      final data = await _apiService.get(endpoint: '/chat/history/$sessionId');

      print('🔍 API: Raw response: $data');

      if (data is List) {
        print('🔍 API: Response is List with ${data.length} items');

        // ✅ NEW: Handle individual messages with Author field
        final List<ChatHistoryItem> pairs = [];
        String? pendingQuestion;

        for (int i = 0; i < data.length; i++) {
          final msg = data[i];
          final author = msg['Author']?.toString().toLowerCase() ?? '';
          final content = msg['Content']?.toString() ?? msg['Message']?.toString() ?? '';

          print('🔍 Processing message $i: Author=$author, Content=${content.substring(0, min(50, content.length))}...');

          if (author == 'user') {
            pendingQuestion = content;
          } else if (author.contains('bot') || author.contains('vitty') || author.contains('system')) {
            if (pendingQuestion != null) {
              pairs.add(ChatHistoryItem(
                question: pendingQuestion,
                answer: content,
              ));
              pendingQuestion = null;
            } else {
              // Bot message without user question - skip or handle as needed
              print('⚠️ Bot message without user question, skipping');
            }
          }
        }

        print('🔍 API: Successfully created ${pairs.length} message pairs');
        return pairs;
      } else {
        print('❌ API: Expected List but got ${data.runtimeType}');
        return [];
      }
    } catch (e) {
      print('❌ API: Error fetching messages: $e');
      rethrow;
    }
  }

  Future<ChatSession> createSession(String title) async {
    final data = await _apiService.post(
      endpoint: '/chat/createSession',
      body: {'title': title},
    );

    final id = (data['_id'] ?? data['session_id'] ?? data['id'])?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Server did not return a session id');
    }

    final serverTitle = data['title'];
    final safeTitle = (serverTitle is String && serverTitle.isNotEmpty)
        ? serverTitle
        : title; // fallback to the one you passed

    final createdAtStr = data['created_at']?.toString();
    final createdAt = DateTime.tryParse(createdAtStr ?? '') ?? DateTime.now();

    return ChatSession(
      id: id,
      title: safeTitle,              // avoid null title
      createdAt: createdAt,
      messages: const [],
    );
  }



  // OLD Code??
  // Future<ChatSession> createSession(String title) async {
  //   final data = await _apiService.post(
  //     endpoint: '/chat/createSession',
  //     body: {'title': title},
  //   );
  //   return ChatSession.fromJson(data);
  // }


  // Future<List<ChatSession>> fetchSessions() async {
  //   final data = await _apiService.get(endpoint: '/chat/sessions');
  //   return (data as List).map((json) => ChatSession.fromJson(json)).toList();
  // }


  Future<List<ChatSession>> fetchSessions() async {
    final data = await _apiService.get(endpoint: '/chat/sessions');
    final List list = (data is Map && data['sessions'] is List) ? data['sessions'] : (data as List? ?? []);

    // Parse sessions from JSON
    final sessions = list.map((json) => ChatSession.fromJson(json as Map<String, dynamic>)).toList();

    // ✅ FIXED: Sort by created_at in descending order (newest first)
    sessions.sort((a, b) {
      final dateA = a.createdAt;
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Newest first
    });

    return sessions;
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
  //       // Don't add currentStatus here, add it only when needed
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
  //     _currentStreamingId = '';
  //     int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  //     String? currentStatus; // Track current status
  //
  //     _streamSubscription = responseStream.listen((message) {
  //       if (_currentStreamingId.isEmpty) {
  //         _currentStreamingId = message.id;
  //       }
  //
  //       // Track status updates from streaming
  //       String? newStatus = currentStatus; // Keep current status by default
  //       bool shouldUpdateMessage = false;
  //
  //       if (message.currentStatus != null) {
  //         newStatus = message.currentStatus;
  //         shouldUpdateMessage = true; // Always update when status changes
  //         print("📊 Status update: $newStatus");
  //       } else if (message.text.isNotEmpty && currentStatus != null) {
  //         // Clear status when text starts coming
  //         newStatus = null;
  //         shouldUpdateMessage = true; // Update to clear status
  //         print("🔄 Clearing status, text started: '${message.text}'");
  //       }
  //
  //       currentStatus = newStatus; // Update the tracked status
  //
  //       final currentTime = DateTime.now().millisecondsSinceEpoch;
  //       final timeSinceLastUpdate = currentTime - lastUpdateTime;
  //
  //       // Update message if: time threshold passed, message complete, or status changed
  //       if (timeSinceLastUpdate > 150 || message.isComplete || shouldUpdateMessage) {
  //         final updated = [..._messagesSubject.value];
  //         final lastIndex = updated.length - 1;
  //         if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //           // Create base message map
  //           Map<String, Object> messageMap = {
  //             'id': botMessageId,
  //             'role': 'bot',
  //             'msg': message.text,
  //             'isComplete': message.isComplete,
  //           };
  //
  //           // Only add currentStatus if it's not null
  //           if (newStatus != null) {
  //             messageMap['currentStatus'] = newStatus;
  //             print("💬 Adding status to message: '$newStatus'");
  //           } else {
  //             print("💬 No status in message, text: '${message.text}'");
  //           }
  //
  //           updated[lastIndex] = messageMap;
  //           _messagesSubject.add(updated);
  //           print("📤 Message updated - status: '$newStatus', text: '${message.text.length > 20 ? message.text.substring(0, 20) + '...' : message.text}'");
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
  //             'msg': message.text,
  //             'isComplete': true,
  //             // Don't add currentStatus when complete
  //           };
  //           _messagesSubject.add(updated);
  //         }
  //
  //         _isTypingSubject.add(false);
  //         _checkAndNotifyFirstMessageComplete();
  //
  //         // Check for stock data in the complete message
  //         if (message.text.contains('"stocks":')) {
  //           try {
  //             final cleaned = message.text.replaceAll("```json", "").replaceAll("```", "").trim();
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
  //
  //         // Check for JSON payloads in ChatMessage
  //         if (message.jsonPayloads.isNotEmpty) {
  //           for (var payload in message.jsonPayloads) {
  //             if (payload['type'] == 'list_of_assets') {
  //               final updated = [..._messagesSubject.value];
  //               final lastIndex = updated.length - 1;
  //               if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //                 updated[lastIndex] = {
  //                   ...updated[lastIndex],
  //                   'type': 'assets',
  //                   'assets': payload['list'],
  //                 };
  //                 _messagesSubject.add(updated);
  //               }
  //             } else if (payload['type'] == 'stocks') {
  //               final updated = [..._messagesSubject.value];
  //               updated.removeLast();
  //               updated.add({
  //                 'id': UniqueKey().toString(),
  //                 'role': 'bot',
  //                 'msg': '',
  //                 'type': 'stocks',
  //                 'stocks': payload['list'],
  //               });
  //               _messagesSubject.add(updated);
  //             }
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




// ========================= sendMessage =========================

  void markUiRenderCompleteForLatest() {
    // hide stop button
    _isTypingSubject.add(false);

    // mark latest bot message as complete (UI complete, not backend)
    final updated = [..._messagesSubject.value];
    final last = updated.length - 1;
    if (last >= 0 && updated[last]['role'] == 'bot') {
      updated[last] = {
        ...updated[last],
        'isComplete': true,
      };
      _messagesSubject.add(updated);
    }

    _checkAndNotifyFirstMessageComplete();
  }

  // Future<void> sendMessage(String? sessionId, String text) async {
  //   // 🔐 ensure we have a real session id (creates one if needed)
  //   final effectiveSessionId = await _ensureActiveSessionId(sessionId);
  //
  //   final userMessage = sanitizeMessage(text);
  //   final isFirstMessage = !messages.any((m) => m['role'] == 'user');
  //   final userMessageId = UniqueKey().toString();
  //   final botMessageId = UniqueKey().toString();
  //
  //   _isTypingSubject.add(true);
  //
  //   _messagesSubject.add([
  //     ...messages,
  //     {
  //       'id': userMessageId,
  //       'role': 'user',
  //       'content': userMessage,
  //       'isComplete': true,
  //     },
  //     {
  //       'id': botMessageId,
  //       'role': 'bot',
  //       'content': '',
  //       'isComplete': false,
  //     }
  //   ]);
  //
  //   try {
  //     if (isFirstMessage) {
  //       await updateSessionTitle(effectiveSessionId, userMessage);
  //     }
  //
  //     final responseStream = await sendMessageWithStreaming(
  //       sessionId: effectiveSessionId,
  //       message: userMessage,
  //     );
  //
  //     _currentStreamingId = '';
  //
  //     _streamSubscription = responseStream.listen((chatMessage) {
  //       if (_currentStreamingId.isEmpty) {
  //         _currentStreamingId = chatMessage.id;
  //       }
  //
  //       final updated = [..._messagesSubject.value];
  //       final lastIndex = updated.length - 1;
  //
  //       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //         final prev = Map<String, Object>.from(updated[lastIndex]);
  //
  //         final Map<String, Object> messageData = <String, Object>{
  //           ...prev,
  //           'id': botMessageId,
  //           'role': 'bot',
  //           'content': chatMessage.text,
  //           'isComplete': (prev['isComplete'] as bool?) ?? false,
  //           'backendComplete': chatMessage.isComplete,
  //           'currentStatus': chatMessage.currentStatus ?? '',
  //         };
  //
  //         // ✅ Preserve table data + render type
  //         if (chatMessage.isTable && chatMessage.structuredData != null) {
  //           final sd = Map<String, dynamic>.from(chatMessage.structuredData!);
  //
  //           final heading = sd['heading']?.toString() ?? 'Results';
  //           final rows = (sd['rows'] as List?)
  //               ?.whereType<Map>()
  //               .map((e) => Map<String, dynamic>.from(e))
  //               .toList() ??
  //               const <Map<String, dynamic>>[];
  //
  //           // Prefer sd['type']; fall back to chatMessage.messageType; finally 'cards'
  //           final renderType = ((sd['type'] ?? chatMessage.messageType) as String?)
  //               ?.toLowerCase()
  //               ?.trim() ??
  //               'cards';
  //
  //           messageData['type'] = 'kv_table';
  //           messageData['tableData'] = <String, Object>{
  //             'heading': heading,
  //             'rows': rows,
  //             'type': renderType, // 🔴 CRITICAL: keep the render type
  //             'columnOrder': (prev['tableData'] is Map &&
  //                 (prev['tableData'] as Map)['columnOrder'] is List)
  //                 ? List<String>.from((prev['tableData'] as Map)['columnOrder'])
  //                 : const <String>[],
  //           };
  //         } else if (prev.containsKey('tableData') && prev['tableData'] != null) {
  //           // keep whatever we had (including its 'type')
  //           messageData['tableData'] = prev['tableData']!;
  //         }
  //
  //         // Preserve previous message-level type if we didn't set one this tick
  //         if (prev.containsKey('type') &&
  //             !messageData.containsKey('type') &&
  //             prev['type'] != null) {
  //           messageData['type'] = prev['type']!;
  //         }
  //
  //         // mark front-end completion if backend finished
  //         if (chatMessage.isComplete) {
  //           messageData['isComplete'] = true;
  //         }
  //
  //         updated[lastIndex] = messageData;
  //         _messagesSubject.add(updated);
  //       }
  //     }, onError: (e) {
  //       debugPrint("❌ CHAT SERVICE ERROR: $e");
  //       _isTypingSubject.add(false);
  //
  //       final updated = [..._messagesSubject.value];
  //       final lastIndex = updated.length - 1;
  //       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //         updated[lastIndex] = {
  //           'id': botMessageId,
  //           'role': 'bot',
  //           'content': '❌ Failed to respond.',
  //           'isComplete': true,
  //           'retry': true,
  //           'originalMessage': userMessage,
  //         };
  //         _messagesSubject.add(updated);
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("❌ SEND MESSAGE ERROR: $e");
  //     _isTypingSubject.add(false);
  //
  //     final updated = [..._messagesSubject.value];
  //     final lastIndex = updated.length - 1;
  //     if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //       updated[lastIndex] = {
  //         'id': botMessageId,
  //         'role': 'bot',
  //         'content': '❌ Failed to send.',
  //         'isComplete': true,
  //         'retry': true,
  //         'originalMessage': userMessage,
  //       };
  //       _messagesSubject.add(updated);
  //     }
  //   }
  // }


  // Add these methods to your ChatService class

  Future<void> sendMessage(String? sessionId, String text) async {
    final uid = SessionManager.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No UID. Log in first.');
    }

    final userMessage = sanitizeMessage(text);
    final isFirstMessage = !messages.any((m) => m['role'] == 'user');
    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    _isTypingSubject.add(true);

    // Add user message + empty bot bubble (NO "Connecting..." here)
    _messagesSubject.add([
      ...messages,
      {
        'id': userMessageId,
        'role': 'user',
        'content': userMessage,
        'isComplete': true,
      },
      {
        'id': botMessageId,
        'role': 'bot',
        'content': '',
        'isComplete': false,
        // no currentStatus => UI shows typing dots until SSE arrives
      }
    ]);

    try {
      final responseStream = await sendMessageWithStreamingRespond(
        uid: uid,
        debugLog: true,
        sessionId: _currentSession?.id,
        message: userMessage,
        firstMessageForTitle: isFirstMessage ? userMessage : null,
      );

      _currentStreamingId = '';

      _streamSubscription = responseStream.listen((chatMessage) {
        if (_currentStreamingId.isEmpty) _currentStreamingId = chatMessage.id;

        final updated = [..._messagesSubject.value];
        final lastIndex = updated.length - 1;

        if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
          final prev = Map<String, Object>.from(updated[lastIndex]);

          final Map<String, Object> messageData = <String, Object>{
            'id': botMessageId,
            'role': 'bot',
            'content': chatMessage.text,
            'isComplete': false,                 // keep animating
            'backendComplete': chatMessage.isComplete,
            // only set status if backend sends a real status_update
            if ((chatMessage.currentStatus ?? '').isNotEmpty &&
                chatMessage.currentStatus != 'null')
              'currentStatus': chatMessage.currentStatus!,
          };

          // table handling (unchanged) …
          if (chatMessage.isTable && chatMessage.structuredData != null) {
            messageData['type'] = 'kv_table';
            messageData['tableData'] =
            Map<String, dynamic>.from(chatMessage.structuredData!);
          } else {
            if (prev['tableData'] != null) messageData['tableData'] = prev['tableData']!;
            if (prev['type'] != null) messageData['type'] = prev['type']!;
          }

          updated[lastIndex] = messageData;
          _messagesSubject.add(updated);
        }
      }, onError: (e) {
        debugPrint("❌ CHAT SERVICE STREAM ERROR: $e");
        _handleConnectionError(botMessageId, userMessage, e);
      });
    } catch (e) {
      debugPrint("SEND MESSAGE SETUP ERROR: $e");
      _handleConnectionError(botMessageId, userMessage, e);
    }
  }


// NEW: Graceful error handling method
  void _handleConnectionError(String botMessageId, String userMessage, dynamic error) {
    _isTypingSubject.add(false);

    final updated = [..._messagesSubject.value];
    final lastIndex = updated.length - 1;

    if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
      updated[lastIndex] = {
        'id': botMessageId,
        'role': 'bot',
        'content': '',                               // keep bubble empty
        'isComplete': false,
        'currentStatus': 'Connection failed. Retrying...', // visible only on error
        'isConnecting': true,
      };
      _messagesSubject.add(updated);
    }

    // After 3s show retry UI
    Timer(const Duration(seconds: 3), () {
      if (_messagesSubject.isClosed) return;
      final msgs = [..._messagesSubject.value];
      final i = msgs.length - 1;

      if (i >= 0 && msgs[i]['role'] == 'bot' && msgs[i]['id'] == botMessageId) {
        msgs[i] = {
          'id': botMessageId,
          'role': 'bot',
          'content':
          "I'm having trouble connecting right now. Please check your internet connection and try again.",
          'isComplete': true,
          'retry': true,
          'originalMessage': userMessage,
          'errorType': 'connection_failed',
          'currentStatus': '', // clear status
        };
        _messagesSubject.add(msgs);
      }
    });
  }

// NEW: Method to retry a failed message
// Updated retryMessage method for ChatService class
  Future<void> retryMessage(String originalMessage) async {
    debugPrint("🔄 Retrying message: $originalMessage");
    final uid = SessionManager.uid;
    if (uid == null || uid.isEmpty) throw StateError('No UID. Log in first.');

    final updated = [..._messagesSubject.value];

    // remove last retry bot bubble
    for (int i = updated.length - 1; i >= 0; i--) {
      if (updated[i]['role'] == 'bot' && updated[i]['retry'] == true) {
        updated.removeAt(i);
        break;
      }
    }
    _messagesSubject.add(updated);

    final botMessageId = UniqueKey().toString();
    _messagesSubject.add([
      ...updated,
      {
        'id': botMessageId,
        'role': 'bot',
        'content': '',
        'isComplete': false,
        // no currentStatus here either
      }
    ]);

    _isTypingSubject.add(true);

    try {
      final effectiveSessionId = await _ensureActiveSessionId(_currentSession?.id);
      final responseStream = await sendMessageWithStreamingRespond(
        uid: uid,
        sessionId: effectiveSessionId,
        message: originalMessage,
      );

      _currentStreamingId = '';
      _streamSubscription = responseStream.listen((chatMessage) {
        if (_currentStreamingId.isEmpty) _currentStreamingId = chatMessage.id;

        final msgs = [..._messagesSubject.value];
        final lastIndex = msgs.length - 1;
        if (lastIndex >= 0 && msgs[lastIndex]['role'] == 'bot') {
          final prev = Map<String, Object>.from(msgs[lastIndex]);

          final data = <String, Object>{
            ...prev,
            'id': botMessageId,
            'role': 'bot',
            'content': chatMessage.text,
            'isComplete': (prev['isComplete'] as bool?) ?? false,
            'backendComplete': chatMessage.isComplete,
            if ((chatMessage.currentStatus ?? '').isNotEmpty)
              'currentStatus': chatMessage.currentStatus!,
          };

          if (chatMessage.isTable && chatMessage.structuredData != null) {
            final sd = chatMessage.structuredData!;
            data['type'] = 'kv_table';
            data['tableData'] = {
              'heading': sd['heading']?.toString() ?? 'Results',
              'rows': ((sd['rows'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
              'type': sd['type']?.toString() ?? 'cards',
              'columnOrder': <String>[],
            };
          }

          msgs[lastIndex] = data;
          _messagesSubject.add(msgs);
        }
      }, onError: (e) {
        debugPrint("❌ RETRY STREAM ERROR: $e");
        _handleConnectionError(botMessageId, originalMessage, e);
      });

    } catch (e) {
      debugPrint("❌ RETRY SETUP ERROR: $e");
      _handleConnectionError(botMessageId, originalMessage, e);
    }
  }

// Updated stopResponse method with better error handling
  Future<void> stopResponse(String sessionId) async {
    // Ask server to cancel the live stream first
    if (_currentStreamingId.isNotEmpty) {
      try {
        await _apiService.post(endpoint: '/chat/message/stop', body: {
          'session_id': sessionId,
          'message_id': _currentStreamingId,
        });
      } catch (e) {
        debugPrint('Stop (server) failed: $e');
      }
    }

    // Cancel local SSE subscription
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentStreamingId = '';

    // Freeze the last bot message at current progress
    final updated = [..._messagesSubject.value];
    final lastIndex = updated.length - 1;
    if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
      updated[lastIndex] = {
        ...updated[lastIndex],
        'currentStatus': '',
        'forceStop': true,
        'stopTs': DateTime.now().toIso8601String(),
      };
      _messagesSubject.add(updated);
    }

    // Hide stop button
    _isTypingSubject.add(false);
  }

  // Future<void> stopResponse(String sessionId) async {
  //   // 1) Ask server to cancel the live stream first
  //   if (_currentStreamingId.isNotEmpty) {
  //     try {
  //       await _apiService.post(endpoint: '/chat/message/stop', body: {
  //         'session_id': sessionId,
  //         'message_id': _currentStreamingId, // server ignores if not used
  //       });
  //     } catch (e) {
  //       debugPrint('❌ Stop (server) failed: $e'); // fine, we'll still freeze UI
  //     }
  //   }
  //
  //   // 2) Now cancel local SSE subscription
  //   _streamSubscription?.cancel();
  //   _streamSubscription = null;
  //   _currentStreamingId = '';
  //
  //   // 3) Freeze the last bot message at current progress (no isComplete=true)
  //   final updated = [..._messagesSubject.value];
  //   final lastIndex = updated.length - 1;
  //   if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //     updated[lastIndex] = {
  //       ...updated[lastIndex],
  //       'currentStatus': '',
  //       'forceStop': true,                     // BotMessageWidget will finish animation
  //       'stopTs': DateTime.now().toIso8601String(),
  //     };
  //     _messagesSubject.add(updated);
  //   }
  //
  //   // 4) Hide stop button (typing false). Do NOT call _checkAndNotifyFirstMessageComplete() here.
  //   _isTypingSubject.add(false);
  // }
  //
  //
  // Future<void> sendMessage(String? sessionId, String text) async {
  //   // 🔐 ensure we have a real session id (creates one if needed)
  //   final effectiveSessionId = await _ensureActiveSessionId(sessionId);
  //
  //   final userMessage = sanitizeMessage(text);
  //   final isFirstMessage = !messages.any((m) => m['role'] == 'user');
  //   final userMessageId = UniqueKey().toString();
  //   final botMessageId = UniqueKey().toString();
  //
  //   _isTypingSubject.add(true);
  //
  //   _messagesSubject.add([
  //     ...messages,
  //     {
  //       'id': userMessageId,
  //       'role': 'user',
  //       'content': userMessage,
  //       'isComplete': true,
  //     },
  //     {
  //       'id': botMessageId,
  //       'role': 'bot',
  //       'content': '',
  //       'isComplete': false,
  //     }
  //   ]);
  //
  //   try {
  //     if (isFirstMessage) {
  //       await updateSessionTitle(effectiveSessionId, userMessage);
  //     }
  //
  //     final responseStream = await sendMessageWithStreaming(
  //       sessionId: effectiveSessionId,
  //       message: userMessage,
  //     );
  //
  //     _currentStreamingId = '';
  //
  //     _streamSubscription = responseStream.listen((chatMessage) {
  //       if (_currentStreamingId.isEmpty) {
  //         _currentStreamingId = chatMessage.id;
  //       }
  //
  //       final updated = [..._messagesSubject.value];
  //       final lastIndex = updated.length - 1;
  //
  //       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //         final prev = Map<String, Object>.from(updated[lastIndex]);
  //
  //         Map<String, Object> messageData = <String, Object>{
  //           ...prev,
  //           'id': botMessageId,
  //           'role': 'bot',
  //           'content': chatMessage.text,
  //           'isComplete': (prev['isComplete'] as bool?) ?? false,
  //           'backendComplete': chatMessage.isComplete,
  //           'currentStatus': chatMessage.currentStatus ?? '',
  //         };
  //
  //         // ✅ FIXED: Handle table data with type preservation
  //         if (chatMessage.isTable && chatMessage.structuredData != null) {
  //           final sd = chatMessage.structuredData!;
  //           final heading = sd['heading']?.toString() ?? 'Results';
  //           final type = sd['type']?.toString() ?? 'cards'; // ✅ PRESERVE TYPE
  //           final rows = (sd['rows'] as List?)
  //               ?.whereType<Map>()
  //               .map((e) => Map<String, dynamic>.from(e))
  //               .toList() ??
  //               <Map<String, dynamic>>[];
  //
  //           messageData['type'] = 'kv_table';
  //           messageData['tableData'] = <String, Object>{
  //             'heading': heading,
  //             'rows': rows,
  //             'type': type, // ✅ CRITICAL: Pass the type through
  //             'columnOrder': (prev['tableData'] is Map &&
  //                 (prev['tableData'] as Map)['columnOrder'] is List)
  //                 ? List<String>.from((prev['tableData'] as Map)['columnOrder'])
  //                 : <String>[],
  //           };
  //         } else if (prev.containsKey('tableData') && prev['tableData'] != null) {
  //           // ✅ FIXED: Preserve existing tableData including type
  //           final existingTableData = prev['tableData'] as Map;
  //           messageData['tableData'] = Map<String, Object>.from(existingTableData);
  //         }
  //
  //         // ✅ FIXED: Preserve existing type if no new type is set
  //         if (prev.containsKey('type') &&
  //             !messageData.containsKey('type') &&
  //             prev['type'] != null) {
  //           messageData['type'] = prev['type']!;
  //         }
  //
  //         updated[lastIndex] = messageData;
  //         _messagesSubject.add(updated);
  //       }
  //     }, onError: (e) {
  //       debugPrint("❌ CHAT SERVICE ERROR: $e");
  //       _isTypingSubject.add(false);
  //
  //       final updated = [..._messagesSubject.value];
  //       final lastIndex = updated.length - 1;
  //       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //         updated[lastIndex] = {
  //           'id': botMessageId,
  //           'role': 'bot',
  //           'content': '❌ Failed to respond.',
  //           'isComplete': true,
  //           'retry': true,
  //           'originalMessage': userMessage,
  //         };
  //         _messagesSubject.add(updated);
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("❌ SEND MESSAGE ERROR: $e");
  //     _isTypingSubject.add(false);
  //
  //     final updated = [..._messagesSubject.value];
  //     final lastIndex = updated.length - 1;
  //     if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
  //       updated[lastIndex] = {
  //         'id': botMessageId,
  //         'role': 'bot',
  //         'content': '❌ Failed to send.',
  //         'isComplete': true,
  //         'retry': true,
  //         'originalMessage': userMessage,
  //       };
  //       _messagesSubject.add(updated);
  //     }
  //   }
  // }








  // Add this updated sendMessageWithStreaming method to your ChatService











  Future<Stream<ChatMessage>> sendMessageWithStreamingRespond({
    required String uid,
    String? sessionId,
    required String message,
    String? firstMessageForTitle,
    bool debugLog = false,
  }) async {
    await SessionManager.checkTokenValidityAndRefresh();

    final stats = _StreamDebugStats();
    if (debugLog) {
      final preview = message.length > 120 ? '${message.substring(0, 120)}…' : message;
      print('START STREAM - /chat/respond');
      print('uid: $uid');
      print('sessionId: ${sessionId ?? "<null - will be created by server>"}');
      print('user message: "$preview"');
    }

    try {
     final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
      //final String _baseUrl = "http://localhost:8000";
      //final String _baseUrl = 'http://192.168.1.5:8000';
      final url = Uri.parse('$_baseUrl/chat/respond');

      final req = http.Request('POST', url);
      req.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
        if (SessionManager.refreshToken != null) 'X-Refresh-Token': SessionManager.refreshToken!,
      });

      final body = <String, dynamic>{
        'uid': uid,
        'input': utf8.decode(message.codeUnits),
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      };
      req.body = jsonEncode(body);

      if (debugLog) {
        print('POST $_baseUrl/chat/respond');
        print('headers: ${req.headers}');
        print('body: ${req.body}');
      }

      final streamedResponse = await req.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout after 30 seconds'),
      );

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final errorBody = await streamedResponse.stream.bytesToString();
        if (debugLog) {
          print('Non-2xx status: ${streamedResponse.statusCode}');
          print('Body: $errorBody');
        }
        throw Exception("Streaming failed: $errorBody");
      }

      final controller = StreamController<ChatMessage>();
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      var currentMessage = ChatMessage(
        id: messageId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isComplete: false,
      );

      String buffer = '';
      String textBeforeTable = '';
      String textAfterTable = '';
      bool tableReceived = false;

      List<Map<String, dynamic>> allTableRows = [];
      String combinedHeading = 'Results';
      Map<String, dynamic>? tableData;

      Timer? inactivityTimer;
      void resetInactivityTimer() {
        inactivityTimer?.cancel();
        inactivityTimer = Timer(const Duration(seconds: 60), () {
          if (debugLog) print('Inactivity timeout (60s) - closing stream');
          controller.addError(TimeoutException('Stream inactive timeout', const Duration(seconds: 60)));
          controller.close();
        });
      }
      resetInactivityTimer();

      streamedResponse.stream.transform(utf8.decoder).listen(
            (chunk) {
          stats.onRawChunk(chunk);
          if (debugLog) print('CHUNK bytes=${chunk.length}');

          resetInactivityTimer();
          buffer += chunk;

          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final raw in lines) {
            stats.onLine(raw);
            final line = raw.trim();

            if (line.isEmpty) {
              if (debugLog) print('(empty line)');
              continue;
            }
            if (!line.startsWith('data:')) {
              if (debugLog) print('(non-data line) "$line"');
              continue;
            }

            final jsonText = line.substring(5).trim();
            if (debugLog) {
              print('\n' + '=' * 80);
              print('SSE DATA LINE (#${stats.dataLines})');
              print('raw: $jsonText');
            }
            if (jsonText.isEmpty) {
              if (debugLog) print('empty data payload');
              continue;
            }

            Map<String, dynamic> decoded;
            try {
              decoded = jsonDecode(jsonText) as Map<String, dynamic>;
            } catch (e) {
              stats.badJsonLines++;
              if (debugLog) print('JSON parse error: $e');
              continue;
            }

            final type = (decoded['type'] ?? '').toString();
            final payload = decoded['payload'] as Map<String, dynamic>? ?? const {};
            final payloadType = (payload['type'] ?? '').toString();

            stats.onParsedEvent(type: type, payloadType: payloadType);
            stats.markFirstChunkIfNeeded();

            if (debugLog) {
              print('event.type: "$type"');
              if (payload.isNotEmpty) print('payload.type: "$payloadType"');
            }

            // 1) Handle session_created
            if (type == 'session_created') {
              stats.sessionCreated++;
              final sid = decoded['session_id']?.toString();
              if (debugLog) print('session_created: session_id=$sid');
              if (sid != null && sid.isNotEmpty) {
                _adoptServerSession(sid);
                if (firstMessageForTitle != null && firstMessageForTitle.trim().isNotEmpty) {
                  updateSessionTitle(sid, firstMessageForTitle);
                }
              }
              continue;
            }

            // 2) Handle status_update
            if (type == 'status_update') {
              stats.statusUpdates++;
              final reason = (payload['reason'] ?? '').toString();
              if (debugLog) print('status_update: "$reason"');

              String displayText = textBeforeTable;
              if (tableReceived) {
                displayText += '___TABLE_PLACEHOLDER___';
                displayText += textAfterTable;
              }

              currentMessage = ChatMessage(
                id: messageId,
                text: displayText,
                isUser: false,
                timestamp: currentMessage.timestamp,
                isComplete: false,
                currentStatus: reason,
                isTable: tableReceived,
                structuredData: tableData,
                messageType: tableReceived ? 'kv_table' : null,
              );
              controller.add(currentMessage);
              continue;
            }

            // 3) Handle response events
            if (type == 'response') {
              if (payloadType == 'text') {
                stats.responseTextChunks++;
                final data = (payload['data'] ?? '').toString();
                final prevLenBefore = textBeforeTable.length;
                final prevLenAfter = textAfterTable.length;

                if (tableReceived) {
                  textAfterTable += data;
                  stats.textAfterChars += (textAfterTable.length - prevLenAfter);
                } else {
                  textBeforeTable += data;
                  stats.textBeforeChars += (textBeforeTable.length - prevLenBefore);
                }

                if (debugLog) {
                  final where = tableReceived ? 'AFTER_TABLE' : 'BEFORE_TABLE';
                  final preview = data.length > 140 ? '${data.substring(0, 140)}…' : data;
                  print('response:text [$where] +${data.length} chars');
                  print('   preview: "$preview"');
                  print('   totals so far - before:${stats.textBeforeChars}, after:${stats.textAfterChars}');
                }

                String displayText = textBeforeTable;
                if (tableReceived) {
                  displayText += '___TABLE_PLACEHOLDER___';
                  displayText += textAfterTable;
                }

                currentMessage = ChatMessage(
                  id: messageId,
                  text: displayText,
                  isUser: false,
                  timestamp: currentMessage.timestamp,
                  isComplete: false,
                  currentStatus: null, // Clear status when text arrives
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableReceived ? 'kv_table' : null,
                );
                controller.add(currentMessage);
                continue;
              }

              if (payloadType == 'json') {
                stats.responseJsonChunks++;
                final jsonData = payload['data'];
                if (debugLog) {
                  final pretty = const JsonEncoder.withIndent('  ').convert(jsonData);
                  print('response:json payload:\n$pretty');
                }

                if (jsonData is Map && (jsonData['type'] == 'cards_of_market' ||
                    jsonData['type'] == 'cards_of_asset'  ||
                    jsonData['type'] == 'table_of_asset'||
                    jsonData['type'] == 'table_of_market')) {

                  final heading = (jsonData['heading']?.toString() ?? 'Results');
                  final dataList = (jsonData['list'] as List?) ?? const [];
                  final rows = dataList.map<Map<String, dynamic>>((e) =>
                  (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}
                  ).toList();

                  if (!tableReceived) {
                    tableReceived = true;
                    combinedHeading = heading;
                  }
                  allTableRows.addAll(rows);
                  stats.jsonRowsAccumulated = allTableRows.length;

                  tableData = {
                    'heading': combinedHeading,
                    'rows': allTableRows,
                    'type': jsonData['type'].toString(),
                  };

                  if (debugLog) {
                    print('table/cards chunk - heading="$combinedHeading", added=${rows.length}, totalRows=${allTableRows.length}, type=${jsonData['type']}');
                    if (rows.isNotEmpty) {
                      final sample = rows.first;
                      print('   sample row keys: ${sample.keys.toList()}');
                    }
                  }

                  final displayText = textBeforeTable + '___TABLE_PLACEHOLDER___' + textAfterTable;

                  currentMessage = ChatMessage(
                    id: messageId,
                    text: displayText,
                    isUser: false,
                    timestamp: currentMessage.timestamp,
                    isComplete: false,
                    currentStatus: null, // Clear status when table arrives
                    isTable: true,
                    structuredData: tableData,
                    messageType: 'kv_table',
                  );
                  controller.add(currentMessage);
                }
                continue;
              }

              if (payloadType == 'complete') {
                stats.responseCompletes++;
                if (debugLog) print('response:complete');

                String displayText = textBeforeTable;
                if (tableReceived) {
                  displayText += '___TABLE_PLACEHOLDER___';
                  displayText += textAfterTable;
                }

                currentMessage = ChatMessage(
                  id: currentMessage.id,
                  text: displayText,
                  isUser: currentMessage.isUser,
                  timestamp: currentMessage.timestamp,
                  isComplete: true,
                  currentStatus: null,
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableReceived ? 'kv_table' : null,
                );
                controller.add(currentMessage);
                continue;
              }
            }

            if (debugLog) {
              print('Unhandled event. type="$type" payload.type="$payloadType"');
            }
          }
        },
        onDone: () {
          resetInactivityTimer();
          inactivityTimer?.cancel();

          String finalText = textBeforeTable;
          if (tableReceived) {
            finalText += '___TABLE_PLACEHOLDER___';
            finalText += textAfterTable;
          }

          controller.add(ChatMessage(
            id: currentMessage.id,
            text: finalText,
            isUser: false,
            timestamp: currentMessage.timestamp,
            isComplete: true,
            currentStatus: null,
            isTable: tableReceived,
            structuredData: tableData,
            messageType: tableReceived ? 'kv_table' : null,
          ));
          controller.close();

          stats.printSummary(debugLog: debugLog);
        },
        onError: (e) {
          inactivityTimer?.cancel();
          if (debugLog) print('STREAM ERROR: $e');
          stats.printSummary(debugLog: debugLog);
          controller.addError(e);
          controller.close();
        },
      );

      return controller.stream;
    } catch (e) {
      if (debugLog) print('sendMessageWithStreamingRespond setup error: $e');
      rethrow;
    }
  }








  // Future<Stream<ChatMessage>> sendMessageWithStreaming({
  //   required String sessionId,
  //   required String message,
  // }) async {
  //   await SessionManager.checkTokenValidityAndRefresh();
  //
  //   try {
  //     final url = Uri.parse('https://fastapi-app-130321581049.asia-south1.run.app/chat/respond');
  //    // final url = Uri.parse('http://localhost:8000/chat/respond');
  //     //final url = Uri.parse('http://192.168.1.2:8000/chat/respond');
  //     final request = http.Request('POST', url);
  //
  //     request.headers.addAll({
  //       'Content-Type': 'application/json',
  //       'Accept': 'text/event-stream',
  //       if (SessionManager.token != null)
  //         'Authorization': 'Bearer ${SessionManager.token}',
  //     });
  //
  //     request.body = jsonEncode({
  //       'session_id': sessionId,
  //       'input': utf8.decode(message.codeUnits),
  //     });
  //
  //     final streamedResponse = await request.send();
  //
  //     if (streamedResponse.statusCode != 200) {
  //       final errorBody = await streamedResponse.stream.bytesToString();
  //       throw Exception("Streaming failed: $errorBody");
  //     }
  //
  //     final controller = StreamController<ChatMessage>();
  //     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
  //
  //     var currentMessage = ChatMessage(
  //       id: messageId,
  //       text: '',
  //       isUser: false,
  //       timestamp: DateTime.now(),
  //       isComplete: false,
  //       currentStatus: null,
  //     );
  //
  //     String buffer = '';
  //     String textBeforeTable = '';
  //     String textAfterTable = '';
  //     bool tableReceived = false;
  //
  //     List<Map<String, dynamic>> allTableRows = [];
  //     String combinedHeading = 'Performance Comparison';
  //     Map<String, dynamic>? tableData;
  //
  //     List<Map<String, dynamic>> allChunks = [];
  //     int chunkCounter = 0;
  //
  //     streamedResponse.stream.transform(utf8.decoder).listen(
  //           (chunk) {
  //         buffer += chunk;
  //         final lines = buffer.split('\n');
  //         buffer = lines.removeLast();
  //
  //         for (var raw in lines) {
  //           var line = raw.trim();
  //           if (line.isEmpty) continue;
  //
  //           if (!line.startsWith('data:')) continue;
  //
  //           final jsonText = line.substring(5).trim();
  //           if (jsonText.isEmpty) continue;
  //
  //           try {
  //             final decoded = jsonDecode(jsonText);
  //             allChunks.add(Map<String, dynamic>.from(decoded));
  //             chunkCounter++;
  //
  //             print("\n" + "="*80);
  //             print("📦 CHUNK #$chunkCounter");
  //             print("🔍 Raw JSON: $jsonText");
  //             print("📋 Parsed: ${JsonEncoder.withIndent('  ').convert(decoded)}");
  //             print("🏷️  Type: ${decoded['type']}");
  //             if (decoded['payload'] != null) {
  //               print("📄 Payload Type: ${decoded['payload']['type']}");
  //               if (decoded['payload']['data'] != null) {
  //                 final data = decoded['payload']['data'];
  //                 if (data is String) {
  //                   print("📝 Data (String): '$data'");
  //                 } else {
  //                   print("📊 Data (Object): ${JsonEncoder.withIndent('  ').convert(data)}");
  //                 }
  //               }
  //             }
  //             print("="*80 + "\n");
  //
  //             final type = decoded['type'];
  //
  //             // Handle status updates
  //             if (type == 'status_update') {
  //               final reason = (decoded['payload']?['reason'] ?? '').toString();
  //               print("🟡 STATUS UPDATE: $reason");
  //
  //               String displayText = textBeforeTable;
  //               if (tableReceived) {
  //                 displayText += '___TABLE_PLACEHOLDER___';
  //                 displayText += textAfterTable;
  //               }
  //
  //               currentMessage = ChatMessage(
  //                 id: messageId,
  //                 text: displayText,
  //                 isUser: false,
  //                 timestamp: currentMessage.timestamp,
  //                 isComplete: false,
  //                 currentStatus: reason,
  //                 messageType: tableReceived ? 'kv_table' : null,
  //                 structuredData: tableData,
  //               );
  //               controller.add(currentMessage);
  //               continue;
  //             }
  //
  //             // Handle response chunks
  //             if (type == 'response') {
  //               final payload = decoded['payload'] as Map<String, dynamic>? ?? const {};
  //               final pType = (payload['type'] ?? '').toString();
  //
  //               // Handle text chunks
  //               if (pType == 'text') {
  //                 final data = (payload['data'] ?? '').toString();
  //                 print("📝 TEXT CHUNK: '$data' (goes to ${tableReceived ? 'AFTER' : 'BEFORE'} table)");
  //
  //                 if (tableReceived) {
  //                   textAfterTable += data;
  //                 } else {
  //                   textBeforeTable += data;
  //                 }
  //
  //                 String displayText = textBeforeTable;
  //                 if (tableReceived) {
  //                   displayText += '___TABLE_PLACEHOLDER___';
  //                   displayText += textAfterTable;
  //                 }
  //
  //                 currentMessage = ChatMessage(
  //                   id: messageId,
  //                   text: displayText,
  //                   isUser: false,
  //                   timestamp: currentMessage.timestamp,
  //                   isComplete: false,
  //                   currentStatus: null,
  //                   messageType: tableReceived ? 'kv_table' : null,
  //                   structuredData: tableData,
  //                 );
  //                 controller.add(currentMessage);
  //                 continue;
  //               }
  //
  //               // Handle table chunks - UNIFIED LOGIC
  //               if (pType == 'json') {
  //                 final jsonData = payload['data'];
  //                 print("📊 JSON CHUNK RECEIVED:");
  //                 print("   └─ Data: ${JsonEncoder.withIndent('    ').convert(jsonData)}");
  //
  //                 // Check for all supported table types
  //                 if (jsonData is Map && (jsonData['type'] == 'cards' ||
  //                     jsonData['type'] == 'card' ||
  //                     jsonData['type'] == 'tables' ||
  //                     jsonData['type'] == 'table')) {
  //
  //                   print("🎯 TABLE DETECTED! Type: ${jsonData['type']}");
  //
  //                   // UNIFIED DATA EXTRACTION - same logic for all types
  //                   List<Map<String, dynamic>> rows = [];
  //                   String heading = 'Results';
  //
  //                   // Extract data from the list regardless of type
  //                   final dataList = (jsonData['list'] as List?) ?? const [];
  //                   heading = (jsonData['heading']?.toString() ?? 'Results');
  //
  //                   rows = dataList.map<Map<String, dynamic>>((e) {
  //                     if (e is Map) return Map<String, dynamic>.from(e);
  //                     return <String, dynamic>{};
  //                   }).toList();
  //
  //                   print("📊 DATA EXTRACTED: heading='$heading', ${rows.length} items, type='${jsonData['type']}'");
  //
  //                   // Set tableReceived flag
  //                   if (!tableReceived) {
  //                     tableReceived = true;
  //                     combinedHeading = heading;
  //                     print("🏁 FIRST TABLE: Setting tableReceived=true, heading='$combinedHeading'");
  //                   }
  //
  //                   // Add rows to combined list
  //                   allTableRows.addAll(rows);
  //                   print("📈 ACCUMULATED ROWS: ${allTableRows.length} total rows (added ${rows.length} from this chunk)");
  //
  //                   // Store the original type to determine widget rendering
  //                   final originalType = jsonData['type'].toString();
  //                   tableData = {
  //                     'heading': combinedHeading,
  //                     'rows': allTableRows,
  //                     'type': originalType, // This determines which widget to use
  //                   };
  //
  //                   print("✅ Combined table data processed: ${allTableRows.length} total rows");
  //                   for (int i = 0; i < allTableRows.length && i < 3; i++) {
  //                     print("   Row $i: ${allTableRows[i]}");
  //                   }
  //                   if (allTableRows.length > 3) print("   ... and ${allTableRows.length - 3} more rows");
  //
  //                   // Send message with combined table placeholder
  //                   String displayText = textBeforeTable + '___TABLE_PLACEHOLDER___' + textAfterTable;
  //
  //                   currentMessage = ChatMessage(
  //                     id: messageId,
  //                     text: displayText,
  //                     isUser: false,
  //                     timestamp: currentMessage.timestamp,
  //                     isComplete: false,
  //                     currentStatus: null,
  //                     messageType: 'kv_table',
  //                     structuredData: tableData,
  //                   );
  //                   controller.add(currentMessage);
  //                   print("✅ Table chunk processed: heading='$combinedHeading', total_rows=${allTableRows.length}, type='$originalType'");
  //                 }
  //                 continue;
  //               }
  //
  //               // Handle completion
  //               if (pType == 'complete') {
  //                 print("🏁 COMPLETION CHUNK RECEIVED");
  //                 String displayText = textBeforeTable;
  //                 if (tableReceived) {
  //                   displayText += '___TABLE_PLACEHOLDER___';
  //                   displayText += textAfterTable;
  //                 }
  //
  //                 currentMessage = ChatMessage(
  //                   id: currentMessage.id,
  //                   text: displayText,
  //                   isUser: currentMessage.isUser,
  //                   timestamp: currentMessage.timestamp,
  //                   isComplete: true,
  //                   currentStatus: null,
  //                   messageType: tableReceived ? 'kv_table' : null,
  //                   structuredData: tableData,
  //                 );
  //                 controller.add(currentMessage);
  //                 continue;
  //               }
  //             }
  //           } catch (e) {
  //             print("❌ Error parsing chunk #$chunkCounter: $e");
  //             print("❌ Raw line: '$line'");
  //           }
  //         }
  //       },
  //       onDone: () {
  //         print("\n" + "🎉"*30);
  //         print("📊 STREAMING COMPLETE");
  //         print("💬 Message: '$message'");
  //         print("📦 Total chunks: ${allChunks.length}");
  //         print("📝 Text before table: '$textBeforeTable'");
  //         print("📝 Text after table: '$textAfterTable'");
  //         print("📋 Table received: $tableReceived");
  //         print("📊 Total combined rows: ${allTableRows.length}");
  //
  //         // Print summary of all chunk types
  //         Map<String, int> chunkTypes = {};
  //         for (var chunk in allChunks) {
  //           final type = "${chunk['type']}";
  //           final payloadType = chunk['payload']?['type'] ?? '';
  //           final key = payloadType.isEmpty ? type : "$type:$payloadType";
  //           chunkTypes[key] = (chunkTypes[key] ?? 0) + 1;
  //         }
  //         print("📊 Chunk types summary: $chunkTypes");
  //         print("🎉"*30 + "\n");
  //
  //         // Always send final complete message
  //         String finalText = textBeforeTable;
  //         if (tableReceived) {
  //           finalText += '___TABLE_PLACEHOLDER___';
  //           finalText += textAfterTable;
  //         }
  //
  //         // Create final complete message
  //         final finalMessage = ChatMessage(
  //           id: messageId,
  //           text: finalText,
  //           isUser: false,
  //           timestamp: currentMessage.timestamp,
  //           isComplete: true,
  //           currentStatus: null,
  //           messageType: tableReceived ? 'kv_table' : null,
  //           structuredData: tableData,
  //         );
  //
  //         controller.add(finalMessage);
  //         controller.close();
  //       },
  //       onError: (e) {
  //         print("❌ Stream error: $e");
  //         controller.addError(e);
  //         controller.close();
  //       },
  //     );
  //
  //     return controller.stream;
  //   } catch (e) {
  //     print("❌ sendMessageWithStreaming error: $e");
  //     rethrow;
  //   }
  // }












  // Future<Stream<ChatMessage>> sendMessageWithStreaming({
  //   required String sessionId,
  //   required String message,
  // }) async {
  //   await SessionManager.checkTokenValidityAndRefresh();
  //
  //   try {
  //  //final url = Uri.parse('https://fastapi-app-130321581049.asia-south1.run.app/chat/respond');
  //     final url = Uri.parse('http://localhost:8000/chat/respond');
  //     final request = http.Request('POST', url);
  //
  //     request.headers.addAll({
  //       'Content-Type': 'application/json',
  //       'Accept': 'text/event-stream',
  //       if (SessionManager.token != null)
  //         'Authorization': 'Bearer ${SessionManager.token}',
  //     });
  //
  //     request.body = jsonEncode({
  //       'session_id': sessionId,
  //       'input': utf8.decode(message.codeUnits),
  //     });
  //
  //     final streamedResponse = await request.send();
  //
  //     if (streamedResponse.statusCode != 200) {
  //       final errorBody = await streamedResponse.stream.bytesToString();
  //       throw Exception("Streaming failed: $errorBody");
  //     }
  //
  //     final controller = StreamController<ChatMessage>();
  //     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
  //
  //     var currentMessage = ChatMessage(
  //       id: messageId,
  //       text: '',
  //       isUser: false,
  //       timestamp: DateTime.now(),
  //       isComplete: false,
  //       currentStatus: null,
  //     );
  //
  //     String buffer = '';
  //     String textBeforeTable = '';  // ✅ Text before any tables
  //     String textAfterTable = '';   // ✅ Text after all tables
  //     bool tableReceived = false;   // ✅ Track when first table arrives
  //
  //     // ✅ FIXED: Variables for combining multiple tables
  //     List<Map<String, dynamic>> allTableRows = []; // Store all rows from all tables
  //     String combinedHeading = 'Performance Comparison'; // Combined heading
  //     Map<String, dynamic>? tableData;
  //
  //     List<Map<String, dynamic>> allChunks = [];
  //     int chunkCounter = 0;
  //
  //     streamedResponse.stream.transform(utf8.decoder).listen(
  //           (chunk) {
  //         buffer += chunk;
  //         final lines = buffer.split('\n');
  //         buffer = lines.removeLast();
  //
  //         for (var raw in lines) {
  //           var line = raw.trim();
  //           if (line.isEmpty) continue;
  //
  //           if (!line.startsWith('data:')) continue;
  //
  //           final jsonText = line.substring(5).trim();
  //           if (jsonText.isEmpty) continue;
  //
  //           try {
  //             final decoded = jsonDecode(jsonText);
  //             allChunks.add(Map<String, dynamic>.from(decoded));
  //             chunkCounter++;
  //
  //             // 🔥 PRINT EACH CHUNK AS IT ARRIVES
  //             print("\n" + "="*80);
  //             print("📦 CHUNK #$chunkCounter");
  //             print("🔍 Raw JSON: $jsonText");
  //             print("📋 Parsed: ${JsonEncoder.withIndent('  ').convert(decoded)}");
  //             print("🏷️  Type: ${decoded['type']}");
  //             if (decoded['payload'] != null) {
  //               print("📄 Payload Type: ${decoded['payload']['type']}");
  //               if (decoded['payload']['data'] != null) {
  //                 final data = decoded['payload']['data'];
  //                 if (data is String) {
  //                   print("📝 Data (String): '$data'");
  //                 } else {
  //                   print("📊 Data (Object): ${JsonEncoder.withIndent('  ').convert(data)}");
  //                 }
  //               }
  //             }
  //             print("="*80 + "\n");
  //
  //             final type = decoded['type'];
  //
  //             // ✅ Handle status updates
  //             if (type == 'status_update') {
  //               final reason = (decoded['payload']?['reason'] ?? '').toString();
  //               print("🟡 STATUS UPDATE: $reason");
  //
  //               // Build display text with marker
  //               String displayText = textBeforeTable;
  //               if (tableReceived) {
  //                 displayText += '___TABLE_PLACEHOLDER___';
  //                 displayText += textAfterTable;
  //               }
  //
  //               currentMessage = ChatMessage(
  //                 id: messageId,
  //                 text: displayText,
  //                 isUser: false,
  //                 timestamp: currentMessage.timestamp,
  //                 isComplete: false,
  //                 currentStatus: reason,
  //                 messageType: tableReceived ? 'kv_table' : null,
  //                 structuredData: tableData,
  //               );
  //               controller.add(currentMessage);
  //               continue;
  //             }
  //
  //             // ✅ Handle response chunks
  //             if (type == 'response') {
  //               final payload = decoded['payload'] as Map<String, dynamic>? ?? const {};
  //               final pType = (payload['type'] ?? '').toString();
  //
  //               // ✅ Handle text chunks - route to correct bucket
  //               if (pType == 'text') {
  //                 final data = (payload['data'] ?? '').toString();
  //                 print("📝 TEXT CHUNK: '$data' (goes to ${tableReceived ? 'AFTER' : 'BEFORE'} table)");
  //
  //                 if (tableReceived) {
  //                   textAfterTable += data;  // Add to after-table text
  //                 } else {
  //                   textBeforeTable += data; // Add to before-table text
  //                 }
  //
  //                 // Build display text with table placeholder
  //                 String displayText = textBeforeTable;
  //                 if (tableReceived) {
  //                   displayText += '___TABLE_PLACEHOLDER___';
  //                   displayText += textAfterTable;
  //                 }
  //
  //                 currentMessage = ChatMessage(
  //                   id: messageId,
  //                   text: displayText,
  //                   isUser: false,
  //                   timestamp: currentMessage.timestamp,
  //                   isComplete: false,
  //                   currentStatus: null,
  //                   messageType: tableReceived ? 'kv_table' : null,
  //                   structuredData: tableData,
  //                 );
  //                 controller.add(currentMessage);
  //                 continue;
  //               }
  //
  //               // ✅ Handle table chunks - FIXED VERSION WITH COMBINED TABLES
  //               if (pType == 'json') {
  //                 final jsonData = payload['data'];
  //                 print("📊 JSON CHUNK RECEIVED:");
  //                 print("   └─ Data: ${JsonEncoder.withIndent('    ').convert(jsonData)}");
  //
  //                 // 🔥 FIX: Check for 'table' (singular) as well as 'tables' and 'cards'
  //                 if (jsonData is Map && (jsonData['type'] == 'cards' ||
  //                     jsonData['type'] == 'card' || jsonData['type'] == 'tables' ||
  //                     jsonData['type'] == 'table')) {
  //
  //                   print("🎯 TABLE DETECTED! Type: ${jsonData['type']}");
  //
  //                   List<Map<String, dynamic>> rows = [];
  //                   String heading = 'Results';
  //
  //                   if (jsonData['type'] == 'cards' ||jsonData['type'] == 'cards' ) {
  //                     final cardsList = (jsonData['list'] as List?) ?? const [];
  //                     heading = (jsonData['heading']?.toString() ?? 'Results');
  //                     rows = cardsList.map<Map<String, dynamic>>((e) {
  //                       if (e is Map) return Map<String, dynamic>.from(e);
  //                       return <String, dynamic>{};
  //                     }).toList();
  //                     print("🎴 CARDS: heading='$heading', ${rows.length} cards");
  //                   } else if (jsonData['type'] == 'tables' || jsonData['type'] == 'table') {
  //                     heading = (jsonData['heading']?.toString() ?? 'Market Data');
  //                     final listData = jsonData['list'];
  //
  //                     List<dynamic> tableList = [];
  //                     if (listData is Map && listData.containsKey('')) {
  //                       final innerList = listData[''];
  //                       if (innerList is List) {
  //                         tableList = innerList;
  //                       }
  //                     } else if (listData is List) {
  //                       tableList = listData;
  //                     }
  //
  //                     // 🔥 ENHANCED: Better data extraction for your backend format
  //                     rows = tableList.map<Map<String, dynamic>>((item) {
  //                       if (item is Map) {
  //                         final itemMap = Map<String, dynamic>.from(item);
  //
  //                         // Extract nested data if present (like your ratios.returns structure)
  //                         if (itemMap.containsKey('ratios') && itemMap['ratios'] is Map) {
  //                           final ratios = itemMap['ratios'] as Map;
  //                           if (ratios.containsKey('returns') && ratios['returns'] is Map) {
  //                             final returns = ratios['returns'] as Map;
  //
  //                             // Flatten the returns data into the main item
  //                             final flattened = Map<String, dynamic>.from(itemMap);
  //                             flattened.remove('ratios'); // Remove nested structure
  //
  //                             // Add return metrics with proper formatting
  //                             if (returns.containsKey('1m')) {
  //                               flattened['1M Return'] = "${(returns['1m'] as num).toStringAsFixed(2)}%";
  //                             }
  //                             if (returns.containsKey('6m')) {
  //                               flattened['6M Return'] = "${(returns['6m'] as num).toStringAsFixed(2)}%";
  //                             }
  //                             if (returns.containsKey('1y')) {
  //                               flattened['1Y Return'] = "${(returns['1y'] as num).toStringAsFixed(2)}%";
  //                             }
  //                             if (returns.containsKey('1y_excess_over_Nifty')) {
  //                               flattened['1Y vs Nifty'] = "${(returns['1y_excess_over_Nifty'] as num).toStringAsFixed(2)}%";
  //                             }
  //
  //                             return flattened;
  //                           }
  //                         }
  //
  //                         return itemMap;
  //                       }
  //                       return <String, dynamic>{};
  //                     }).toList();
  //                     print("📊 TABLES: heading='$heading', ${rows.length} rows");
  //                   }
  //
  //                   // ✅ FIXED: Combine multiple tables instead of overwriting
  //                   if (!tableReceived) {
  //                     // First table - set the flag and use its heading
  //                     tableReceived = true;
  //                     combinedHeading = heading;
  //                     print("🏁 FIRST TABLE: Setting tableReceived=true, heading='$combinedHeading'");
  //                   }
  //
  //                   // Add all rows to the combined list
  //                   allTableRows.addAll(rows);
  //                   print("📈 ACCUMULATED ROWS: ${allTableRows.length} total rows (added ${rows.length} from this chunk)");
  //                   final originalType = jsonData['type'].toString();
  //                   // Create combined table data
  //                   tableData = {
  //                     'heading': combinedHeading,
  //                     'rows': allTableRows,
  //                     'type': originalType,
  //                   };
  //
  //                   print("✅ Combined table data processed: ${allTableRows.length} total rows");
  //                   for (int i = 0; i < allTableRows.length && i < 5; i++) {
  //                     print("   Row $i: ${allTableRows[i]}");
  //                   }
  //                   if (allTableRows.length > 5) print("   ... and ${allTableRows.length - 5} more rows");
  //
  //                   // Send message with combined table placeholder
  //                   String displayText = textBeforeTable + '___TABLE_PLACEHOLDER___' + textAfterTable;
  //
  //                   currentMessage = ChatMessage(
  //                     id: messageId,
  //                     text: displayText,
  //                     isUser: false,
  //                     timestamp: currentMessage.timestamp,
  //                     isComplete: false,
  //                     currentStatus: null,
  //                     messageType: 'kv_table',
  //                     structuredData: tableData,
  //                   );
  //                   controller.add(currentMessage);
  //                   print("✅ Combined table chunk processed: heading='$combinedHeading', total_rows=${allTableRows.length}");
  //                 }
  //                 continue;
  //               }
  //
  //               // ✅ Handle completion
  //               if (pType == 'complete') {
  //                 print("🏁 COMPLETION CHUNK RECEIVED");
  //                 String displayText = textBeforeTable;
  //                 if (tableReceived) {
  //                   displayText += '___TABLE_PLACEHOLDER___';
  //                   displayText += textAfterTable;
  //                 }
  //
  //                 currentMessage = ChatMessage(
  //                   id: currentMessage.id,
  //                   text: displayText,
  //                   isUser: currentMessage.isUser,
  //                   timestamp: currentMessage.timestamp,
  //                   isComplete: true,
  //                   currentStatus: null,
  //                   messageType: tableReceived ? 'kv_table' : null,
  //                   structuredData: tableData,
  //                 );
  //                 controller.add(currentMessage);
  //                 continue;
  //               }
  //             }
  //           } catch (e) {
  //             print("❌ Error parsing chunk #$chunkCounter: $e");
  //             print("❌ Raw line: '$line'");
  //           }
  //         }
  //       },
  //       onDone: () {
  //         print("\n" + "🎉"*30);
  //         print("📊 STREAMING COMPLETE");
  //         print("💬 Message: '$message'");
  //         print("📦 Total chunks: ${allChunks.length}");
  //         print("📝 Text before table: '$textBeforeTable'");
  //         print("📝 Text after table: '$textAfterTable'");
  //         print("📋 Table received: $tableReceived");
  //         print("📊 Total combined rows: ${allTableRows.length}");
  //
  //         // Print summary of all chunk types
  //         Map<String, int> chunkTypes = {};
  //         for (var chunk in allChunks) {
  //           final type = "${chunk['type']}";
  //           final payloadType = chunk['payload']?['type'] ?? '';
  //           final key = payloadType.isEmpty ? type : "$type:$payloadType";
  //           chunkTypes[key] = (chunkTypes[key] ?? 0) + 1;
  //         }
  //         print("📊 Chunk types summary: $chunkTypes");
  //         print("🎉"*30 + "\n");
  //
  //         // ✅ FIXED: Always send final complete message
  //         String finalText = textBeforeTable;
  //         if (tableReceived) {
  //           finalText += '___TABLE_PLACEHOLDER___';
  //           finalText += textAfterTable;
  //         }
  //
  //         // Create final complete message
  //         final finalMessage = ChatMessage(
  //           id: messageId,
  //           text: finalText,
  //           isUser: false,
  //           timestamp: currentMessage.timestamp,
  //           isComplete: true,           // ✅ Force completion
  //           currentStatus: null,        // ✅ Clear status
  //           messageType: tableReceived ? 'kv_table' : null,
  //           structuredData: tableData,
  //         );
  //
  //         controller.add(finalMessage);
  //         controller.close();
  //       },
  //       onError: (e) {
  //         print("❌ Stream error: $e");
  //         controller.addError(e);
  //         controller.close();
  //       },
  //     );
  //
  //     return controller.stream;
  //   } catch (e) {
  //     print("❌ sendMessageWithStreaming error: $e");
  //     rethrow;
  //   }
  // }








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














//   Future<Stream<ChatMessage>> sendMessageWithStreaming({
//     required String sessionId,
//     required String message,
//   }) async {
//
//     // DEBUG: Add this to confirm the method is being called
//     print("🔍 DEBUG: sendMessageWithStreaming called with message: '$message'");
//
//     // FOR NOW: Return hardcoded enhanced responses
//     // LATER: Simply uncomment the backend call and remove hardcoded logic
//
//     // ============= HARDCODED SECTION (REMOVE WHEN BACKEND IS READY) =============
//     final controller = StreamController<ChatMessage>();
//     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     print("🔍 DEBUG: Generated messageId: $messageId");
//
//     // Check if message matches our test scenarios
//     if (_shouldReturnEnhancedResponse(message)) {
//       print("🔍 DEBUG: Message matches enhanced response");
//       _simulateEnhancedResponse(controller, messageId, message);
//       return controller.stream;
//     }
//
//     print("🔍 DEBUG: Message doesn't match, returning default response");
//
//     // Default simple response for other messages
//     controller.add(ChatMessage(
//       id: messageId,
//       text: 'I can help you with portfolio analysis, expense analysis, account summary, or weather updates. Try asking about any of these!',
//       isUser: false,
//       timestamp: DateTime.now(),
//       isComplete: true,
//     ));
//     controller.close();
//     return controller.stream;
//     // ============= END HARDCODED SECTION =============
//   }
//
// // Helper method to check if we should return enhanced response
//   bool _shouldReturnEnhancedResponse(String message) {
//     final lowerMessage = message.toLowerCase();
//     print("🔍 DEBUG: Checking message: '$lowerMessage'");
//
//     final hasPortfolio = lowerMessage.contains('portfolio');
//     final hasExpense = lowerMessage.contains('expense');
//     final hasAccount = lowerMessage.contains('account');
//     final hasWeather = lowerMessage.contains('weather');
//
//     print("🔍 DEBUG: Contains portfolio: $hasPortfolio, expense: $hasExpense, account: $hasAccount, weather: $hasWeather");
//
//     return hasPortfolio || hasExpense || hasAccount || hasWeather;
//   }
//
// // Simulate enhanced response with hardcoded data
//   void _simulateEnhancedResponse(
//       StreamController<ChatMessage> controller,
//       String messageId,
//       String message
//       ) async {
//     print("🔍 DEBUG: _simulateEnhancedResponse started");
//
//     final lowerMessage = message.toLowerCase();
//
//     // Determine which scenario to simulate
//     Map<String, dynamic> scenarioData;
//
//     if (lowerMessage.contains('portfolio')) {
//       print("🔍 DEBUG: Using portfolio data");
//       scenarioData = _getPortfolioData();
//     } else if (lowerMessage.contains('expense')) {
//       print("🔍 DEBUG: Using expense data");
//       scenarioData = _getExpenseData();
//     } else if (lowerMessage.contains('account')) {
//       print("🔍 DEBUG: Using account data");
//       scenarioData = _getAccountData();
//     } else if (lowerMessage.contains('weather')) {
//       print("🔍 DEBUG: Using weather data");
//       scenarioData = _getWeatherData();
//     } else {
//       print("🔍 DEBUG: Using simple data");
//       scenarioData = _getSimpleData();
//     }
//
//     final statusUpdates = scenarioData['statusUpdates'] as List;
//     final payloads = scenarioData['payloads'] as List;
//
//     print("🔍 DEBUG: Status updates: ${statusUpdates.length}, Payloads: ${payloads.length}");
//
//     List<StatusUpdate> allStatusUpdates = [];
//     List<ResponsePayload> allPayloads = [];
//
//     // Simulate status updates
//     for (int i = 0; i < statusUpdates.length; i++) {
//       final statusData = statusUpdates[i];
//       print("🔍 DEBUG: Processing status update $i: ${statusData['message']}");
//
//       final statusUpdate = StatusUpdate(
//         id: '${messageId}_status_$i',
//         type: _parseStatusType(statusData['type']),
//         message: statusData['message'],
//         timestamp: DateTime.now(),
//         isComplete: false,
//       );
//       allStatusUpdates.add(statusUpdate);
//
//       controller.add(ChatMessage(
//         id: messageId,
//         text: '',
//         isUser: false,
//         timestamp: DateTime.now(),
//         isComplete: false,
//         statusUpdates: List.from(allStatusUpdates),
//         payloads: List.from(allPayloads),
//       ));
//
//       await Future.delayed(Duration(milliseconds: statusData['duration']));
//
//       // Mark status as complete
//       allStatusUpdates[i] = StatusUpdate(
//         id: statusUpdate.id,
//         type: statusUpdate.type,
//         message: statusUpdate.message,
//         timestamp: statusUpdate.timestamp,
//         isComplete: true,
//       );
//
//       controller.add(ChatMessage(
//         id: messageId,
//         text: '',
//         isUser: false,
//         timestamp: DateTime.now(),
//         isComplete: false,
//         statusUpdates: List.from(allStatusUpdates),
//         payloads: List.from(allPayloads),
//       ));
//
//       await Future.delayed(Duration(milliseconds: 500));
//     }
//
//     // Simulate payloads
//     for (int i = 0; i < payloads.length; i++) {
//       final payloadData = payloads[i];
//       print("🔍 DEBUG: Processing payload $i: ${payloadData['title']}");
//
//       final payload = ResponsePayload(
//         id: '${messageId}_payload_$i',
//         type: _parsePayloadType(payloadData['type']),
//         data: payloadData['data'],
//         title: payloadData['title'],
//         description: payloadData['description'],
//       );
//       allPayloads.add(payload);
//
//       controller.add(ChatMessage(
//         id: messageId,
//         text: '',
//         isUser: false,
//         timestamp: DateTime.now(),
//         isComplete: false,
//         statusUpdates: List.from(allStatusUpdates),
//         payloads: List.from(allPayloads),
//       ));
//
//       await Future.delayed(Duration(milliseconds: 800));
//     }
//
//     // Final complete message
//     print("🔍 DEBUG: Sending final complete message");
//     controller.add(ChatMessage(
//       id: messageId,
//       text: '',
//       isUser: false,
//       timestamp: DateTime.now(),
//       isComplete: true,
//       statusUpdates: List.from(allStatusUpdates),
//       payloads: List.from(allPayloads),
//     ));
//
//     controller.close();
//   }
//
//
//
// // Hardcoded data scenarios
//   Map<String, dynamic> _getPortfolioData() {
//     return {
//       'statusUpdates': [
//         {'type': 'thinking', 'message': 'Analyzing your portfolio', 'duration': 2000},
//         {'type': 'searching', 'message': 'Fetching latest market data', 'duration': 3000},
//         {'type': 'analyzing', 'message': 'Calculating performance metrics', 'duration': 2000},
//       ],
//       'payloads': [
//         {
//           'type': 'text',
//           'data': 'Here\'s your comprehensive portfolio analysis:',
//           'title': 'Portfolio Overview',
//           'description': null,
//         },
//         {
//           'type': 'json',
//           'data': {
//             'display_type': 'table',
//             'headers': ['Stock', 'Current Price', 'Holdings', 'P&L', 'Performance'],
//             'rows': [
//               ['Zomato', '₹156.75', '50 shares', '+₹2,337.50', '+15.2%'],
//               ['TCS', '₹3,245.80', '10 shares', '+₹1,458.00', '+4.7%'],
//               ['Reliance', '₹2,678.90', '5 shares', '-₹567.50', '-4.1%'],
//               ['HDFC Bank', '₹1,567.25', '15 shares', '+₹3,456.75', '+17.3%'],
//               ['Infosys', '₹1,389.60', '20 shares', '+₹2,792.00', '+11.2%'],
//             ]
//           },
//           'title': 'Stock Holdings',
//           'description': 'Your current stock positions and performance',
//         },
//         {
//           'type': 'text',
//           'data': '**Summary**: Portfolio gained ₹9,476.75 (8.9%) this quarter. **Top performers**: Zomato and HDFC Bank. **Recommendation**: Consider rebalancing Reliance position.',
//           'title': null,
//           'description': null,
//         },
//       ],
//     };
//   }
//
//   Map<String, dynamic> _getExpenseData() {
//     return {
//       'statusUpdates': [
//         {'type': 'thinking', 'message': 'Processing your expense data...', 'duration': 2500},
//         {'type': 'analyzing', 'message': 'Categorizing transactions...', 'duration': 2000},
//       ],
//       'payloads': [
//         {
//           'type': 'text',
//           'data': 'Your expense breakdown for this month:',
//           'title': 'Monthly Expenses',
//           'description': null,
//         },
//         {
//           'type': 'json',
//           'data': {
//             'display_type': 'table',
//             'headers': ['Category', 'Amount', 'Percentage', 'Budget Status'],
//             'rows': [
//               ['Food & Dining', '₹12,450', '35%', 'Over Budget'],
//               ['Transportation', '₹5,670', '16%', 'Within Budget'],
//               ['Entertainment', '₹8,230', '23%', 'Within Budget'],
//               ['Shopping', '₹6,890', '19%', 'Over Budget'],
//               ['Utilities', '₹2,560', '7%', 'Within Budget'],
//             ]
//           },
//           'title': 'Expense Categories',
//           'description': 'Breakdown of your monthly spending',
//         },
//         {
//           'type': 'text',
//           'data': '**Total**: ₹35,800. Over budget by ₹5,800 due to **food and shopping**. **Tip**: Try meal planning to reduce costs.',
//           'title': null,
//           'description': null,
//         },
//       ],
//     };
//   }
//
//   Map<String, dynamic> _getAccountData() {
//     return {
//       'statusUpdates': [
//         {'type': 'searching', 'message': 'Retrieving account information...', 'duration': 1500},
//       ],
//       'payloads': [
//         {
//           'type': 'text',
//           'data': 'Here\'s your current account summary:',
//           'title': 'Account Overview',
//           'description': null,
//         },
//         {
//           'type': 'json',
//           'data': {
//             'account_number': '****7891',
//             'account_type': 'Savings Account',
//             'current_balance': '₹1,25,450.75',
//             'available_balance': '₹1,20,450.75',
//             'last_transaction': 'July 28, 2025',
//             'interest_rate': '3.5% per annum',
//             'status': 'Active'
//           },
//           'title': 'Account Details',
//           'description': 'Your primary savings account information',
//         },
//       ],
//     };
//   }
//
//   Map<String, dynamic> _getWeatherData() {
//     return {
//       'statusUpdates': [
//         {'type': 'searching', 'message': 'Fetching current weather data...', 'duration': 1500},
//       ],
//       'payloads': [
//         {
//           'type': 'text',
//           'data': '**Current Weather**: 28°C in Jaipur, partly cloudy with 65% humidity. **Forecast**: High 32°C, low 24°C with evening showers possible.',
//           'title': "Weather",
//           'description': null,
//         },
//       ],
//     };
//   }
//
//   Map<String, dynamic> _getSimpleData() {
//     return {
//       'statusUpdates': [],
//       'payloads': [
//         {
//           'type': 'text',
//           'data': 'I can help you with various financial queries and analysis!',
//           'title': null,
//           'description': null,
//         },
//       ],
//     };
//   }
//
// // Helper methods for parsing (needed for backend integration later)
//   StatusType _parseStatusType(String type) {
//     switch (type.toLowerCase()) {
//       case 'thinking': return StatusType.thinking;
//       case 'searching': return StatusType.searching;
//       case 'analyzing': return StatusType.analyzing;
//       case 'processing': return StatusType.processing;
//       case 'completed': return StatusType.completed;
//       default: return StatusType.processing;
//     }
//   }
//
//   PayloadType _parsePayloadType(String type) {
//     switch (type.toLowerCase()) {
//       case 'text': return PayloadType.text;
//       case 'json': return PayloadType.json;
//       case 'chart': return PayloadType.chart;
//       default: return PayloadType.text;
//     }
//   }






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

    final completed = userCount >= 1 && botCount >= 1;
    if (completed) {
      // 👇 This was missing — without it, the UI has nothing to read
      if (!_showNewChatButton) {
        _showNewChatButton = true;
      }
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
    _showNewChatButton = false;
  }

  void dispose() {
    _messagesSubject.close();
    _isTypingSubject.close();
    _hasLoadedMessagesSubject.close();
    _firstMessageCompleteSubject.close();
    _streamSubscription?.cancel();
  }
}



// ✨ Put this helper at the bottom of your ChatService file (outside the class or inside as a private class).
class _StreamDebugStats {
  int rawChunks = 0;
  int totalLines = 0;
  int dataLines = 0;
  int badJsonLines = 0;
  int sessionCreated = 0;
  int statusUpdates = 0;
  int responseTextChunks = 0;
  int responseJsonChunks = 0;
  int responseCompletes = 0;
  int textBeforeChars = 0;
  int textAfterChars = 0;
  int jsonRowsAccumulated = 0;
  DateTime? firstChunkTime;

  void onRawChunk(String chunk) {
    rawChunks++;
  }

  void onLine(String line) {
    totalLines++;
    if (line.trim().startsWith('data:')) {
      dataLines++;
    }
  }

  void onParsedEvent({required String type, required String payloadType}) {
    // Events are tracked by individual handlers
  }

  void markFirstChunkIfNeeded() {
    firstChunkTime ??= DateTime.now();
  }

  void printSummary({bool debugLog = false}) {
    if (!debugLog) return;

    print('\n' + '=' * 50);
    print('STREAMING COMPLETE STATS');
    print('Raw chunks: $rawChunks');
    print('Total lines: $totalLines');
    print('Data lines: $dataLines');
    print('Bad JSON lines: $badJsonLines');
    print('Session created events: $sessionCreated');
    print('Status updates: $statusUpdates');
    print('Text chunks: $responseTextChunks');
    print('JSON chunks: $responseJsonChunks');
    print('Complete events: $responseCompletes');
    print('Text before table: $textBeforeChars chars');
    print('Text after table: $textAfterChars chars');
    print('JSON rows accumulated: $jsonRowsAccumulated');
    print('=' * 50 + '\n');
  }
}




//   Future<void> sendMessage(String? sessionId, String text) async {
//     // 🔐 ensure we have a real session id (creates one if needed)
//     final effectiveSessionId = await _ensureActiveSessionId(sessionId);
//
//     final userMessage = sanitizeMessage(text);
//     final isFirstMessage = !messages.any((m) => m['role'] == 'user');
//     final userMessageId = UniqueKey().toString();
//     final botMessageId = UniqueKey().toString();
//
//     _isTypingSubject.add(true);
//
//     _messagesSubject.add([
//       ...messages,
//       {
//         'id': userMessageId,
//         'role': 'user',
//         'content': userMessage,  // ✅ Changed 'msg' to 'content'
//         'isComplete': true,
//         // ✅ NEW messages are NOT historical
//       },
//       {
//         'id': botMessageId,
//         'role': 'bot',
//         'content': '',  // ✅ Changed 'msg' to 'content'
//         'isComplete': false,
//         // ✅ NEW messages are NOT historical - will have typing animation
//       }
//     ]);
//
//     try {
//       if (isFirstMessage) {
//         // now we always have a valid id
//         await updateSessionTitle(effectiveSessionId, userMessage);
//       }
//
//       final responseStream = await sendMessageWithStreaming(
//         sessionId: effectiveSessionId,
//         message: userMessage,
//       );
// print("BHAIIII $responseStream");
//       _currentStreamingId = '';
//
//       _streamSubscription = responseStream.listen((chatMessage) {
//         if (_currentStreamingId.isEmpty) {
//           _currentStreamingId = chatMessage.id;
//         }
//
//         final updated = [..._messagesSubject.value];
//         final lastIndex = updated.length - 1;
//
//         if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
//           final prev = Map<String, Object>.from(updated[lastIndex]);
//
//           Map<String, Object> messageData = <String, Object>{
//             ...prev,
//             'id': botMessageId,
//             'role': 'bot',
//             'content': chatMessage.text,  // ✅ Changed 'msg' to 'content'
//             'isComplete': (prev['isComplete'] as bool?) ?? false,
//             'backendComplete': chatMessage.isComplete,
//             'currentStatus': chatMessage.currentStatus ?? '',
//             // ✅ Still NO isHistorical flag - keeps typing animation
//           };
//
//           if (chatMessage.isTable && chatMessage.structuredData != null) {
//             final sd = chatMessage.structuredData!;
//             final heading = sd['heading']?.toString() ?? 'Results';
//             final rows = (sd['rows'] as List?)
//                 ?.whereType<Map>()
//                 .map((e) => Map<String, dynamic>.from(e))
//                 .toList() ??
//                 <Map<String, dynamic>>[];
//
//             messageData['type'] = 'kv_table';
//             messageData['tableData'] = <String, Object>{
//               'heading': heading,
//               'rows': rows,
//               'columnOrder': (prev['tableData'] is Map &&
//                   (prev['tableData'] as Map)['columnOrder'] is List)
//                   ? List<String>.from((prev['tableData'] as Map)['columnOrder'])
//                   : <String>[],
//             };
//           } else if (prev.containsKey('tableData') && prev['tableData'] != null) {
//             messageData['tableData'] = prev['tableData']!;
//           }
//
//           if (prev.containsKey('type') &&
//               !messageData.containsKey('type') &&
//               prev['type'] != null) {
//             messageData['type'] = prev['type']!;
//           }
//
//           updated[lastIndex] = messageData;
//           _messagesSubject.add(updated);
//         }
//       }, onError: (e) {
//         debugPrint("❌ CHAT SERVICE ERROR: $e");
//         _isTypingSubject.add(false);
//
//         final updated = [..._messagesSubject.value];
//         final lastIndex = updated.length - 1;
//         if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
//           updated[lastIndex] = {
//             'id': botMessageId,
//             'role': 'bot',
//             'content': '❌ Failed to respond.',  // ✅ Changed 'msg' to 'content'
//             'isComplete': true,
//             'retry': true,
//             'originalMessage': userMessage,
//           };
//           _messagesSubject.add(updated);
//         }
//       });
//     } catch (e) {
//       debugPrint("❌ SEND MESSAGE ERROR: $e");
//       _isTypingSubject.add(false);
//
//       final updated = [..._messagesSubject.value];
//       final lastIndex = updated.length - 1;
//       if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
//         updated[lastIndex] = {
//           'id': botMessageId,
//           'role': 'bot',
//           'content': '❌ Failed to send.',  // ✅ Changed 'msg' to 'content'
//           'isComplete': true,
//           'retry': true,
//           'originalMessage': userMessage,
//         };
//         _messagesSubject.add(updated);
//       }
//     }
//   }