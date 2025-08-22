import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';

// class BotMessageWidget extends StatefulWidget {
//   final String message;
//   final bool isComplete;
//   final bool isLatest;
//   final String? currentStatus;
//   final Function(String)? onAskVitty;
//
//   const BotMessageWidget({
//     Key? key,
//     required this.message,
//     required this.isComplete,
//     this.isLatest = false,
//     this.currentStatus,
//     this.onAskVitty,
//   }) : super(key: key);
//
//   @override
//   State<BotMessageWidget> createState() => _BotMessageWidgetState();
// }
//
// class _BotMessageWidgetState extends State<BotMessageWidget> {
//   String _displayedText = '';
//   String _fullReceivedText = '';
//   bool _isTyping = false;
//   Timer? _typingTimer;
//
//   // Typing speed: characters per second
//   static const int _typingSpeed = 30; // Adjust this to make it faster or slower
//   static const int _typingIntervalMs = 1000 ~/ _typingSpeed; // milliseconds between each character
//
//   @override
//   void initState() {
//     super.initState();
//     print("🚀 BotMessageWidget initState:");
//     print("   - initial message: '${widget.message}'");
//     print("   - initial status: '${widget.currentStatus}'");
//
//     _fullReceivedText = widget.message;
//     _startTypingEffect();
//   }
//
//   @override
//   void didUpdateWidget(BotMessageWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     // Debug status changes
//     if (widget.currentStatus != oldWidget.currentStatus) {
//       print("🔄 Status changed: '${oldWidget.currentStatus}' → '${widget.currentStatus}'");
//     }
//
//     // When new message content arrives
//     if (widget.message != oldWidget.message) {
//       print("📝 Message changed: '${oldWidget.message}' → '${widget.message}'");
//       _fullReceivedText = widget.message;
//
//       // If we're not currently typing and have actual content, start the typing effect
//       if (!_isTyping && widget.message.isNotEmpty) {
//         _startTypingEffect();
//       }
//       // If we are typing, the timer will automatically pick up the new content
//     }
//
//     // Handle status changes - when status appears, stop typing temporarily
//     if (widget.currentStatus != oldWidget.currentStatus) {
//       if (widget.currentStatus != null) {
//         // Status appeared - pause typing effect
//         print("⏸️ Pausing typing for status: ${widget.currentStatus}");
//         _pauseTypingForStatus();
//       } else if (oldWidget.currentStatus != null && widget.currentStatus == null) {
//         // Status cleared - resume or start typing effect
//         print("▶️ Status cleared, resuming typing effect");
//         if (_fullReceivedText.isNotEmpty && !_isTyping) {
//           _startTypingEffect();
//         }
//       }
//       setState(() {});
//     }
//   }
//
//   void _startTypingEffect() {
//     if (_fullReceivedText.isEmpty || _isTyping || widget.currentStatus != null) {
//       print("❌ Cannot start typing: receivedText empty: ${_fullReceivedText.isEmpty}, isTyping: $_isTyping, hasStatus: ${widget.currentStatus != null}");
//       return;
//     }
//
//     print("▶️ Starting typing effect for: '${_fullReceivedText.substring(0, _fullReceivedText.length.clamp(0, 50))}...'");
//     _isTyping = true;
//
//     _typingTimer = Timer.periodic(
//       Duration(milliseconds: _typingIntervalMs),
//           (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }
//
//         // If there's a status update, pause typing
//         if (widget.currentStatus != null) {
//           print("⏸️ Pausing typing due to status: ${widget.currentStatus}");
//           timer.cancel();
//           _isTyping = false;
//           return;
//         }
//
//         // If we've displayed all available text
//         if (_displayedText.length >= _fullReceivedText.length) {
//           // If the message is complete from backend, stop typing
//           if (widget.isComplete) {
//             print("✅ Typing complete");
//             timer.cancel();
//             _isTyping = false;
//             setState(() {
//               _displayedText = _fullReceivedText; // Ensure we show the complete text
//             });
//           }
//           // If not complete, just wait for more content (timer keeps running)
//           return;
//         }
//
//         // Add next character
//         setState(() {
//           _displayedText = _fullReceivedText.substring(0, _displayedText.length + 1);
//         });
//       },
//     );
//   }
//
//   void _pauseTypingForStatus() {
//     print("⏸️ Pausing typing for status");
//     _typingTimer?.cancel();
//     _isTyping = false;
//   }
//
//   @override
//   void dispose() {
//     _typingTimer?.cancel();
//     super.dispose();
//   }
//
//   List<TextSpan> _processTextWithFormatting(String text, TextStyle baseStyle) {
//     final regexBold = RegExp(r"\*\*(.+?)\*\*");
//     List<TextSpan> spans = [];
//     int lastMatchEnd = 0;
//
//     for (var match in regexBold.allMatches(text)) {
//       if (match.start > lastMatchEnd) {
//         spans.add(
//           TextSpan(
//             text: text.substring(lastMatchEnd, match.start),
//             style: baseStyle,
//           ),
//         );
//       }
//
//       spans.add(
//         TextSpan(
//           text: match.group(1),
//           style: baseStyle.copyWith(
//             fontWeight: FontWeight.w700,
//             height: 1.5,
//             fontFamily: "SF Pro Text",
//           ),
//         ),
//       );
//
//       lastMatchEnd = match.end;
//     }
//
//     if (lastMatchEnd < text.length) {
//       spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
//     }
//
//     return spans;
//   }
//
//   List<TextSpan> _buildFormattedSpans(String fullText, TextStyle baseStyle) {
//     // During streaming, show simple formatting
//     if (!widget.isComplete || _isTyping) {
//       return _processTextWithFormatting(fullText, baseStyle);
//     }
//
//     // Apply full formatting when complete
//     final lines = fullText.trim().split('\n');
//     List<TextSpan> spans = [];
//
//     for (int i = 0; i < lines.length; i++) {
//       final line = lines[i];
//
//       if (line.trim().isEmpty) {
//         spans.add(const TextSpan(text: '\n'));
//         continue;
//       }
//
//       // Add emoji based on line content
//       String emoji = '';
//       if (line.trim().startsWith(RegExp(r"^(\*|•|-|\d+\.)\s"))) {
//         emoji = '👉 ';
//       } else if (line.contains('Tip') || line.contains('Note')) {
//         emoji = '💡 ';
//       } else if (line.contains('Save') || line.contains('budget')) {
//         emoji = '💰 ';
//       }
//
//       // Add newline only if not the first line
//       if (i > 0) {
//         spans.add(TextSpan(text: '\n$emoji'));
//       } else if (emoji.isNotEmpty) {
//         spans.add(TextSpan(text: emoji));
//       }
//
//       spans.addAll(_processTextWithFormatting(line, baseStyle));
//     }
//
//     return spans;
//   }
//
//   Widget _buildStatusIndicator() {
//     if (widget.currentStatus == null) return const SizedBox.shrink();
//
//     return PremiumShimmerWidget(
//       text: widget.currentStatus!,
//       isComplete: false, // Always animate for status
//       baseColor: const Color(0xFF9CA3AF),
//       highlightColor: const Color(0xFF6B7280),
//     );
//   }
//
//
//   Widget _buildTypewriterCursor() {
//     // Show cursor when typing or when there's more content to display
//     final showCursor = _isTyping || (!widget.isComplete && _displayedText.length < _fullReceivedText.length);
//
//     if (!showCursor) return const SizedBox.shrink();
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
//   Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
//     final value = editableTextState.textEditingValue;
//     final selection = value.selection;
//
//     if (!selection.isValid || selection.isCollapsed) {
//       return const SizedBox.shrink();
//     }
//
//     final selectedText = value.text.substring(selection.start, selection.end);
//
//     return AdaptiveTextSelectionToolbar(
//       anchors: editableTextState.contextMenuAnchors,
//       children: [
//         if (widget.onAskVitty != null)
//           TextButton(
//             onPressed: () {
//               widget.onAskVitty!(selectedText);
//               ContextMenuController.removeAny();
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Ask Vitty'),
//                 const SizedBox(width: 8),
//                 Image.asset(
//                   'assets/images/vitty.png',
//                   width: 20,
//                   height: 20,
//                 ),
//               ],
//             ),
//           ),
//         TextButton(
//           onPressed: () {
//             Clipboard.setData(ClipboardData(text: selectedText));
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Copied!')),
//             );
//             ContextMenuController.removeAny();
//           },
//           child: const Text('Copy', style: TextStyle(color: Colors.black)),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = locator<ThemeService>().currentTheme;
//
//     final style = TextStyle(
//       fontFamily: 'DM Sans',
//       fontSize: 16,
//       fontWeight: FontWeight.w500,
//       height: 1.75,
//       color: theme.text,
//     );
//
//     // Always use displayed text for typewriter effect
//     final textToShow = _displayedText;
//     final spans = _buildFormattedSpans(textToShow, style);
//
//     // // Debug widget state
//     // print("🎨 BotMessageWidget build:");
//     // print("   - currentStatus: '${widget.currentStatus}'");
//     // print("   - message: '${widget.message.length > 50 ? widget.message.substring(0, 50) + '...' : widget.message}'");
//     // print("   - displayedText: '${_displayedText.length > 50 ? _displayedText.substring(0, 50) + '...' : _displayedText}'");
//     // print("   - isTyping: $_isTyping");
//     // print("   - isComplete: ${widget.isComplete}");
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4, top: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Status indicator
//           _buildStatusIndicator(),
//
//           // Main content with typewriter effect
//           if (textToShow.isNotEmpty || _isTyping || widget.currentStatus != null)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: widget.currentStatus != null
//                       ? const SizedBox.shrink() // Hide text content when showing status
//                       : SelectableText.rich(
//                     TextSpan(style: style, children: spans),
//                     contextMenuBuilder: _buildContextMenu,
//                   ),
//                 ),
//                 // Show typewriter cursor only when actually typing text (not during status)
//                 if (widget.currentStatus == null) _buildTypewriterCursor(),
//               ],
//             ),
//
//           const SizedBox(height: 15),
//           _buildActionButtons(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         _AnimatedActionButton(
//           icon: Icons.copy,
//           size: 14,
//           isVisible: widget.isComplete && !_isTyping,
//         ),
//         const SizedBox(width: 12),
//         _AnimatedActionButton(
//           icon: Icons.thumb_up_alt_outlined,
//           size: 16,
//           isVisible: widget.isComplete && !_isTyping,
//         ),
//         const SizedBox(width: 12),
//         _AnimatedActionButton(
//           icon: Icons.thumb_down_alt_outlined,
//           size: 16,
//           isVisible: widget.isComplete && !_isTyping,
//         ),
//       ],
//     );
//   }
// }
//
//
//
// class _AnimatedActionButton extends StatelessWidget {
//   final IconData icon;
//   final double size;
//   final bool isVisible;
//
//   const _AnimatedActionButton({
//     required this.icon,
//     required this.size,
//     required this.isVisible,
//   });
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
//         child: Icon(
//           icon,
//           size: size,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }
// }




import 'dart:async';
import 'package:flutter/material.dart';



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

  // Handle force stop from chat service
  final bool? forceStop;
  final String? stopTs;

  const BotMessageWidget({
    Key? key,
    required this.message,
    required this.isComplete,
    this.isLatest = false,
    this.isHistorical = false,  // ✅ NEW: Add this with default false
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

class _BotMessageWidgetState extends State<BotMessageWidget> {
  static const _kPlaceholder = '___TABLE_PLACEHOLDER___';
  static const int _cps = 28;
  static const int _postHoldMs = 900;

  Timer? _timer;
  bool _isTyping = false;
  bool _hasCompletedTyping = false;
  bool _wasForceStopped = false; // ✅ FIXED: Correct variable name

  String _preFull = '';
  String _postFull = '';
  int _preShown = 0;
  int _postShown = 0;

  List<Map<String, dynamic>> _availableTableRows = [];
  String? _availableTableHeading;
  bool _hasTableDataAvailable = false;
  bool _shouldShowTable = false;
  bool _postDelayApplied = false;

  int get _intervalMs => 1000 ~/ _cps;
  String get _preDisplay => _preFull.substring(0, _preShown.clamp(0, _preFull.length));
  String get _postDisplay => _postFull.substring(0, _postShown.clamp(0, _postFull.length));
  bool get _reachedPlaceholder => _preShown >= _preFull.length;

  @override
  void initState() {
    super.initState();
    _recomputeSegments(widget.message);
    _updateTableData();

    // Check for force stop on init
    if (widget.forceStop == true) {
      _handleForceStop();
      return;
    }

    // ✅ CHANGE: Historical messages OR complete messages should appear instantly
    if (widget.isComplete || widget.isHistorical) {
      // Show all content immediately without typing animation
      _preShown = _preFull.length;
      _postShown = _postFull.length;
      _hasCompletedTyping = true;
      _shouldShowTable = _hasTableDataAvailable;

      // ✅ NEW: For historical messages, immediately call onRenderComplete
      if (widget.isHistorical) {
        print("📄 Historical message - showing instantly");
        Future.microtask(() => widget.onRenderComplete?.call());
      }
    } else {
      // Only start typing animation for NEW messages (not historical)
      print("⌨️ New message - starting typing animation");
      _startOrResumeTyping();
    }
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
      _availableTableRows = rowsRaw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      _availableTableHeading = widget.tableData!['heading']?.toString();
      _hasTableDataAvailable = _availableTableRows.isNotEmpty;
    } else {
      _availableTableRows = [];
      _availableTableHeading = null;
      _hasTableDataAvailable = false;
      _shouldShowTable = false;
    }
  }

  // ✅ NEW: Handle force stop - finish animation immediately
  void _handleForceStop() {
    print("🛑 Force stop detected - finishing animation immediately");

    _timer?.cancel();
    _isTyping = false;
    _wasForceStopped = true; // ✅ FIXED: Correct variable name

    // Show current state without further animation
    if (_hasTableDataAvailable && _reachedPlaceholder) {
      _shouldShowTable = true;
    }

    // Mark as completed
    _hasCompletedTyping = true;

    setState(() {});

    // Notify parent that render is complete
    widget.onRenderComplete?.call();
  }

  @override
  void didUpdateWidget(BotMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ NEW: Check for force stop changes
    if (widget.forceStop == true && oldWidget.forceStop != true) {
      _handleForceStop();
      return;
    }

    if (widget.message != oldWidget.message) {
      _recomputeSegments(widget.message);
      if (!_isTyping && !_hasCompletedTyping && !_wasForceStopped &&
          (widget.currentStatus == null || widget.currentStatus!.isEmpty)) {
        _startOrResumeTyping();
      }
    }

    if (widget.tableData != oldWidget.tableData) {
      _updateTableData();
      setState(() {});
    }

    if (widget.currentStatus != oldWidget.currentStatus) {
      if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
        _pauseTyping();
      } else {
        if (!_hasCompletedTyping && !_wasForceStopped) _startOrResumeTyping();
      }
      setState(() {});
    }
  }

  void _startOrResumeTyping() {
    if (_isTyping || _hasCompletedTyping || _wasForceStopped) return;
    if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) return;
    if (widget.forceStop == true) return;

    // ✅ NEW: Never start typing animation for historical messages
    if (widget.isHistorical) {
      print("🚫 Skipping typing animation for historical message");
      return;
    }

    print("▶️ Starting typing animation for new message");
    _isTyping = true;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), _tick);
  }

  void _pauseTyping() {
    _timer?.cancel();
    _isTyping = false;
  }

  void _finishTyping() {
    _timer?.cancel();
    _isTyping = false;
    _hasCompletedTyping = true;
    setState(() {});

    // ✅ Only notify if not force stopped (to avoid duplicate notifications)
    if (!_wasForceStopped) {
      widget.onRenderComplete?.call();
    }
  }

  void _applyPostDelayOnce() {
    if (_postDelayApplied || _wasForceStopped) return; // ✅ Skip delay if force stopped
    _postDelayApplied = true;
    _pauseTyping();
    Future.delayed(const Duration(milliseconds: _postHoldMs), () {
      if (!mounted || _hasCompletedTyping || _wasForceStopped) return;
      _startOrResumeTyping();
    });
  }

  void _tick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }

    // ✅ Stop ticking if force stopped
    if (widget.forceStop == true || _wasForceStopped) {
      _handleForceStop();
      return;
    }

    if (widget.currentStatus != null && widget.currentStatus!.isNotEmpty) {
      _pauseTyping();
      return;
    }

    if (_preShown < _preFull.length) {
      setState(() => _preShown++);
      return;
    }

    if (_reachedPlaceholder && _hasTableDataAvailable && !_shouldShowTable) {
      setState(() => _shouldShowTable = true);
      _applyPostDelayOnce();
      return;
    }

    if (_shouldShowTable && !_postDelayApplied) {
      _applyPostDelayOnce();
      return;
    }

    if (_postShown < _postFull.length) {
      setState(() => _postShown++);
      return;
    }

    _finishTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- UI helpers ----------
  Widget _buildStatusIndicator() {
    if (widget.currentStatus == null || widget.currentStatus!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: PremiumShimmerWidget(
        text: widget.currentStatus!,
        isComplete: false,
        baseColor: const Color(0xFF9CA3AF),
        highlightColor: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildTypewriterCursor() {
    // ✅ CHANGE: Hide cursor for historical messages, force stopped, or completed messages
    final showCursor = _isTyping &&
        !_hasCompletedTyping &&
        !_wasForceStopped &&
        !widget.isHistorical;  // ✅ NEW: Hide for historical messages

    if (!showCursor) return const SizedBox.shrink();

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

  List<TextSpan> _buildFormattedSpans(String text, TextStyle baseStyle) {
    final regexBold = RegExp(r"\*\*(.+?)\*\*");
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in regexBold.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.5,
          fontFamily: "SF Pro Text",
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return spans;
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState s) {
    final value = s.textEditingValue;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return const SizedBox.shrink();
    final selectedText = value.text.substring(selection.start, selection.end);

    return AdaptiveTextSelectionToolbar(
      anchors: s.contextMenuAnchors,
      children: [
        if (widget.onAskVitty != null)
          TextButton(
            onPressed: () {
              widget.onAskVitty!(selectedText);
              ContextMenuController.removeAny();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ask Vitty',style: TextStyle(color: Colors.black),),
                const SizedBox(width: 8),
                Image.asset('assets/images/vitty.png', width: 20, height: 20),
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selectedText));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
            ContextMenuController.removeAny();
          },
          child: const Text('Copy', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final style = TextStyle(
      fontFamily: 'DM Sans',
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

          if (_shouldShowTable && _availableTableRows.isNotEmpty) ...[
            KeyValueTableWidget(
              heading: _availableTableHeading,
              rows: _availableTableRows,
              columnOrder: widget.tableData?['columnOrder']?.cast<String>(),
              onCardTap: widget.onStockTap,
            ),
          ],

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
                if (_shouldShowTable && _isTyping && !_hasCompletedTyping && !_wasForceStopped && _postShown < _postFull.length)
                  _buildTypewriterCursor(),
              ],
            ),

          // ✅ Show action buttons if completed OR force stopped
          if ((_hasCompletedTyping || widget.isComplete || _wasForceStopped) && !_isTyping) ...[
            const SizedBox(height: 15),
            _buildActionButtons(),
          ],
        ],
      ),
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
    return Visibility(
      visible: true,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1 : 0,
        child: Icon(icon, size: size, color: Colors.grey),
      ),
    );
  }
}

