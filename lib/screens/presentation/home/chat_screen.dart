import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../../constants/add_short_cut_card.dart';
import '../../../constants/bottomsheet.dart';
import '../../../constants/widgets.dart';
import '../../../core/helpers/chat_navigation_helper.dart';
import '../../../core/helpers/chat_scroll_helper.dart';
import '../../../core/helpers/chat_ui_helper.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../../services/voice_service.dart';
import '../../../testpage.dart';
import '../../asset_page/assets_page.dart';
import 'package:http/http.dart' as http;

import '../../widgets/chat_input_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/message_row_widget.dart';
import '../../widgets/suggestions_widget.dart';

class LimitFromEndScrollPhysics extends ClampingScrollPhysics {
  final chatservice = locator<ChatService>();
  final double padFromEnd; // how many pixels before the end to stop

  LimitFromEndScrollPhysics({required this.padFromEnd, ScrollPhysics? parent})
      : super(parent: parent);

  @override
  LimitFromEndScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LimitFromEndScrollPhysics(
      padFromEnd: padFromEnd,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Allowed max is (maxScrollExtent - padFromEnd), but never below min.
    final double allowedMax = (position.maxScrollExtent - padFromEnd);

    print("Allowd Max $allowedMax | $value");
    // block forward scrolling beyond allowedMax
    if (value > allowedMax && chatservice.isTyping == false) {
      print("VALUE $value");
      return value - allowedMax; // consume the excess
    }


    // // (Optional) also block going above minScrollExtent (normal behavior)
    // if (value < position.minScrollExtent) {
    //   return value - position.minScrollExtent;
    // }

    return super.applyBoundaryConditions(position, value);
  }
}


class DownBlockPhysics extends ClampingScrollPhysics {
  final bool isLocked;
  final double Function(ScrollMetrics) floorFor;
  final double epsilon;

  const DownBlockPhysics({
    required this.isLocked,
    required this.floorFor,
    this.epsilon = 0.5,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  DownBlockPhysics applyTo(ScrollPhysics? ancestor) {
    return DownBlockPhysics(
      isLocked: isLocked,
      floorFor: floorFor,
      epsilon: epsilon,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (!isLocked) return super.applyBoundaryConditions(position, value);

    final floor = floorFor(position);
    final current = position.pixels;
    final delta = value -
        current; // >0 = bottom ki taraf (down), <0 = upar (older msgs)

    // RULE: Agar hum floor par/usse upar (current <= floor) hain,
    // aur user "down" jaa kar floor cross karna chahe (value > floor),
    // to bas extra movement block kar do.
    if (current <= floor + epsilon && delta > 0 && value > floor + epsilon) {
      return value - (floor + epsilon);
    }
    return 0.0;
  }
}




// class ChatScreen extends StatefulWidget {
//   final ChatSession? session;
//   final ChatService chatService;
//   final void Function(int)? onNavigateToTab;
//   final void Function(bool)? onFirstMessageComplete;
//   final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetKey;
//   final Function(String)? onAskVitty;
//   final void Function(String)? onStockTap;
//   final bool isThreadMode;
//   final VoidCallback? onSendMessageStarted;
//
//   const ChatScreen({
//     Key? key,
//     required this.session,
//     required this.chatService,
//     this.onNavigateToTab,
//     this.onFirstMessageComplete,
//     this.onAskVitty,
//     this.isThreadMode = false,
//     this.sheetKey,
//     this.onStockTap,
//     this.onSendMessageStarted,
//   }) : super(key: key);
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   ScrollController _scrollController = ScrollController();
//   final _textFieldKey = GlobalKey();
//   late StreamSubscription<bool> _scrollLockSub;
//   bool _isScrollLocked = false;
//   static const double _lockEps = 0.5;
//   double _lastBottomInset = 0.0; // add this field to your state
//
//
//
//
//
//   // Services
//   final AudioService _audioService = AudioService.instance;
//
//   // Simple UI state
//   bool _showExpandedInput = false;
//   double _keyboardInset = 0;
//   double _chatHeight = 0;
//   final Map<String, double> _messageHeights = {};
//   double _latestUserMessageHeight = 52;
//   bool _showScrollToBottomButton = false;
//   double? padFromEnd;
//
//   // Track user message heights by index for stability
//   final Map<int, double> _userMessageHeights = {};
//   double get _layoutGutter => MediaQuery.of(context).size.width * 0.06;
//
//   // Subscriptions
//   late StreamSubscription _messagesSubscription;
//   StreamSubscription? _isTypingSubscription;
//   late StreamSubscription _hasLoadedMessagesSubscription;
//   late StreamSubscription _firstMessageCompleteSubscription;
//   double adjustment = 0.0;
//
//
//   @override
//   void initState() {
//     super.initState();
//
//     _audioService.initialize();
//     _setupSubscriptions();
//
//     final session = widget.chatService.currentSession;
//     if (session != null && session.id.isNotEmpty) {
//       widget.chatService.loadMessages(session.id);
//     }
//
//     WidgetsBinding.instance.addObserver(this);
//
//
//
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (mounted) FocusScope.of(context).requestFocus(_focusNode);
//     });
//
//     _setupScrollListener();
//     _focusNode.addListener(_onFocusChange);
//
//     if (!_scrollController.hasClients) return;
//     final max = _scrollController.position.maxScrollExtent;
//     // use max safely here
//     setState(() { /* ... */ });
//   }
//
//   void _setupSubscriptions() {
//     _messagesSubscription = widget.chatService.messagesStream.listen((_) {
//       if (mounted) setState(() {});
//     });
//
//     // _isTypingSubscription = widget.chatService.isTypingStream.listen((isTyping) {
//     //   if (mounted) setState(() {});
//     //   if (!isTyping) {
//     //     WidgetsBinding.instance.addPostFrameCallback((_) {
//     //       if (!_scrollController.hasClients) return;
//     //       final m = _scrollController.position;
//     //       final floor = _computeFloor(m);
//     //       if (_scrollController.offset <= floor + _lockEps) {
//     //         widget.chatService.lockScroll(); // ✅ re-lock
//     //       }
//     //     });
//     //   }
//     // });
//
//
//     _hasLoadedMessagesSubscription = widget.chatService.hasLoadedMessagesStream.listen((_) {
//       if (mounted) setState(() {});
//     });
//
//     _firstMessageCompleteSubscription =
//         widget.chatService.firstMessageCompleteStream.listen((isComplete) {
//           if (isComplete) {
//             widget.onFirstMessageComplete?.call(isComplete);
//           }
//         });
//
//     // ✅ Scroll-lock state subscribe
//     _scrollLockSub = widget.chatService.isScrollLockedStream.listen((locked) {
//       _isScrollLocked = locked;
//       if (!mounted) return;
//       setState(() {}); // physics ko fresh flag mile
//
//     });
//   }
//
//
//   void _setupScrollListener() {
//     _scrollController.addListener(() {
//       if (!_scrollController.hasClients) return;
//
//       final shouldShowScrollToBottomButton =
//           _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
//
//       if (_showScrollToBottomButton != shouldShowScrollToBottomButton) {
//         setState(() => _showScrollToBottomButton = shouldShowScrollToBottomButton);
//       }
//
//
//       if(_scrollController.position.maxScrollExtent - adjustment > 0 && !widget.chatService.isTyping){
//         if(_scrollController.position.maxScrollExtent - adjustment < _scrollController.offset){
//           _scrollController.jumpTo(_scrollController.position.maxScrollExtent - adjustment);
//         }
//       }
//
//       print(" ${adjustment}||||${_scrollController.position.maxScrollExtent} |||${_scrollController.position.maxScrollExtent - adjustment} ||| ${_scrollController.offset} ||| ${widget.chatService.isTyping}");
//
//     });
//   }
//
//
//
//
//
//
//
//
//   @override
//   void didChangeMetrics() {
//     if (!mounted) return;
//
//     // Defer until the new metrics have actually been applied
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//
//       // Read from PlatformDispatcher, not from context/MediaQuery/View.of
//       final dispatcher = WidgetsBinding.instance.platformDispatcher;
//       final view = dispatcher.implicitView ?? (dispatcher.views.isNotEmpty ? dispatcher.views.first : null);
//       final double bottomInset = view?.viewInsets.bottom ?? 0.0;
//
//       // Throttle redundant work
//       if ((bottomInset - _lastBottomInset).abs() < 0.5) return;
//       _lastBottomInset = bottomInset;
//
//       // Only auto-scroll when keyboard shows
//       if (bottomInset > 0.0 && _scrollController.hasClients) {
//         // Optionally defer to next frame again if your helper does layout
//         // WidgetsBinding.instance.addPostFrameCallback((_) { ... });
//         ChatScrollHelper.handleKeyboardScroll(_scrollController);
//       }
//
//       // Update your state safely
//       setState(() {
//         _keyboardInset = bottomInset;
//       });
//     });
//   }
//
//
//
//   void _onFocusChange() {
//     if (mounted) {
//       setState(() => _showExpandedInput = _focusNode.hasFocus);
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     if (_controller.text.trim().isEmpty) return;
//     widget.onSendMessageStarted?.call();
//
//     FocusScope.of(context).unfocus();
//     final messageText = _controller.text.trim();
//     _controller.clear();
//
//     try {
//       await widget.chatService
//           .sendMessage(widget.chatService.currentSession?.id, messageText);
//
//       await Future.delayed(const Duration(milliseconds: 100));
//       ChatScrollHelper.scrollToLatestLikeChatPage(
//         scrollController: _scrollController,
//         chatHeight: _chatHeight,
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send message: $e'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
//
//   void _stopResponse() {
//     final sid = widget.chatService.currentSession?.id;
//     if (sid != null && sid.isNotEmpty) {
//       widget.chatService.stopResponse(sid);
//     }
//   }
//
//   void _onStockTap(String assetId) {
//     widget.onStockTap?.call(assetId);
//   }
//
//   void _onUserMessageHeightMeasured(String messageKey, double height) {
//     if (!mounted || height <= 0) return;
//
//     _messageHeights[messageKey] = height;
//
//     final messages = widget.chatService.messages;
//     double latestHeight = 52;
//
//     for (int i = messages.length - 1; i >= 0; i--) {
//       final msg = messages[i];
//       if (msg['role'] == 'user') {
//         final resolvedKey = msg['id']?.toString() ?? 'msg_$i';
//         final h = _messageHeights[resolvedKey];
//         if (h != null) {
//           latestHeight = h;
//           break;
//         }
//       }
//     }
//
//     if (_latestUserMessageHeight != latestHeight) {
//       setState(() => _latestUserMessageHeight = latestHeight);
//
//       ChatScrollHelper.scrollToLatestLikeChatPage(
//         scrollController: _scrollController,
//         chatHeight: _chatHeight,
//       );
//     }
//   }
//
//   void _onAskVittyFromSelection(String selectedText) {
//     widget.onAskVitty?.call(selectedText);
//   }
//
//   void _onRetryMessage(String originalMessage) {
//     widget.chatService.retryMessage(originalMessage);
//   }
//
//   Widget _buildMessageRow(Map<String, Object> msg, int index) {
//     final bool isLatest = index == widget.chatService.messages.length - 1;
//     final bool isBot = msg['role'] == 'bot';
//     final bool isUser = msg['role'] == 'user';
//
//     final messageId = msg['id']?.toString() ?? 'msg_$index';
//     final Key messageKey = ValueKey(messageId);
//
//     return MessageRowWidget(
//       key: messageKey,
//       message: Map<String, dynamic>.from(msg),
//       isLatest: isLatest,
//       onAskVitty: _onAskVittyFromSelection,
//       onStockTap: _onStockTap,
//       onBotRenderComplete: (isLatest && isBot)
//           ? () => widget.chatService.markUiRenderCompleteForLatest()
//           : null,
//       onHeightMeasuredWithValue: isUser
//           ? (double height) => _onUserMessageHeightMeasured(messageId, height)
//           : null,
//       onRetryMessage: _onRetryMessage,
//     );
//   }
//
//   @override
//   void dispose() {
//     _messagesSubscription.cancel();
//     _isTypingSubscription?.cancel();
//     _hasLoadedMessagesSubscription.cancel();
//     _firstMessageCompleteSubscription.cancel();
//     _scrollLockSub.cancel();
//
//     WidgetsBinding.instance.removeObserver(this);
//     _focusNode.removeListener(_onFocusChange);
//     _focusNode.dispose();
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final isListening = _audioService.isListening;
//     final noUserMsgYet =
//     !widget.chatService.messages.any((m) => m['role'] == 'user');
//     final blankStart = widget.chatService.currentSession == null &&
//         widget.chatService.messages.isEmpty;
//     final shouldShowSuggestions = _controller.text.isEmpty &&
//         !widget.chatService.isTyping &&
//         (blankStart || (widget.chatService.hasLoadedMessages && noUserMsgYet));
//
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     _chatHeight = constraints.maxHeight;
//                     return Stack(
//                       children: [
//                         GestureDetector(
//                           behavior: HitTestBehavior.translucent,
//                           onTap: () => FocusScope.of(context).unfocus(),
//                           child: Container(
//                             height: double.infinity,
//                             width: double.infinity,
//                             color: Colors.transparent,
//                           ),
//                         ),
//
//                         ListView.builder(
//                           controller:  _scrollController,
//                           //physics: BouncingScrollPhysics(),
//                           reverse: false,
//                           padding: EdgeInsets.symmetric(
//                             horizontal: _layoutGutter,
//                             vertical: 20,
//
//                           ),
//                           itemCount: widget.chatService.messages.length + 1,
//                           itemBuilder: (context, index) {
//                             if (index == widget.chatService.messages.length) {
//
//                               adjustment = ChatUIHelper.calculateScrollAdjustment(
//                                 chatHeight: _chatHeight,
//                                 latestUserMessageHeight: _latestUserMessageHeight,
//                               );
//                               //rint("ADJUSTMENT BRO: $adjustment");
//                               //print("LATEST USER MESSAGE HEIGHT  ${(_scrollController.position.maxScrollExtent || _scrollController.offset");
//                               // print("${_scrollController.position.maxScrollExtent - adjustment} || ${_scrollController.offset}");
//                               return SizedBox(height: adjustment);
//                             }
//                             final msg = widget.chatService.messages[index];
//                             return GestureDetector(
//                               behavior: HitTestBehavior.opaque,
//                               onTap: () => FocusScope.of(context).unfocus(),
//                               child: _buildMessageRow(msg, index),
//                             );
//                           },
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//
//               isListening
//                   ? const SizedBox.shrink()
//                   : AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 350),
//                 switchInCurve: Curves.easeOutCubic,
//                 switchOutCurve: Curves.easeInCubic,
//                 transitionBuilder:
//                     (Widget child, Animation<double> animation) {
//                   return FadeTransition(
//                     opacity: animation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0.0, 0.15),
//                         end: Offset.zero,
//                       ).animate(animation),
//                       child: child,
//                     ),
//                   );
//                 },
//                 child: shouldShowSuggestions
//                     ? SuggestionsWidget(
//                   key: const ValueKey('suggestions'),
//                   controller: _controller,
//                   onAskVitty: _onAskVittyFromSelection,
//                   onSuggestionSelected: () {
//                     if (mounted) setState(() {});
//                   },
//                 )
//                     : const SizedBox.shrink(
//                   key: ValueKey('emptySuggestions'),
//                 ),
//               ),
//
//               const SizedBox(height: 5),
//
//               ChatInputWidget(
//                 controller: _controller,
//                 focusNode: _focusNode,
//                 textFieldKey: _textFieldKey,
//                 isTyping: widget.chatService.isTyping,
//                 keyboardInset: _keyboardInset,
//                 onSendMessage: _sendMessage,
//                 onStopResponse: _stopResponse,
//                 onTextChanged: () {
//                   if (mounted) setState(() {});
//                 },
//                 audioService: _audioService,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

///////////////////////////////////// with condition ///////////////////////////////////////////////////////////////////




class ChatScreen extends StatefulWidget {
  final ChatSession? session;
  final ChatService chatService;

  final void Function(bool)? onFirstMessageComplete;
  final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetKey;
  final Function(String)? onAskVitty;
  final void Function(String)? onStockTap;
  final bool isThreadMode;
 // final VoidCallback? onSendMessageStarted;

  const ChatScreen({
    Key? key,
    required this.session,
    required this.chatService,
    this.onFirstMessageComplete,
    this.onAskVitty,
    this.isThreadMode = false,
    this.sheetKey,
    this.onStockTap,
    //this.onSendMessageStarted,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ScrollController _scrollController = ScrollController();
  final _textFieldKey = GlobalKey();
  late StreamSubscription<bool> _scrollLockSub;
  bool _isScrollLocked = false;
  static const double _lockEps = 0.5;
  double _lastBottomInset = 0.0;
  double _inputHeight = 0.0;

  // Services
  final AudioService _audioService = AudioService.instance;

  // Simple UI state
  bool _showExpandedInput = false;
  double _keyboardInset = 0;
  double _chatHeight = 0;
  final Map<String, double> _messageHeights = {};
  double _latestUserMessageHeight = 52;
  bool _showScrollToBottomButton = false;
  double? padFromEnd;

  // Track user message heights by index for stability
  final Map<int, double> _userMessageHeights = {};
  double get _layoutGutter => MediaQuery.of(context).size.width * 0.06;

  // Subscriptions
  late StreamSubscription _messagesSubscription;
  StreamSubscription? _isTypingSubscription;
  late StreamSubscription _hasLoadedMessagesSubscription;
  late StreamSubscription _firstMessageCompleteSubscription;
  double adjustment = 0.0;

  @override
  void initState() {
    super.initState();

    _audioService.initialize();
    _setupSubscriptions();

    // CRITICAL FIX: Don't automatically load messages in initState
    // This was causing refresh in thread mode when session changes from null to actual session
    // The thread management should handle message loading, not ChatScreen
    print("🖥️ ChatScreen initState - session: ${widget.session?.id ?? 'null'}");
    print("📊 Current messages count: ${widget.chatService.messages.length}");

    // REMOVED: This line was causing the refresh in thread mode
    // final session = widget.chatService.currentSession;
    // if (session != null && session.id.isNotEmpty) {
    //   widget.chatService.loadMessages(session.id);
    // }

    WidgetsBinding.instance.addObserver(this);

    // Only auto-focus in non-thread mode when there are no messages
    if (!widget.isThreadMode) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.chatService.messages.isEmpty) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    }

    _setupScrollListener();
    _focusNode.addListener(_onFocusChange);

    print("✅ ChatScreen initState complete - no message loading triggered");

    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
   // setState(() {});
  }

  void _setupSubscriptions() {
    _messagesSubscription = widget.chatService.messagesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _hasLoadedMessagesSubscription = widget.chatService.hasLoadedMessagesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _firstMessageCompleteSubscription =
        widget.chatService.firstMessageCompleteStream.listen((isComplete) {
          if (isComplete) {
            widget.onFirstMessageComplete?.call(isComplete);
          }
        });

    // Scroll-lock state subscribe
    _scrollLockSub = widget.chatService.isScrollLockedStream.listen((locked) {
      _isScrollLocked = locked;
      if (!mounted) return;
      setState(() {});
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final shouldShowScrollToBottomButton =
          _scrollController.offset < _scrollController.position.maxScrollExtent - 100;

      // if (_showScrollToBottomButton != shouldShowScrollToBottomButton) {
      //   setState(() => _showScrollToBottomButton = shouldShowScrollToBottomButton);
      // }


      // if(_scrollController.offset < _scrollController.position.maxScrollExtent - adjustment && !widget.chatService.isTyping){
      //   _scrollController.jumpTo(_scrollController.position.maxScrollExtent - adjustment);
      // }
      // print("OFFSET ${_scrollController.offset} ||| MAX EXTENT ${_scrollController.position.maxScrollExtent} ||| adjustment ${adjustment}");
    });
  }

  // FIXED: Removed automatic keyboard scrolling that caused upward scrolling
  @override
  void didChangeMetrics() {
    if (!mounted) return;

    // Defer until the new metrics have actually been applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Read from PlatformDispatcher, not from context/MediaQuery/View.of
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      final view = dispatcher.implicitView ?? (dispatcher.views.isNotEmpty ? dispatcher.views.first : null);
      final double bottomInset = view?.viewInsets.bottom ?? 0.0;

      // Throttle redundant work
      if ((bottomInset - _lastBottomInset).abs() < 0.5) return;
      _lastBottomInset = bottomInset;
    });
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _showExpandedInput = _focusNode.hasFocus);
    }
  }

  // IMPROVED: Better scroll timing after sending message
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
   // widget.onSendMessageStarted?.call();

    // Force unfocus and clear controller first
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await widget.chatService
          .sendMessage(widget.chatService.currentSession?.id, messageText);

      // Wait for keyboard to dismiss before scrolling
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _stopResponse() {
    final sid = widget.chatService.currentSession?.id;
    if (sid != null && sid.isNotEmpty) {
      widget.chatService.stopResponse(sid);
    }
  }

  void _onStockTap(String assetId) {
    widget.onStockTap?.call(assetId);
  }

  void _onUserMessageHeightMeasured(String messageKey, double height) {
    if (!mounted || height <= 0) return;

    _messageHeights[messageKey] = height;

    final messages = widget.chatService.messages;
    double latestHeight = 52;

    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['role'] == 'user') {
        final resolvedKey = msg['id']?.toString() ?? 'msg_$i';
        final h = _messageHeights[resolvedKey];
        if (h != null) {
          latestHeight = h;
          break;
        }
      }
    }

    // if (_latestUserMessageHeight != latestHeight) {
    //   setState(() => _latestUserMessageHeight = latestHeight);

      ChatScrollHelper.scrollToLatestLikeChatPage(
        scrollController: _scrollController,
        chatHeight: _chatHeight,
      );
    //}
  }

  void _onAskVittyFromSelection(String selectedText) {
    widget.onAskVitty?.call(selectedText);
  }

  void _onRetryMessage(String originalMessage) {
    widget.chatService.retryMessage(originalMessage);
  }

  Widget _buildMessageRow(Map<String, Object> msg, int index) {
    final bool isLatest = index == widget.chatService.messages.length - 1;
    final bool isBot = msg['role'] == 'bot';
    final bool isUser = msg['role'] == 'user';

    final messageId = msg['id']?.toString() ?? 'msg_$index';
    final Key messageKey = ValueKey(messageId);

    return MessageRowWidget(
      index: index,
      key: messageKey,
      message: Map<String, dynamic>.from(msg),
      //isLatest: isLatest,
      onAskVitty: _onAskVittyFromSelection,
      onStockTap: _onStockTap,
      // onBotRenderComplete: (isLatest && isBot)
      //     ? () => widget.chatService.markUiRenderCompleteForLatest()
      //     : null,
      // onHeightMeasuredWithValue: isUser
      //     ? (double height) => _onUserMessageHeightMeasured(messageId, height)
      //     : null,
      onRetryMessage: _onRetryMessage,
    );
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _isTypingSubscription?.cancel();
    _hasLoadedMessagesSubscription.cancel();
    _firstMessageCompleteSubscription.cancel();
    _scrollLockSub.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isListening = _audioService.isListening;

    // Proper logic for when to show suggestions
    final messages = widget.chatService.messages;
    final hasAnyMessages = messages.isNotEmpty;
    final hasUserMessages = messages.any((m) => m['role'] == 'user');
    final isTyping = widget.chatService.isTyping;

    // In thread mode, only show suggestions when completely empty AND not typing
    final shouldShowSuggestions = widget.isThreadMode
        ? (!hasAnyMessages && !isTyping && _controller.text.isEmpty)  // Thread: only when completely empty
        : (_controller.text.isEmpty && !isTyping && (!hasUserMessages || (!widget.chatService.hasLoadedMessages && !hasAnyMessages))); // Normal: existing logic

    return Scaffold(
      backgroundColor: theme.background,
      // Control keyboard behavior - set to false if you want no automatic adjustments
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _chatHeight = constraints.maxHeight;

                    if (!widget.chatService.isViewportFixed && _keyboardInset == 0.0 && _chatHeight > 0) {
                      widget.chatService.commitViewportOnce(_chatHeight);
                    }

                    return Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => FocusScope.of(context).unfocus(),
                          child: Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: Colors.transparent,
                          ),
                        ),

                        ListView.builder(
                          controller: _scrollController,
                          reverse: false,
                          // Use ClampingScrollPhysics to prevent over-scroll
                        //  physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: _layoutGutter,
                            vertical: 20,
                          ),
                          itemCount:  messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              if(messages.isNotEmpty){
                                final chatH = widget.chatService.chatViewportHeight; // ab constant
                                final adjustment = ChatUIHelper.calculateScrollAdjustment(
                                  chatHeight: chatH,
                                  latestUserMessageHeight: _latestUserMessageHeight,
                                );

                                if (kDebugMode && index == messages.length) {
                                  print("Chatheight :${chatH} |||  Adjustment${adjustment} ||| maxscollextent${_scrollController.position.maxScrollExtent}  ||| offset${_scrollController.offset.toInt()} |||maxsroll - offset ${_scrollController.position.maxScrollExtent - adjustment} userheight${_latestUserMessageHeight}");
                                }                                return
                                  SizedBox(height: math.max(0, adjustment));
                              }else{
                                return SizedBox.shrink();
                              }
                            }
                            final msg = messages[index];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: _buildMessageRow(msg, index),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Suggestions with proper debugging
              isListening
                  ? const SizedBox.shrink()
                  : AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: shouldShowSuggestions
                    ? SuggestionsWidget(
                  ghost: true,
                  key: const ValueKey('suggestions'),
                  controller: _controller,
                  onAskVitty: _onAskVittyFromSelection,
                  onSuggestionSelected: () {
                    if (mounted) setState(() {});
                  },
                )
                    : const SizedBox.shrink(
                  key: ValueKey('emptySuggestions'),
                ),
              ),

              const SizedBox(height: 5),

              ChatInputWidget(
                controller: _controller,
                focusNode: _focusNode,
                textFieldKey: _textFieldKey,
                isTyping: isTyping,
                keyboardInset: _keyboardInset,
                onSendMessage: _sendMessage,
                onStopResponse: _stopResponse,
                onTextChanged: () { if (mounted) setState(() {}); },
                audioService: _audioService,
              ),

            ],
          ),
        ],
      ),
    );
  }
}







class MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onChange;

  const MeasureSize({Key? key, required this.onChange, required Widget child})
      : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context,
      covariant _RenderMeasureSize ro) {
    ro.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  void Function(Size size) onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}















