import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/screens/widgets/stock_tile_widget.dart';

import '../../constants/chat_typing_indicator.dart';
import '../../constants/widgets.dart';
import '../../services/chat_service.dart';
import '../../services/theme_service.dart';



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
