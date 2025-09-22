import 'dart:async';

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

import 'chat_message_row_widget.dart';
import 'constants/widgets.dart';
import 'input_field_widget.dart';
import 'models/chat_message.dart';



class NewChatScreen extends StatefulWidget {
  final ChatService chatService;

  const NewChatScreen({super.key, required this.chatService});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {


  final FocusNode _focusNode = FocusNode();
  final _textFieldKey = GlobalKey();
  double _keyboardInset = 0;
  final AudioService _audioService = AudioService.instance;




  @override
  void initState() {
    super.initState();
_audioService.initialize();
    // Listen to pairs stream and rebuild
    widget.chatService.pairStream.listen((_) {
      if (mounted) setState(() {});
    });


    // Handle auto-scroll when new pairs are added
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





  Future<void> _sendMessage() async {
    if (widget.chatService.textController.text.trim().isEmpty) return;
    // widget.onSendMessageStarted?.call();

    // Force unfocus and clear controller first
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final messageText = widget.chatService.textController.text.trim();
    widget.chatService.textController.clear();


    try {
      // await widget.chatService
      //     .sendMessage(widget.chatService.currentSession?.id, messageText);
      await widget.chatService.sendNewMessage(
        message: Message(byUser: true, content: messageText),
        context: context,
      );
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




  @override
  Widget build(BuildContext context) {
    final hasAnyMessages = widget.chatService.pairs.isNotEmpty;
    final isTyping = widget.chatService.isTyping;
    final hasText = widget.chatService.textController.text.isNotEmpty;

    final shouldShowSuggestions = !hasAnyMessages && !isTyping && !hasText;
    final isListening = _audioService.isListening;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main chat content
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: widget.chatService.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.chatService.pairs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == widget.chatService.pairs.length) {
                      if (widget.chatService.pairs.isNotEmpty) {
                        return SizedBox(height: widget.chatService.adjustment);
                      } else {
                        return const SizedBox(height: 100.0);
                      }
                    }
                    final pair = widget.chatService.pairs[index];
                    return NewPairWidget(pair: pair, service: widget.chatService);
                  },
                ),
              ),

              // Chat input (fixed height, no animation)
              ChatInputWidget(
                controller: widget.chatService.textController,
                focusNode: _focusNode,
                textFieldKey: _textFieldKey,
                isTyping: widget.chatService.isTyping,
                keyboardInset: _keyboardInset,
                onSendMessage: _sendMessage,
                onStopResponse: _stopResponse,
                onTextChanged: () { if (mounted) setState(() {}); },
                audioService: _audioService,
              ),
            ],
          ),

          // Suggestions overlay (positioned above chat input)
          Positioned(
            left: 0,
            right: 0,
            bottom: 140, // Will be above ChatInputWidget due to stack order
            child: isListening
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
                key: const ValueKey('suggestions'),
                controller: widget.chatService.textController,
                onAskVitty: (text) {
                  // Handle suggestion selection
                  widget.chatService.textController.text = text;
                  if (mounted) setState(() {});
                },
                onSuggestionSelected: () {
                  if (mounted) setState(() {});
                },
              )
                  : const SizedBox.shrink(
                key: ValueKey('emptySuggestions'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewPairWidget extends StatelessWidget {
  final MessagePair pair;
  final ChatService service;

  const NewPairWidget({super.key, required this.pair, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Column(
      children: [

        Transform.translate(
          offset: const Offset(0, 10),
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0,right: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 14),
                  GestureDetector(
                    //onTap: () => _copyToClipboard(context),
                    child: const Icon(
                      Icons.copy,
                      size: 14,
                      color: Color(0XFF7E7E7E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    child: Container(
                      //key: bubbleKey, // optional, safe to keep
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: theme.message,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        pair.userMessage.content ?? "",
                        style: TextStyle(
                          height: 1.9,
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
SizedBox(height: 10,),
        // Bot responses
        NewBotResponsesList(pair: pair, service: service),
      ],
    );
  }
}

class NewBotResponsesList extends StatelessWidget {
  final MessagePair pair;
  final ChatService service;

  const NewBotResponsesList({
    super.key,
    required this.pair,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final items = pair.botResponses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Before first bot message appears (streaming started)
          if (items.isEmpty && pair.isStreaming)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: (pair.currentStatus != null &&
                  pair.currentStatus!.trim().isNotEmpty)
                  ? _StatusHeader(
                // latest hai (newly streaming), not complete by definition
                isLatest: true,
                isComplete: false,
                currentStatus: pair.currentStatus,
              )
                  : const TypingIndicatorWithHaptics(),
            ),

          // 🔹 Render each bot bubble
          for (int i = 0; i < items.length; i++)
            NewStreamingBotBubble(
              key: ValueKey('bot_${pair.hashCode}_$i'),
              message: items[i],
              service: service,
              isLatest: i == items.length - 1,
              // 👇 pass current status for inline display (pre-first-chunk)
              currentStatus: pair.currentStatus,
            ),
        ],
      ),
    );
  }
}



class NewStreamingBotBubble extends StatefulWidget {
  final Message message;
  final ChatService service;
  final bool isLatest;
  final String? currentStatus;

  const NewStreamingBotBubble({
    super.key,
    required this.message,
    required this.service,
    required this.isLatest,
    this.currentStatus,
  });

  @override
  State<NewStreamingBotBubble> createState() => _NewStreamingBotBubbleState();
}

class _NewStreamingBotBubbleState extends State<NewStreamingBotBubble> {
  String _displayText = "";
  bool _isStreaming = false;
  String? _currentStatus;
  bool _isTable = false;
  Map<String, dynamic>? _structuredData;
  String? _messageType;

  StreamSubscription? _chunkSubscription;
  StreamSubscription? _pairSubscription;

  @override
  void initState() {
    super.initState();
    _displayText = widget.message.content ?? "";
    _isStreaming = widget.message.streaming ?? false;
    _currentStatus = widget.message.currentStatus ?? widget.currentStatus;
    _isTable = widget.message.isTable;
    _structuredData = widget.message.structuredData;
    _messageType = widget.message.messageType;

    if (widget.isLatest && _isStreaming) {
      _chunkSubscription = widget.service.chunkStream.listen((chunk) {
        if (!mounted || !_isStreaming) return;
        setState(() {
          _displayText = chunk;
        });
      });
    }

    _pairSubscription = widget.service.pairStream.listen((pairs) {
      if (!mounted || pairs.isEmpty) return;
      for (final pair in pairs) {
        for (final botMsg in pair.botResponses) {
          if (botMsg.id == widget.message.id) {
            setState(() {
              final wasStreaming = _isStreaming;
              _isStreaming = botMsg.streaming ?? false;
              _currentStatus = botMsg.currentStatus ?? pair.currentStatus;
              _isTable = botMsg.isTable;
              _structuredData = botMsg.structuredData;
              _messageType = botMsg.messageType;

              if (wasStreaming && !_isStreaming) {
                _displayText = botMsg.content ?? "";
                _chunkSubscription?.cancel();
                _chunkSubscription = null;
              }
            });
            return;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _chunkSubscription?.cancel();
    _pairSubscription?.cancel();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _displayText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Widget _buildStructuredContent() {
    if (_structuredData == null) return const SizedBox.shrink();

    switch (_messageType) {
      case 'table':
        return _buildTableWidget();
      case 'card':
      case 'cards':
        return _buildCardsWidget();
      case 'list':
        return _buildListWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTableWidget() {
    if (_structuredData == null) return const SizedBox.shrink();

    // Assume your structured data has 'headers' and 'rows'
    final headers = (_structuredData!['headers'] as List<dynamic>?)?.cast<String>() ?? [];
    final rows = (_structuredData!['rows'] as List<Map<String, dynamic>>?) ?? [];

    if (headers.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    return ComparisonTableWidget(rows: rows);
  }

  Widget _buildCardsWidget() {
    if (_structuredData == null) return const SizedBox.shrink();

    final cards = (_structuredData!['cards'] as List<dynamic>?) ?? [];

    return Column(
      children: cards.map<Widget>((cardData) {
        final card = cardData as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card['title'] != null)
                  Text(
                    card['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                if (card['subtitle'] != null)
                  Text(
                    card['subtitle'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                if (card['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(card['description']),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListWidget() {
    if (_structuredData == null) return const SizedBox.shrink();

    final items = (_structuredData!['items'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(item.toString())),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool waitingForFirstChunk = _isStreaming && _displayText.trim().isEmpty;
    final bool hasStatus = (_currentStatus != null && _currentStatus!.trim().isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status header (when waiting for first chunk)
                  if (waitingForFirstChunk && hasStatus)
                    _StatusHeader(
                      isLatest: widget.isLatest,
                      isComplete: false,
                      currentStatus: _currentStatus,
                    )
                  else if (waitingForFirstChunk && !hasStatus)
                    const TypingIndicatorWithHaptics(),

                  // Main text content
                  if (_displayText.trim().isNotEmpty)
                    Text(
                      _displayText,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                  // Structured content (tables, cards, lists)
                  _buildStructuredContent(),

                  // Copy button (only show when content is complete)
                  if (!_isStreaming && _displayText.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => _copyToClipboard(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 14, color: Color(0xFF7E7E7E)),
                            SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamMessageParser {
  static ChatMessage parseChatMessage(Map<String, dynamic> rawData) {
    // Parse the basic ChatMessage fields
    final id = rawData['id'] ?? UniqueKey().toString();
    final text = rawData['text'] ?? '';
    final isUser = rawData['isUser'] ?? false;
    final timestamp = rawData['timestamp'] != null
        ? DateTime.parse(rawData['timestamp'])
        : DateTime.now();
    final isComplete = rawData['isComplete'] ?? true;

    // Parse enhanced fields
    String? currentStatus;
    bool isTable = false;
    Map<String, dynamic>? structuredData;
    String? messageType;

    // Handle different stream chunk types
    if (rawData['chunk'] != null) {
      final chunk = StreamChunk.fromJson(rawData['chunk']);

      if (chunk.isStatusUpdate) {
        currentStatus = chunk.statusReason;
      }

      if (chunk.isResponse) {
        final responseData = chunk.responseData;

        if (responseData is Map<String, dynamic>) {
          // Check for table data
          if (responseData['type'] == 'table' || responseData['isTable'] == true) {
            isTable = true;
            messageType = 'table';
            structuredData = {
              'headers': responseData['headers'] ?? [],
              'rows': responseData['rows'] ?? [],
            };
          }

          // Check for cards data
          else if (responseData['type'] == 'cards' || responseData['cards'] != null) {
            messageType = 'cards';
            structuredData = {
              'cards': responseData['cards'] ?? [],
            };
          }

          // Check for list data
          else if (responseData['type'] == 'list' || responseData['items'] != null) {
            messageType = 'list';
            structuredData = {
              'items': responseData['items'] ?? [],
            };
          }

          // Generic structured data
          else if (responseData['structuredData'] != null) {
            structuredData = responseData['structuredData'];
            messageType = responseData['messageType'] ?? 'unknown';
          }
        }
      }
    }

    // Fallback: check direct fields in rawData
    currentStatus ??= rawData['currentStatus'];
    isTable = rawData['isTable'] ?? isTable;
    structuredData ??= rawData['structuredData'];
    messageType ??= rawData['messageType'];

    return ChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: timestamp,
      isComplete: isComplete,
      currentStatus: currentStatus,
      isTable: isTable,
      structuredData: structuredData,
      messageType: messageType,
    );
  }

  // Helper method to extract status from stream chunk
  static String? extractStatusFromChunk(Map<String, dynamic> chunkData) {
    if (chunkData['type'] == 'status_update') {
      return chunkData['payload']?['reason'];
    }
    return null;
  }

  // Helper method to extract structured data from chunk
  static Map<String, dynamic>? extractStructuredDataFromChunk(Map<String, dynamic> chunkData) {
    if (chunkData['type'] == 'response') {
      final payload = chunkData['payload'];
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    }
    return null;
  }
}

// Extension to help with message type detection
extension MessageTypeExtension on ChatMessage {
  bool get hasStructuredData => structuredData != null && structuredData!.isNotEmpty;

  bool get isCardMessage => messageType == 'card' || messageType == 'cards';

  bool get isListMessage => messageType == 'list';

  bool get hasCurrentStatus => currentStatus != null && currentStatus!.trim().isNotEmpty;

  Widget buildStatusWidget({
    required bool isLatest,
    required bool isComplete,
  }) {
    if (!hasCurrentStatus || !isLatest || isComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currentStatus!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatefulWidget {
  final bool isLatest;
  final bool isComplete;
  final String? currentStatus;

  const _StatusHeader({
    Key? key,
    required this.isLatest,
    required this.isComplete,
    required this.currentStatus,
  }) : super(key: key);

  @override
  State<_StatusHeader> createState() => _StatusHeaderState();
}

class _StatusHeaderState extends State<_StatusHeader> {
  static const double _kStatusHeight = 24.0;
  bool _hasEverShown = false;

  bool _shouldShowNow() {
    final valid = widget.currentStatus != null &&
        widget.currentStatus!.isNotEmpty &&
        widget.currentStatus! != 'null' &&
        widget.currentStatus! != 'undefined';
    return widget.isLatest && !widget.isComplete && valid;
  }

  @override
  void didUpdateWidget(covariant _StatusHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldShowNow() && !_hasEverShown) {
      _hasEverShown = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = _shouldShowNow();

    if (!_hasEverShown && !show) {
      // Never shown & not showing → no space
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: show ? _kStatusHeight : 0,
      child: show
          ? Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              // 🔹 Uses your shimmer exactly like old widget
              child: PremiumShimmerWidget(
                text: widget.currentStatus!,
                isComplete: false,
                baseColor: const Color(0xFF9CA3AF),
                highlightColor: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }
}




