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

import 'bot_response_widget.dart';
import 'chat_message_row_widget.dart';
import 'constants/widgets.dart';
import 'input_field_widget.dart';
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

class _NewChatScreenState extends State<NewChatScreen> {
  final FocusNode _focusNode = FocusNode();
  final _textFieldKey = GlobalKey();
  double _keyboardInset = 0;
  final AudioService _audioService = AudioService.instance;
  String? _lastLoadedSessionId; // Track last loaded session

  @override
  void initState() {
    super.initState();
    _audioService.initialize();

    // Load messages for initial session
    _loadMessagesIfNeeded();

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

  @override
  void didUpdateWidget(NewChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if session changed
    final currentSessionId = widget.chatService.currentSession?.id;
    final oldSessionId = oldWidget.chatService.currentSession?.id;

    if (currentSessionId != oldSessionId) {
      print("🔄 Session changed from $oldSessionId to $currentSessionId");
      _loadMessagesIfNeeded();
    }
  }

  void _loadMessagesIfNeeded() {
    final session = widget.chatService.currentSession;
    if (session != null &&
        session.id.isNotEmpty &&
        _lastLoadedSessionId != session.id) {

      print("📥 Loading messages for session: ${session.id}");
      _lastLoadedSessionId = session.id;
      widget.chatService.loadMessages(session.id);
    }
  }

  Future<void> _sendMessage() async {
    if (widget.chatService.textController.text.trim().isEmpty) return;

    // Force unfocus and clear controller first
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final messageText = widget.chatService.textController.text.trim();
    widget.chatService.textController.clear();

    try {
      await widget.chatService.sendNewMessage(
        isThreadMode: widget.isThreadMode,
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
                      if (widget.chatService.pairs.isNotEmpty) {
                        return SizedBox(height: widget.chatService.adjustment);
                      } else {
                        return const SizedBox(height: 100.0);
                      }
                    }
                    final pair = widget.chatService.pairs[index];
                    return NewPairWidget(
                      pair: pair,
                      service: widget.chatService,
                      onAskVitty: widget.onAskVitty,
                      onStockTap: widget.onStockTap,
                    );
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
            bottom: 140,
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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}


class NewPairWidget extends StatefulWidget {
  final MessagePair pair;
  final ChatService service;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;

  const NewPairWidget({
    super.key,
    required this.pair,
    required this.service,
    this.onAskVitty,
    this.onStockTap,
  });

  @override
  State<NewPairWidget> createState() => _NewPairWidgetState();
}

class _NewPairWidgetState extends State<NewPairWidget> {
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.pair.userMessage.content ?? ""));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _editMessage(BuildContext context) {
    // your existing edit flow…
  }

  String get _previewText {
    final t = widget.pair.userMessage.content ?? '';
    if (t.isEmpty) return 'Message';
    return t.length > 30 ? '${t.substring(0, 30)}…' : t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final userBubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          widget.pair.userMessage.content ?? "",
          style: TextStyle(
            height: 1.9,
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.text,
          ),
        ),
      ),
    );

    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, 10),
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0, right: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context),
                    child: const Icon(Icons.copy, size: 14, color: Color(0xFF7E7E7E)),
                  ),
                  const SizedBox(width: 10),

                  // ⬇️ Wrap your bubble with the iOS pop menu (LEFT side)
                  IOSPopContextMenu(
                    previewText: _previewText,
                    onCopy: () => _copyToClipboard(context),
                    onEdit: () => _editMessage(context),
                    side: MenuSide.right, // ← like the video
                    child: userBubble,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        NewBotResponsesList(
          pair: widget.pair,
          service: widget.service,
          onAskVitty: widget.onAskVitty,
          onStockTap: widget.onStockTap,
        ),
      ],
    );
  }
}


class NewBotResponsesList extends StatelessWidget {
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final MessagePair pair;
  final ChatService service;

  const NewBotResponsesList({
    super.key,
    required this.pair,
    required this.service,
    this.onAskVitty,
    this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = pair.botResponses;

    // Check if we have any meaningful content
    final hasStatus = pair.currentStatus != null && pair.currentStatus!.trim().isNotEmpty;
    final hasContent = items.isNotEmpty &&
        (items.any((msg) => (msg.content?.isNotEmpty ?? false) ||
            msg.isTable ||
            (msg.structuredData != null)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show loader only when streaming AND no content/status yet
          if (pair.isStreaming && !hasContent && !hasStatus) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TypingIndicatorWithHaptics(),
            ),
          ],
          for (int i = 0; i < items.length; i++)
            NewBotMessageWidget(
              key: ValueKey('bot_msg_${items[i].id ?? '${pair.hashCode}_$i'}'),
              message: items[i],
              isLatest: i == items.length - 1,
              pairCurrentStatus: pair.currentStatus,
              onAskVitty: onAskVitty,
              onStockTap: onStockTap,
            ),
        ],
      ),
    );
  }
}

class NewBotMessageWidget extends StatefulWidget {
  final Message message;
  final bool isLatest;
  final String? pairCurrentStatus;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;
  final VoidCallback? onRenderComplete;

  const NewBotMessageWidget({
    Key? key,
    required this.message,
    required this.isLatest,
    this.pairCurrentStatus,
    this.onAskVitty,
    this.onStockTap,
    this.onRenderComplete,
  }) : super(key: key);

  @override
  State<NewBotMessageWidget> createState() => _NewBotMessageWidgetState();
}

class _NewBotMessageWidgetState extends State<NewBotMessageWidget>
    with AutomaticKeepAliveClientMixin {
  // Message split placeholder for table
  static const _kPlaceholder = '___TABLE_PLACEHOLDER___';

  // Image token regex  __IMG_n__
  static final RegExp _imgTokenRe = RegExp(r'__IMG_(\d+)__', caseSensitive: false);

  // Spacing
  static const double _kGapTextToBlock = 6.0;
  static const double _kGapBlockToText = 8.0;

  // Status height when showing
  static const double _kStatusHeight = 24.0;

  // Reserve space for content to prevent jumping
  static const double _kMinContentHeight = 30.0;

  // Trim extra ascent/descent so lines don't add hidden top/bottom space
  static const TextHeightBehavior _thb = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  String _preFull = '';
  String _postFull = '';
  List<Map<String, dynamic>> _availableTableRows = [];
  String? _availableTableHeading;
  bool _hasTableDataAvailable = false;

  // Track if we ever showed status to prevent jumping
  bool _hasEverShownStatus = false;

  // Track if content has ever been rendered to prevent sudden expansion
  bool _hasEverRenderedContent = false;

  // Image-related fields
  List<String> _imageUrls = [];
  String _textWithTokens = '';

  // Haptic feedback states
  bool _hasTriggeredStartHaptic = false;
  bool _hasTriggeredEndHaptic = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final messageContent = widget.message.content ?? '';

    // Extract images as tokens (order preserved)
    _extractImages(messageContent);

    // Split by table placeholder into pre/post (with tokens inside)
    _recomputeSegments(_textWithTokens.isNotEmpty ? _textWithTokens : messageContent);

    // Table availability
    _updateTableData();

    // Mark "has ever rendered"
    final hasInitialContent = messageContent.isNotEmpty ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;
    if (hasInitialContent) {
      _hasEverRenderedContent = true;
    }

    // Trigger start haptic if this is a new bot response
    _checkAndTriggerStartHaptic();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRenderComplete?.call();
    });
  }

  @override
  void didUpdateWidget(covariant NewBotMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsUpdate = false;

    if (widget.message.content != oldWidget.message.content) {
      _extractImages(widget.message.content ?? '');
      _recomputeSegments(_textWithTokens.isNotEmpty ? _textWithTokens : (widget.message.content ?? ''));
      needsUpdate = true;
    }

    if (widget.message.structuredData != oldWidget.message.structuredData) {
      _updateTableData();
      needsUpdate = true;
    }

    // Track if status was ever shown
    final bool currentShowStatus = _shouldShowStatus();
    if (currentShowStatus && !_hasEverShownStatus) {
      _hasEverShownStatus = true;
      needsUpdate = true;
    }

    // Track if content has appeared
    final bool hasContent = (widget.message.content?.isNotEmpty ?? false) ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;
    if (hasContent && !_hasEverRenderedContent) {
      _hasEverRenderedContent = true;
      needsUpdate = true;
    }

    // Check for response start
    _checkAndTriggerStartHaptic();

    // Check for response completion
    if ((widget.message.streaming ?? false) != (oldWidget.message.streaming ?? false)) {
      _checkAndTriggerEndHaptic();
      needsUpdate = true;
    }

    if (needsUpdate && mounted) setState(() {});
  }

  void _checkAndTriggerStartHaptic() {
    if (_hasTriggeredStartHaptic) return;

    final hasContent = (widget.message.content?.isNotEmpty ?? false) ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty ||
        _shouldShowStatus();

    if (widget.isLatest && hasContent && !_hasTriggeredStartHaptic) {
      print("🎯 HAPTIC: Bot response started");
      HapticFeedback.mediumImpact();
      _hasTriggeredStartHaptic = true;
    }
  }

  void _checkAndTriggerEndHaptic() {
    if (_hasTriggeredEndHaptic) return;

    final hasRealContent = (widget.message.content?.isNotEmpty ?? false) ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;

    if (!(widget.message.streaming ?? false) &&
        widget.isLatest &&
        hasRealContent &&
        !_hasTriggeredEndHaptic) {
      print("🎯 HAPTIC: Bot response completed");
      HapticFeedback.mediumImpact();
      _hasTriggeredEndHaptic = true;
    }
  }

  void _recomputeSegments(String full) {
    final parts = full.split(_kPlaceholder);
    _preFull = parts.isNotEmpty ? parts.first : '';
    _postFull = parts.length > 1 ? parts.sublist(1).join(_kPlaceholder) : '';
  }

  void _extractImages(String message) {
    _imageUrls = [];

    final imgRe = RegExp(
      r'!\[.*?\]\((https?://[^\s)]+)\)'
      r'|"\s*image_url\s*"\s*:\s*"([^"]+)"'
      r'|(https?://[^\s]+\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\s]*)?)'
      r'|(https://[^\s]*googleusercontent\.com/[^\s]+)',
      caseSensitive: false,
    );

    final sb = StringBuffer();
    int pos = 0;
    final matches = imgRe.allMatches(message).toList();

    for (final m in matches) {
      final url = m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4);
      if (url == null || url.isEmpty) continue;

      if (m.start > pos) sb.write(message.substring(pos, m.start));

      final idx = _imageUrls.length;
      _imageUrls.add(url);
      sb.write('__IMG_${idx}__');

      pos = m.end;
    }

    if (pos < message.length) sb.write(message.substring(pos));

    _textWithTokens = sb.toString().trim();
  }

  void _updateTableData() {
    if (widget.message.isTable && widget.message.structuredData != null) {
      final structuredData = widget.message.structuredData!;

      // Handle different message types
      switch (widget.message.messageType?.toLowerCase()) {
        case 'table':
          final rowsRaw = (structuredData['rows'] as List?) ?? const [];
          _availableTableRows = rowsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
          _availableTableHeading = structuredData['heading']?.toString() ?? structuredData['title']?.toString();
          break;
        case 'cards':
        case 'card':
          final cardsRaw = (structuredData['cards'] as List?) ?? const [];
          _availableTableRows = cardsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
          _availableTableHeading = structuredData['heading']?.toString() ?? structuredData['title']?.toString();
          break;
        default:
          final rowsRaw = (structuredData['rows'] as List?) ?? const [];
          _availableTableRows = rowsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
          _availableTableHeading = structuredData['heading']?.toString();
      }

      _hasTableDataAvailable = _availableTableRows.isNotEmpty;
    } else {
      _availableTableRows = [];
      _availableTableHeading = null;
      _hasTableDataAvailable = false;
    }
  }

  bool _shouldShowStatus() {
    final String? currentStatus = widget.message.currentStatus ?? widget.pairCurrentStatus;
    final bool validStatus = (currentStatus != null &&
        currentStatus.isNotEmpty &&
        currentStatus != 'null' &&
        currentStatus != 'undefined');

    return widget.isLatest && (widget.message.streaming ?? false) && validStatus;
  }

  TextStyle _bodyStyle(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    return TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 16,
      height: 1.5,
      color: textColor,
    );
  }

  String _trimRightSoft(String s) => s.replaceAll(RegExp(r'[\n\s]+$'), '');
  String _trimLeftSoft(String s) => s.replaceAll(RegExp(r'^\s+'), '');

  String _preprocessText(String text) {
    String processed = text;

    processed = processed.replaceAllMapped(
      RegExp(r'\*\s*(Capitalisation|Performance|Valuation|Volatility & Risk|Technical Indicators|Key Observations|Market Capitalisation|Recent Performance|Volatility):\s*\*'),
          (m) => '\n\n**${m.group(1)}:**\n',
    );

    processed = processed.replaceAllMapped(
      RegExp(r'\*\s*([^*:]+?):\s*([^*]+?)\s*\*', multiLine: true),
          (m) => '• **${m.group(1)?.trim()}:** ${m.group(2)?.trim()}\n',
    );

    processed = processed.replaceAllMapped(
      RegExp(r'(-?\d+\.?\d*%)', multiLine: true),
          (m) => '**${m.group(1)}**',
    );

    processed = processed.replaceAllMapped(
      RegExp(r'(₹[\d,]+\.?\d*)', multiLine: true),
          (m) => '**${m.group(1)}**',
    );

    processed = processed.replaceAllMapped(
      RegExp(r'(\d+\.\d{2,})', multiLine: true),
          (m) => '**${m.group(1)}**',
    );

    processed = processed.replaceAll(RegExp(r' +'), ' ');
    processed = processed.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    return processed.trim();
  }

  List<TextSpan> _buildFormattedSpans(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      String line = lines[lineIndex].trim();
      if (line.isEmpty) {
        if (lineIndex < lines.length - 1) {
          spans.add(TextSpan(text: '\n', style: base));
        }
        continue;
      }

      final sectionHeaderMatch = RegExp(r'^\*\*(.+?):\*\*$').firstMatch(line);
      if (sectionHeaderMatch != null) {
        spans.add(TextSpan(
          text: '${sectionHeaderMatch.group(1)?.trim()}\n',
          style: base.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF2C3E50),
            height: 1.8,
          ),
        ));
        continue;
      }

      if (line.startsWith('•')) {
        final bulletContent = line.substring(1).trim();
        _processBulletPoint(bulletContent, base, spans);
        if (lineIndex < lines.length - 1) {
          spans.add(TextSpan(text: '\n', style: base));
        }
        continue;
      }

      _processLineWithFormatting(line, base, spans);

      if (lineIndex < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: base));
      }
    }

    return spans;
  }

  void _processBulletPoint(String content, TextStyle base, List<TextSpan> spans) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    spans.add(TextSpan(text: '• ', style: base.copyWith(color: theme.text)));
    _processLineWithFormatting(content, base, spans);
  }

  void _processLineWithFormatting(String text, TextStyle base, List<TextSpan> spans) {
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: base));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.w600, color: theme.text),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState s) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final value = s.textEditingValue;
    final sel = value.selection;
    if (!sel.isValid || sel.isCollapsed) return const SizedBox.shrink();
    final selected = value.text.substring(sel.start, sel.end);

    return AdaptiveTextSelectionToolbar(
      anchors: s.contextMenuAnchors,
      children: [
        if (widget.onAskVitty != null)
          TextButton(
            onPressed: () {
              widget.onAskVitty!(selected);
              ContextMenuController.removeAny();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ask Vitty', style: TextStyle(color: theme.text)),
                SizedBox(width: 4),
                Image.asset("assets/images/ying yang.png", height: 22)
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selected));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Copied!')));
            ContextMenuController.removeAny();
          },
          child: Text('Copy', style: TextStyle(color: theme.text)),
        ),
      ],
    );
  }

  Widget _buildTableWidget() {
    if (!_hasTableDataAvailable) {
      return const SizedBox.shrink();
    }

    final messageType = widget.message.messageType?.toLowerCase() ?? '';
    final allowTap = messageType == 'table_of_asset' || messageType == 'cards_of_asset';

    if (messageType.startsWith('table')) {
      return ComparisonTableWidget(
        heading: _availableTableHeading,
        rows: _availableTableRows,
        onRowTap: allowTap ? widget.onStockTap : null,
      );
    }

    return KeyValueTableWidget(
      heading: _availableTableHeading,
      rows: _availableTableRows,
      columnOrder: widget.message.structuredData?['columnOrder']?.cast<String>(),
      onCardTap: allowTap ? widget.onStockTap : null,
      cardSpacing: 6,
      headerBottomSpacing: 6,
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(
        maxHeight: 300,
        maxWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInlineContent(String text, TextStyle base) {
    if (text.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    final splits = text.split(_imgTokenRe);
    final matches = _imgTokenRe.allMatches(text).toList();

    int seg = 0;
    int tok = 0;

    void pushText(String s) {
      final sTrim = s.trim();
      if (sTrim.isEmpty) return;
      widgets.add(
        SelectableText.rich(
          TextSpan(
            style: base.copyWith(height: 1.6),
            children: _buildFormattedSpans(_preprocessText(sTrim), base),
          ),
          textHeightBehavior: _thb,
          contextMenuBuilder: _buildContextMenu,
        ),
      );
    }

    // First text segment
    if (seg < splits.length) pushText(splits[seg++]);

    // For each token -> image + next text
    for (; tok < matches.length && seg < splits.length; tok++, seg++) {
      final tokenMatch = matches[tok];
      final idxStr = tokenMatch.group(1);
      final idx = int.tryParse(idxStr ?? '');
      if (idx != null && idx >= 0 && idx < _imageUrls.length) {
        widgets.add(_buildImageWidget(_imageUrls[idx]));
      }
      pushText(splits[seg]);
    }

    // Any tail segments
    while (seg < splits.length) {
      pushText(splits[seg++]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets
          .expand((w) => [w, const SizedBox(height: 6)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: const [
        _AnimatedActionButton(icon: Icons.copy, size: 14, isVisible: true),
        SizedBox(width: 12),
        _AnimatedActionButton(icon: Icons.thumb_up_alt_outlined, size: 16, isVisible: true),
        SizedBox(width: 12),
        _AnimatedActionButton(icon: Icons.thumb_down_alt_outlined, size: 16, isVisible: true),
      ],
    );
  }

  Widget _buildStatusHeader() {
    final bool showStatus = _shouldShowStatus();

    if (!_hasEverShownStatus && !showStatus) {
      return const SizedBox.shrink();
    }

    final String? currentStatus = widget.message.currentStatus ?? widget.pairCurrentStatus;

    return SizedBox(
      height: showStatus ? _kStatusHeight : 0,
      child: showStatus && (currentStatus?.isNotEmpty ?? false)
          ? Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PremiumShimmerWidget(
                text: currentStatus!,
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // CRITICAL: Required for AutomaticKeepAliveClientMixin

    // print("🔄 NewBotMessageWidget build - id: ${widget.message.id}, isInitialized: ");

    final style = _bodyStyle(context);
    final messageContent = widget.message.content ?? '';

    // Use segments computed with tokens
    final preForView = _trimRightSoft(_preFull);
    final postForView = _trimLeftSoft(_postFull);

    final hasPreText = preForView.isNotEmpty;
    final hasPostText = postForView.isNotEmpty;
    final hasTable = _hasTableDataAvailable;
    final hasImages = _imageUrls.isNotEmpty;
    final hasAnyContent = hasPreText || hasPostText || hasTable || hasImages;

    final shouldShowPlaceholder =
        !hasAnyContent &&
            (widget.message.streaming ?? false) &&
            widget.isLatest &&
            !_hasEverRenderedContent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(),

          if (shouldShowPlaceholder)
            SizedBox(
              height: _kMinContentHeight,
              child: Container(),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRE (with inline images)
                if (hasPreText)
                  Container(
                    width: double.infinity,
                    child: _buildInlineContent(preForView, style),
                  ),

                // TABLE (if any)
                if (hasTable) ...[
                  if (hasPreText) const SizedBox(height: _kGapTextToBlock),
                  _buildTableWidget(),
                ],

                // POST (with inline images)
                if (hasPostText) ...[
                  if (hasTable) const SizedBox(height: _kGapBlockToText),
                  Container(
                    width: double.infinity,
                    child: _buildInlineContent(postForView, style),
                  ),
                ],

                if (!(widget.message.streaming ?? false) || hasAnyContent) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AnimatedActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isVisible;

  const _AnimatedActionButton({
    Key? key,
    required this.icon,
    required this.size,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: Colors.grey.shade600);
  }
}



extension MessageToBotWidgetAdapter on Message {
  Map<String, dynamic>? get tableDataForWidget {
    if (!isTable || structuredData == null) return null;

    // Convert your structuredData format to what BotMessageWidget expects
    switch (messageType) {
      case 'table':
        return {
          'type': 'table_of_asset', // or appropriate type
          'heading': structuredData?['title'] ?? structuredData?['heading'],
          'rows': structuredData?['rows'] ?? [],
        };
      case 'cards':
      case 'card':
        return {
          'type': 'cards_of_asset',
          'heading': structuredData?['title'] ?? structuredData?['heading'],
          'rows': structuredData?['cards'] ?? [],
          'columnOrder': structuredData?['columnOrder'],
        };
      default:
        return structuredData;
    }
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



enum MenuSide { left, right }

class IOSPopContextMenu extends StatefulWidget {
  final Widget child;                 // your message bubble
  final String previewText;           // pill text on top
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final MenuSide side;

  const IOSPopContextMenu({
    Key? key,
    required this.child,
    required this.previewText,
    required this.onCopy,
    required this.onEdit,
    this.side = MenuSide.left,
  }) : super(key: key);

  @override
  State<IOSPopContextMenu> createState() => _IOSPopContextMenuState();
}

class _IOSPopContextMenuState extends State<IOSPopContextMenu>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  OverlayEntry? _entry;

  late final AnimationController _ac;
  late final Animation<double> _scale;      // bubble pop
  late final Animation<double> _elev;       // shadow lift
  late final Animation<double> _fade;       // menu fade

  bool _showGhost = false; // hide original while ghost is shown

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ac);
    _elev  = Tween(begin: 0.0, end: 16.0).chain(CurveTween(curve: Curves.easeOut)).animate(_ac);
    _fade  = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)).animate(_ac);
  }

  @override
  void dispose() {
    _remove();
    _ac.dispose();
    super.dispose();
  }

  void _show() {
    HapticFeedback.mediumImpact();
    if (_entry != null) return;
    setState(() => _showGhost = true);

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(children: [
          // Dim + blur backdrop; tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hide,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(.12)),
              ),
            ),
          ),

          // Popped bubble (ghost), anchored to original
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 0),
            child: Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: _ac,
                builder: (context, _) {
                  return Transform.scale(
                    alignment: Alignment.centerRight, // right-aligned bubble feel
                    scale: _scale.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.18),
                            blurRadius: _elev.value,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  );
                },
              ),
            ),
          ),

          // iOS-style menu card — positioned to the LEFT (or right) of bubble
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,

            // ⬇️ place menu exactly UNDER the bubble (right edges aligned)
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,

            // ⬇️ a bit LEFT and a bit DOWN from the bubble
            // tweak gapX/gapY if you need finer control
            offset: widget.side == MenuSide.left
                ? const Offset(-12, 10)   // left shift 12px, down 8px
                : const Offset(12, 8),   // (if you ever use right-side)
            child: FadeTransition(
              opacity: _fade,
              child: _CupertinoMenuCard(
                preview: SizedBox.shrink(),
                actions: [
                  _CupertinoRowAction(
                    label: 'Copy',
                    icon: CupertinoIcons.doc_on_doc,
                    onTap: () { _hide(); widget.onCopy(); },
                  ),
                  _divider,
                  _CupertinoRowAction(
                    label: 'Edit',
                    icon: CupertinoIcons.pencil,
                    onTap: () { _hide(); widget.onEdit(); },
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _ac.forward();
  }

  void _hide() async {
    await _ac.reverse();
    _remove();
    if (mounted) setState(() => _showGhost = false);
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onLongPress: _show,
        behavior: HitTestBehavior.translucent,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _showGhost ? 0.0 : 1.0, // hide original when ghost is drawn
          child: widget.child,
        ),
      ),
    );
  }
}

/// ---- iOS-looking pieces ----

class _CupertinoMenuCard extends StatelessWidget {
  final Widget preview;
  final List<Widget> actions;
  const _CupertinoMenuCard({required this.preview, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.withOpacity(.92),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 20, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 4,  offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             // Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: preview),
              // _divider,
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

const _divider = Divider(height: 1, thickness: .5, color: Color(0x14000000));

class _CupertinoRowAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CupertinoRowAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            Icon(icon, size: 20, color: CupertinoColors.black),
          ],
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  final String text;
  const _PreviewPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        // color: CupertinoColors.systemGrey6.withOpacity(.95),
        // borderRadius: BorderRadius.circular(22),
      ),
      // child: Text(
      //   text,
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      //   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      // ),
    );
  }
}


