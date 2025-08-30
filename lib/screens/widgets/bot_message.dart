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
  static const _kPlaceholder = '___TABLE_PLACEHOLDER___';
  static const int _cps = 130;
  static const int _postHoldMs = 900;

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
    final newPre = parts.isNotEmpty ? parts.first : '';
    final newPost = parts.length > 1 ? parts.sublist(1).join(_kPlaceholder) : '';

    if (_preFull == newPre && _postFull == newPost) return;

    final oldPreLen = _preFull.length;
    _preFull = newPre;
    _postFull = newPost;

    if (_preFull.length >= oldPreLen &&
        oldPreLen > 0 &&
        _preFull.startsWith(_preFull.substring(0, oldPreLen.clamp(0, _preFull.length)))) {
      _preShown = _preShown.clamp(0, _preFull.length);
    } else {
      _preShown = _preShown.clamp(0, _preFull.length);
      _postShown = _postShown.clamp(0, _postFull.length);
    }
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

  // Ignore isLatest flips; they shouldn't trigger rebuild
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

    // Demotion guard: when last bubble stops being latest, freeze current view.
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

    // Force stop
    final stopTsChanged = widget.stopTs != old.stopTs && widget.stopTs != null;
    if ((widget.forceStop == true && old.forceStop != true) || stopTsChanged) {
      _handleForceStop();
      return;
    }

    // Completion flips: finish whatever is left right now.
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
    // Clean up completed states to prevent memory leaks
    if (_hasCompletedTyping || _wasForceStopped) {
      _streamingStates.remove(_stateKey);
    }
    super.dispose();
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
            height: 20,
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
        style: base.copyWith(fontWeight: FontWeight.w700, height: 1.5, fontFamily: "SF Pro"),
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

    if (dataType == 'tables' || dataType == 'table') {
      return ComparisonTableWidget(
        heading: _availableTableHeading,
        rows: _availableTableRows,
        onRowTap: widget.onStockTap,
      );
    }
    return KeyValueTableWidget(
      heading: _availableTableHeading,
      rows: _availableTableRows,
      columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
      onCardTap: widget.onStockTap,
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // important for keep-alive
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final style = TextStyle(
      fontFamily: 'SF Pro',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.75,
      color: textColor,
    );

    final hasPostText = _postDisplay.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(),

          if (_preDisplay.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(style: style, children: _buildFormattedSpans(_preDisplay, style)),
                    contextMenuBuilder: _buildContextMenu,
                  ),
                ),
                if ((_isTyping && !_hasCompletedTyping && !_wasForceStopped) &&
                    (!_shouldShowTable || _preShown < _preFull.length))
                  _buildTypewriterCursor(),
              ],
            ),

          if (_shouldShowTable && _availableTableRows.isNotEmpty) _buildTableWidget(),

          if (hasPostText)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(style: style, children: _buildFormattedSpans(_postDisplay, style)),
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

          if ((_hasCompletedTyping || widget.isComplete || _wasForceStopped) && !_isTyping) ...[
            const SizedBox(height: 15),
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
//   final String message;                   // full message with ___TABLE_PLACEHOLDER___
//   final bool isComplete;                  // backend finished
//   final bool isLatest;                    // last bubble
//   final bool isHistorical;                // loaded from history
//   final String? currentStatus;            // live status text (optional)
//   final Function(String)? onAskVitty;     // context menu action (optional)
//   final Map<String, dynamic>? tableData;  // {heading, rows, type, columnOrder?}
//   final Function(String)? onStockTap;     // tap handler for rows/cards
//   final VoidCallback? onRenderComplete;   // notify ChatService when fully painted
//
//   // Force-stop support from ChatService
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
// class _BotMessageWidgetState extends State<BotMessageWidget> {
//   // ——— config ———
//   static const _kPlaceholder = '___TABLE_PLACEHOLDER___';
//   static const int _cps = 90;         // characters per second
//   static const int _postHoldMs = 900; // small pause after table shows
//
//   // ——— runtime state ———
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
//   // resume across rebuilds
//   static final Map<String, _StreamingState> _streamingStates = {};
//   String get _stateKey => '${widget.message.hashCode}_${widget.isLatest}';
//
//   int get _intervalMs => 1000 ~/ _cps;
//   String get _preDisplay => _preFull.substring(0, _preShown.clamp(0, _preFull.length));
//   String get _postDisplay => _postFull.substring(0, _postShown.clamp(0, _postFull.length));
//   bool get _reachedPlaceholder => _preShown >= _preFull.length;
//
//   @override
//   void initState() {
//     super.initState();
//     debugPrint("🎬 BotMessage: initState called");
//     _initializeWidget();
//   }
//
//
//   void _initializeWidget() {
//     _recomputeSegments(widget.message);
//     _updateTableData();
//
//     // try resume
//     final existing = _streamingStates[_stateKey];
//     if (existing != null && !existing.wasCompleted) {
//       _restoreStreamingState(existing);
//       return;
//     }
//
//     final shouldInstant =
//         widget.forceStop == true || widget.isComplete || widget.isHistorical;
//
//     if (shouldInstant) {
//       _showInstantly();
//       return;
//     }
//
//     // FIXED: Always start streaming for latest non-complete messages
//     // Don't wait for content - start immediately for live messages
//     if (widget.isLatest && !widget.isComplete && !widget.isHistorical) {
//       debugPrint("🚀 BotMessage: Starting streaming for latest message");
//       _startContinuousStreaming();
//     } else {
//       // Historical or complete messages show instantly
//       _showInstantly();
//     }
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
//   void _showInstantly() {
//     _preShown = _preFull.length;
//     _postShown = _postFull.length;
//     _hasCompletedTyping = true;
//     _shouldShowTable = _hasTableDataAvailable;
//     _wasForceStopped = widget.forceStop == true;
//     _saveStreamingState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) widget.onRenderComplete?.call();
//     });
//   }
//
//   void _recomputeSegments(String full) {
//     final parts = full.split(_kPlaceholder);
//     final newPre = parts.isNotEmpty ? parts.first : '';
//     final newPost = parts.length > 1 ? parts.sublist(1).join(_kPlaceholder) : '';
//
//     if (_preFull == newPre && _postFull == newPost) return;
//
//     final oldPreLen = _preFull.length;
//     _preFull = newPre;
//     _postFull = newPost;
//
//     // if text extended forward, keep current progress
//     if (_preFull.length >= oldPreLen && _preFull.startsWith(full.substring(0, oldPreLen))) {
//       _preShown = _preShown.clamp(0, _preFull.length);
//     } else {
//       _preShown = _preShown.clamp(0, _preFull.length);
//       _postShown = _postShown.clamp(0, _postFull.length);
//     }
//   }
//
//   void _updateTableData() {
//     if (widget.tableData != null) {
//       final rowsRaw = (widget.tableData!['rows'] as List?) ?? const [];
//       _availableTableRows = rowsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
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
//
//
//   @override
//   void didUpdateWidget(BotMessageWidget old) {
//     super.didUpdateWidget(old);
//
//     // message text updates
//     if (widget.message != old.message) {
//       debugPrint("📝 BotMessage: Message content updated during streaming");
//       _recomputeSegments(widget.message);
//
//       // if we were waiting for first content, start now
//       final hasAnyContent = _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
//       if (!_isTyping &&
//           !_hasCompletedTyping &&
//           !_wasForceStopped &&
//           hasAnyContent) {
//         _startContinuousStreaming();
//       }
//       _saveStreamingState();
//       setState(() {});
//     }
//
//     // table updates
//     if (widget.tableData != old.tableData) {
//       _updateTableData();
//       if (_reachedPlaceholder && _hasTableDataAvailable) {
//         _shouldShowTable = true;
//       }
//       setState(() {});
//     }
//
//     // status pause/resume (do not tie to scroll)
//     if (widget.currentStatus != old.currentStatus) {
//       if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
//         _pauseForStatus();
//       } else if (!_hasCompletedTyping && !_wasForceStopped) {
//         _resumeFromStatus();
//       }
//       setState(() {});
//     }
//
//     // force stop
//     final stopTsChanged = widget.stopTs != old.stopTs && widget.stopTs != null;
//     if ((widget.forceStop == true && old.forceStop != true) || stopTsChanged) {
//       _handleForceStop();
//       return;
//     }
//
//     // completion -> reveal everything
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
//     // start only when there is something to animate
//     final hasAnyContent = _preFull.isNotEmpty || _postFull.isNotEmpty || _hasTableDataAvailable;
//     if (!hasAnyContent) return;
//
//     if (_isTyping) return;
//
//     debugPrint("🚀 BotMessage: Starting continuous streaming (scroll-resistant)");
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
//       debugPrint("⏸️ BotMessage: Paused for status (saving state)");
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
//   /// 🔧 MAIN FIX: when the backend signals completion, reveal the rest of the text
//   /// and show the table immediately so the bubble never stays empty.
//   void _finishStreaming() {
//     debugPrint("✅ BotMessage: Finishing continuous streaming");
//
//     _recomputeSegments(widget.message);
//     _updateTableData();
//
//     // reveal all remaining content
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
//
//     if (!_wasForceStopped) {
//       widget.onRenderComplete?.call();
//     }
//   }
//
//   void _applyPostDelayOnce() {
//     if (_postDelayApplied || _wasForceStopped) return;
//     _postDelayApplied = true;
//     Future.delayed(const Duration(milliseconds: _postHoldMs), () {
//       if (!mounted || _hasCompletedTyping || _wasForceStopped) return;
//       // after the hold, normal ticking continues
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
//     // stream pre text
//     if (_preShown < _preFull.length) {
//       setState(() => _preShown++);
//       _saveStreamingState();
//       return;
//     }
//
//     // show table when placeholder reached
//     if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
//       setState(() => _shouldShowTable = true);
//       _applyPostDelayOnce();
//       _saveStreamingState();
//       return;
//     }
//
//     // after small delay, stream post text
//     if (_postDelayApplied && _postShown < _postFull.length) {
//       setState(() => _postShown++);
//       _saveStreamingState();
//       return;
//     }
//
//     // all done?
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
//     // keep state only if still streaming; otherwise clean up
//     if (_hasCompletedTyping || _wasForceStopped) {
//       _streamingStates.remove(_stateKey);
//     }
//     super.dispose();
//   }
//
//   // ——— UI ———
//
//
//   Widget _buildStatusIndicator() {
//     // FIXED: Handle both null and string 'null'
//     final status = widget.currentStatus;
//     final hasValidStatus = status != null &&
//         status.isNotEmpty &&
//         status != 'null' &&           // Handle string 'null'
//         status != 'undefined';        // Handle string 'undefined'
//
//     //print("BotMessage _buildStatusIndicator: currentStatus='$status', hasValidStatus=$hasValidStatus");
//
//     if (!hasValidStatus) {
//      // print("BotMessage: No valid status to show");
//       return const SizedBox.shrink();
//     }
//
//     //print("BotMessage: Showing status: '$status'");
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
//             height: 20,
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
//         style: base.copyWith(fontWeight: FontWeight.w700, height: 1.5, fontFamily: "SF Pro"),
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
//             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
//             ContextMenuController.removeAny();
//           },
//           child: const Text('Copy', style: TextStyle(color: Colors.black)),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTableWidget() {
//     // DEBUG: Add this print
//     //print("BotMessage _buildTableWidget: tableData=${widget.tableData != null ? 'Present' : 'Null'}, rows=${_availableTableRows.length}");
//
//     if (widget.tableData == null || _availableTableRows.isEmpty) {
//       print("BotMessage: No table data to show");
//       return const SizedBox.shrink();
//     }
//
//     final dataType = (widget.tableData!['type']?.toString().toLowerCase() ?? '').trim();
//    // print("BotMessage: Showing table with type='$dataType', rows=${_availableTableRows.length}");
//
//     if (dataType == 'tables' || dataType == 'table') {
//       return ComparisonTableWidget(
//         heading: _availableTableHeading,
//         rows: _availableTableRows,
//         onRowTap: widget.onStockTap,
//       );
//     }
//     // 'cards' | 'card' | unknown -> fall back to KV cards
//     return KeyValueTableWidget(
//       heading: _availableTableHeading,
//       rows: _availableTableRows,
//       columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
//       onCardTap: widget.onStockTap,
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
//   @override
//   Widget build(BuildContext context) {
//     final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
//     final style = TextStyle(
//       fontFamily: 'SF Pro',
//       fontSize: 16,
//       fontWeight: FontWeight.w500,
//       height: 1.75,
//       color: textColor,
//     );
//
//     final hasPostText = _postDisplay.isNotEmpty;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4, top: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildStatusIndicator(),
//
//           if (_preDisplay.isNotEmpty)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: SelectableText.rich(
//                     TextSpan(style: style, children: _buildFormattedSpans(_preDisplay, style)),
//                     contextMenuBuilder: _buildContextMenu,
//                   ),
//                 ),
//                 if ((_isTyping && !_hasCompletedTyping && !_wasForceStopped) &&
//                     (!_shouldShowTable || _preShown < _preFull.length))
//                   _buildTypewriterCursor(),
//               ],
//             ),
//
//           if (_shouldShowTable && _availableTableRows.isNotEmpty) _buildTableWidget(),
//
//           if (hasPostText)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: SelectableText.rich(
//                     TextSpan(style: style, children: _buildFormattedSpans(_postDisplay, style)),
//                     contextMenuBuilder: _buildContextMenu,
//                   ),
//                 ),
//                 if (_shouldShowTable && _isTyping && !_hasCompletedTyping && !_wasForceStopped && _postShown < _postFull.length)
//                   _buildTypewriterCursor(),
//               ],
//             ),
//
//           if ((_hasCompletedTyping || widget.isComplete || _wasForceStopped) && !_isTyping) ...[
//             const SizedBox(height: 15),
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
//     return Visibility(
//       visible: true,
//       maintainSize: true,
//       maintainAnimation: true,
//       maintainState: true,
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 300),
//         opacity: isVisible ? 1 : 0,
//         child: Icon(icon, size: size, color: Colors.grey),
//       ),
//     );
//   }
// }

