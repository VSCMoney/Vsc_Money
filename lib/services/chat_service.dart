import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../controllers/session_manager.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../models/chat_history_model.dart';
import '../services/api_service.dart';
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
  final _isScrollLocked = BehaviorSubject<bool>.seeded(true);

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

    final currentLockState = _isScrollLocked.value;
    clear();

    if (!_isScrollLocked.isClosed) {
      _isScrollLocked.add(currentLockState);
    }

    _currentSession = null;
    _showNewChatButton = false;

    // ✅ ADD: Reset first message complete flag
    _firstMessageCompleteSubject.add(false);

    print("✅ ChatService reset complete");
  }

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


  Map<String, List<Map<String, Object>>> get sessionMessagesCache => _sessionMessagesCache;

  List<Map<String, Object>> get messages => _messagesSubject.value;
  bool get hasLoadedMessages => _hasLoadedMessagesSubject.value;
  bool get isTyping => _isTypingSubject.value;
  bool get firstMessageComplete => _firstMessageCompleteSubject.value;

  String _currentStreamingId = '';
  StreamSubscription<ChatMessage>? _streamSubscription;



  ChatSession? get currentSession => _currentSession;
  bool get isInitialized => _isInitialized;
  bool get showNewChatButton => _showNewChatButton;
  bool get isLoadingSession => _isLoadingSession;
  String? get error => _error;
  List<ChatSession> get sessions => _sessions;



  static const TextStyle _measureStyle = TextStyle(fontSize: 16, height: 1.4);
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();

  List<MessagePair> pairs = [];
  bool shouldPin = false;
  double adjustment = 0;

  final _pairSubject = BehaviorSubject<List<MessagePair>>.seeded([]);
  final _chunkSubject = BehaviorSubject<String>.seeded("");


  Stream<List<MessagePair>> get pairStream => _pairSubject.stream;
  Stream<String> get chunkStream => _chunkSubject.stream;







  Future<void> sendNewMessage({
    required Message message,
    required BuildContext context,
    bool isThreadMode = false,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    shouldPin = true;
    _isTypingSubject.add(true);

    final messageText = (message.content ?? '').trim();
    textController.clear();

    final newPair = MessagePair(
      userMessage: message,
      isStreaming: true,
    );
    pairs.add(newPair);
    _pairSubject.add(List.from(pairs));

    await Future.delayed(const Duration(milliseconds: 200));

    // ✅ WAIT for next frame to ensure appBar height is updated
    await Future.delayed(const Duration(milliseconds: 50));

    // NOW calculate adjustment with current (updated) appBar height
    adjustment = _calculateKeyboardAwareAdjustment(
      message.content!,
      context,
      isThreadMode: isThreadMode,
    );

    if (scrollController.hasClients) {
      // Wait for layout to settle
      await Future.delayed(const Duration(milliseconds: 100));

      final targetPosition = scrollController.position.maxScrollExtent - adjustment;

      print("📍 Target scroll: $targetPosition");
      print("  maxScrollExtent: ${scrollController.position.maxScrollExtent}");
      print("  adjustment: $adjustment");

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    }

    // if (scrollController.hasClients) {
    //   scrollController.animateTo(
    //     scrollController.position.maxScrollExtent,
    //     duration: const Duration(milliseconds: 650),
    //     curve: Curves.easeIn,
    //   );
    // }

    await _startRealBotResponse(pairs.length - 1, messageText);
  }




  Future<void> _startRealBotResponse(int pairIndex, String userMessage) async {
    print("🟢 _startRealBotResponse called for pair $pairIndex");
    print("🟢 Current pairs count: ${pairs.length}");
    if (pairIndex >= pairs.length) return;

    await Future.delayed(const Duration(milliseconds: 600));

    final botResponse = Message(
      byUser: false,
      content: "",
      streaming: true,
      id: UniqueKey().toString(),
    );

    if (pairIndex < pairs.length) {
      pairs[pairIndex].botResponses.add(botResponse);
      pairs[pairIndex].isStreaming = true;
      _pairSubject.add(List.from(pairs));
    }

    try {
      final uid = SessionManager.uid;
      if (uid == null || uid.isEmpty) {
        throw StateError('No UID. Log in first.');
      }
      print("🚨 About to call sendMessageWithStreamingRespond");

      final responseStream = await sendMessageWithStreamingRespond(
        uid: uid,
        sessionId: _currentSession?.id,
        message: userMessage,
        firstMessageForTitle: !messages.any((m) => m['role'] == 'user') ? userMessage : null,
      );

      _streamSubscription = responseStream.listen(
            (chatMessage) {
          if (pairIndex >= pairs.length) return;

          final status = chatMessage.currentStatus?.trim();
          if (status != null && status.isNotEmpty) {
            pairs[pairIndex].currentStatus = status;
            pairs[pairIndex].isStreaming = true;
            _pairSubject.add(List.from(pairs));
            return;
          }

          if (pairs[pairIndex].botResponses.isEmpty) {
            pairs[pairIndex].botResponses.add(
              Message(byUser: false, content: "", streaming: true, id: UniqueKey().toString()),
            );
          }
          final lastIdx = pairs[pairIndex].botResponses.length - 1;
          final currentBot = pairs[pairIndex].botResponses[lastIdx];

          // ✅ UPDATE: Use chatMessage.text directly (it already has placeholder)
          final incomingText = chatMessage.text;

          print('📨 Received text (length: ${incomingText.length}):');
          if (incomingText.contains('___TABLE_PLACEHOLDER___')) {
            print('   ✅ Contains placeholder!');
          } else {
            print('   ❌ NO placeholder found');
          }

          pairs[pairIndex].botResponses[lastIdx] = currentBot.copyWith(
            content: incomingText, // ✅ Use chatMessage.text directly
            streaming: !chatMessage.isComplete,
            isTable: chatMessage.isTable,
            structuredData: chatMessage.structuredData,
            messageType: chatMessage.messageType,
          );

          pairs[pairIndex].isStreaming = !chatMessage.isComplete;
          pairs[pairIndex].currentStatus = null;
          _pairSubject.add(List.from(pairs));

          // Only send chunks for text (not for structured data)
          if (!chatMessage.isTable && incomingText.isNotEmpty) {
            _chunkSubject.add(incomingText);
          }

          if (chatMessage.isComplete) {
            print('✅ Message complete - final content length: ${incomingText.length}');
            _isTypingSubject.add(false);
            lockScroll();
            _checkAndNotifyFirstMessageComplete();
          }
        },
        onError: (e) {
          _isTypingSubject.add(false);
          if (pairIndex < pairs.length && pairs[pairIndex].botResponses.isNotEmpty) {
            final lastIdx = pairs[pairIndex].botResponses.length - 1;
            final currentBot = pairs[pairIndex].botResponses[lastIdx];
            pairs[pairIndex].botResponses[lastIdx] = currentBot.copyWith(
              content: "Connection failed. Please try again.",
              streaming: false,
              currentStatus: null,
            );
            pairs[pairIndex].isStreaming = false;
            pairs[pairIndex].currentStatus = null;
            _pairSubject.add(List.from(pairs));
          }
        },
        onDone: () {
          _isTypingSubject.add(false);
          if (pairIndex < pairs.length) {
            pairs[pairIndex].isStreaming = false;
            pairs[pairIndex].currentStatus = null;
            _pairSubject.add(List.from(pairs));
          }
          lockScroll();
          _checkAndNotifyFirstMessageComplete();
        },
      );

    } catch (e) {
      print("❌ Real stream setup error: $e");
      _isTypingSubject.add(false);

      if (pairIndex < pairs.length && pairs[pairIndex].botResponses.isNotEmpty) {
        final currentBotResponse = pairs[pairIndex].botResponses.last;
        pairs[pairIndex].botResponses[pairs[pairIndex].botResponses.length - 1] =
            currentBotResponse.copyWith(
              content: "Failed to connect. Please try again.",
              streaming: false,
              currentStatus: null,
            );
        pairs[pairIndex].isStreaming = false;
        pairs[pairIndex].updateStatus(null);
        _pairSubject.add(List.from(pairs));
      }
    }
  }
  // double _calculateKeyboardAwareAdjustment(String content, BuildContext context, {bool isThreadMode = false}) {
  //   final mediaQuery = MediaQuery.of(context);
  //   final platform = Theme.of(context).platform;
  //
  //   // Current state values
  //   final currentScreenHeight = mediaQuery.size.height;
  //   final keyboardHeight = mediaQuery.viewInsets.bottom;
  //
  //   final topPadding = mediaQuery.padding.top;
  //   final bottomPadding = mediaQuery.padding.bottom;
  //   const appBarHeight = kToolbarHeight;
  //
  //   final availableHeight = currentScreenHeight - topPadding - bottomPadding - appBarHeight;
  //
  //   final keyboardCompensation = keyboardHeight;
  //
  //   // ChatInputWidget height calculation
  //   final textLines = _calculateTextLines(content);
  //   const singleLineHeight = 55.0;
  //   const lineHeight = 15.0;
  //   const containerVerticalPadding = 20.0;
  //   const actionsBarHeight = 44.0;
  //   const bottomSpacing = 10.0;
  //   final extraGap = textLines >= 2 ? 6.0 : 0.0;
  //
  //   final normalHeight = singleLineHeight + (textLines - 1) * lineHeight;
  //   final textFieldHeight = normalHeight.clamp(singleLineHeight, singleLineHeight + 9 * lineHeight);
  //
  //   final totalChatInputHeight = containerVerticalPadding +
  //       textFieldHeight + actionsBarHeight + bottomSpacing + extraGap;
  //
  //   final screenWidth = mediaQuery.size.width;
  //   final messageWidth = screenWidth * 0.6;
  //
  //   // Original message height calculation
  //   final originalMessageHeight = MessageMetrics.height(
  //     text: content,
  //     maxWidth: messageWidth - 28,
  //     style: const TextStyle(
  //       fontFamily: 'DM Sans',
  //       fontSize: 16,
  //       fontWeight: FontWeight.w500,
  //       height: 1.9,
  //     ),
  //   );
  //
  //   // CAP MESSAGE HEIGHT AT 150px
  //   const double MAX_MESSAGE_HEIGHT = 150.0;
  //   final cappedMessageHeight = originalMessageHeight > MAX_MESSAGE_HEIGHT
  //       ? MAX_MESSAGE_HEIGHT
  //       : originalMessageHeight;
  //
  //   int dynamicOffset;
  //
  //   if (platform == TargetPlatform.iOS) {
  //     // iOS offsets (current working values)
  //     if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
  //       dynamicOffset = 120;
  //     } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 90) {
  //       dynamicOffset = 90;
  //     } else if (cappedMessageHeight > 90 && cappedMessageHeight <= 150) {
  //       dynamicOffset = 70;
  //     }else if (cappedMessageHeight ==120 ) {
  //       dynamicOffset = 60;
  //     }
  //     else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
  //       dynamicOffset = 50;
  //     } else {
  //       dynamicOffset = 90;
  //     }
  //   }
  //   else if (platform == TargetPlatform.android) {
  //     // Calculate base offset based on message height
  //     int baseOffset;
  //
  //     if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
  //       baseOffset = 110;
  //     } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 90) {
  //       baseOffset = 90;
  //     } else if (originalMessageHeight == 90) {
  //       baseOffset = 50;
  //     } else if (cappedMessageHeight >= 120 && cappedMessageHeight <= 150) {
  //       baseOffset = 60;
  //     } else {
  //       baseOffset = 120;
  //     }
  //
  //     // Thread mode: add 60px for bottom sheet header + padding
  //     dynamicOffset = isThreadMode ? baseOffset + 300 : baseOffset;
  //
  //     print("Android ${isThreadMode ? 'Thread' : 'Normal'} Mode - dynamicOffset: $dynamicOffset");
  //   }
  //   else {
  //     dynamicOffset = 90;
  //   }
  //
  //   // Calculate adjustment using CAPPED message height
  //   var adjustment = availableHeight - totalChatInputHeight - cappedMessageHeight - 30 + keyboardCompensation - dynamicOffset;
  //
  //   print("🔧 Platform-Specific Adjustment calculation:");
  //   print("  platform: ${platform.name}");
  //   print("  isThreadMode: $isThreadMode");
  //   print("  originalMessageHeight: $originalMessageHeight");
  //   print("  cappedMessageHeight: $cappedMessageHeight");
  //   print("  isMessageCapped: ${originalMessageHeight > MAX_MESSAGE_HEIGHT}");
  //   print("  dynamicOffset: $dynamicOffset");
  //   print("  keyboardHeight: $keyboardHeight");
  //   print("  final adjustment: $adjustment");
  //
  //   // Guard: never negative
  //   if (adjustment.isNaN || adjustment.isInfinite) adjustment = 0;
  //   return adjustment.clamp(0, 2000);
  // }


  bool _isSmallIPhone13_14(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double h = math.max(mq.size.height, mq.size.width);
    return h >= 810.0 && h <= 846.0;
  }







  double _calculateKeyboardAwareAdjustment(String content, BuildContext context,{bool isThreadMode = false}) {
    final mediaQuery = MediaQuery.of(context);
    final platform = Theme.of(context).platform;

    // Current state values
    final currentScreenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    const appBarHeight = kToolbarHeight;

    final availableHeight = currentScreenHeight - topPadding - bottomPadding - appBarHeight;

    final keyboardCompensation = keyboardHeight;

    // ChatInputWidget height calculation
    final textLines = _calculateTextLines(content);
    const singleLineHeight = 55.0;
    const lineHeight = 15.0;
    const containerVerticalPadding = 20.0;
    const actionsBarHeight = 44.0;
    const bottomSpacing = 10.0;
    final extraGap = textLines >= 2 ? 6.0 : 0.0;

    final normalHeight = singleLineHeight + (textLines - 1) * lineHeight;
    final textFieldHeight = normalHeight.clamp(singleLineHeight, singleLineHeight + 9 * lineHeight);

    final totalChatInputHeight = containerVerticalPadding +
        textFieldHeight + actionsBarHeight + bottomSpacing + extraGap;

    final screenWidth = mediaQuery.size.width;
    final messageWidth = screenWidth * 0.6;

    // Original message height calculation
    final originalMessageHeight = MessageMetrics.height(
      text: content,
      maxWidth: messageWidth - 28,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.9,
      ),
    );

    // CAP MESSAGE HEIGHT AT 150px
    const double MAX_MESSAGE_HEIGHT = 150.0;
    final cappedMessageHeight = originalMessageHeight > MAX_MESSAGE_HEIGHT
        ? MAX_MESSAGE_HEIGHT
        : originalMessageHeight;

    int dynamicOffset;


    if (platform == TargetPlatform.iOS) {
      final bool isSmall1314 = _isSmallIPhone13_14(context);

      if (isSmall1314) {
        if (isThreadMode) {
          if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
            dynamicOffset = 95;
          } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
            dynamicOffset = 78;
          } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 110) {
            dynamicOffset = 65;
          } else if (cappedMessageHeight >= 120 && cappedMessageHeight < 150) {
            dynamicOffset = 58;
          } else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
            dynamicOffset = 55;
          } else {
            dynamicOffset = 100;
          }
          print("iOS Small 13/14 Thread - dynamicOffset: $dynamicOffset");
        } else {
          print("this is iphone 14");
          if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
            dynamicOffset = 100;
          } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
            dynamicOffset = 85;
          } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 110) {
            dynamicOffset = 70;
          } else if (cappedMessageHeight >= 120 && cappedMessageHeight < 150) {
            dynamicOffset = 58;
          } else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
            dynamicOffset = 55;
          } else {
            dynamicOffset = 85;
          }
          print("iOS Small 13/14 Normal - dynamicOffset: $dynamicOffset");
        }

      } else {
        // 🔸 Your existing iOS logic for other models (14 Pro/Max, 15, etc.)
        if (isThreadMode) {
          if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
            dynamicOffset = 105; // 130 + 20
          } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
            dynamicOffset = 85;  // 110 + 20
          } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 150) {
            dynamicOffset = 75;  // 90 + 20
          } else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
            dynamicOffset = 60;  // 70 + 20
          } else {
            dynamicOffset = 110; // 90 + 20
          }
          print("iOS Thread Mode - dynamicOffset: $dynamicOffset");
        } else {
          if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
            dynamicOffset = 120;
          } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
            dynamicOffset = 90;
          } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 110) {
            dynamicOffset = 80;
          } else if (cappedMessageHeight >= 120 && cappedMessageHeight < 140) {
            dynamicOffset = 60;
          } else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
            dynamicOffset = 60;
          } else {
            dynamicOffset = 90;
          }
        }
      }
    }



    // if (platform == TargetPlatform.iOS) {
    //   if (isThreadMode) {
    //     // iOS Thread Mode - Add 20px to normal offsets
    //     if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
    //       dynamicOffset = 105; // 130 + 20
    //     } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
    //       dynamicOffset = 85; // 110 + 20
    //     } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 150) {
    //       dynamicOffset = 75; // 90 + 20
    //     } else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
    //       dynamicOffset = 60; // 70 + 20
    //     } else {
    //       dynamicOffset = 110; // 90 + 20
    //     }
    //     print("iOS Thread Mode - dynamicOffset: $dynamicOffset");
    //   } else {
    //     // iOS Normal Mode
    //     if (cappedMessageHeight >= 30 && cappedMessageHeight <= 50) {
    //       dynamicOffset = 105;
    //     } else if (cappedMessageHeight >= 60 && cappedMessageHeight <= 80) {
    //       dynamicOffset = 90;
    //     } else if (cappedMessageHeight >= 90 && cappedMessageHeight < 110) {
    //       dynamicOffset = 67;
    //     } else if (cappedMessageHeight >= 120 && cappedMessageHeight < 140) {
    //       dynamicOffset = 60;
    //     }
    //     else if (cappedMessageHeight >= 150 && cappedMessageHeight <= 250) {
    //       dynamicOffset = 60;
    //     } else {
    //       dynamicOffset = 90;
    //     }
    //   }
    // }







    else if (platform == TargetPlatform.android) {
      final mq = MediaQuery.of(context);
      final availH = mq.size.height - mq.padding.top - mq.padding.bottom - kToolbarHeight;

      // 1) Reference visible height you tuned on (change if your dev phone differs)
      const double REF_AVAIL_H = 800.0;

      // 2) Message bubble height at runtime (same as you do)
      final bubbleW = (mq.size.width * 0.6) - 28;
      final h = MessageMetrics.height(
        text: content,
        maxWidth: bubbleW,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.9,
        ),
      ).clamp(30.0, 150.0);

      // 3) Multi-stop interpolation helper
      double lerpStops(double x, List<double> s, List<double> v) {
        if (x <= s.first) return v.first;
        if (x >= s.last)  return v.last;
        int i = 0;
        while (i < s.length - 1 && !(x >= s[i] && x <= s[i + 1])) i++;
        final t = (x - s[i]) / (s[i + 1] - s[i]);
        return v[i] + (v[i + 1] - v[i]) * t;
      }

      const stops = [30.0, 60.0, 90.0, 120.0, 150.0];

      // 4) These are your tuned OFFSETS on your reference phone (in PX on REF_AVAIL_H)
      //    If 30px bubble → 100 worked on your dev phone, put 100 in the list, etc.
      final normalPx = [110.0, 75.0, 65.0, 45.0, 30.0];
      final threadPx = [200.0, 180.0, 160.0, 140.0, 140.0];

      // 5) Convert PX@ref to PERCENT of ref height (so they scale automatically)
      final normalPct = normalPx.map((v) => v / REF_AVAIL_H).toList(growable: false);
      final threadPct = threadPx.map((v) => v / REF_AVAIL_H).toList(growable: false);

      // 6) Pick percent based on current message height, then scale by current availH
      final basePercent = isThreadMode
          ? lerpStops(h, stops, threadPct.cast<double>())
          : lerpStops(h, stops, normalPct.cast<double>());

      double off = basePercent * availH;

      // 7) Tiny adjustment for gesture/bottom inset differences (0..8dp)
      off += (mq.padding.bottom).clamp(0.0, 16.0) * 0.5;

      // 8) Gentle safety bounds relative to screen, not hard numbers
      final minOff = (availH * 0.05).clamp(30.0, 90.0);
      final maxOff = (availH * 0.30).clamp(140.0, 300.0);
      dynamicOffset = off.clamp(minOff, maxOff).round();
    }


    else {
      dynamicOffset = 90;
    }










    var adjustment = availableHeight - totalChatInputHeight - cappedMessageHeight - 30 + keyboardCompensation - dynamicOffset;

    print("🔧 Platform-Specific Adjustment calculation:");
    print("  platform: ${platform.name}");
    print("  originalMessageHeight: $originalMessageHeight");
    print("  cappedMessageHeight: $cappedMessageHeight");
    print("  isMessageCapped: ${originalMessageHeight > MAX_MESSAGE_HEIGHT}");
    print("  dynamicOffset: $dynamicOffset");
    print("  keyboardHeight: $keyboardHeight");
    print("  final adjustment: $adjustment");

    // Guard: never negative
    if (adjustment.isNaN || adjustment.isInfinite) adjustment = 0;
    return adjustment.clamp(0, 2000);
  }






  int _calculateTextLines(String content) {
    if (content.isEmpty) return 1;
    int lines = content.split('\n').length;
    const avgCharsPerLine = 36;
    final wrapped = (content.length / avgCharsPerLine).ceil();
    return math.max(lines, wrapped).clamp(1, 10);
  }





  final _chatViewportHeightSubject = BehaviorSubject<double>.seeded(0.0);
  bool _viewportFixed = false;

  double get chatViewportHeight => _chatViewportHeightSubject.value;
  bool get isViewportFixed => _viewportFixed;

  void commitViewportOnce(double value) {
    if (_viewportFixed) return;
    if (value <= 0) return;
    _chatViewportHeightSubject.add(value);
    _viewportFixed = true;
    debugPrint("📐 Viewport FIXED at: $value");
  }

  void resetViewport() {
    _viewportFixed = false;
    _chatViewportHeightSubject.add(0.0);
  }

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





  void addLocalMessage(Map<String, Object> msg) {
    final updated = [..._messagesSubject.value, msg];
    _messagesSubject.add(updated);
  }

  Future<void> initializeForDashboard({String? initialSessionId}) async {
    print('🔄 Initializing ChatService for dashboard...');
    _isInitialized = false;

    try {
      // ✅ CRITICAL: Ensure token is valid FIRST
      print('🔐 Checking token validity before loading sessions...');
      final isValid = await SessionManager.checkTokenValidityAndRefresh(silent: false);

      if (!isValid) {
        print('❌ Token invalid after refresh attempt');
        throw Exception('Authentication failed');
      }

      print('✅ Token valid, proceeding with sessions load');

      // NOW load sessions with fresh token
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
        _currentSession = null;
        _messagesSubject.add([]);
        _hasLoadedMessagesSubject.add(true);
        lockScroll();
      }

      _isInitialized = true;

    } catch (e) {
      print('❌ Failed to initialize ChatService: $e');
      _isInitialized = true;
      await createNewChatSession();
      lockScroll();
    }
  }

  Future<String> _ensureActiveSessionId([String? sessionId]) async {
    // No-op now. We don't pre-create. If null, /respond will create and stream session_created.
    return sessionId ?? (_currentSession?.id ?? '');
  }





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


  Future<void> _loadSessions() async {
    try {
      _sessions = await fetchSessions();
      print("✅ Loaded ${_sessions.length} sessions");
    } catch (e) {
      print("❌ Failed to load sessions: $e");
      _sessions = [];
    }
  }


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
    print('🔍 CHAT: Loading messages for session: $sessionId');

    if (_sessionMessagesCache.containsKey(sessionId)) {
      print('📋 Found cached messages for session: $sessionId');
      final cachedMessages = _sessionMessagesCache[sessionId]!;
      _messagesSubject.add(List<Map<String, Object>>.from(cachedMessages));
      _convertMessagesToPairs(cachedMessages);
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();
      return;
    }

    _messagesSubject.add([]);

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
            authorLower == 'model' ||
            authorLower == 'tbd') {
          role = 'bot';
        } else {
          role = 'bot';
        }

        // ✅ Parse structured data from BOTH chunks AND infographic_data
        bool isTable = false;
        Map<String, dynamic>? structuredData;
        String? messageType;

        if (role == 'bot') {
          // ✅ PRIORITY 1: Try chunks array first (new format)
          if (msg['chunks'] != null && msg['chunks'] is List) {
            final chunks = msg['chunks'] as List;

            for (final chunk in chunks) {
              if (chunk is! Map<String, dynamic>) continue;

              if (chunk['type'] == 'response') {
                final payload = chunk['payload'];
                if (payload is Map<String, dynamic> && payload['type'] == 'json') {
                  final jsonData = payload['data'];
                  if (jsonData is Map<String, dynamic>) {
                    final normalized = _normalizeStructured(jsonData);
                    if (normalized != null) {
                      isTable = true;
                      structuredData = normalized.data;
                      messageType = normalized.messageType;
                      print('✅ Found structured data in chunks: type=$messageType, rows=${structuredData?['rows']?.length ?? 0}');
                      break;
                    }
                  }
                }
              }
            }
          }

          // ✅ FALLBACK: Try infographic_data (old format)
          if (!isTable && msg['infographic_data'] != null && msg['infographic_data'] is List) {
            final infographics = msg['infographic_data'] as List;

            if (infographics.isNotEmpty) {
              final firstInfographic = infographics[0] as Map<String, dynamic>;
              final type = firstInfographic['type']?.toString() ?? '';
              final dataList = firstInfographic['data'] as List?;

              if (type.isNotEmpty && dataList != null && dataList.isNotEmpty) {
                final normalized = _normalizeStructured({
                  'type': type,
                  'list': dataList,
                  'heading': firstInfographic['heading'],
                });

                if (normalized != null) {
                  isTable = true;
                  structuredData = normalized.data;
                  messageType = normalized.messageType;
                  print('✅ Found structured data in infographic_data: type=$messageType, rows=${structuredData?['rows']?.length ?? 0}');
                }
              }
            }
          }
        }

        print('📝 Adding message: role=$role, content=${content.substring(0, min(50, content.length))}..., isTable=$isTable, messageType=$messageType');

        final messageMap = <String, Object>{
          'role': role,
          'content': content,
          'isComplete': true,
          'isHistorical': true,
          'timestamp': msg['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
          'author': author,
          'id': '${sessionId}_$i',
          'isTable': isTable,
        };

        if (structuredData != null) {
          messageMap['structuredData'] = structuredData;
        }
        if (messageType != null) {
          messageMap['messageType'] = messageType;
        }

        loaded.add(messageMap);
      }

      print('✅ CHAT: Successfully processed ${loaded.length} messages');

      _sessionMessagesCache[sessionId] = List<Map<String, Object>>.from(loaded);
      _messagesSubject.add(loaded);
      _convertMessagesToPairs(loaded);
      _hasLoadedMessagesSubject.add(true);
      _checkAndNotifyFirstMessageComplete();

    } catch (e, stack) {
      debugPrint("❌ Failed to load messages: $e");
      debugPrint("Stack trace: $stack");
      _hasLoadedMessagesSubject.add(true);
    }
  }

  _Normalized? _normalizeStructured(Map<String, dynamic> data) {
    final t = (data['type'] ?? '').toString().toLowerCase();
    if (t.isEmpty) return null;

    print('🔍 Normalizing structured data: type=$t');

    if (t.startsWith('cards')) {
      final rows = data['list'] ?? data['cards'] ?? data['data'] ?? [];
      print('   Found ${rows.length} cards');

      return _Normalized(
        messageType: 'cards',
        data: {
          'heading': data['heading'],
          'rows': rows,
          'columnOrder': data['columnOrder'],
          'type': t,
        },
      );
    }

    if (t.startsWith('table')) {
      final rows = data['rows'] ?? data['list'] ?? data['data'] ?? [];
      print('   Found ${rows.length} table rows');

      return _Normalized(
        messageType: 'table',
        data: {
          'heading': data['heading'],
          'rows': rows,
          'columnOrder': data['columnOrder'],
          'type': t,
        },
      );
    }

    return null;
  }





  void _convertMessagesToPairs(List<Map<String, Object>> messages) {
    pairs.clear();

    for (int i = 0; i < messages.length; i += 2) {
      if (i >= messages.length) break;

      final userMsg = messages[i];
      final userRole = userMsg['role']?.toString() ?? '';

      if (userRole != 'user') {
        print('⚠️ Expected user message at index $i, got: $userRole');
        continue;
      }

      final userMessage = Message(
        byUser: true,
        content: userMsg['content']?.toString() ?? '',
        streaming: false,
        id: userMsg['id']?.toString() ?? UniqueKey().toString(),
      );

      final pair = MessagePair(userMessage: userMessage);

      // ✅ Add bot response if available
      if (i + 1 < messages.length) {
        final botMsg = messages[i + 1];
        final botRole = botMsg['role']?.toString() ?? '';

        if (botRole == 'bot') {
          final isTable = botMsg['isTable'] == true;
          final structuredData = botMsg['structuredData'] as Map<String, dynamic>?;
          final messageType = botMsg['messageType']?.toString();

          final botMessage = Message(
            byUser: false,
            content: botMsg['content']?.toString() ?? '',
            streaming: false,
            id: botMsg['id']?.toString() ?? UniqueKey().toString(),
            isTable: isTable,
            structuredData: structuredData,
            messageType: messageType,
          );

          pair.botResponses.add(botMessage);
          pair.isStreaming = false;

          print('✅ Created pair with bot response (isTable: $isTable, type: $messageType, rows: ${structuredData?['rows']?.length ?? 0})');
        }
      }

      pairs.add(pair);
    }

    print('✅ Converted ${messages.length} messages to ${pairs.length} pairs');
    _pairSubject.add(List.from(pairs));
    _checkAndNotifyFirstMessageComplete();
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
   //_isTypingSubject.add(false);

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




  Future<void> sendMessage(String? sessionId, String text) async {
    final uid = SessionManager.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No UID. Log in first.');
    }

    final userMessage = sanitizeMessage(text);
    final isFirstMessage = !messages.any((m) => m['role'] == 'user');
    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    // ⏱️ Client-level timing: sendMessage start
    final DateTime _clientSendStart = DateTime.now();
    bool _firstEventCaptured = false;

    print("📤 Adding user message to stream");
    print("  userMessageId: $userMessageId");
    print("  isFirstMessage: $isFirstMessage");
    print("⏱️ T0(sendMessage): ${_clientSendStart.toIso8601String()}");

    _isTypingSubject.add(true);

    // ✅ Ensure user message is properly added and persisted
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
          // ⏱️ TTFB (client): sendMessage -> first stream event
          if (!_firstEventCaptured) {
            _firstEventCaptured = true;
            final ttfbClientMs =
                DateTime.now().difference(_clientSendStart).inMilliseconds;
            print("⏱️ TTFB(client): $ttfbClientMs ms (sendMessage → first stream event)");
          }

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

            if (chatMessage.isComplete) {
              print("✅ MESSAGE COMPLETE - locking scroll");
              _isTypingSubject.add(false);

              // First-message-complete hook
              _checkAndNotifyFirstMessageComplete();

              // ⏱️ Total (client send → message complete)
              final totalClientMs =
                  DateTime.now().difference(_clientSendStart).inMilliseconds;
              print("⏱️ Total(client send → message complete): $totalClientMs ms");

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

          final errMs =
              DateTime.now().difference(_clientSendStart).inMilliseconds;
          print("⏱️ (client) Duration until error: $errMs ms");

          _handleConnectionError(botMessageId, userMessage, e);
        },
        onDone: () {
          print("✅ STREAM DONE");
          _isTypingSubject.add(false);

          final doneMs =
              DateTime.now().difference(_clientSendStart).inMilliseconds;
          print("⏱️ Total(client send → stream done): $doneMs ms");
        },
      );
    } catch (e) {
      print("❌ SEND MESSAGE ERROR: $e");
      _isTypingSubject.add(false);

      final errMs = DateTime.now().difference(_clientSendStart).inMilliseconds;
      print("⏱️ (client) Duration until send error: $errMs ms");

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
    print("🚨 sendMessageWithStreamingRespond called for: $message");
    final ok = await SessionManager.checkTokenValidityAndRefresh(silent: false);
    if (!ok || SessionManager.token == null) {
      throw StateError('Not authenticated (no/expired token)');
    }
    final String token = SessionManager.token!;

    final stats = _StreamDebugStats();
    final DateTime _hitAtUtc = DateTime.now().toUtc();
    final String _hitAtUtcIso = _hitAtUtc.toIso8601String();

    final DateTime _reqStart = DateTime.now();
    DateTime? _headersAt;
    DateTime? _firstDataAt;
    DateTime? _completeAt;

    if (debugLog) {
      final preview = message.length > 120 ? '${message.substring(0, 120)}…' : message;
      print('START STREAM - /chat/respond');
      print('uid: $uid');
      print('sessionId: ${sessionId ?? "<null - will be created by server>"}');
      print('user message: "$preview"');
      print('⏱️ T0(reqStart): ${_reqStart.toIso8601String()}');
    }

    try {
      final String _baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';
      final url = Uri.parse('$_baseUrl/chat/respond');
      final req = http.Request('POST', url);
      req.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (SessionManager.token != null) 'Authorization': 'Bearer ${SessionManager.token}',
      });

      final body = <String, dynamic>{
        'uid': uid,
        'input': message,
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

      _headersAt = DateTime.now();
      print('RESPONSE STATUS: ${streamedResponse.statusCode}');
      print('RESPONSE HEADERS: ${streamedResponse.headers}');
      print('⏱️ Time to headers: ${_headersAt.difference(_reqStart).inMilliseconds} ms');

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

          if (_firstDataAt == null && chunk.trim().isNotEmpty) {
            _firstDataAt = DateTime.now();
            final ttfbReqToData = _firstDataAt!.difference(_reqStart).inMilliseconds;
            final ttfbHeadersToData = (_headersAt != null)
                ? _firstDataAt!.difference(_headersAt!).inMilliseconds
                : -1;
            print('⏱️ TTFB(network): $ttfbReqToData ms (reqStart → first data)');
            if (ttfbHeadersToData >= 0) {
              print('⏱️ TTFB(headers→data): $ttfbHeadersToData ms');
            }
          }

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

            // session_created
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

            // status_update
            if (type == 'status_update') {
              print('HANDLING STATUS_UPDATE EVENT');
              final reason = (payload['reason'] ?? '').toString();
              print('STATUS REASON: "$reason"');

              // ✅ FIX: Build displayText properly
              String displayText = textBeforeTable;
              if (tableReceived && textAfterTable.isNotEmpty) {
                displayText = '${textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
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
                messageType: tableData?['type']?.toString(),
              );

              controller.add(currentMessage);
              continue;
            }

            // image
            if (type == 'image') {
              print('HANDLING IMAGE EVENT');
              final imageUrl = payload['url']?.toString();
              print('IMAGE URL: $imageUrl');

              if (imageUrl != null && imageUrl.isNotEmpty) {
                if (tableReceived) {
                  textAfterTable += imageUrl + '\n';
                } else {
                  textBeforeTable += imageUrl + '\n';
                }

                // ✅ FIX: Build displayText properly
                String displayText = textBeforeTable;
                if (tableReceived && textAfterTable.isNotEmpty) {
                  displayText = '${textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
                }

                currentMessage = ChatMessage(
                  id: messageId,
                  text: displayText,
                  isUser: false,
                  timestamp: currentMessage.timestamp,
                  isComplete: false,
                  currentStatus: null,
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableData?['type']?.toString(),
                );

                controller.add(currentMessage);
              }
              continue;
            }

            // response
            if (type == 'response') {
              if (payloadType == 'text') {
                final data = (payload['data'] ?? '').toString();

                if (tableReceived) {
                  textAfterTable += data;
                  print('✅ Added to textAfterTable: "$data"');
                  print('📝 Current textAfterTable length: ${textAfterTable.length}');
                } else {
                  textBeforeTable += data;
                }

                // ✅ FIX: Build displayText properly with proper concatenation
                String displayText;
                if (tableReceived) {
                  displayText = '${textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
                  print('✅ Built displayText with table (length: ${displayText.length})');
                } else {
                  displayText = textBeforeTable;
                }

                currentMessage = ChatMessage(
                  id: messageId,
                  text: displayText,
                  isUser: false,
                  timestamp: currentMessage.timestamp,
                  isComplete: false,
                  currentStatus: null,
                  isTable: tableReceived,
                  structuredData: tableData,
                  messageType: tableData?['type']?.toString(),
                );

                controller.add(currentMessage);
                continue;
              }

              if (payloadType == 'json') {
                final jsonData = payload['data'];

                if (jsonData is Map && (jsonData['type'] == 'cards_of_market' ||
                    jsonData['type'] == 'cards_of_asset' ||
                    jsonData['type'] == 'table_of_asset' ||
                    jsonData['type'] == 'table_of_market')) {

                  if (!tableReceived) {
                    tableReceived = true;
                    print('✅ Table received - tableReceived set to true');
                  }

                  final heading = (jsonData['heading']?.toString() ?? 'Results');
                  final dataList = (jsonData['list'] as List?) ?? const [];
                  final rows = dataList.map<Map<String, dynamic>>((e) =>
                  (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}
                  ).toList();

                  if (combinedHeading == 'Results') {
                    combinedHeading = heading;
                  }

                  allTableRows.addAll(rows);

                  tableData = {
                    'heading': combinedHeading,
                    'rows': allTableRows,
                    'type': jsonData['type'].toString(),
                  };

                  // ✅ FIX: Build displayText with placeholder
                  final displayText = '$textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
                  print('✅ Table added - displayText length: ${displayText.length}');

                  currentMessage = ChatMessage(
                    id: messageId,
                    text: displayText,
                    isUser: false,
                    timestamp: currentMessage.timestamp,
                    isComplete: false,
                    currentStatus: null,
                    isTable: true,
                    structuredData: tableData,
                    messageType: tableData?['type']?.toString(),

                  );

                  controller.add(currentMessage);
                }
                continue;
              }

              if (payloadType == 'complete') {
                streamCompleted = true;
                print('HANDLING COMPLETE PAYLOAD');

                // ✅ FIX: Final displayText with all content
                String displayText;
                if (tableReceived) {
                  displayText = '${textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
                  print('✅ COMPLETE - Final text:');
                  print('   Before: ${textBeforeTable.substring(0, min(50, textBeforeTable.length))}');
                  print('   After: ${textAfterTable.substring(0, min(50, textAfterTable.length))}');
                } else {
                  displayText = textBeforeTable;
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
                  messageType: tableData?['type']?.toString(),
                );

                controller.add(currentMessage);
                continue;
              }
            }
          }
        },
        onDone: () {
          print('\n=== STREAM ON DONE ===');
          print('streamCompleted: $streamCompleted');
          print('✅ Final state:');
          print('   textBeforeTable length: ${textBeforeTable.length}');
          print('   textAfterTable length: ${textAfterTable.length}');
          print('   tableReceived: $tableReceived');

          resetInactivityTimer();
          inactivityTimer?.cancel();

          if (_completeAt == null) _completeAt = DateTime.now();

          if (!streamCompleted) {
            // ✅ FIX: Build final text properly
            String finalText;
            if (tableReceived) {
              finalText = '${textBeforeTable}___TABLE_PLACEHOLDER___$textAfterTable';
            } else {
              finalText = textBeforeTable;
            }

            print('✅ Sending final message with text length: ${finalText.length}');

            controller.add(ChatMessage(
              id: currentMessage.id,
              text: finalText,
              isUser: false,
              timestamp: currentMessage.timestamp,
              isComplete: true,
              currentStatus: null,
              isTable: tableReceived,
              structuredData: tableData,
              messageType: tableData?['type']?.toString(),
            ));
          }

          final totalMs = _completeAt!.difference(_reqStart).inMilliseconds;
          final ttfbReqToData =
          (_firstDataAt != null) ? _firstDataAt!.difference(_reqStart).inMilliseconds : -1;
          final headersMs =
          (_headersAt != null) ? _headersAt!.difference(_reqStart).inMilliseconds : -1;
          final streamAfterFirstByteMs =
          (_firstDataAt != null) ? _completeAt!.difference(_firstDataAt!).inMilliseconds : -1;

          print('⏱️ SUMMARY:');
          print('  • Time to headers: ${headersMs >= 0 ? "$headersMs ms" : "n/a"}');
          print('  • TTFB(network reqStart→first data): ${ttfbReqToData >= 0 ? "$ttfbReqToData ms" : "n/a"}');
          print('  • Stream after first byte: ${streamAfterFirstByteMs >= 0 ? "$streamAfterFirstByteMs ms" : "n/a"}');
          print('  • Total(reqStart→done): ${totalMs} ms');

          controller.close();
          if (debugLog) print('STREAM DONE - Controller closed');
        },
        onError: (e) {
          print('\n=== STREAM ON ERROR ===');
          print('ERROR: $e');
          print('ERROR TYPE: ${e.runtimeType}');

          if (_completeAt == null) _completeAt = DateTime.now();

          final totalMs = _completeAt!.difference(_reqStart).inMilliseconds;
          print('⏱️ (network) Duration until error: $totalMs ms');

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



  String sanitizeMessage(String input) {
    return input
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .trim();
  }

  void _checkAndNotifyFirstMessageComplete() {
    // ✅ NEW: Check pairs instead of old messages
    final hasUserMessage = pairs.any((p) => p.userMessage != null);
    final hasCompletedBot = pairs.any((p) =>
    p.botResponses.isNotEmpty && !p.isStreaming
    );

    print("🔍 First message check (NEW pairs system):");
    print("  hasUserMessage: $hasUserMessage");
    print("  hasCompletedBot: $hasCompletedBot");
    print("  _showNewChatButton: $_showNewChatButton");
    print("  _isTyping: ${_isTypingSubject.value}");

    final completed = hasUserMessage && hasCompletedBot;

    if (completed) {
      if (!_showNewChatButton) {
        _showNewChatButton = true;
        print("✅ Setting showNewChatButton = true");
      }

      // Only notify when NOT typing
      if (!_firstMessageCompleteSubject.value && !_isTypingSubject.value) {
        _firstMessageCompleteSubject.add(true);
        print("✅ Notifying first message complete");
      }
    }
  }



  void clear() {
    print("🧹 ChatService.clear() called");

    // Clear OLD system messages
    _messagesSubject.add([]);
    _firstMessageCompleteSubject.add(false);
    _hasLoadedMessagesSubject.add(false);
    _isTypingSubject.add(false);

    // ADD: Clear NEW pair system
    pairs.clear();
    _pairSubject.add([]);
    _chunkSubject.add("");

    // Cancel any ongoing streams
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentStreamingId = '';

    // Reset UI state
    _showNewChatButton = false;
    shouldPin = false;

    print("✅ ChatService cleared - both old and new systems reset");
  }

  void dispose() {
    // OLD system cleanup
    _messagesSubject.close();
    _isTypingSubject.close();
    _hasLoadedMessagesSubject.close();
    _firstMessageCompleteSubject.close();
    _isScrollLocked.close();
    _chatViewportHeightSubject.close();

    // ADD: NEW system cleanup
    _pairSubject.close();
    _chunkSubject.close();

    // Stream cleanup
    _streamSubscription?.cancel();

    // ADD: Controllers cleanup
    scrollController.dispose();
    textController.dispose();
  }
}



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



// ✅ Add helper class at class level or outside
class _Normalized {
  final String messageType;
  final Map<String, dynamic> data;
  _Normalized({required this.messageType, required this.data});
}

class Message {
  late final bool byUser;
  String? content;
  bool? streaming;
  String? id;

  // Add new fields for enhanced functionality
  String? currentStatus;
  bool isTable;
  Map<String, dynamic>? structuredData;
  String? messageType;

  Message({
    required this.byUser,
    this.content,
    this.streaming,
    this.id,
    this.currentStatus,
    this.isTable = false,
    this.structuredData,
    this.messageType,
  });

  Message copyWith({
    bool? byUser,
    String? content,
    bool? streaming,
    String? id,
    String? currentStatus,
    bool? isTable,
    Map<String, dynamic>? structuredData,
    String? messageType,
  }) {
    return Message(
      byUser: byUser ?? this.byUser,
      content: content ?? this.content,
      streaming: streaming ?? this.streaming,
      id: id ?? this.id,
      currentStatus: currentStatus ?? this.currentStatus,
      isTable: isTable ?? this.isTable,
      structuredData: structuredData ?? this.structuredData,
      messageType: messageType ?? this.messageType,
    );
  }
}

class MessagePair {
  final Message userMessage;
  final List<Message> botResponses;
  bool isStreaming;
  String? currentStatus; // Current status for the entire pair

  MessagePair({
    required this.userMessage,
    List<Message>? botResponses,
    this.isStreaming = false,
    this.currentStatus,
  }) : botResponses = botResponses ?? [];

  // Helper method to update current status
  void updateStatus(String? status) {
    currentStatus = status;
    // Also update the latest bot response if it exists
    if (botResponses.isNotEmpty) {
      final lastResponse = botResponses.last;
      botResponses[botResponses.length - 1] = lastResponse.copyWith(
        currentStatus: status,
      );
    }
  }

  // Helper method to add structured data
  void addStructuredData({
    required String messageType,
    Map<String, dynamic>? data,
    bool isTable = false,
  }) {
    if (botResponses.isNotEmpty) {
      final lastResponse = botResponses.last;
      botResponses[botResponses.length - 1] = lastResponse.copyWith(
        messageType: messageType,
        structuredData: data,
        isTable: isTable,
      );
    }
  }
}



class MessageMetrics {
  static int lineCount({
    required String text,
    required double maxWidth,
    required TextStyle style,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    String? ellipsis,
  }) {
    final painter = _layoutPainter(
      text: text,
      style: style,
      maxWidth: maxWidth,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: ellipsis,
    );
    return painter.computeLineMetrics().length;
  }

  static double height({
    required String text,
    required double maxWidth,
    required TextStyle style,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    String? ellipsis,
  }) {
    final painter = _layoutPainter(
      text: text,
      style: style,
      maxWidth: maxWidth,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: ellipsis,
    );
    return painter.height;
  }

  static TextPainter _layoutPainter({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextDirection textDirection,
    int? maxLines,
    String? ellipsis,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: ellipsis,
    )..layout(maxWidth: maxWidth);
    return painter;
  }
}









