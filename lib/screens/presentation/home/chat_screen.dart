// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/message_row_widget.dart';
import '../../widgets/suggestions_widget.dart';



class ChatScreen extends StatefulWidget {
  final ChatSession? session;
  final ChatService chatService;
  final void Function(int)? onNavigateToTab;
  final void Function(bool)? onFirstMessageComplete;
  final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetKey;
  final Function(String)? onAskVitty;
  final void Function(String)? onStockTap;
  final bool isThreadMode;
  final VoidCallback? onSendMessageStarted;

  const ChatScreen({
    Key? key,
    required this.session,
    required this.chatService,
    this.onNavigateToTab,
    this.onFirstMessageComplete,
    this.onAskVitty,
    this.isThreadMode = false,
    this.sheetKey,
    this.onStockTap,
    this.onSendMessageStarted,
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

  // Services
  final AudioService _audioService = AudioService.instance;

  // Simple UI state
  bool _showExpandedInput = false;
  double _keyboardInset = 0;
  double _chatHeight = 0;
  final Map<String, double> _messageHeights = {};
  double _latestUserMessageHeight = 52;
  bool _showScrollToBottomButton = false;

  // Track user message heights by index for stability
  final Map<int, double> _userMessageHeights = {};
  double get _layoutGutter => MediaQuery.of(context).size.width * 0.06;

  // Subscriptions
  late StreamSubscription _messagesSubscription;
  late StreamSubscription _isTypingSubscription;
  late StreamSubscription _hasLoadedMessagesSubscription;
  late StreamSubscription _firstMessageCompleteSubscription;

  @override
  void initState() {
    super.initState();

    _audioService.initialize();
    _setupSubscriptions();

    final session = widget.chatService.currentSession;
    if (session != null && session.id.isNotEmpty) {
      widget.chatService.loadMessages(session.id);
    }

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });

    _setupScrollListener();
    _focusNode.addListener(_onFocusChange);
  }

  void _setupSubscriptions() {
    _messagesSubscription = widget.chatService.messagesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _isTypingSubscription = widget.chatService.isTypingStream.listen((_) {
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
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final shouldShow =
          _scrollController.offset < _scrollController.position.maxScrollExtent - 100;

      if (_showScrollToBottomButton != shouldShow) {
        setState(() => _showScrollToBottomButton = shouldShow);
      }
    });
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;

    if (bottomInset > 0.0) {
      ChatScrollHelper.handleKeyboardScroll(_scrollController);
    }

    if (mounted) {
      setState(() {
        _keyboardInset = bottomInset;
      });
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _showExpandedInput = _focusNode.hasFocus);
    }
  }

  // Send
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    widget.onSendMessageStarted?.call();

    FocusScope.of(context).unfocus();
    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await widget.chatService
          .sendMessage(widget.chatService.currentSession?.id, messageText);

      await Future.delayed(const Duration(milliseconds: 100));
      ChatScrollHelper.scrollToLatestLikeChatPage(
        scrollController: _scrollController,
        chatHeight: _chatHeight,
      );
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

  // Height coming from MessageRowWidget → MessageBubble(MeasureSize)
  void _onUserMessageHeightMeasured(String messageKey, double height) {
    if (!mounted || height <= 0) return;

    _messageHeights[messageKey] = height;

    // ⭐ Use the SAME key we used to store (message 'id'), not msg['key'].
    final messages = widget.chatService.messages;
    double latestHeight = 52; // default one-liner

    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['role'] == 'user') {
        // ⭐ Changed: resolve the same key we pass to _onUserMessageHeightMeasured
        final resolvedKey = msg['id']?.toString() ?? 'msg_$i';
        final h = _messageHeights[resolvedKey];
        if (h != null) {
          latestHeight = h;
          break;
        }
      }
    }

    if (_latestUserMessageHeight != latestHeight) {
      setState(() => _latestUserMessageHeight = latestHeight);

      ChatScrollHelper.scrollToLatestLikeChatPage(
        scrollController: _scrollController,
        chatHeight: _chatHeight,
      );
    }
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

    // ⭐ Use the same id here and in the height map
    final messageId = msg['id']?.toString() ?? 'msg_$index';
    final Key messageKey = ValueKey(messageId);

    return MessageRowWidget(
      key: messageKey,
      message: Map<String, dynamic>.from(msg),
      isLatest: isLatest,
      onAskVitty: _onAskVittyFromSelection,
      onStockTap: _onStockTap,
      onBotRenderComplete: (isLatest && isBot)
          ? () => widget.chatService.markUiRenderCompleteForLatest()
          : null,
      onHeightMeasuredWithValue: isUser
          ? (double height) => _onUserMessageHeightMeasured(messageId, height) // ⭐
          : null,
      onRetryMessage: _onRetryMessage,
    );
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _isTypingSubscription.cancel();
    _hasLoadedMessagesSubscription.cancel();
    _firstMessageCompleteSubscription.cancel();

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
    final noUserMsgYet =
    !widget.chatService.messages.any((m) => m['role'] == 'user');
    final blankStart = widget.chatService.currentSession == null &&
        widget.chatService.messages.isEmpty;

    final shouldShowSuggestions = _controller.text.isEmpty &&
        !widget.chatService.isTyping &&
        (blankStart || (widget.chatService.hasLoadedMessages && noUserMsgYet));

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _chatHeight = constraints.maxHeight;

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
                          padding: EdgeInsets.symmetric(
                            horizontal: _layoutGutter,
                            vertical: 20,
                          ),
                          itemCount: widget.chatService.messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == widget.chatService.messages.length) {
                              final adjustment = ChatUIHelper.calculateScrollAdjustment(
                                chatHeight: _chatHeight,
                                latestUserMessageHeight: _latestUserMessageHeight,
                              );
                              return SizedBox(height: adjustment);
                            }
                            final msg = widget.chatService.messages[index];
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

              isListening
                  ? const SizedBox.shrink()
                  : AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
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
                isTyping: widget.chatService.isTyping,
                keyboardInset: _keyboardInset,
                onSendMessage: _sendMessage,
                onStopResponse: _stopResponse,
                onTextChanged: () {
                  if (mounted) setState(() {});
                },
                audioService: _audioService,
              ),
            ],
          ),
        ],
      ),
    );
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
//   final VoidCallback? onSendMessageStarted; // NEW: Add callback for immediate divider
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
//     this.onSendMessageStarted, // NEW: Add parameter
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
//
//   // Track user message heights by index for stability
//   final Map<int, double> _userMessageHeights = {};
//   double get _layoutGutter => MediaQuery.of(context).size.width * 0.06;
//
//   // Subscriptions to ChatService streams
//   late StreamSubscription _messagesSubscription;
//   late StreamSubscription _isTypingSubscription;
//   late StreamSubscription _hasLoadedMessagesSubscription;
//   late StreamSubscription _firstMessageCompleteSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize services
//     _audioService.initialize();
//
//     // Setup subscriptions to ChatService streams
//     _setupSubscriptions();
//
//     final session = widget.chatService.currentSession;
//     if (session != null && session.id.isNotEmpty) {
//       print('Loading messages for session: ${session.id}');
//       widget.chatService.loadMessages(session.id);
//     } else {
//       print('No current session, waiting for service to initialize');
//     }
//
//     WidgetsBinding.instance.addObserver(this);
//
//     Future.delayed(Duration(milliseconds: 300), () {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(_focusNode);
//       }
//     });
//
//     _setupScrollListener();
//     _focusNode.addListener(_onFocusChange);
//   }
//
//   void _setupSubscriptions() {
//     // Listen to ChatService streams
//     _messagesSubscription = widget.chatService.messagesStream.listen((_) {
//       if (mounted) setState(() {});
//     });
//
//     _isTypingSubscription = widget.chatService.isTypingStream.listen((_) {
//       if (mounted) setState(() {});
//     });
//
//     _hasLoadedMessagesSubscription = widget.chatService.hasLoadedMessagesStream.listen((_) {
//       if (mounted) setState(() {});
//     });
//
//     _firstMessageCompleteSubscription = widget.chatService.firstMessageCompleteStream.listen((isComplete) {
//       if (isComplete) {
//         print("First message completed, notifying parent");
//         widget.onFirstMessageComplete?.call(isComplete);
//       }
//     });
//   }
//
//   void _setupScrollListener() {
//     _scrollController.addListener(() {
//       if (!_scrollController.hasClients) return;
//
//       final shouldShow = _scrollController.offset <
//           _scrollController.position.maxScrollExtent - 100;
//
//       if (_showScrollToBottomButton != shouldShow) {
//         setState(() {
//           _showScrollToBottomButton = shouldShow;
//         });
//       }
//     });
//   }
//
//   @override
//   void didChangeMetrics() {
//     final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
//
//     if (bottomInset > 0.0) {
//       ChatScrollHelper.handleKeyboardScroll(_scrollController);
//     }
//
//     if (mounted) {
//       setState(() {
//         _keyboardInset = bottomInset;
//       });
//     }
//   }
//
//   void _onFocusChange() {
//     if (mounted) {
//       setState(() {
//         _showExpandedInput = _focusNode.hasFocus;
//       });
//     }
//   }
//
//   // UPGRADED: Added immediate callback for divider functionality
//   Future<void> _sendMessage() async {
//     if (_controller.text.trim().isEmpty) return;
//
//     // NEW: Call the callback IMMEDIATELY when send button is clicked
//     widget.onSendMessageStarted?.call();
//
//     FocusScope.of(context).unfocus();
//     final messageText = _controller.text.trim();
//     _controller.clear();
//
//     try {
//       // Pass the current (possibly null) session id; service will handle null
//       await widget.chatService.sendMessage(widget.chatService.currentSession?.id, messageText);
//
//       await Future.delayed(const Duration(milliseconds: 100));
//       ChatScrollHelper.scrollToLatestLikeChatPage(
//         scrollController: _scrollController,
//         chatHeight: _chatHeight,
//       );
//     } catch (e) {
//       print("Error sending message: $e");
//
//       // Show error feedback to user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
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
//     print("Stock tapped in ChatScreen: $assetId");
//     widget.onStockTap?.call(assetId);
//   }
//
//   void _onUserMessageHeightMeasured(String messageKey, double height) {
//     if (mounted && height > 0) {
//       _messageHeights[messageKey] = height;
//
//       // Update latest user message height
//       final messages = widget.chatService.messages;
//       double latestHeight = 52; // default
//
//       // Find the most recent user message height
//       for (int i = messages.length - 1; i >= 0; i--) {
//         final msg = messages[i];
//         if (msg['role'] == 'user') {
//           final key = msg['key']?.toString() ?? 'msg_$i';
//           if (_messageHeights.containsKey(key)) {
//             latestHeight = _messageHeights[key]!;
//             break;
//           }
//         }
//       }
//
//       if (_latestUserMessageHeight != latestHeight) {
//         setState(() {
//           _latestUserMessageHeight = latestHeight;
//         });
//         ChatScrollHelper.scrollToLatestLikeChatPage(
//           scrollController: _scrollController,
//           chatHeight: _chatHeight,
//         );
//         print("Updated latest user message height: $latestHeight");
//       }
//     }
//   }
//
//   void _onAskVittyFromSelection(String selectedText) {
//     print("Ask Vitty from selection: $selectedText");
//     widget.onAskVitty?.call(selectedText);
//   }
//
//   // Handle retry messages
//   void _onRetryMessage(String originalMessage) {
//     print("Retrying message: $originalMessage");
//     widget.chatService.retryMessage(originalMessage);
//   }
//
//   Widget _buildMessageRow(Map<String, Object> msg, int index) {
//     final bool isLatest = index == widget.chatService.messages.length - 1;
//     final bool isBot = msg['role'] == 'bot';
//     final bool isUser = msg['role'] == 'user';
//
//     // Use message ID for stable key, not content-based key
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
//     // Cancel subscriptions
//     _messagesSubscription.cancel();
//     _isTypingSubscription.cancel();
//     _hasLoadedMessagesSubscription.cancel();
//     _firstMessageCompleteSubscription.cancel();
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
//     final noUserMsgYet = !widget.chatService.messages.any((m) => m['role'] == 'user');
//     final blankStart = widget.chatService.currentSession == null &&
//         widget.chatService.messages.isEmpty;
//
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
//
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
//                           controller: _scrollController,
//                           reverse: false,
//                           padding: EdgeInsets.symmetric(horizontal: _layoutGutter, vertical: 20),
//                           itemCount: widget.chatService.messages.length + 1,
//                           itemBuilder: (context, index) {
//                             if (index == widget.chatService.messages.length) {
//                               final adjustment = ChatUIHelper.calculateScrollAdjustment(
//                                 chatHeight: _chatHeight,
//                                 latestUserMessageHeight: _latestUserMessageHeight,
//                               );
//                               //print("Box spacing : ${adjustment}");
//                               return SizedBox(height: adjustment);
//                             }
//                             print("Latest box height : ${_latestUserMessageHeight}");
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
//                   ? SizedBox.shrink()
//                   : AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 350),
//                 switchInCurve: Curves.easeOutCubic,
//                 switchOutCurve: Curves.easeInCubic,
//                 transitionBuilder: (Widget child, Animation<double> animation) {
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
//                 child:
//                 shouldShowSuggestions
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
//               // Input widget with direct isTyping access
//               ChatInputWidget(
//                 controller: _controller,
//                 focusNode: _focusNode,
//                 textFieldKey: _textFieldKey,
//                 isTyping: widget.chatService.isTyping,
//                 keyboardInset: _keyboardInset,
//                 onSendMessage: _sendMessage, // This will trigger onSendMessageStarted
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







