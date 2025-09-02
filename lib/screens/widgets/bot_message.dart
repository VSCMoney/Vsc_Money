import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';



import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final bool? forceStop;
  final String? stopTs;

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
    this.forceStop,
    this.stopTs,
  }) : super(key: key);

  @override
  State<BotMessageWidget> createState() => _BotMessageWidgetState();
}

class _BotMessageWidgetState extends State<BotMessageWidget>
    with AutomaticKeepAliveClientMixin {
  // --------------------------------- spacing + typing ---------------------------------
  static const _kPlaceholder = '___TABLE_PLACEHOLDER___';
  static const int _cps = 130;
  static const int _postHoldMs = 900;

  // compact, controlled gaps between segments
  static const double _kGapTextToBlock = 6.0;
  static const double _kGapBlockToText = 8.0;

  // trim extra ascent/descent so lines don't add hidden top/bottom space
  static const TextHeightBehavior _thb = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  Timer? _timer;
  bool _isTyping = false;
  bool _hasCompletedTyping = false;
  bool _wasForceStopped = false;

  String _preFull = '';
  String _postFull = '';
  int _preShown = 0;
  int _postShown = 0;

  List<Map<String, dynamic>> _availableTableRows = [];
  String? _availableTableHeading;
  bool _hasTableDataAvailable = false;
  bool _shouldShowTable = false;
  bool _postDelayApplied = false;

  // Stable state by message content (+ historical flag). DO NOT include isLatest.
  static final Map<String, _StreamingState> _streamingStates = {};
  String get _stateKey {
    final base = widget.message.hashCode;
    return '${base}_${widget.isHistorical}';
  }

  int get _intervalMs => 1000 ~/ _cps;
  String get _preDisplay => _preFull.substring(0, _preShown.clamp(0, _preFull.length));
  String get _postDisplay => _postFull.substring(0, _postShown.clamp(0, _postFull.length));
  bool get _reachedPlaceholder => _preShown >= _preFull.length;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("🎬 BotMessage: initState message hash: ${widget.message.hashCode}");
    _initializeWidget();
  }

  void _initializeWidget() {
    _recomputeSegments(widget.message);
    _updateTableData();

    final shouldRestoreState = _streamingStates.containsKey(_stateKey) &&
        !_streamingStates[_stateKey]!.wasCompleted &&
        !_streamingStates[_stateKey]!.wasForceStopped;

    if (shouldRestoreState) {
      debugPrint("🔄 BotMessage: Restoring existing state for key: $_stateKey");
      _restoreStreamingState(_streamingStates[_stateKey]!);
      return;
    }

    if (_streamingStates.containsKey(_stateKey) &&
        (_streamingStates[_stateKey]!.wasCompleted ||
            _streamingStates[_stateKey]!.wasForceStopped)) {
      _streamingStates.remove(_stateKey);
    }

    // Show instantly only if historical or explicitly force-stopped
    if (widget.forceStop == true || widget.isHistorical) {
      debugPrint("🚀 BotMessage: Showing instantly (historical/forceStop)");
      _showInstantly();
      return;
    }

    // Latest message always typewriters (even if isComplete already true)
    if (widget.isLatest) {
      debugPrint("🚀 BotMessage: Starting streaming for latest message");
      _startContinuousStreaming();
      return;
    }

    // Non-latest messages render instantly
    debugPrint("🚀 BotMessage: Showing instantly (non-latest)");
    _showInstantly();
  }

  void _saveStreamingState() {
    _streamingStates[_stateKey] = _StreamingState(
      preShown: _preShown,
      postShown: _postShown,
      shouldShowTable: _shouldShowTable,
      postDelayApplied: _postDelayApplied,
      wasCompleted: _hasCompletedTyping,
      wasForceStopped: _wasForceStopped,
    );
  }

  void _restoreStreamingState(_StreamingState s) {
    _preShown = s.preShown;
    _postShown = s.postShown;
    _shouldShowTable = s.shouldShowTable;
    _postDelayApplied = s.postDelayApplied;
    _hasCompletedTyping = s.wasCompleted;
    _wasForceStopped = s.wasForceStopped;

    if (!_hasCompletedTyping && !_wasForceStopped) {
      _isTyping = true;
      _timer = Timer.periodic(Duration(milliseconds: _intervalMs), _continuousStreamingTick);
      debugPrint("🔄 BotMessage: Resumed streaming from $_preShown");
    } else {
      setState(() {});
    }
  }

  void _showInstantly() {
    _preShown = _preFull.length;
    _postShown = _postFull.length;
    _hasCompletedTyping = true;
    _shouldShowTable = _hasTableDataAvailable;
    _wasForceStopped = widget.forceStop == true;

    _saveStreamingState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRenderComplete?.call();
    });
  }

  void _recomputeSegments(String full) {
    final parts = full.split(_kPlaceholder);
    _preFull = parts.isNotEmpty ? parts.first : '';
    _postFull = parts.length > 1 ? parts.sublist(1).join(_kPlaceholder) : '';

    _preShown = _preShown.clamp(0, _preFull.length);
    _postShown = _postShown.clamp(0, _postFull.length);
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
      _shouldShowTable = false;
    }
  }

  bool _shouldRebuild(BotMessageWidget oldWidget) {
    if (widget.message == oldWidget.message &&
        widget.isComplete == oldWidget.isComplete &&
        /* isLatest intentionally ignored */
        widget.isHistorical == oldWidget.isHistorical &&
        widget.forceStop == oldWidget.forceStop &&
        widget.tableData == oldWidget.tableData &&
        widget.currentStatus == oldWidget.currentStatus) {
      return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(BotMessageWidget old) {
    super.didUpdateWidget(old);
    if (!_shouldRebuild(old)) {
      debugPrint("⏭️ BotMessage: Skipping unnecessary update");
      return;
    }

    if (old.isLatest && !widget.isLatest) {
      debugPrint("🧍 BotMessage: Demoted from latest → non-latest, freezing state");
      _timer?.cancel();
      _isTyping = false;
      if (widget.isComplete && !_hasCompletedTyping) {
        _finishStreaming();
        return;
      }
      _saveStreamingState();
      setState(() {});
      return;
    }

    debugPrint(
        "🔄 UPDATE - Key: $_stateKey, Message changed: ${widget.message != old.message}, Complete changed: ${widget.isComplete != old.isComplete}");

    if (widget.message != old.message) {
      debugPrint("📝 BotMessage: Message content updated during streaming");
      _recomputeSegments(widget.message);

      if (!_hasCompletedTyping && !_wasForceStopped && !_isTyping) {
        final hasAnyContent =
            _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
        if (hasAnyContent && widget.isLatest && !widget.isHistorical) {
          _startContinuousStreaming();
        }
      }
      _saveStreamingState();
      setState(() {});
    }

    if (widget.tableData != old.tableData) {
      _updateTableData();
      if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
        _shouldShowTable = true;
      }
      setState(() {});
    }

    if (widget.currentStatus != old.currentStatus) {
      if (!_hasCompletedTyping) {
        if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
          _pauseForStatus();
        } else if (!_wasForceStopped) {
          _resumeFromStatus();
        }
      }
      setState(() {});
    }

    final stopTsChanged = widget.stopTs != old.stopTs && widget.stopTs != null;
    if ((widget.forceStop == true && old.forceStop != true) || stopTsChanged) {
      _handleForceStop();
      return;
    }

    if (widget.isComplete && !old.isComplete && !_hasCompletedTyping) {
      _finishStreaming();
    }
  }

  void _handleForceStop() {
    debugPrint("🛑 Force stop detected");
    _timer?.cancel();
    _isTyping = false;
    _wasForceStopped = true;
    _hasCompletedTyping = true;
    if (_hasTableDataAvailable && _reachedPlaceholder) _shouldShowTable = true;
    _saveStreamingState();
    setState(() {});
    widget.onRenderComplete?.call();
  }

  void _startContinuousStreaming() {
    if (_hasCompletedTyping || _wasForceStopped || widget.forceStop == true) return;

    final hasAnyContent =
        _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
    if (!hasAnyContent) return;
    if (_isTyping) return;

    debugPrint("🚀 BotMessage: Starting continuous streaming");
    _isTyping = true;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), _continuousStreamingTick);
  }

  void _pauseForStatus() {
    if (_isTyping) {
      _timer?.cancel();
      _isTyping = false;
      _saveStreamingState();
      debugPrint("⏸️ BotMessage: Paused for status");
    }
  }

  void _resumeFromStatus() {
    if (!_hasCompletedTyping && !_wasForceStopped && !_isTyping) {
      debugPrint("▶️ BotMessage: Resuming from status pause");
      _startContinuousStreaming();
    }
  }

  void _finishStreaming() {
    debugPrint("✅ BotMessage: Finishing streaming");

    _recomputeSegments(widget.message);
    _updateTableData();

    _preShown = _preFull.length;
    if (_hasTableDataAvailable) _shouldShowTable = true;
    _postShown = _postFull.length;

    _timer?.cancel();
    _isTyping = false;
    _hasCompletedTyping = true;

    _saveStreamingState();
    if (mounted) setState(() {});
    if (!_wasForceStopped) widget.onRenderComplete?.call();
  }

  void _applyPostDelayOnce() {
    if (_postDelayApplied || _wasForceStopped) return;
    _postDelayApplied = true;
    Future.delayed(const Duration(milliseconds: _postHoldMs), () {
      if (!mounted || _hasCompletedTyping || _wasForceStopped) return;
    });
  }

  void _continuousStreamingTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    if (widget.forceStop == true || _wasForceStopped) {
      _handleForceStop();
      return;
    }
    if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
      _pauseForStatus();
      return;
    }

    if (_preShown < _preFull.length) {
      setState(() => _preShown++);
      _saveStreamingState();
      return;
    }

    if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
      setState(() => _shouldShowTable = true);
      _applyPostDelayOnce();
      _saveStreamingState();
      return;
    }

    if (_postDelayApplied && _postShown < _postFull.length) {
      setState(() => _postShown++);
      _saveStreamingState();
      return;
    }

    final allPreDone = _preShown >= _preFull.length;
    final allPostDone = _postFull.isEmpty || _postShown >= _postFull.length;
    final tableOk = !_hasTableDataAvailable || _shouldShowTable;

    if (allPreDone && allPostDone && tableOk) {
      _finishStreaming();
    }
  }

  @override
  void dispose() {
    debugPrint("🧹 BotMessage: Disposing timer");
    _timer?.cancel();
    if (_hasCompletedTyping || _wasForceStopped) {
      _streamingStates.remove(_stateKey);
    }
    super.dispose();
  }

  // --------------------------------- UI helpers ---------------------------------

  TextStyle _bodyStyle(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    return TextStyle(
      fontFamily: 'SF Pro',
      fontSize: 16,
     //fontWeight: FontWeight.w600,
      height: 1.5,
      color: textColor,
    );
  }

  String _trimRightSoft(String s) {
    return s.replaceAll(RegExp(r'[\n\s]+$'), '');
  }

  String _trimLeftSoft(String s) {
    return s.replaceAll(RegExp(r'^\s+'), '');
  }

  Widget _buildStatusIndicator() {
    final status = widget.currentStatus;
    final hasValidStatus =
        status != null && status.isNotEmpty && status != 'null' && status != 'undefined';
    if (!hasValidStatus) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: PremiumShimmerWidget(
        text: status,
        isComplete: false,
        baseColor: const Color(0xFF9CA3AF),
        highlightColor: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildTypewriterCursor() {
    final show = _isTyping &&
        !_hasCompletedTyping &&
        !_wasForceStopped &&
        !widget.isHistorical &&
        !widget.isComplete;
    if (!show) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2) % 1.0 > 0.5 ? 1.0 : 0.3,
          child: Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }

  List<TextSpan> _buildFormattedSpans(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final bold = RegExp(r"\*\*(.+?)\*\*");
    int last = 0;
    for (final m in bold.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(fontWeight: FontWeight.w400, height: 2, fontFamily: "SF Pro"),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState s) {
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
                const Text('Ask Vitty', style: TextStyle(color: Colors.black)),
                const SizedBox(width: 8),
                Image.asset('assets/images/vitty.png', width: 20, height: 20),
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
          child: const Text('Copy', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildTableWidget() {
    if (widget.tableData == null || _availableTableRows.isEmpty) {
      return const SizedBox.shrink();
    }

    final dataType = (widget.tableData!['type']?.toString().toLowerCase() ?? '').trim();

    // ✅ Only allow tap when type is for assets; block for market lists
    final allowTap = dataType == 'table_of_asset' || dataType == 'cards_of_asset';

    if (dataType.startsWith('table')) {
      return ComparisonTableWidget(
        heading: _availableTableHeading,
        rows: _availableTableRows,
        onRowTap: allowTap ? widget.onStockTap : null, // <- disable taps for market
      );
    }

    // Cards (key-value)
    return KeyValueTableWidget(
      heading: _availableTableHeading,
      rows: _availableTableRows,
      columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
      onCardTap: allowTap ? widget.onStockTap : null, // <- disable taps for market
      cardSpacing: 6,
      headerBottomSpacing: 6,
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

  // --------------------------------- build ---------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep-alive
    final style = _bodyStyle(context);

    // Trim only the edges around the placeholder to kill invisible gaps.
    final preForView = _trimRightSoft(_preDisplay);
    final postForView = _trimLeftSoft(_postDisplay);

    final hasPreText = preForView.isNotEmpty;
    final hasPostText = postForView.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(),

          if (hasPreText)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(style: style, children: _buildFormattedSpans(preForView, style)),
                    textHeightBehavior: _thb,
                    contextMenuBuilder: _buildContextMenu,
                  ),
                ),
                if ((_isTyping && !_hasCompletedTyping && !_wasForceStopped) &&
                    (!_shouldShowTable || _preShown < _preFull.length))
                  _buildTypewriterCursor(),
              ],
            ),

          if (_shouldShowTable && _availableTableRows.isNotEmpty) ...[
            if (hasPreText) const SizedBox(height: _kGapTextToBlock),
            _buildTableWidget(),
          ],

          if (hasPostText) ...[
            if (_shouldShowTable) const SizedBox(height: _kGapBlockToText),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(style: style, children: _buildFormattedSpans(postForView, style)),
                    textHeightBehavior: _thb,
                    contextMenuBuilder: _buildContextMenu,
                  ),
                ),
                if (_shouldShowTable &&
                    _isTyping &&
                    !_hasCompletedTyping &&
                    !_wasForceStopped &&
                    _postShown < _postFull.length)
                  _buildTypewriterCursor(),
              ],
            ),
          ],

          if ((_hasCompletedTyping || widget.isComplete || _wasForceStopped) && !_isTyping) ...[
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }
}

class _StreamingState {
  final int preShown;
  final int postShown;
  final bool shouldShowTable;
  final bool postDelayApplied;
  final bool wasCompleted;
  final bool wasForceStopped;

  _StreamingState({
    required this.preShown,
    required this.postShown,
    required this.shouldShowTable,
    required this.postDelayApplied,
    required this.wasCompleted,
    required this.wasForceStopped,
  });
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
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Icon(icon, size: size, color: Colors.grey.shade600),
    );
  }
}


// class BotMessageWidget extends StatefulWidget {
//   final String message;
//   final bool isComplete;
//   final bool isLatest;
//   final bool isHistorical;
//   final String? currentStatus;
//   final Function(String)? onAskVitty;
//   final Map<String, dynamic>? tableData;
//   final Function(String)? onStockTap;
//   final VoidCallback? onRenderComplete;
//   final bool? forceStop;
//   final String? stopTs;
//
//   const BotMessageWidget({
//     Key? key,
//     required this.message,
//     required this.isComplete,
//     this.isLatest = false,
//     this.isHistorical = false,
//     this.currentStatus,
//     this.onAskVitty,
//     this.tableData,
//     this.onStockTap,
//     this.onRenderComplete,
//     this.forceStop,
//     this.stopTs,
//   }) : super(key: key);
//
//   @override
//   State<BotMessageWidget> createState() => _BotMessageWidgetState();
// }
//
// class _BotMessageWidgetState extends State<BotMessageWidget>
//     with AutomaticKeepAliveClientMixin {
//   // --------------------------------- spacing + typing ---------------------------------
//   static const _kPlaceholder = '___TABLE_PLACEHOLDER___';
//   static const int _cps = 130;
//   static const int _postHoldMs = 900;
//
//   // compact, controlled gaps between segments
//   static const double _kGapTextToBlock = 6.0;
//   static const double _kGapBlockToText = 8.0;
//
//   // trim extra ascent/descent so lines don't add hidden top/bottom space
//   static const TextHeightBehavior _thb = TextHeightBehavior(
//     applyHeightToFirstAscent: false,
//     applyHeightToLastDescent: false,
//   );
//
//   Timer? _timer;
//   bool _isTyping = false;
//   bool _hasCompletedTyping = false;
//   bool _wasForceStopped = false;
//
//   String _preFull = '';
//   String _postFull = '';
//   int _preShown = 0;
//   int _postShown = 0;
//
//   List<Map<String, dynamic>> _availableTableRows = [];
//   String? _availableTableHeading;
//   bool _hasTableDataAvailable = false;
//   bool _shouldShowTable = false;
//   bool _postDelayApplied = false;
//
//   // Stable state by message content (+ historical flag). DO NOT include isLatest.
//   static final Map<String, _StreamingState> _streamingStates = {};
//   String get _stateKey {
//     final base = widget.message.hashCode;
//     return '${base}_${widget.isHistorical}';
//   }
//
//   int get _intervalMs => 1000 ~/ _cps;
//   String get _preDisplay => _preFull.substring(0, _preShown.clamp(0, _preFull.length));
//   String get _postDisplay => _postFull.substring(0, _postShown.clamp(0, _postFull.length));
//   bool get _reachedPlaceholder => _preShown >= _preFull.length;
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//     debugPrint("🎬 BotMessage: initState message hash: ${widget.message.hashCode}");
//     _initializeWidget();
//   }
//
//   void _initializeWidget() {
//     _recomputeSegments(widget.message);
//     _updateTableData();
//
//     final shouldRestoreState = _streamingStates.containsKey(_stateKey) &&
//         !_streamingStates[_stateKey]!.wasCompleted &&
//         !_streamingStates[_stateKey]!.wasForceStopped;
//
//     if (shouldRestoreState) {
//       debugPrint("🔄 BotMessage: Restoring existing state for key: $_stateKey");
//       _restoreStreamingState(_streamingStates[_stateKey]!);
//       return;
//     }
//
//     if (_streamingStates.containsKey(_stateKey) &&
//         (_streamingStates[_stateKey]!.wasCompleted ||
//             _streamingStates[_stateKey]!.wasForceStopped)) {
//       _streamingStates.remove(_stateKey);
//     }
//
//     // Show instantly only if historical or explicitly force-stopped
//     if (widget.forceStop == true || widget.isHistorical) {
//       debugPrint("🚀 BotMessage: Showing instantly (historical/forceStop)");
//       _showInstantly();
//       return;
//     }
//
//     // Latest message always typewriters (even if isComplete already true)
//     if (widget.isLatest) {
//       debugPrint("🚀 BotMessage: Starting streaming for latest message");
//       _startContinuousStreaming();
//       return;
//     }
//
//     // Non-latest messages render instantly
//     debugPrint("🚀 BotMessage: Showing instantly (non-latest)");
//     _showInstantly();
//   }
//
//   void _saveStreamingState() {
//     _streamingStates[_stateKey] = _StreamingState(
//       preShown: _preShown,
//       postShown: _postShown,
//       shouldShowTable: _shouldShowTable,
//       postDelayApplied: _postDelayApplied,
//       wasCompleted: _hasCompletedTyping,
//       wasForceStopped: _wasForceStopped,
//     );
//   }
//
//   void _restoreStreamingState(_StreamingState s) {
//     _preShown = s.preShown;
//     _postShown = s.postShown;
//     _shouldShowTable = s.shouldShowTable;
//     _postDelayApplied = s.postDelayApplied;
//     _hasCompletedTyping = s.wasCompleted;
//     _wasForceStopped = s.wasForceStopped;
//
//     if (!_hasCompletedTyping && !_wasForceStopped) {
//       _isTyping = true;
//       _timer = Timer.periodic(Duration(milliseconds: _intervalMs), _continuousStreamingTick);
//       debugPrint("🔄 BotMessage: Resumed streaming from $_preShown");
//     } else {
//       setState(() {});
//     }
//   }
//
//   void _showInstantly() {
//     _preShown = _preFull.length;
//     _postShown = _postFull.length;
//     _hasCompletedTyping = true;
//     _shouldShowTable = _hasTableDataAvailable;
//     _wasForceStopped = widget.forceStop == true;
//
//     _saveStreamingState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) widget.onRenderComplete?.call();
//     });
//   }
//
//   void _recomputeSegments(String full) {
//     // Split once; trimming is handled at render-time to preserve typing cadence.
//     final parts = full.split(_kPlaceholder);
//     _preFull = parts.isNotEmpty ? parts.first : '';
//     _postFull = parts.length > 1 ? parts.sublist(1).join(_kPlaceholder) : '';
//
//     _preShown = _preShown.clamp(0, _preFull.length);
//     _postShown = _postShown.clamp(0, _postFull.length);
//   }
//
//   void _updateTableData() {
//     if (widget.tableData != null) {
//       final rowsRaw = (widget.tableData!['rows'] as List?) ?? const [];
//       _availableTableRows =
//           rowsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
//       _availableTableHeading = widget.tableData!['heading']?.toString();
//       _hasTableDataAvailable = _availableTableRows.isNotEmpty;
//     } else {
//       _availableTableRows = [];
//       _availableTableHeading = null;
//       _hasTableDataAvailable = false;
//       _shouldShowTable = false;
//     }
//   }
//
//   bool _shouldRebuild(BotMessageWidget oldWidget) {
//     if (widget.message == oldWidget.message &&
//         widget.isComplete == oldWidget.isComplete &&
//         /* isLatest intentionally ignored */
//         widget.isHistorical == oldWidget.isHistorical &&
//         widget.forceStop == oldWidget.forceStop &&
//         widget.tableData == oldWidget.tableData &&
//         widget.currentStatus == oldWidget.currentStatus) {
//       return false;
//     }
//     return true;
//   }
//
//   @override
//   void didUpdateWidget(BotMessageWidget old) {
//     super.didUpdateWidget(old);
//     if (!_shouldRebuild(old)) {
//       debugPrint("⏭️ BotMessage: Skipping unnecessary update");
//       return;
//     }
//
//     // Demotion guard: when last bubble stops being latest, freeze current view.
//     if (old.isLatest && !widget.isLatest) {
//       debugPrint("🧍 BotMessage: Demoted from latest → non-latest, freezing state");
//       _timer?.cancel();
//       _isTyping = false;
//       if (widget.isComplete && !_hasCompletedTyping) {
//         _finishStreaming();
//         return;
//       }
//       _saveStreamingState();
//       setState(() {});
//       return;
//     }
//
//     debugPrint(
//         "🔄 UPDATE - Key: $_stateKey, Message changed: ${widget.message != old.message}, Complete changed: ${widget.isComplete != old.isComplete}");
//
//     if (widget.message != old.message) {
//       debugPrint("📝 BotMessage: Message content updated during streaming");
//       _recomputeSegments(widget.message);
//
//       if (!_hasCompletedTyping && !_wasForceStopped && !_isTyping) {
//         final hasAnyContent =
//             _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
//         if (hasAnyContent && widget.isLatest && !widget.isHistorical) {
//           _startContinuousStreaming();
//         }
//       }
//       _saveStreamingState();
//       setState(() {});
//     }
//
//     if (widget.tableData != old.tableData) {
//       _updateTableData();
//       if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
//         _shouldShowTable = true;
//       }
//       setState(() {});
//     }
//
//     if (widget.currentStatus != old.currentStatus) {
//       if (!_hasCompletedTyping) {
//         if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
//           _pauseForStatus();
//         } else if (!_wasForceStopped) {
//           _resumeFromStatus();
//         }
//       }
//       setState(() {});
//     }
//
//     // Force stop
//     final stopTsChanged = widget.stopTs != old.stopTs && widget.stopTs != null;
//     if ((widget.forceStop == true && old.forceStop != true) || stopTsChanged) {
//       _handleForceStop();
//       return;
//     }
//
//     // Completion flips: finish whatever is left right now.
//     if (widget.isComplete && !old.isComplete && !_hasCompletedTyping) {
//       _finishStreaming();
//     }
//   }
//
//   void _handleForceStop() {
//     debugPrint("🛑 Force stop detected");
//     _timer?.cancel();
//     _isTyping = false;
//     _wasForceStopped = true;
//     _hasCompletedTyping = true;
//     if (_hasTableDataAvailable && _reachedPlaceholder) _shouldShowTable = true;
//     _saveStreamingState();
//     setState(() {});
//     widget.onRenderComplete?.call();
//   }
//
//   void _startContinuousStreaming() {
//     if (_hasCompletedTyping || _wasForceStopped || widget.forceStop == true) return;
//
//     final hasAnyContent =
//         _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
//     if (!hasAnyContent) return;
//     if (_isTyping) return;
//
//     debugPrint("🚀 BotMessage: Starting continuous streaming");
//     _isTyping = true;
//     _timer?.cancel();
//     _timer = Timer.periodic(Duration(milliseconds: _intervalMs), _continuousStreamingTick);
//   }
//
//   void _pauseForStatus() {
//     if (_isTyping) {
//       _timer?.cancel();
//       _isTyping = false;
//       _saveStreamingState();
//       debugPrint("⏸️ BotMessage: Paused for status");
//     }
//   }
//
//   void _resumeFromStatus() {
//     if (!_hasCompletedTyping && !_wasForceStopped && !_isTyping) {
//       debugPrint("▶️ BotMessage: Resuming from status pause");
//       _startContinuousStreaming();
//     }
//   }
//
//   void _finishStreaming() {
//     debugPrint("✅ BotMessage: Finishing streaming");
//
//     _recomputeSegments(widget.message);
//     _updateTableData();
//
//     _preShown = _preFull.length;
//     if (_hasTableDataAvailable) _shouldShowTable = true;
//     _postShown = _postFull.length;
//
//     _timer?.cancel();
//     _isTyping = false;
//     _hasCompletedTyping = true;
//
//     _saveStreamingState();
//     if (mounted) setState(() {});
//     if (!_wasForceStopped) widget.onRenderComplete?.call();
//   }
//
//   void _applyPostDelayOnce() {
//     if (_postDelayApplied || _wasForceStopped) return;
//     _postDelayApplied = true;
//     Future.delayed(const Duration(milliseconds: _postHoldMs), () {
//       if (!mounted || _hasCompletedTyping || _wasForceStopped) return;
//     });
//   }
//
//   void _continuousStreamingTick(Timer t) {
//     if (!mounted) {
//       t.cancel();
//       return;
//     }
//     if (widget.forceStop == true || _wasForceStopped) {
//       _handleForceStop();
//       return;
//     }
//     if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
//       _pauseForStatus();
//       return;
//     }
//
//     if (_preShown < _preFull.length) {
//       setState(() => _preShown++);
//       _saveStreamingState();
//       return;
//     }
//
//     if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
//       setState(() => _shouldShowTable = true);
//       _applyPostDelayOnce();
//       _saveStreamingState();
//       return;
//     }
//
//     if (_postDelayApplied && _postShown < _postFull.length) {
//       setState(() => _postShown++);
//       _saveStreamingState();
//       return;
//     }
//
//     final allPreDone = _preShown >= _preFull.length;
//     final allPostDone = _postFull.isEmpty || _postShown >= _postFull.length;
//     final tableOk = !_hasTableDataAvailable || _shouldShowTable;
//
//     if (allPreDone && allPostDone && tableOk) {
//       _finishStreaming();
//     }
//   }
//
//   @override
//   void dispose() {
//     debugPrint("🧹 BotMessage: Disposing timer");
//     _timer?.cancel();
//     if (_hasCompletedTyping || _wasForceStopped) {
//       _streamingStates.remove(_stateKey);
//     }
//     super.dispose();
//   }
//
//   // --------------------------------- UI helpers ---------------------------------
//
//   TextStyle _bodyStyle(BuildContext context) {
//     final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
//     return TextStyle(
//       fontFamily: 'SF Pro',
//       fontSize: 16,
//       fontWeight: FontWeight.w400,
//       height: 1.4, // 🔻 tighter line-height
//       color: textColor,
//     );
//   }
//
//   String _trimRightSoft(String s) {
//     // remove trailing newlines/spaces only; keeps typing natural
//     return s.replaceAll(RegExp(r'[\n\s]+$'), '');
//   }
//
//   String _trimLeftSoft(String s) {
//     // remove leading newlines/spaces only
//     return s.replaceAll(RegExp(r'^\s+'), '');
//     // (keeps interior spacing/paragraphs)
//   }
//
//   Widget _buildStatusIndicator() {
//     final status = widget.currentStatus;
//     final hasValidStatus =
//         status != null && status.isNotEmpty && status != 'null' && status != 'undefined';
//     if (!hasValidStatus) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: PremiumShimmerWidget(
//         text: status,
//         isComplete: false,
//         baseColor: const Color(0xFF9CA3AF),
//         highlightColor: const Color(0xFF6B7280),
//       ),
//     );
//   }
//
//   Widget _buildTypewriterCursor() {
//     final show = _isTyping &&
//         !_hasCompletedTyping &&
//         !_wasForceStopped &&
//         !widget.isHistorical &&
//         !widget.isComplete;
//     if (!show) return const SizedBox.shrink();
//
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(milliseconds: 500),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: (value * 2) % 1.0 > 0.5 ? 1.0 : 0.3,
//           child: Container(
//             width: 2,
//             height: 18,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade600,
//               borderRadius: BorderRadius.circular(1),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   List<TextSpan> _buildFormattedSpans(String text, TextStyle base) {
//     final spans = <TextSpan>[];
//     final bold = RegExp(r"\*\*(.+?)\*\*");
//     int last = 0;
//     for (final m in bold.allMatches(text)) {
//       if (m.start > last) {
//         spans.add(TextSpan(text: text.substring(last, m.start), style: base));
//       }
//       spans.add(TextSpan(
//         text: m.group(1),
//         style: base.copyWith(fontWeight: FontWeight.w700, height: 1.4, fontFamily: "SF Pro"),
//       ));
//       last = m.end;
//     }
//     if (last < text.length) {
//       spans.add(TextSpan(text: text.substring(last), style: base));
//     }
//     return spans;
//   }
//
//   Widget _buildContextMenu(BuildContext context, EditableTextState s) {
//     final value = s.textEditingValue;
//     final sel = value.selection;
//     if (!sel.isValid || sel.isCollapsed) return const SizedBox.shrink();
//     final selected = value.text.substring(sel.start, sel.end);
//
//     return AdaptiveTextSelectionToolbar(
//       anchors: s.contextMenuAnchors,
//       children: [
//         if (widget.onAskVitty != null)
//           TextButton(
//             onPressed: () {
//               widget.onAskVitty!(selected);
//               ContextMenuController.removeAny();
//             },
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Ask Vitty', style: TextStyle(color: Colors.black)),
//                 const SizedBox(width: 8),
//                 Image.asset('assets/images/vitty.png', width: 20, height: 20),
//               ],
//             ),
//           ),
//         TextButton(
//           onPressed: () {
//             Clipboard.setData(ClipboardData(text: selected));
//             ScaffoldMessenger.of(context)
//                 .showSnackBar(const SnackBar(content: Text('Copied!')));
//             ContextMenuController.removeAny();
//           },
//           child: const Text('Copy', style: TextStyle(color: Colors.black)),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTableWidget() {
//     if (widget.tableData == null || _availableTableRows.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     final dataType = (widget.tableData!['type']?.toString().toLowerCase() ?? '').trim();
//
//     if (dataType == 'table_of_market' || dataType == 'table_of_asset') {
//       return ComparisonTableWidget(
//         heading: _availableTableHeading,
//         rows: _availableTableRows,
//         onRowTap: widget.onStockTap,
//       );
//     }
//     // ✅ pass compact spacing to KeyValueTableWidget
//     return KeyValueTableWidget(
//       heading: _availableTableHeading,
//       rows: _availableTableRows,
//       columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
//       onCardTap: widget.onStockTap,
//       cardSpacing: 6,
//       headerBottomSpacing: 6,
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: const [
//         _AnimatedActionButton(icon: Icons.copy, size: 14, isVisible: true),
//         SizedBox(width: 12),
//         _AnimatedActionButton(icon: Icons.thumb_up_alt_outlined, size: 16, isVisible: true),
//         SizedBox(width: 12),
//         _AnimatedActionButton(icon: Icons.thumb_down_alt_outlined, size: 16, isVisible: true),
//       ],
//     );
//   }
//
//   // --------------------------------- build ---------------------------------
//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // for keep-alive
//     final style = _bodyStyle(context);
//
//     // Trim only the edges around the placeholder to kill invisible gaps.
//     final preForView = _trimRightSoft(_preDisplay);
//     final postForView = _trimLeftSoft(_postDisplay);
//
//     final hasPreText = preForView.isNotEmpty;
//     final hasPostText = postForView.isNotEmpty;
//
//     return Padding(
//       // keep bubble top modest; most "gap" users see is inside the bubble, not here
//       padding: const EdgeInsets.only(bottom: 4, top: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildStatusIndicator(),
//
//           if (hasPreText)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: SelectableText.rich(
//                     TextSpan(style: style, children: _buildFormattedSpans(preForView, style)),
//                     textHeightBehavior: _thb,
//                     contextMenuBuilder: _buildContextMenu,
//                   ),
//                 ),
//                 if ((_isTyping && !_hasCompletedTyping && !_wasForceStopped) &&
//                     (!_shouldShowTable || _preShown < _preFull.length))
//                   _buildTypewriterCursor(),
//               ],
//             ),
//
//           if (_shouldShowTable && _availableTableRows.isNotEmpty) ...[
//             if (hasPreText) const SizedBox(height: _kGapTextToBlock),
//             _buildTableWidget(),
//           ],
//
//           if (hasPostText) ...[
//             if (_shouldShowTable) const SizedBox(height: _kGapBlockToText),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: SelectableText.rich(
//                     TextSpan(style: style, children: _buildFormattedSpans(postForView, style)),
//                     textHeightBehavior: _thb,
//                     contextMenuBuilder: _buildContextMenu,
//                   ),
//                 ),
//                 if (_shouldShowTable &&
//                     _isTyping &&
//                     !_hasCompletedTyping &&
//                     !_wasForceStopped &&
//                     _postShown < _postFull.length)
//                   _buildTypewriterCursor(),
//               ],
//             ),
//           ],
//
//           if ((_hasCompletedTyping || widget.isComplete || _wasForceStopped) && !_isTyping) ...[
//             const SizedBox(height: 12),
//             _buildActionButtons(),
//           ],
//         ],
//       ),
//     );
//   }
// }
//
// class _StreamingState {
//   final int preShown;
//   final int postShown;
//   final bool shouldShowTable;
//   final bool postDelayApplied;
//   final bool wasCompleted;
//   final bool wasForceStopped;
//
//   _StreamingState({
//     required this.preShown,
//     required this.postShown,
//     required this.shouldShowTable,
//     required this.postDelayApplied,
//     required this.wasCompleted,
//     required this.wasForceStopped,
//   });
// }
//
// class _AnimatedActionButton extends StatelessWidget {
//   final IconData icon;
//   final double size;
//   final bool isVisible;
//
//   const _AnimatedActionButton({
//     Key? key,
//     required this.icon,
//     required this.size,
//     required this.isVisible,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedOpacity(
//       opacity: isVisible ? 1.0 : 0.0,
//       duration: const Duration(milliseconds: 300),
//       child: Icon(icon, size: size, color: Colors.grey.shade600),
//     );
//   }
// }







