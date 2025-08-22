import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vscmoney/screens/widgets/chat_input_widget.dart';
import 'package:vscmoney/screens/widgets/message_row_widget.dart';
import 'package:vscmoney/screens/widgets/suggestions_widget.dart';
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






class AskVittyChat extends StatefulWidget {
  final ChatSession session;
  final ChatService chatService;
  final void Function(int)? onNavigateToTab;
  final void Function(bool)? onFirstMessageComplete;
  final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetKey;
  final Function(String)? onAskVitty;
  final void Function(String, String)? onStockTap;
  final bool isThreadMode;

  const AskVittyChat({
    Key? key,
    required this.session,
    required this.chatService,
    this.onNavigateToTab,
    this.onFirstMessageComplete,
    this.onAskVitty,
    this.isThreadMode = false,
    this.sheetKey,
    this.onStockTap
  }) : super(key: key);

  @override
  State<AskVittyChat> createState() => _AskVittyChatState();
}

class _AskVittyChatState extends State<AskVittyChat>
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
  double _latestUserMessageHeight = 0;
  bool _showScrollToBottomButton = false;

  // Subscriptions to ChatService streams
  late StreamSubscription _messagesSubscription;
  late StreamSubscription _isTypingSubscription;
  late StreamSubscription _hasLoadedMessagesSubscription;
  late StreamSubscription _firstMessageCompleteSubscription;


  @override
  void initState() {
    super.initState();

    // Initialize services
    _audioService.initialize();

    // Setup subscriptions to ChatService streams
    _setupSubscriptions();

    // Load messages using ChatService
    widget.chatService.loadMessages(widget.session.id);

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    _setupScrollListener();
    _focusNode.addListener(_onFocusChange);
  }

  void _setupSubscriptions() {
    // Listen to ChatService streams
    _messagesSubscription = widget.chatService.messagesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _isTypingSubscription = widget.chatService.isTypingStream.listen((_) {
      if (mounted) setState(() {});
    });

    _hasLoadedMessagesSubscription = widget.chatService.hasLoadedMessagesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _firstMessageCompleteSubscription = widget.chatService.firstMessageCompleteStream.listen((isComplete) {
      if (isComplete) {
        print("📲 ChatScreen: First message completed, notifying parent");
        widget.onFirstMessageComplete?.call(isComplete);  // ✅ This should trigger the callback
      }
    });  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final shouldShow = _scrollController.offset <
          _scrollController.position.maxScrollExtent - 100;

      if (_showScrollToBottomButton != shouldShow) {
        setState(() {
          _showScrollToBottomButton = shouldShow;
        });
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
      setState(() {
        _showExpandedInput = _focusNode.hasFocus;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final messageText = _controller.text.trim();
    _controller.clear();

    // Update session title if first message
    final isFirstMessage = !widget.chatService.messages.any((m) => m['role'] == 'user');
    if (isFirstMessage) {
      widget.session.title = messageText;
    }

    // Use ChatService to send message
    await widget.chatService.sendMessage(widget.session.id, messageText);

    // Scroll to latest
    ChatScrollHelper.scrollToLatestLikeChatPage(
      scrollController: _scrollController,
      chatHeight: _chatHeight,
    );
  }
  void _stopResponse() {
    widget.chatService.stopResponse(widget.session.id);
  }



  void _onStockTap(String stockSymbol) {
    print("🔍 Stock tapped in ChatScreen: $stockSymbol");
    // Use the callback to open the stock detail sheet in the parent
    // Extract stock name from symbol if needed, or pass both
    widget.onStockTap?.call(stockSymbol, stockSymbol); // stockSymbol, stockName
  }

  void _onMessageHeightMeasured(double height) {
    if (mounted && _latestUserMessageHeight != height) {
      setState(() {
        _latestUserMessageHeight = height;
      });
      print("📏 Updated latest user message height: $height");
    }
  }

  void _onAskVittyFromSelection(String selectedText) {
    print("🤖 Ask Vitty from selection: $selectedText");
    // Use the callback to open the ask vitty sheet in the parent
    widget.onAskVitty?.call(selectedText);
  }





  Widget _buildMessageRow(Map<String, Object> msg) {
    final bool isLatest = msg == widget.chatService.messages.last;
    final bool isBot = msg['role'] == 'bot';

    return MessageRowWidget(
      message: msg,
      isLatest: isLatest,
      onAskVitty: _onAskVittyFromSelection,
      onStockTap: _onStockTap,
      onBotRenderComplete: (isLatest && isBot)
          ? () => widget.chatService.markUiRenderCompleteForLatest()
          : null,
      onHeightMeasured: () => _onMessageHeightMeasured(_latestUserMessageHeight),
    );
  }

  @override
  void dispose() {
    // Cancel subscriptions
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
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

                        // Direct access to messages without StreamBuilder
                        ListView.builder(
                          controller: _scrollController,
                          reverse: false,
                          padding: const EdgeInsets.all(20),
                          itemCount: widget.chatService.messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == widget.chatService.messages.length) {
                              final adjustment = ChatUIHelper.calculateScrollAdjustment(
                                chatHeight: _chatHeight,
                                latestUserMessageHeight: _latestUserMessageHeight,
                              );
                              return SizedBox(height: adjustment);
                            }
                            // print("Latest user message height: $_latestUserMessageHeight");
                            final msg = widget.chatService.messages[index];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: _buildMessageRow(msg),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              isListening
                  ? SizedBox.shrink()
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
                child: (widget.chatService.hasLoadedMessages &&
                    !widget.chatService.messages.any((m) => m['role'] == 'user') &&
                    _controller.text.isEmpty)
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

              // Input widget with direct isTyping access
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