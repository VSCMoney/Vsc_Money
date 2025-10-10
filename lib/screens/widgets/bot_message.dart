import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/theme_service.dart';



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../testpage.dart';
import 'chat_input_widget.dart';
import 'message_bubble.dart';





class BotMessageWidget extends StatefulWidget {
  final String message;
  final bool isComplete;
  final bool isLatest;
  final bool isHistorical;
  final String? currentStatus;
  final Function(String)? onAskVitty;
  final Map<String, dynamic>? tableData;
  final Function(String)? onStockTap;
  final VoidCallback? onRenderComplete;

  const BotMessageWidget({
    Key? key,
    required this.message,
    required this.isComplete,
    this.isLatest = false,
    this.isHistorical = false,
    this.currentStatus,
    this.onAskVitty,
    this.tableData,
    this.onStockTap,
    this.onRenderComplete,
  }) : super(key: key);

  @override
  State<BotMessageWidget> createState() => _BotMessageWidgetState();
}

class _BotMessageWidgetState extends State<BotMessageWidget>
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
  String _textWithTokens = ''; // message with __IMG_n__ tokens (order-preserved)

  // ✅ HAPTIC FEEDBACK: Track states for bot response lifecycle
  bool _hasTriggeredStartHaptic = false;
  bool _hasTriggeredEndHaptic = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Extract images as tokens (order preserved)
    _extractImages(widget.message);

    // Split by table placeholder into pre/post (with tokens inside)
    _recomputeSegments(_textWithTokens.isNotEmpty ? _textWithTokens : widget.message);

    // Table availability
    _updateTableData();

    // Mark "has ever rendered"
    final hasInitialContent = widget.message.isNotEmpty ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;
    if (hasInitialContent) {
      _hasEverRenderedContent = true;
    }

    // ✅ HAPTIC FEEDBACK: Trigger start haptic if this is a new bot response
    _checkAndTriggerStartHaptic();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRenderComplete?.call();
    });
  }

  @override
  void didUpdateWidget(covariant BotMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsUpdate = false;

    if (widget.message != oldWidget.message) {
      _extractImages(widget.message);
      _recomputeSegments(_textWithTokens.isNotEmpty ? _textWithTokens : widget.message);
      needsUpdate = true;
    }

    if (widget.tableData != oldWidget.tableData) {
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
    final bool hasContent = widget.message.isNotEmpty ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;
    if (hasContent && !_hasEverRenderedContent) {
      _hasEverRenderedContent = true;
      needsUpdate = true;
    }

    // ✅ HAPTIC FEEDBACK: Check for response start
    _checkAndTriggerStartHaptic();

    // ✅ HAPTIC FEEDBACK: Check for response completion
    if (widget.isComplete != oldWidget.isComplete) {
      _checkAndTriggerEndHaptic();
      needsUpdate = true;
    }

    if (needsUpdate && mounted) setState(() {});
  }

  // ✅ HAPTIC FEEDBACK: Trigger haptic when bot response starts
  void _checkAndTriggerStartHaptic() {
    if (_hasTriggeredStartHaptic) return;

    // Trigger haptic when:
    // 1. This is the latest message
    // 2. Content or status starts appearing
    // 3. Not a historical message
    final hasContent = widget.message.isNotEmpty ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty ||
        _shouldShowStatus();

    if (widget.isLatest &&
        !widget.isHistorical &&
        hasContent &&
        !_hasTriggeredStartHaptic) {

      print("🎯 HAPTIC: Bot response started");
      HapticFeedback.mediumImpact();
      _hasTriggeredStartHaptic = true;
    }
  }

  // ✅ HAPTIC FEEDBACK: Trigger haptic when bot response completes
  void _checkAndTriggerEndHaptic() {
    if (_hasTriggeredEndHaptic) return;

    // Trigger haptic when:
    // 1. Response is marked as complete
    // 2. This is the latest message
    // 3. Not a historical message
    // 4. Has actual content (not just status)
    final hasRealContent = widget.message.isNotEmpty ||
        _hasTableDataAvailable ||
        _imageUrls.isNotEmpty;

    if (widget.isComplete &&
        widget.isLatest &&
        !widget.isHistorical &&
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

    // Combined regex: markdown, "image_url":"...", direct extensions, googleusercontent
    final imgRe = RegExp(
      r'!\[.*?\]\((https?://[^\s)]+)\)' // markdown
      r'|"\s*image_url\s*"\s*:\s*"([^"]+)"' // "image_url":"..."
      r'|(https?://[^\s]+\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\s]*)?)' // direct ext
      r'|(https://[^\s]*googleusercontent\.com/[^\s]+)', // googleusercontent
      caseSensitive: false,
    );

    final sb = StringBuffer();
    int pos = 0;
    final matches = imgRe.allMatches(message).toList();

    for (final m in matches) {
      // whichever group matched
      final url = m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4);
      if (url == null || url.isEmpty) continue;

      // append text before match
      if (m.start > pos) sb.write(message.substring(pos, m.start));

      // write token
      final idx = _imageUrls.length;
      _imageUrls.add(url);
      sb.write('__IMG_${idx}__');

      pos = m.end;
    }

    // tail
    if (pos < message.length) sb.write(message.substring(pos));

    _textWithTokens = sb.toString().trim();
  }

  void _updateTableData() {
    if (widget.tableData != null) {
      final rowsRaw = (widget.tableData!['rows'] as List?) ?? const [];
      _availableTableRows =
          rowsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      _availableTableHeading = widget.tableData!['heading']?.toString();
      _hasTableDataAvailable = _availableTableRows.isNotEmpty;
    } else {
      _availableTableRows = [];
      _availableTableHeading = null;
      _hasTableDataAvailable = false;
    }
  }

  bool _shouldShowStatus() {
    final bool validStatus = (widget.currentStatus != null &&
        widget.currentStatus!.isNotEmpty &&
        widget.currentStatus! != 'null' &&
        widget.currentStatus! != 'undefined');

    return widget.isLatest && !widget.isComplete && validStatus;
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

  // Enhanced text preprocessing for better formatting (does NOT touch tokens)
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
    if (widget.tableData == null || _availableTableRows.isEmpty) {
      return const SizedBox.shrink();
    }

    final dataType = (widget.tableData!['type']?.toString().toLowerCase() ?? '').trim();
    final allowTap = dataType == 'table_of_asset' || dataType == 'cards_of_asset';

    if (dataType.startsWith('table')) {
      return ComparisonTableWidget(
        heading: _availableTableHeading,
        rows: _availableTableRows,
        onRowTap: allowTap ? widget.onStockTap : null,
      );
    }

    return KeyValueTableWidget(
      heading: _availableTableHeading,
      rows: _availableTableRows,
      columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
      onCardTap: allowTap ? widget.onStockTap : null,
      cardSpacing: 6,
      headerBottomSpacing: 6,
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    return Container(
      // ✅ REDUCED: Smaller vertical margins to minimize bottom spacing
      margin: const EdgeInsets.symmetric(vertical: 4), // Reduced from 8 to 4
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

  /// Text + inline images renderer (order preserved via tokens)
  Widget _buildInlineContent(String text, TextStyle base) {
    if (text.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];

    final splits = text.split(_imgTokenRe); // text segments between tokens
    final matches = _imgTokenRe.allMatches(text).toList();

    int seg = 0;
    int tok = 0;

    // ✅ REMOVED: Misplaced haptic feedback from here
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
      final idxStr = tokenMatch.group(1); // (\d+)
      final idx = int.tryParse(idxStr ?? '');
      if (idx != null && idx >= 0 && idx < _imageUrls.length) {
        widgets.add(_buildImageWidget(_imageUrls[idx]));
      }
      pushText(splits[seg]);
    }

    // Any tail segments (rare)
    while (seg < splits.length) {
      pushText(splits[seg++]);
    }

    // Gap between parts
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
    // ✅ REMOVED: Misplaced haptic feedback from here
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

    return SizedBox(
      height: showStatus ? _kStatusHeight : 0,
      child: showStatus && (widget.currentStatus?.isNotEmpty ?? false)
          ? Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final style = _bodyStyle(context);

    // Use segments computed with tokens
    final preForView = _trimRightSoft(_preFull);
    final postForView = _trimLeftSoft(_postFull);

    final hasPreText = preForView.isNotEmpty;
    final hasPostText = postForView.isNotEmpty;
    final hasTable = _hasTableDataAvailable;
    final hasImages = _imageUrls.isNotEmpty; // content presence
    final hasAnyContent = hasPreText || hasPostText || hasTable || hasImages;

    final shouldShowPlaceholder =
        !hasAnyContent &&
        !widget.isComplete &&
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

                if (widget.isComplete || hasAnyContent) ...[
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

///////////////////////////////// New Bot Message Widget////////////////////////////////////

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



class NewBotResponsesList extends StatefulWidget {
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
  State<NewBotResponsesList> createState() => _NewBotResponsesListState();
}

class _NewBotResponsesListState extends State<NewBotResponsesList> {
  bool _showOrb = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowOrb();
  }

  @override
  void didUpdateWidget(NewBotResponsesList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasStreaming = oldWidget.pair.isStreaming;
    final isNowStreaming = widget.pair.isStreaming;

    if (!wasStreaming && isNowStreaming) {
      setState(() => _showOrb = false);
      _checkAndShowOrb();
    }
  }

  void _checkAndShowOrb() {
    final items = widget.pair.botResponses;
    final hasStatus = widget.pair.currentStatus != null &&
        widget.pair.currentStatus!.trim().isNotEmpty;
    final hasContent = items.isNotEmpty &&
        (items.any((msg) => (msg.content?.isNotEmpty ?? false) ||
            msg.isTable ||
            (msg.structuredData != null)));

    if (widget.pair.isStreaming && !hasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _showOrb = true);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.pair.botResponses;

    final hasStatus = widget.pair.currentStatus != null &&
        widget.pair.currentStatus!.trim().isNotEmpty;
    final hasContent = items.isNotEmpty &&
        (items.any((msg) => (msg.content?.isNotEmpty ?? false) ||
            msg.isTable ||
            (msg.structuredData != null)));

    final shouldShowOrbRow = widget.pair.isStreaming && !hasContent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED: Orb row with consistent positioning
          if (shouldShowOrbRow) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 22), // ✅ Same as message padding
              child: AnimatedOpacity(
                opacity: _showOrb ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedScale(
                  scale: _showOrb ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // ⬅️ top-align everything
                    children: [
                      // ORB pinned to first line top
                      Padding(
                        padding: const EdgeInsets.only(top: 2), // tweak 0–3px to match cap height
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: OrbWithBackplate(
                            size: 25,
                            backplatePad: 25,
                            lottie: 'assets/images/retry3.json',
                            nudge: const Offset(0, -2),
                          ),
                        ),
                      ),

                      if (hasStatus) ...[
                        const SizedBox(width: 22),

                        // Status text can wrap; orb won't move now
                        Flexible(
                          child: PremiumShimmerWidget(
                            text: widget.pair.currentStatus!,
                            isComplete: false,
                            baseColor: Colors.black.withOpacity(0.78),
                            highlightColor: const Color(0xFF9CA3AF),
                            // if your widget supports these:
                            maxLines: 2,              // avoid 3+ line spikes
                           // overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ✅ Messages with EXACT same padding as orb row
          for (int i = 0; i < items.length; i++)
            NewBotMessageWidget(
              key: ValueKey('bot_msg_${items[i].id ?? '${widget.pair.hashCode}_$i'}'),
              message: items[i],
              isLatest: i == items.length - 1,
              pairCurrentStatus: widget.pair.currentStatus,
              onAskVitty: widget.onAskVitty,
              onStockTap: widget.onStockTap,
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
    if (!full.contains(_kPlaceholder)) {
      _preFull = full;
      _postFull = '';
      print('📝 No placeholder found - all text in _preFull');
      return;
    }

    final idx = full.indexOf(_kPlaceholder);
    if (idx == -1) {
      _preFull = full;
      _postFull = '';
    } else {
      _preFull = full.substring(0, idx);
      _postFull = full.substring(idx + _kPlaceholder.length);

      print('📝 Split at placeholder:');
      print('   _preFull: ${_preFull.substring(0, math.min(50, _preFull.length))}...');
      print('   _postFull: ${_postFull.substring(0, math.min(50, _postFull.length))}...');
    }
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

      // ✅ Preserve text before image (including newlines)
      if (m.start > pos) {
        sb.write(message.substring(pos, m.start));
      }

      final idx = _imageUrls.length;
      _imageUrls.add(url);
      sb.write('__IMG_${idx}__');

      pos = m.end;
    }

    // ✅ Don't forget remaining text
    if (pos < message.length) {
      sb.write(message.substring(pos));
    }

    _textWithTokens = sb.toString(); // ✅ Don't trim - preserve structure
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
    // ✅ Return empty for truly empty text
    if (text.trim().isEmpty) return const SizedBox.shrink();

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

    // ✅ Process all segments with images
    while (seg < splits.length || tok < matches.length) {
      // Add text segment if available
      if (seg < splits.length) {
        pushText(splits[seg]);
        seg++;
      }

      // Add image if available
      if (tok < matches.length) {
        final tokenMatch = matches[tok];
        final idxStr = tokenMatch.group(1);
        final idx = int.tryParse(idxStr ?? '');
        if (idx != null && idx >= 0 && idx < _imageUrls.length) {
          widgets.add(_buildImageWidget(_imageUrls[idx]));
        }
        tok++;
      }
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

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
          //   _buildStatusHeader(),

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
        // ✅ APPEND, DON'T OVERWRITE
        setState(() {
          _displayText += chunk;
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
                _displayText = botMsg.content ?? _displayText;
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
                  // // Status header (when waiting for first chunk)
                  // if (waitingForFirstChunk && hasStatus)
                  //   _StatusHeader(
                  //     isLatest: widget.isLatest,
                  //     isComplete: false,
                  //     currentStatus: _currentStatus,
                  //   )
                  // else if (waitingForFirstChunk && !hasStatus)
                  //   const TypingIndicatorWithHaptics(),

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
  static const String kTablePlaceholder = '___TABLE_PLACEHOLDER___';

  static ChatMessage parseChatMessage(Map<String, dynamic> rawData) {
    final id = rawData['id'] ?? UniqueKey().toString();
    final text = rawData['text'] ?? '';
    final isUser = rawData['isUser'] ?? false;
    final timestamp = rawData['timestamp'] != null
        ? DateTime.parse(rawData['timestamp'])
        : DateTime.now();
    final isComplete = rawData['isComplete'] ?? true;

    String? currentStatus;
    bool isTable = false;
    Map<String, dynamic>? structuredData;
    String? messageType;

    if (rawData['chunk'] != null) {
      final chunk = StreamChunk.fromJson(rawData['chunk']);

      if (chunk.isStatusUpdate) {
        currentStatus = chunk.statusReason;
      }

      if (chunk.isResponse) {
        // ✅ SAFE: payload ko rawData se uthao (koi custom getter nahi chahiye)
        Map<String, dynamic>? payload;
        if (rawData['chunk'] is Map<String, dynamic>) {
          final m = rawData['chunk'] as Map<String, dynamic>;
          payload = m['payload'] as Map<String, dynamic>?;
        }

        final responseType = payload?['type'];
        final responseData = payload?['data'];

        if (responseType == 'json' && responseData is Map<String, dynamic>) {
          final normalized = _normalizeStructured(responseData);
          if (normalized != null) {
            structuredData = normalized.data;
            messageType = normalized.messageType;
            isTable = true;
          }
        }
      }
    }

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

  static String? extractStatusFromChunk(Map<String, dynamic> chunkData) {
    if (chunkData['type'] == 'status_update') {
      return chunkData['payload']?['reason'];
    }
    return null;
  }

  static Map<String, dynamic>? extractStructuredDataFromChunk(
      Map<String, dynamic> chunkData) {
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

  /// normalizes:
  ///  - type: cards_of_* -> messageType 'cards', with list -> cards
  ///  - type: table_of_* -> messageType 'table', rows as-is
  ///  - keeps optional heading/columnOrder
  static _Normalized? _normalizeStructured(Map<String, dynamic> data) {
    final t = (data['type'] ?? '').toString().toLowerCase();
    if (t.isEmpty) return null;

    if (t.startsWith('cards')) {
      return _Normalized(
        messageType: 'cards',
        data: {
          'heading': data['heading'],
          'cards': data['list'] ?? data['cards'] ?? [],
          'columnOrder': data['columnOrder'],
          // keep an easy flag for UI allowing taps on assets
          'type': t, // original type retained
        },
      );
    }

    if (t.startsWith('table')) {
      return _Normalized(
        messageType: 'table',
        data: {
          'heading': data['heading'],
          'rows': data['rows'] ?? [],
          'columnOrder': data['columnOrder'],
          'type': t,
        },
      );
    }

    return null;
  }
}

class _Normalized {
  final String messageType;
  final Map<String, dynamic> data;
  _Normalized({required this.messageType, required this.data});
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