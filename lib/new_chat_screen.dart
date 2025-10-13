import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/screens/widgets/chat_input_widget.dart';
import 'package:vscmoney/screens/widgets/message_row_widget.dart';
import 'package:vscmoney/screens/widgets/suggestions_widget.dart';
import 'package:vscmoney/screens/widgets/typing%20indicator.dart';
import 'package:vscmoney/services/chat_service.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/services/theme_service.dart';
import 'package:vscmoney/services/voice_service.dart';

import 'constants/widgets.dart';
import 'core/helpers/themes.dart';
import 'models/chat_message.dart';

class NewChatScreen extends StatefulWidget {
  final ChatService chatService;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final bool isThreadMode;

  const NewChatScreen({
    super.key,
    required this.chatService,
    this.onAskVitty,
    this.onStockTap,
    this.isThreadMode = false,
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final _textFieldKey = GlobalKey();

  double _inputHeight = 0;

  final AudioService _audioService = AudioService.instance;
  String? _lastLoadedSessionId;

  bool _isEditing = false;
  bool _ghostMode = false;
  bool _isKeyboardVisible = false;

  // ✅ Local state for isListening
  bool _isListening = false;

  // ✅ Stream subscription
  StreamSubscription<bool>? _isListeningSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioService.initialize();
    _loadMessagesIfNeeded();

    // ✅ Listen to isListening stream
    _isListeningSubscription = _audioService.isListening$.listen((listening) {
      if (mounted && _isListening != listening) {
        setState(() => _isListening = listening);
        print('🎙️ isListening changed: $listening');
      }
    });

    _focusNode.addListener(() {
      print('🎯 Focus changed: ${_focusNode.hasFocus}');

      if (_focusNode.hasFocus && !_isKeyboardVisible) {
        // Keyboard opening
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && _focusNode.hasFocus) {
            setState(() => _isKeyboardVisible = true);
          }
        });
      } else if (!_focusNode.hasFocus && _isKeyboardVisible) {
        // Keyboard closing
        setState(() => _isKeyboardVisible = false);
      }
    });

    widget.chatService.pairStream.listen((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chatService.shouldPin) {
        widget.chatService.shouldPin = false;
        widget.chatService.scrollController.animateTo(
          widget.chatService.scrollController.position.maxScrollExtent -
              widget.chatService.adjustment,
          duration: const Duration(milliseconds: 2550),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void didChangeMetrics() {
    // Force rebuild when IME shows/hides.
    setState(() {});
  }

  void _loadMessagesIfNeeded() {
    final session = widget.chatService.currentSession;
    if (session != null &&
        session.id.isNotEmpty &&
        _lastLoadedSessionId != session.id) {
      _lastLoadedSessionId = session.id;
      widget.chatService.loadMessages(session.id);
    }
  }

  void beginEditing(String text) {
    setState(() => _isEditing = true);
    widget.chatService.textController.text = text;
    widget.chatService.textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
    widget.chatService.textController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _sendMessage() async {
    final txt = widget.chatService.textController.text.trim();
    if (txt.isEmpty) return;

    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    widget.chatService.textController.clear();

    try {
      await widget.chatService.sendNewMessage(
        isThreadMode: widget.isThreadMode,
        message: Message(byUser: true, content: txt),
        context: context,
      );

      // Reset states
      if (_isEditing) setState(() => _isEditing = false);
      if (_ghostMode) setState(() => _ghostMode = false);
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

  @override
  Widget build(BuildContext context) {
    //print("rebuilt");
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isListening = _isListening; // ✅ Use local state

    final hasAnyMessages = widget.chatService.pairs.isNotEmpty;
    final isTyping = widget.chatService.isTyping;
    final hasText = widget.chatService.textController.text.trim().isNotEmpty;
    final activeGhostMode = _ghostMode && hasText;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final kb = View.of(context).viewInsets.bottom;

    final double suggestionsBottom = _inputHeight + 8;
    final showNormalCards = !hasAnyMessages && !isTyping && !hasText;

    return Scaffold(
      backgroundColor: theme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  controller: widget.chatService.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.chatService.pairs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == widget.chatService.pairs.length) {
                      return SizedBox(
                        height: widget.chatService.pairs.isNotEmpty
                            ? widget.chatService.adjustment
                            : 100,
                      );
                    }
                    final pair = widget.chatService.pairs[index];
                    return NewPairWidget(
                      pair: pair,
                      service: widget.chatService,
                      onAskVitty: widget.onAskVitty,
                      onStockTap: widget.onStockTap,
                      onEditStart: beginEditing,
                    );
                  },
                ),
              ),

              MeasureSize(
                onChange: (sz) => setState(() => _inputHeight = (sz?.height ?? 0)),
                child: ChatInputWidget(
                  controller: widget.chatService.textController,
                  focusNode: _focusNode,
                  textFieldKey: _textFieldKey,
                  isTyping: widget.chatService.isTyping,
                  keyboardInset: kb,
                  isEditing: _isEditing,
                  onCancelEdit: _cancelEditing,
                  onSendMessage: _sendMessage,
                  onStopResponse: _stopResponse,
                  onTextChanged: () {
                    if (_ghostMode &&
                        widget.chatService.textController.text.trim().isEmpty) {
                      _ghostMode = false;
                    }
                    if (mounted) setState(() {});
                  },
                  audioService: _audioService,
                ),
              ),
            ],
          ),

          // ✅ Cards disappear when listening
          if ((showNormalCards || activeGhostMode) && !isListening)
            Positioned(
              left: 16,
              right: 0,
              bottom: suggestionsBottom,
              child: SuggestionsWidget(
                ghost: activeGhostMode,
                key: ValueKey<bool>(activeGhostMode),
                controller: widget.chatService.textController,
                onAskVitty: (text) {
                  widget.chatService.textController.text = text;
                  widget.chatService.textController.selection =
                      TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                },
                onSuggestionSelected: () => setState(() => _ghostMode = true),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _isListeningSubscription?.cancel(); // ✅ Cancel subscription
    super.dispose();
  }
}

// class _StatusHeader extends StatefulWidget {
//   final bool isLatest;
//   final bool isComplete;
//   final String? currentStatus;
//
//   const _StatusHeader({
//     Key? key,
//     required this.isLatest,
//     required this.isComplete,
//     required this.currentStatus,
//   }) : super(key: key);
//
//   @override
//   State<_StatusHeader> createState() => _StatusHeaderState();
// }
//
// class _StatusHeaderState extends State<_StatusHeader> {
//   static const double _kStatusHeight = 24.0;
//   bool _hasEverShown = false;
//
//   bool _shouldShowNow() {
//     final valid = widget.currentStatus != null &&
//         widget.currentStatus!.isNotEmpty &&
//         widget.currentStatus! != 'null' &&
//         widget.currentStatus! != 'undefined';
//     return widget.isLatest && !widget.isComplete && valid;
//   }
//
//   @override
//   void didUpdateWidget(covariant _StatusHeader oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (_shouldShowNow() && !_hasEverShown) {
//       _hasEverShown = true;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final show = _shouldShowNow();
//
//     if (!_hasEverShown && !show) {
//       // Never shown & not showing → no space
//       return const SizedBox.shrink();
//     }
//
//     return SizedBox(
//       height: show ? _kStatusHeight : 0,
//       child: show
//           ? Padding(
//         padding: const EdgeInsets.only(bottom: 4),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Expanded(
//               // 🔹 Uses your shimmer exactly like old widget
//               child: PremiumShimmerWidget(
//                 text: widget.currentStatus!,
//                 isComplete: false,
//                 baseColor: const Color(0xFF9CA3AF),
//                 highlightColor: const Color(0xFF6B7280),
//               ),
//             ),
//           ],
//         ),
//       )
//           : null,
//     );
//   }
// }
