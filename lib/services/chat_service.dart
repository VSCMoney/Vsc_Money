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
  final _isScrollLocked = BehaviorSubject<bool>.seeded(true); // ✅ Default true रखें

  Stream<bool> get isScrollLockedStream => _isScrollLocked.stream.distinct();
  bool get isScrollLocked => _isScrollLocked.value;

  void lockScroll() {
    if (!_isScrollLocked.isClosed) {
      _isScrollLocked.add(true);
      print("🔒 Scroll LOCKED");
    }
  }

  void unlockScroll() {
    if (!_isScrollLocked.isClosed) {
      _isScrollLocked.add(false);
      print("🔓 Scroll UNLOCKED");
    }
  }



  void resetForNewChat() {
    print("🧹 Resetting ChatService for new chat");

    // Clear messages but preserve scroll lock state
    final currentLockState = _isScrollLocked.value;
    clear();

    // Restore lock state after clear
    if (!_isScrollLocked.isClosed) {
      _isScrollLocked.add(currentLockState);
    }

    _currentSession = null;
    _showNewChatButton = false;
    print("✅ ChatService reset complete - scroll lock preserved: $currentLockState");
  }

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
  final Map<String, List<Map<String, Object>>> _sessionMessagesCache = {};

  // ✅ ADD THIS: Public getter for cache access
  Map<String, List<Map<String, Object>>> get sessionMessagesCache => _sessionMessagesCache;

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


  // --- ChatService: add fields ---
  final _chatViewportHeightSubject = BehaviorSubject<double>.seeded(0.0);
  bool _viewportFixed = false;

  double get chatViewportHeight => _chatViewportHeightSubject.value;
  bool get isViewportFixed => _viewportFixed;

// --- ChatService: store-once/freeze viewport ---
  void commitViewportOnce(double value) {
    if (_viewportFixed) return;
    if (value <= 0) return;
    _chatViewportHeightSubject.add(value);
    _viewportFixed = true;
    debugPrint("📐 Viewport FIXED at: $value");
  }

// (optional) kabhi reset karna ho (naya chat/orientation)
  void resetViewport() {
    _viewportFixed = false;
    _chatViewportHeightSubject.add(0.0);
  }

// --- ChatService: keep this so callers don't crash ---
  void updateFrameHeights({
    double? appBar,
    double? input,
    double? chatViewport,
  }) {
    // NOTE: chatViewport ko yaha ignore/guard karo — hum freeze model use kar rahe:
    if (chatViewport != null && !_viewportFixed && chatViewport > 0) {
      // Agar kisi ne galti se yahi bhej diya ho, phir bhi sirf tab set karo jab fixed na ho.
      _chatViewportHeightSubject.add(chatViewport);
    }
  }





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



  Future<void> switchToSessionWithoutClearing(ChatSession session) async {
    print("🔄 switchToSessionWithoutClearing: ${session.id}");
    print("📊 Current messages before switch: ${_messagesSubject.value.length}");

    // Save current session's messages if they exist
    final currentSession = _currentSession;
    final currentMessages = List<Map<String, Object>>.from(_messagesSubject.value);

    if (currentSession != null && currentMessages.isNotEmpty) {
      print("💾 Saving ${currentMessages.length} messages for current session: ${currentSession.id}");
      _sessionMessagesCache[currentSession.id] = currentMessages;
    }

    // Switch to new session
    _currentSession = session;
    print("🔄 Switched current session to: ${session.id}");

    // Load messages for this session
    try {
      print("📥 Loading messages for session: ${session.id}");
      await loadMessages(session.id);

      final loadedMessages = _messagesSubject.value;
      print("✅ Loaded ${loadedMessages.length} messages for session: ${session.id}");

    } catch (e) {
      print("❌ Failed to load messages: $e");
      _messagesSubject.add([]);
    }
  }



  void saveMessagesForSession(String sessionId, List<Map<String, Object>> messages) {
    if (messages.isNotEmpty) {
      _sessionMessagesCache[sessionId] = List<Map<String, Object>>.from(messages);
      print("💾 Saved ${messages.length} messages for session: $sessionId");
    }
  }




  void clearCurrentSession() {
    print("🧹 Clearing current session");

    // Save current messages before clearing
    final currentSession = _currentSession;
    final currentMessages = List<Map<String, Object>>.from(_messagesSubject.value);

    if (currentSession != null && currentMessages.isNotEmpty) {
      print("💾 Auto-saving messages before clearing session");
      _sessionMessagesCache[currentSession.id] = currentMessages;
    }

    _currentSession = null;
    _showNewChatButton = false;
    _isLoadingSession = false;
    _error = null;

    print("✅ Current session cleared");
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
      // Load sessions
      await _loadSessions();

      if (initialSessionId != null && initialSessionId.isNotEmpty) {
        try {
          final targetSession = _sessions.firstWhere(
                (session) => session.id == initialSessionId,
          );
          await switchToSession(targetSession);
        } catch (e) {
          print('❌ Session not found: $initialSessionId, creating new session');
          await createNewChatSession();
        }
      } else {
        // For new chat, start with scroll locked
        _currentSession = null;
        _messagesSubject.add([]);
        _hasLoadedMessagesSubject.add(true);
        lockScroll(); // 🔒 Ensure scroll is locked for new chat
      }

      _isInitialized = true;
    //  print('✅ ChatService initialized successfully - scroll locked: ${_isScrollLocked.value}');

    } catch (e) {
      print('❌ Failed to initialize ChatService: $e');
      _isInitialized = true;
      await createNewChatSession();
      lockScroll(); // 🔒 Lock on error recovery too
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




  Future<void> loadMessages(String sessionId) async {
    print('🔍 CHAT: Loading messages for session: $sessionId');

    // First check if we have cached messages for this session
    if (_sessionMessagesCache.containsKey(sessionId)) {
      print('📋 Found cached messages for session: $sessionId');
      final cachedMessages = _sessionMessagesCache[sessionId]!;
      _messagesSubject.add(List<Map<String, Object>>.from(cachedMessages));
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();
      return;
    }

    // Otherwise load from API (your existing logic)
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

        final content = msg['message_text']?.toString() ??
            msg['Content']?.toString() ??
            msg['content']?.toString() ?? '';

        if (content.isEmpty) {
          print('⚠️ Empty content for message $i, skipping');
          continue;
        }

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

        loaded.add({
          'role': role,
          'content': content,
          'isComplete': true,
          'isHistorical': true,
          'timestamp': msg['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
          'author': author,
          'id': '${sessionId}_${i}',
        });
      }

      print('✅ CHAT: Successfully processed ${loaded.length} messages');

      // Cache the loaded messages
      _sessionMessagesCache[sessionId] = List<Map<String, Object>>.from(loaded);

      _messagesSubject.add(loaded);
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();

    } catch (e) {
      debugPrint("❌ Failed to load messages: $e");
      _hasLoadedMessagesSubject.add(true);
    }
  }




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




  void markUiRenderCompleteForLatest() {
    // hide stop button
   // _isTypingSubject.add(false);

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
   // _isTypingSubject.add(false);
    _checkAndNotifyFirstMessageComplete();
  }


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

    // Remove last retry bot bubble and clear any status
    for (int i = updated.length - 1; i >= 0; i--) {
      if (updated[i]['role'] == 'bot' &&
          (updated[i]['retry'] == true || updated[i]['errorType'] != null)) {
        updated.removeAt(i);
        break;
      }
    }
    _messagesSubject.add(updated);

    final botMessageId = UniqueKey().toString();

    // ✅ Add clean bot message without any status initially
    _messagesSubject.add([
      ...updated,
      {
        'id': botMessageId,
        'role': 'bot',
        'content': '',
        'isComplete': false,
        'timestamp': DateTime.now().toIso8601String(),
        // No currentStatus, no retry flags - completely clean
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
      _streamSubscription = responseStream.listen(
              (chatMessage) {
           // _handleStreamingMessage(chatMessage, botMessageId);
          },
          onError: (e) {
            debugPrint("❌ RETRY STREAM ERROR: $e");
            _handleNetworkError(botMessageId, originalMessage, e);
          }
      );

    } catch (e) {
      debugPrint("❌ RETRY SETUP ERROR: $e");
      _handleNetworkError(botMessageId, originalMessage, e);
    }
  }



// ✅ UPDATED: Enhanced network error handler
  void _handleNetworkError(String botMessageId, String userMessage, dynamic error) {
    _isTypingSubject.add(false);

    final updated = [..._messagesSubject.value];
    final lastIndex = updated.length - 1;

    if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
      // First show "Checking connection..." briefly
      updated[lastIndex] = {
        'id': botMessageId,
        'role': 'bot',
        'content': '',
        'isComplete': false,
        'currentStatus': 'Checking connection...',
        'isConnecting': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _messagesSubject.add(updated);
    }

    // After 1.5 seconds, show retry button
    Timer(const Duration(milliseconds: 1500), () {
      if (_messagesSubject.isClosed) return;
      final msgs = [..._messagesSubject.value];
      final i = msgs.length - 1;

      if (i >= 0 && msgs[i]['role'] == 'bot' && msgs[i]['id'] == botMessageId) {
        msgs[i] = {
          'id': botMessageId,
          'role': 'bot',
          'content': "Connection issue detected. Please check your internet and try again.",
          'isComplete': true,
          'retry': true,
          'originalMessage': userMessage,
          'errorType': 'network_error',
          'currentStatus': "", // ✅ Clear status when showing retry
          'isConnecting': "",  // ✅ Clear connecting state
          'timestamp': DateTime.now().toIso8601String(),
        };
        _messagesSubject.add(msgs);
      }
    });
  }



  // ===== ChatService.dart - Fixed stopResponse =====
  Future<void> stopResponse(String sessionId) async {
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

    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentStreamingId = '';

    final updated = [..._messagesSubject.value];
    final lastIndex = updated.length - 1;
    if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
      updated[lastIndex] = {
        ...updated[lastIndex],
        'currentStatus': '',
        'forceStop': true,
        'isComplete': true, // Mark as complete when stopped
        'stopTs': DateTime.now().toIso8601String(),
      };
      _messagesSubject.add(updated);
    }

    _isTypingSubject.add(false);

    // 🔒 Stop करने पर भी lock
    lockScroll();
    print("⏹️ Response stopped - LOCKING scroll");
  }



  void debugPrintMessagesState(String context) {
    final messages = _messagesSubject.value;
    print("🔍 MESSAGES STATE [$context]:");
    print("  Total messages: ${messages.length}");

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final role = msg['role'];
      final content = (msg['content'] as String? ?? '').substring(0, math.min(50, (msg['content'] as String? ?? '').length));
      final isComplete = msg['isComplete'];
      final id = msg['id'];

      print("  [$i] $role: '$content...' (complete: $isComplete, id: $id)");
    }
    print("  _isTypingSubject.value: ${_isTypingSubject.value}");
    print("  _currentSession?.id: ${_currentSession?.id}");
    print("---");
  }


// ChatService.dart - Fixed sendMessage method
//   Future<void> sendMessage(String? sessionId, String text) async {
//     // 🔓 STEP 1: UNLOCK when user starts sending message
//     //unlockScroll();
//     print("🔓 UNLOCKED: User started sending message");
//
//     final uid = SessionManager.uid;
//     if (uid == null || uid.isEmpty) {
//       throw StateError('No UID. Log in first.');
//     }
//
//     final userMessage = sanitizeMessage(text);
//     final isFirstMessage = !messages.any((m) => m['role'] == 'user');
//     final userMessageId = UniqueKey().toString();
//     final botMessageId = UniqueKey().toString();
//
//     _isTypingSubject.add(true);
//     print("TRUE HO GAYA");
//
//     // Add user message + empty bot bubble
//     _messagesSubject.add([
//       ...messages,
//       {
//         'id': userMessageId,
//         'role': 'user',
//         'content': userMessage,
//         'isComplete': true,
//       },
//       {
//         'id': botMessageId,
//         'role': 'bot',
//         'content': '',
//         'isComplete': false,
//       }
//     ]);
//
//     try {
//       //await Future.delayed(const Duration(seconds: 5));
//       final responseStream = await sendMessageWithStreamingRespond(
//         uid: uid,
//         debugLog: true,
//         sessionId: _currentSession?.id,
//         message: userMessage,
//         firstMessageForTitle: isFirstMessage ? userMessage : null,
//       );
//
//       _currentStreamingId = '';
//
//       _streamSubscription = responseStream.listen(
//             (chatMessage) {
//           if (_currentStreamingId.isEmpty) _currentStreamingId = chatMessage.id;
//
//           final updated = [..._messagesSubject.value];
//           final lastIndex = updated.length - 1;
//
//           if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
//             final prev = Map<String, Object>.from(updated[lastIndex]);
//
//             final Map<String, Object> messageData = <String, Object>{
//               'id': botMessageId,
//               'role': 'bot',
//               'content': chatMessage.text,
//               'isComplete': chatMessage.isComplete, // ✅ Use backend completion status
//               'backendComplete': chatMessage.isComplete,
//               if ((chatMessage.currentStatus ?? '').isNotEmpty &&
//                   chatMessage.currentStatus != 'null')
//                 'currentStatus': chatMessage.currentStatus!,
//             };
//
//             // Handle table data
//             if (chatMessage.isTable && chatMessage.structuredData != null) {
//               messageData['type'] = 'kv_table';
//               messageData['tableData'] = Map<String, dynamic>.from(chatMessage.structuredData!);
//             } else {
//               if (prev['tableData'] != null) messageData['tableData'] = prev['tableData']!;
//               if (prev['type'] != null) messageData['type'] = prev['type']!;
//             }
//
//             updated[lastIndex] = messageData;
//             _messagesSubject.add(updated);
//
//            // 🔒 CRITICAL: Lock when individual message is complete
//             if (chatMessage.isComplete) {
//               print("🔒 LOCKING: Bot message complete");
//                _isTypingSubject.add(false);
//
//              // Lock scroll after a short delay to ensure UI has updated
//               Future.delayed(const Duration(milliseconds: 50), () {
//                 lockScroll();
//               });
//             }
//           }
//         },
//         onError: (e) {
//           debugPrint("❌ STREAM ERROR: $e");
//           _isTypingSubject.add(false);
//           lockScroll();
//           print("🔒 LOCKED: Stream error");
//           _handleConnectionError(botMessageId, userMessage, e);
//         },
//           onDone: () {
//             // print("🔒 LOCKING: Stream ended");
//             // _isTypingSubject.add(false);
//           }
//
//       );
//     } catch (e) {
//       debugPrint("❌ SEND MESSAGE ERROR: $e");
//       _isTypingSubject.add(false);
//       //lockScroll();
//       print("🔒 LOCKED: Send message error");
//       _handleConnectionError(botMessageId, userMessage, e);
//     }
//   }

// Updated sendMessageWithStreamingRespond - with proper completion handling


  // Replace your sendMessage method in ChatService with this updated version

  Future<void> sendMessage(String? sessionId, String text) async {

    final uid = SessionManager.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No UID. Log in first.');
    }

    final userMessage = sanitizeMessage(text);
    final isFirstMessage = !messages.any((m) => m['role'] == 'user');
    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    print("📤 Adding user message to stream");
    print("  userMessageId: $userMessageId");
    print("  isFirstMessage: $isFirstMessage");

    _isTypingSubject.add(true);

    // ✅ CRITICAL: Ensure user message is properly added and persisted
    final currentMessages = List<Map<String, Object>>.from(_messagesSubject.value);

    final userMsg = {
      'id': userMessageId,
      'role': 'user',
      'content': userMessage,
      'isComplete': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final botMsg = {
      'id': botMessageId,
      'role': 'bot',
      'content': '',
      'isComplete': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final updatedMessages = [
      ...currentMessages,
      userMsg,
      botMsg,
    ];

    print("📤 Messages before update: ${currentMessages.length}");
    print("📤 Messages after update: ${updatedMessages.length}");

    // Add to stream
    _messagesSubject.add(updatedMessages);

    debugPrintMessagesState("AFTER_USER_MESSAGE_ADDED");

    try {
      final responseStream = await sendMessageWithStreamingRespond(
        uid: uid,
        debugLog: true,
        sessionId: _currentSession?.id,
        message: userMessage,
        firstMessageForTitle: isFirstMessage ? userMessage : null,
      );

      _currentStreamingId = '';

      _streamSubscription = responseStream.listen(
              (chatMessage) {
            print("📥 STREAM MESSAGE: ${chatMessage.text.length} chars, complete: ${chatMessage.isComplete}");

            if (_currentStreamingId.isEmpty) _currentStreamingId = chatMessage.id;

            final updated = List<Map<String, Object>>.from(_messagesSubject.value);
            final lastIndex = updated.length - 1;

            if (lastIndex >= 0 && updated[lastIndex]['role'] == 'bot') {
              final prev = Map<String, Object>.from(updated[lastIndex]);

              final Map<String, Object> messageData = <String, Object>{
                'id': botMessageId,
                'role': 'bot',
                'content': chatMessage.text,
                'isComplete': chatMessage.isComplete,
                'backendComplete': chatMessage.isComplete,
                'timestamp': DateTime.now().toIso8601String(),
                if ((chatMessage.currentStatus ?? '').isNotEmpty &&
                    chatMessage.currentStatus != 'null')
                  'currentStatus': chatMessage.currentStatus!,
              };

              // Handle table data
              if (chatMessage.isTable && chatMessage.structuredData != null) {
                messageData['type'] = 'kv_table';
                messageData['tableData'] = Map<String, dynamic>.from(chatMessage.structuredData!);
              } else {
                if (prev['tableData'] != null) messageData['tableData'] = prev['tableData']!;
                if (prev['type'] != null) messageData['type'] = prev['type']!;
              }

              updated[lastIndex] = messageData;
              _messagesSubject.add(updated);

              debugPrintMessagesState("AFTER_BOT_MESSAGE_UPDATED");

              // Lock when individual message is complete
              if (chatMessage.isComplete) {
                print("✅ MESSAGE COMPLETE - locking scroll");
                _isTypingSubject.add(false);

                // Check and notify first message complete
                _checkAndNotifyFirstMessageComplete();

                Future.delayed(const Duration(milliseconds: 50), () {
                  lockScroll();
                });
              }
            }
          },
          onError: (e) {
            print("❌ STREAM ERROR: $e");
            _isTypingSubject.add(false);
            lockScroll();
            _handleConnectionError(botMessageId, userMessage, e);
          },
          onDone: () {
            print("✅ STREAM DONE");
            _isTypingSubject.add(false);
          }
      );
    } catch (e) {
      print("❌ SEND MESSAGE ERROR: $e");
      _isTypingSubject.add(false);
      _handleConnectionError(botMessageId, userMessage, e);
    }
  }



  Future<Stream<ChatMessage>> sendMessageWithStreamingRespond({
    required String uid,
    String? sessionId,
    required String message,
    String? firstMessageForTitle,
    bool debugLog = true,
  }) async {
    final ok = await SessionManager.checkTokenValidityAndRefresh(silent: false);
    if (!ok || SessionManager.token == null) {
      throw StateError('Not authenticated (no/expired token)');
    }
    final String token = SessionManager.token!;


    final stats = _StreamDebugStats();
    if (debugLog) {
      final preview = message.length > 120 ? '${message.substring(0, 120)}…' : message;
      print('START STREAM - /chat/respond');
      print('uid: $uid');
      print('sessionId: ${sessionId ?? "<null - will be created by server>"}');
      print('user message: "$preview"');
    }
    final DateTime _hitAtUtc = DateTime.now().toUtc();
    final String _hitAtUtcIso = _hitAtUtc.toIso8601String();
    try {
     // final String _baseUrl = 'http://localhost:8000';
      final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
      final url = Uri.parse('$_baseUrl/chat/respond');
      final req = http.Request('POST', url);
      req.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
       // if (SessionManager.refreshToken != null) 'X-Refresh-Token': SessionManager.refreshToken!,
      });

      final body = <String, dynamic>{
        'uid': uid,
        'input': utf8.decode(message.codeUnits),
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        'timestamp': _hitAtUtcIso
      };
      req.body = jsonEncode(body);

      print('REQUEST BODY: ${req.body}');
      print('REQUEST HEADERS: ${req.headers}');

      final streamedResponse = await req.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout after 30 seconds'),
      );

      print('RESPONSE STATUS: ${streamedResponse.statusCode}');
      print('RESPONSE HEADERS: ${streamedResponse.headers}');

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('ERROR BODY: $errorBody');
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
      bool streamCompleted = false;

      print('INITIALIZED VARIABLES:');
      print('messageId: $messageId');
      print('textBeforeTable: "$textBeforeTable"');
      print('textAfterTable: "$textAfterTable"');
      print('tableReceived: $tableReceived');
      print('streamCompleted: $streamCompleted');

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
          print('\n=== NEW CHUNK RECEIVED ===');
          print('CHUNK SIZE: ${chunk.length} bytes');
          print('RAW CHUNK: "$chunk"');

          stats.onRawChunk(chunk);
          resetInactivityTimer();
          buffer += chunk;

          print('BUFFER AFTER ADDING CHUNK: "$buffer"');

          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          print('SPLIT INTO ${lines.length} LINES');
          print('REMAINING BUFFER: "$buffer"');

          for (final raw in lines) {
            print('\n--- PROCESSING LINE ---');
            print('RAW LINE: "$raw"');

            stats.onLine(raw);
            final line = raw.trim();

            print('TRIMMED LINE: "$line"');

            if (line.isEmpty || !line.startsWith('data:')) {
              print('SKIPPING LINE - empty or not data line');
              continue;
            }

            final jsonText = line.substring(5).trim();
            print('EXTRACTED JSON TEXT: "$jsonText"');

            if (jsonText.isEmpty) {
              print('SKIPPING - empty JSON text');
              continue;
            }

            Map<String, dynamic> decoded;
            try {
              decoded = jsonDecode(jsonText) as Map<String, dynamic>;
              print('SUCCESSFULLY DECODED JSON: $decoded');
            } catch (e) {
              if (debugLog) print('JSON parse error: $e');
              continue;
            }

            final type = (decoded['type'] ?? '').toString();
            final payload = decoded['payload'] as Map<String, dynamic>? ?? const {};
            final payloadType = (payload['type'] ?? '').toString();

            print('EVENT TYPE: "$type"');
            print('PAYLOAD TYPE: "$payloadType"');
            print('FULL PAYLOAD: $payload');

            // Handle session_created
            if (type == 'session_created') {
              print('HANDLING SESSION_CREATED EVENT');
              final sid = decoded['session_id']?.toString();
              print('SESSION ID: $sid');

              if (sid != null && sid.isNotEmpty) {
                print('ADOPTING SERVER SESSION: $sid');
                _adoptServerSession(sid);
                if (firstMessageForTitle != null && firstMessageForTitle.trim().isNotEmpty) {
                  print('UPDATING SESSION TITLE: $firstMessageForTitle');
                }
              }
              continue;
            }

            // Handle status_update
            if (type == 'status_update') {
              print('HANDLING STATUS_UPDATE EVENT');
              final reason = (payload['reason'] ?? '').toString();
              print('STATUS REASON: "$reason"');

              String displayText = textBeforeTable;
              if (tableReceived) {
                displayText += '___TABLE_PLACEHOLDER___';
                displayText += textAfterTable;
              }

              print('CURRENT textBeforeTable: "$textBeforeTable"');
              print('CURRENT textAfterTable: "$textAfterTable"');
              print('CURRENT tableReceived: $tableReceived');
              print('CONSTRUCTED DISPLAY TEXT: "$displayText"');

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

              print('ADDING STATUS MESSAGE TO CONTROLLER');
              controller.add(currentMessage);
              continue;
            }

            // 🆕 ADD IMAGE HANDLING
            if (type == 'image') {
              print('HANDLING IMAGE EVENT');
              final imageUrl = payload['url']?.toString();
              print('IMAGE URL: $imageUrl');

              if (imageUrl != null && imageUrl.isNotEmpty) {
                // Add image URL to the appropriate text section
                if (tableReceived) {
                  textAfterTable += imageUrl + '\n';
                  print('ADDED IMAGE URL TO textAfterTable');
                } else {
                  textBeforeTable += imageUrl + '\n';
                  print('ADDED IMAGE URL TO textBeforeTable');
                }

                // Construct display text
                String displayText = textBeforeTable;
                if (tableReceived) {
                  displayText += '___TABLE_PLACEHOLDER___';
                  displayText += textAfterTable;
                }

                print('DISPLAY TEXT WITH IMAGE: "$displayText"');

                currentMessage = ChatMessage(
                  id: messageId,
                  text: displayText,
                  isUser: false,
                  timestamp: currentMessage.timestamp,
                  isComplete: false,
                  currentStatus: null,
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableReceived ? 'kv_table' : null,
                );

                print('ADDING IMAGE MESSAGE TO CONTROLLER');
                controller.add(currentMessage);
              }
              continue;
            }

            // Handle response events
            if (type == 'response') {
              print('HANDLING RESPONSE EVENT');

              if (payloadType == 'text') {
                print('HANDLING TEXT PAYLOAD');
                final data = (payload['data'] ?? '').toString();
                print('TEXT DATA: "$data"');
                print('TEXT DATA LENGTH: ${data.length}');

                print('BEFORE - textBeforeTable: "${textBeforeTable.length} chars"');
                print('BEFORE - textAfterTable: "${textAfterTable.length} chars"');
                print('BEFORE - tableReceived: $tableReceived');

                if (tableReceived) {
                  textAfterTable += data;
                  print('ADDED TEXT TO textAfterTable');
                } else {
                  textBeforeTable += data;
                  print('ADDED TEXT TO textBeforeTable');
                }

                print('AFTER - textBeforeTable: "${textBeforeTable.length} chars" - "$textBeforeTable"');
                print('AFTER - textAfterTable: "${textAfterTable.length} chars" - "$textAfterTable"');

                String displayText = textBeforeTable;
                if (tableReceived) {
                  displayText += '___TABLE_PLACEHOLDER___';
                  displayText += textAfterTable;
                }

                print('FINAL DISPLAY TEXT: "$displayText"');

                currentMessage = ChatMessage(
                  id: messageId,
                  text: displayText,
                  isUser: false,
                  timestamp: currentMessage.timestamp,
                  isComplete: false,
                  currentStatus: null,
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableReceived ? 'kv_table' : null,
                );

                print('ADDING TEXT MESSAGE TO CONTROLLER');
                controller.add(currentMessage);
                continue;
              }

              if (payloadType == 'json') {
                print('HANDLING JSON PAYLOAD');
                final jsonData = payload['data'];
                print('JSON DATA: $jsonData');

                if (jsonData is Map && (jsonData['type'] == 'cards_of_market' ||
                    jsonData['type'] == 'cards_of_asset' ||
                    jsonData['type'] == 'table_of_asset' ||
                    jsonData['type'] == 'table_of_market')) {

                  print('DETECTED TABLE/CARDS DATA');
                  print('JSON DATA TYPE: ${jsonData['type']}');

                  if (!tableReceived) {
                    tableReceived = true;
                    print('SET tableReceived = true');
                  }

                  final heading = (jsonData['heading']?.toString() ?? 'Results');
                  final dataList = (jsonData['list'] as List?) ?? const [];
                  final rows = dataList.map<Map<String, dynamic>>((e) =>
                  (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}
                  ).toList();

                  print('HEADING: "$heading"');
                  print('DATA LIST LENGTH: ${dataList.length}');
                  print('PROCESSED ROWS LENGTH: ${rows.length}');

                  if (combinedHeading == 'Results') {
                    combinedHeading = heading;
                    print('UPDATED combinedHeading TO: "$combinedHeading"');
                  }

                  print('BEFORE - allTableRows LENGTH: ${allTableRows.length}');
                  allTableRows.addAll(rows);
                  print('AFTER - allTableRows LENGTH: ${allTableRows.length}');

                  tableData = {
                    'heading': combinedHeading,
                    'rows': allTableRows,
                    'type': jsonData['type'].toString(),
                  };

                  print('CREATED tableData:');
                  print('  heading: ${tableData!['heading']}');
                  print('  type: ${tableData!['type']}');
                  print('  rows count: ${(tableData!['rows'] as List).length}');

                  final displayText = textBeforeTable + '___TABLE_PLACEHOLDER___' + textAfterTable;
                  print('DISPLAY TEXT WITH PLACEHOLDER: "$displayText"');

                  currentMessage = ChatMessage(
                    id: messageId,
                    text: displayText,
                    isUser: false,
                    timestamp: currentMessage.timestamp,
                    isComplete: false,
                    currentStatus: null,
                    isTable: true,
                    structuredData: tableData,
                    messageType: 'kv_table',
                  );

                  print('ADDING TABLE MESSAGE TO CONTROLLER');
                  controller.add(currentMessage);
                }
                continue;
              }

              if (payloadType == 'complete') {
                print('HANDLING COMPLETE PAYLOAD');
                streamCompleted = true;
                if (debugLog) print('RESPONSE COMPLETE - Setting isComplete=true');
                print('SET streamCompleted = true');

                String displayText = textBeforeTable;
                if (tableReceived) {
                  displayText += '___TABLE_PLACEHOLDER___';
                  displayText += textAfterTable;
                }

                print('FINAL textBeforeTable: "$textBeforeTable"');
                print('FINAL textAfterTable: "$textAfterTable"');
                print('FINAL tableReceived: $tableReceived');
                print('FINAL displayText: "$displayText"');

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

                print('ADDING COMPLETE MESSAGE TO CONTROLLER');
                controller.add(currentMessage);
                continue;
              }
            }
          }
        },
        onDone: () {
          print('\n=== STREAM ON DONE ===');
          print('streamCompleted: $streamCompleted');
          print('textBeforeTable final: "$textBeforeTable"');
          print('textAfterTable final: "$textAfterTable"');
          print('tableReceived final: $tableReceived');
          print('allTableRows final count: ${allTableRows.length}');

          resetInactivityTimer();
          inactivityTimer?.cancel();

          if (!streamCompleted) {
            print('STREAM NOT COMPLETED - FORCING COMPLETION');
            String finalText = textBeforeTable;
            if (tableReceived) {
              finalText += '___TABLE_PLACEHOLDER___';
              finalText += textAfterTable;
            }

            print('FORCING FINAL TEXT: "$finalText"');

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
          }

          controller.close();
          if (debugLog) print('STREAM DONE - Controller closed');
        },
        onError: (e) {
          print('\n=== STREAM ON ERROR ===');
          print('ERROR: $e');
          print('ERROR TYPE: ${e.runtimeType}');

          inactivityTimer?.cancel();
          if (debugLog) print('STREAM ERROR: $e');
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
  // Future<Stream<ChatMessage>> sendMessageWithStreamingRespond({
  //   required String uid,
  //   String? sessionId,
  //   required String message,
  //   String? firstMessageForTitle,
  //   bool debugLog = false,
  // }) async {
  //   await SessionManager.checkTokenValidityAndRefresh();
  //
  //   final stats = _StreamDebugStats();
  //   if (debugLog) {
  //     final preview = message.length > 120 ? '${message.substring(0, 120)}…' : message;
  //     print('START STREAM - /chat/respond');
  //     print('uid: $uid');
  //     print('sessionId: ${sessionId ?? "<null - will be created by server>"}');
  //     print('user message: "$preview"');
  //   }
  //
  //   try {
  //    //final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
  //     final String _baseUrl = "http://localhost:8000";
  //     //final String _baseUrl = 'http://192.168.1.5:8000';
  //     final url = Uri.parse('$_baseUrl/chat/respond');
  //
  //     final req = http.Request('POST', url);
  //     req.headers.addAll({
  //       'Content-Type': 'application/json',
  //       'Accept': 'text/event-stream',
  //       if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
  //       if (SessionManager.refreshToken != null) 'X-Refresh-Token': SessionManager.refreshToken!,
  //     });
  //
  //     final body = <String, dynamic>{
  //       'uid': uid,
  //       'input': utf8.decode(message.codeUnits),
  //       if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
  //     };
  //     req.body = jsonEncode(body);
  //
  //     if (debugLog) {
  //       print('POST $_baseUrl/chat/respond');
  //       print('headers: ${req.headers}');
  //       print('body: ${req.body}');
  //     }
  //
  //     final streamedResponse = await req.send().timeout(
  //       const Duration(seconds: 10),
  //       onTimeout: () => throw TimeoutException('Connection timeout after 30 seconds'),
  //     );
  //
  //     if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
  //       final errorBody = await streamedResponse.stream.bytesToString();
  //       if (debugLog) {
  //         print('Non-2xx status: ${streamedResponse.statusCode}');
  //         print('Body: $errorBody');
  //       }
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
  //     );
  //
  //     String buffer = '';
  //     String textBeforeTable = '';
  //     String textAfterTable = '';
  //     bool tableReceived = false;
  //
  //     List<Map<String, dynamic>> allTableRows = [];
  //     String combinedHeading = 'Results';
  //     Map<String, dynamic>? tableData;
  //
  //     Timer? inactivityTimer;
  //     void resetInactivityTimer() {
  //       inactivityTimer?.cancel();
  //       inactivityTimer = Timer(const Duration(seconds: 60), () {
  //         if (debugLog) print('Inactivity timeout (60s) - closing stream');
  //         controller.addError(TimeoutException('Stream inactive timeout', const Duration(seconds: 60)));
  //         controller.close();
  //       });
  //     }
  //     resetInactivityTimer();
  //
  //     streamedResponse.stream.transform(utf8.decoder).listen(
  //           (chunk) {
  //         stats.onRawChunk(chunk);
  //         if (debugLog) print('CHUNK bytes=${chunk.length}');
  //
  //         resetInactivityTimer();
  //         buffer += chunk;
  //
  //         final lines = buffer.split('\n');
  //         buffer = lines.removeLast();
  //
  //         for (final raw in lines) {
  //           stats.onLine(raw);
  //           final line = raw.trim();
  //
  //           if (line.isEmpty) {
  //             if (debugLog) print('(empty line)');
  //             continue;
  //           }
  //           if (!line.startsWith('data:')) {
  //             if (debugLog) print('(non-data line) "$line"');
  //             continue;
  //           }
  //
  //           final jsonText = line.substring(5).trim();
  //           if (debugLog) {
  //             print('\n' + '=' * 80);
  //             print('SSE DATA LINE (#${stats.dataLines})');
  //             print('raw: $jsonText');
  //           }
  //           if (jsonText.isEmpty) {
  //             if (debugLog) print('empty data payload');
  //             continue;
  //           }
  //
  //           Map<String, dynamic> decoded;
  //           try {
  //             decoded = jsonDecode(jsonText) as Map<String, dynamic>;
  //           } catch (e) {
  //             stats.badJsonLines++;
  //             if (debugLog) print('JSON parse error: $e');
  //             continue;
  //           }
  //
  //           final type = (decoded['type'] ?? '').toString();
  //           final payload = decoded['payload'] as Map<String, dynamic>? ?? const {};
  //           final payloadType = (payload['type'] ?? '').toString();
  //
  //           stats.onParsedEvent(type: type, payloadType: payloadType);
  //           stats.markFirstChunkIfNeeded();
  //
  //           if (debugLog) {
  //             print('event.type: "$type"');
  //             if (payload.isNotEmpty) print('payload.type: "$payloadType"');
  //           }
  //
  //           // 1) Handle session_created
  //           if (type == 'session_created') {
  //             stats.sessionCreated++;
  //             final sid = decoded['session_id']?.toString();
  //             if (debugLog) print('session_created: session_id=$sid');
  //             if (sid != null && sid.isNotEmpty) {
  //               _adoptServerSession(sid);
  //               if (firstMessageForTitle != null && firstMessageForTitle.trim().isNotEmpty) {
  //                 updateSessionTitle(sid, firstMessageForTitle);
  //               }
  //             }
  //             continue;
  //           }
  //
  //           // 2) Handle status_update
  //           if (type == 'status_update') {
  //             stats.statusUpdates++;
  //             final reason = (payload['reason'] ?? '').toString();
  //             if (debugLog) print('status_update: "$reason"');
  //
  //             String displayText = textBeforeTable;
  //             if (tableReceived) {
  //               displayText += '___TABLE_PLACEHOLDER___';
  //               displayText += textAfterTable;
  //             }
  //
  //             currentMessage = ChatMessage(
  //               id: messageId,
  //               text: displayText,
  //               isUser: false,
  //               timestamp: currentMessage.timestamp,
  //               isComplete: false,
  //               currentStatus: reason,
  //               isTable: tableReceived,
  //               structuredData: tableData,
  //               messageType: tableReceived ? 'kv_table' : null,
  //             );
  //             controller.add(currentMessage);
  //             continue;
  //           }
  //
  //           // 3) Handle response events
  //           if (type == 'response') {
  //             if (payloadType == 'text') {
  //               stats.responseTextChunks++;
  //               final data = (payload['data'] ?? '').toString();
  //               final prevLenBefore = textBeforeTable.length;
  //               final prevLenAfter = textAfterTable.length;
  //
  //               if (tableReceived) {
  //                 textAfterTable += data;
  //                 stats.textAfterChars += (textAfterTable.length - prevLenAfter);
  //               } else {
  //                 textBeforeTable += data;
  //                 stats.textBeforeChars += (textBeforeTable.length - prevLenBefore);
  //               }
  //
  //               if (debugLog) {
  //                 final where = tableReceived ? 'AFTER_TABLE' : 'BEFORE_TABLE';
  //                 final preview = data.length > 140 ? '${data.substring(0, 140)}…' : data;
  //                 print('response:text [$where] +${data.length} chars');
  //                 print('   preview: "$preview"');
  //                 print('   totals so far - before:${stats.textBeforeChars}, after:${stats.textAfterChars}');
  //               }
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
  //                 currentStatus: null, // Clear status when text arrives
  //                 isTable: tableReceived,
  //                 structuredData: tableData,
  //                 messageType: tableReceived ? 'kv_table' : null,
  //               );
  //               controller.add(currentMessage);
  //               continue;
  //             }
  //
  //             if (payloadType == 'json') {
  //               stats.responseJsonChunks++;
  //               final jsonData = payload['data'];
  //               if (debugLog) {
  //                 final pretty = const JsonEncoder.withIndent('  ').convert(jsonData);
  //                 print('response:json payload:\n$pretty');
  //               }
  //
  //               if (jsonData is Map && (jsonData['type'] == 'cards_of_market' ||
  //                   jsonData['type'] == 'cards_of_asset'  ||
  //                   jsonData['type'] == 'table_of_asset'||
  //                   jsonData['type'] == 'table_of_market')) {
  //
  //                 final heading = (jsonData['heading']?.toString() ?? 'Results');
  //                 final dataList = (jsonData['list'] as List?) ?? const [];
  //                 final rows = dataList.map<Map<String, dynamic>>((e) =>
  //                 (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}
  //                 ).toList();
  //
  //                 if (!tableReceived) {
  //                   tableReceived = true;
  //                   combinedHeading = heading;
  //                 }
  //                 allTableRows.addAll(rows);
  //                 stats.jsonRowsAccumulated = allTableRows.length;
  //
  //                 tableData = {
  //                   'heading': combinedHeading,
  //                   'rows': allTableRows,
  //                   'type': jsonData['type'].toString(),
  //                 };
  //
  //                 if (debugLog) {
  //                   print('table/cards chunk - heading="$combinedHeading", added=${rows.length}, totalRows=${allTableRows.length}, type=${jsonData['type']}');
  //                   if (rows.isNotEmpty) {
  //                     final sample = rows.first;
  //                     print('   sample row keys: ${sample.keys.toList()}');
  //                   }
  //                 }
  //
  //                 final displayText = textBeforeTable + '___TABLE_PLACEHOLDER___' + textAfterTable;
  //
  //                 currentMessage = ChatMessage(
  //                   id: messageId,
  //                   text: displayText,
  //                   isUser: false,
  //                   timestamp: currentMessage.timestamp,
  //                   isComplete: false,
  //                   currentStatus: null, // Clear status when table arrives
  //                   isTable: true,
  //                   structuredData: tableData,
  //                   messageType: 'kv_table',
  //                 );
  //                 controller.add(currentMessage);
  //               }
  //               continue;
  //             }
  //
  //             if (payloadType == 'complete') {
  //               stats.responseCompletes++;
  //               if (debugLog) print('response:complete');
  //
  //               String displayText = textBeforeTable;
  //               if (tableReceived) {
  //                 displayText += '___TABLE_PLACEHOLDER___';
  //                 displayText += textAfterTable;
  //               }
  //
  //               currentMessage = ChatMessage(
  //                 id: currentMessage.id,
  //                 text: displayText,
  //                 isUser: currentMessage.isUser,
  //                 timestamp: currentMessage.timestamp,
  //                 isComplete: true,
  //                 currentStatus: null,
  //                 isTable: tableReceived,
  //                 structuredData: tableData,
  //                 messageType: tableReceived ? 'kv_table' : null,
  //               );
  //               controller.add(currentMessage);
  //               continue;
  //             }
  //           }
  //
  //           if (debugLog) {
  //             print('Unhandled event. type="$type" payload.type="$payloadType"');
  //           }
  //         }
  //       },
  //       onDone: () {
  //         resetInactivityTimer();
  //         inactivityTimer?.cancel();
  //
  //         String finalText = textBeforeTable;
  //         if (tableReceived) {
  //           finalText += '___TABLE_PLACEHOLDER___';
  //           finalText += textAfterTable;
  //         }
  //
  //         controller.add(ChatMessage(
  //           id: currentMessage.id,
  //           text: finalText,
  //           isUser: false,
  //           timestamp: currentMessage.timestamp,
  //           isComplete: true,
  //           currentStatus: null,
  //           isTable: tableReceived,
  //           structuredData: tableData,
  //           messageType: tableReceived ? 'kv_table' : null,
  //         ));
  //         controller.close();
  //
  //         stats.printSummary(debugLog: debugLog);
  //       },
  //       onError: (e) {
  //         inactivityTimer?.cancel();
  //         if (debugLog) print('STREAM ERROR: $e');
  //         stats.printSummary(debugLog: debugLog);
  //         controller.addError(e);
  //         controller.close();
  //       },
  //     );
  //
  //     return controller.stream;
  //   } catch (e) {
  //     if (debugLog) print('sendMessageWithStreamingRespond setup error: $e');
  //     rethrow;
  //   }
  // }












  // Future<void> updateSessionTitle(String sessionId, String newTitle) async {
  //   try {
  //     await _apiService.postStream(
  //       endpoint: '/chat/session/$sessionId/title',
  //       body: {'title': newTitle},
  //     );
  //   } catch (e) {
  //     debugPrint("❌ Failed to update session title: $e");
  //   }
  // }














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
    final currentMessages = _messagesSubject.value;

    int userCount = 0;
    int botCompleteCount = 0;

    for (var m in currentMessages) {
      if (m['role'] == 'user') {
        userCount++;
      }
      if (m['role'] == 'bot' && (m['isComplete'] == true)) {
        botCompleteCount++;
      }
    }

    print("🔍 First message check:");
    print("  userCount: $userCount");
    print("  botCompleteCount: $botCompleteCount");
    print("  _showNewChatButton: $_showNewChatButton");
    print("  _isTyping: ${_isTypingSubject.value}");

    final completed = userCount >= 1 && botCompleteCount >= 1;

    if (completed) {
      if (!_showNewChatButton) {
        _showNewChatButton = true;
        print("✅ Setting showNewChatButton = true");
      }

      // ✅ CRITICAL FIX: Only notify first message complete when NOT typing
      if (!_firstMessageCompleteSubject.value && !_isTypingSubject.value) {
        _firstMessageCompleteSubject.add(true);
        print("✅ Notifying first message complete (bot finished typing)");
      } else if (_isTypingSubject.value) {
        print("🚫 Not notifying first message complete - bot still typing");
      }
    }
  }




  void clear() {
    print("🧹 ChatService.clear() called");

    // Clear messages and reset streams
    _messagesSubject.add([]);
    _firstMessageCompleteSubject.add(false);
    _hasLoadedMessagesSubject.add(false);
    _isTypingSubject.add(false);

    // Cancel any ongoing streams
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentStreamingId = '';

    // Reset UI state
    _showNewChatButton = false;

    // Note: Don't reset scroll lock here, let individual methods control it
    print("✅ ChatService cleared - messages reset, streams cancelled");
  }

  void dispose() {
    _messagesSubject.close();
    _isTypingSubject.close();
    _hasLoadedMessagesSubject.close();
    _firstMessageCompleteSubject.close();
    _streamSubscription?.cancel();
    _isScrollLocked.close();
    _chatViewportHeightSubject.close();
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






