import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vscmoney/screens/AskVittyChat.dart';
import 'package:vscmoney/screens/presentation/home/chat_screen.dart';

import '../models/chat_session.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';



class ThreadHistoryItem {
  final String id;
  final String text;
  final DateTime createdAt;

  ThreadHistoryItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ThreadHistoryItem &&
              runtimeType == other.runtimeType &&
              text.trim() == other.text.trim();

  @override
  int get hashCode => text.trim().hashCode;
}

class VittyThreadSheet extends StatefulWidget {
  final ChatService chatService;
  final String initialText;
  final List<ThreadHistoryItem>? history;
  final VoidCallback onClose;

  const VittyThreadSheet({
    Key? key,
    required this.chatService,
    required this.initialText,
    this.history,
    required this.onClose,
  }) : super(key: key);

  @override
  State<VittyThreadSheet> createState() => _VittyThreadSheetState();
}

class _VittyThreadSheetState extends State<VittyThreadSheet>
    with TickerProviderStateMixin {
  bool _shouldTriggerAnimation = false;
  ChatSession? _currentSession;
  late List<ThreadHistoryItem> _history;
  String? _selectedText;
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isDropdownExpanded = false;

  // Add a stable thread identifier that doesn't change during conversation
  late final String _threadId;

  // text → session (null = blank thread not sent yet)
  final Map<String, ChatSession?> _threadsByText = <String, ChatSession?>{};

  @override
  void initState() {
    super.initState();

    // Create stable thread ID that won't change during the conversation
    _threadId = 'thread_${widget.initialText.hashCode}_${DateTime.now().millisecondsSinceEpoch}';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectedText = widget.initialText.trim();
    _initializeHistory();

    // CRITICAL FIX: Ensure we start with a completely blank chat state
    _initializeBlankState();

    // NEW: Trigger animation when bottom sheet opens - ONE TIME ONLY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _shouldTriggerAnimation = true; // Trigger animation on sheet open
        });

        // Reset the flag after animation completes to prevent re-triggering
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            setState(() {
              _shouldTriggerAnimation = false; // Reset flag after animation
            });
          }
        });
      }
    });
  }

  void _initializeBlankState() {
    print("🧹 Resetting ChatService for new thread");
    print("📊 Current state check:");
    print("  - Current session: ${widget.chatService.currentSession?.id ?? 'null'}");
    print("  - Messages count: ${widget.chatService.messages.length}");
    print("  - Selected text: $_selectedText");

    // CRITICAL: Only clear if we're truly starting fresh AND no messages exist
    final currentSession = widget.chatService.currentSession;
    final hasMessages = widget.chatService.messages.isNotEmpty;

    if (currentSession == null && !hasMessages) {
      print("🧹 Clearing for truly blank start - no session, no messages");
      widget.chatService.clear();
      widget.chatService.clearCurrentSession();
    } else {
      print("🚫 NOT clearing - preserving existing state");
      print("  - Has session: ${currentSession != null}");
      print("  - Has messages: $hasMessages");
    }

    // Reset local session state
    _currentSession = null;

    // Register initial item as blank thread (no session yet)
    if (_selectedText!.isNotEmpty) {
      _threadsByText[_selectedText!] = null;
    }

    print("✅ Thread initialization complete");
  }

  void _initializeHistory() {
    final original = widget.history ?? <ThreadHistoryItem>[];
    _history = List<ThreadHistoryItem>.from(original);

    final t = widget.initialText.trim();
    if (t.isNotEmpty && !_history.any((it) => it.text.trim() == t)) {
      _history.insert(
        0,
        ThreadHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: t,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // Move/insert text at top of history
  void _touchHistory(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final i = _history.indexWhere((it) => it.text.trim() == trimmed);
    if (i >= 0) {
      final it = _history.removeAt(i);
      _history.insert(0, it);
    } else {
      _history.insert(
        0,
        ThreadHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: trimmed,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (_history.length > 20) {
      _history = _history.take(20).toList();
    }
  }

  // Open BLANK chat for text (no session yet)
  void _openBlankFor(String text) {
    print("🆕 Opening blank thread for: $text");

    // Only clear if we're switching to a truly different thread
    final currentText = _selectedText?.trim();
    final needsClear = currentText != text.trim();

    print("📊 Open blank analysis:");
    print("  - Current text: '$currentText'");
    print("  - New text: '$text'");
    print("  - Needs clear: $needsClear");

    if (needsClear) {
      // Save current state first if it exists
      final currentSession = widget.chatService.currentSession;
      if (currentText != null && currentText.isNotEmpty && currentSession != null) {
        _threadsByText[currentText] = currentSession;
        print("💾 Saved current session before opening blank");

        // Cache messages using the public method
        final currentMessages = widget.chatService.messages;
        if (currentMessages.isNotEmpty) {
          widget.chatService.saveMessagesForSession(currentSession.id, currentMessages);
        }
      }

      // Clear for new blank thread
      widget.chatService.clear();
      widget.chatService.clearCurrentSession();
      print("🧹 Cleared for new blank thread");
    } else {
      print("🚫 Not clearing - same thread");
    }

    setState(() {
      _selectedText = text.trim();
      _currentSession = null;
      _isDropdownExpanded = false;
      _isLoading = false;
    });

    _threadsByText[_selectedText!] = null; // mark as blank
    _touchHistory(_selectedText!);

    print("✅ Blank thread ready for: $_selectedText");
  }

  // Ensure we show either the saved session for text or a blank thread
  Future<void> _showThreadFor(String text) async {
    final t = text.trim();
    final existing = _threadsByText[t];

    print("🔄 _showThreadFor called with: $t");
    print("📊 Existing session for this text: ${existing?.id ?? 'null'}");

    if (existing != null) {
      print("🔄 Switching to existing session: ${existing.id}");

      try {
        // CRITICAL: Use new method that preserves messages
        await widget.chatService.switchToSessionWithoutClearing(existing);

        // CRITICAL FIX: Only setState when actually switching threads
        // Don't setState if we're just binding a session to current thread
        if (_selectedText?.trim() != t) {
          setState(() {
            _selectedText = t;
            _currentSession = existing;
            _isDropdownExpanded = false;
          });
        } else {
          // Same thread, just update session reference without setState
          _currentSession = existing;
          _isDropdownExpanded = false;
        }

        print("✅ Successfully switched to existing session");
        print("📊 Messages after switch: ${widget.chatService.messages.length}");

      } catch (e) {
        print("❌ Failed to switch to session: $e");
        // Fallback to blank
        _openBlankFor(t);
      }
      _touchHistory(t);
    } else {
      print("🆕 No existing session, opening blank");
      // No session yet → create blank thread
      _openBlankFor(t);
    }
  }

  // Called when user taps "Ask Vitty" again with a new selection in response
  void _onAskVitty(String newText) {
    final t = newText.trim();
    if (t.isEmpty) return;

    print("🤖 Ask Vitty called with: $t");
    print("📊 Current state before switch:");
    print("  - Selected text: $_selectedText");
    print("  - Current session: ${widget.chatService.currentSession?.id ?? 'null'}");
    print("  - Messages count: ${widget.chatService.messages.length}");

    // Save current session state BEFORE switching
    final currentText = _selectedText?.trim();
    final currentSession = widget.chatService.currentSession;

    if (currentText != null && currentText.isNotEmpty && currentSession != null) {
      _threadsByText[currentText] = currentSession;
      print("💾 Saved session ${currentSession.id} for text: $currentText");

      // Save current messages using the public method
      final currentMessages = widget.chatService.messages;
      if (currentMessages.isNotEmpty) {
        widget.chatService.saveMessagesForSession(currentSession.id, currentMessages);
        print("💾 Cached ${currentMessages.length} messages for session: ${currentSession.id}");
      }
    }

    // Remember the current selected text in history
    if (currentText != null && currentText.isNotEmpty) {
      _touchHistory(currentText);
    }

    // Make sure we have a thread entry for new text
    _threadsByText.putIfAbsent(t, () => null);

    // Switch to that thread (existing or blank)
    _showThreadFor(t);
  }

  // REPLACE: _onHistoryItemSelected method
  void _onHistoryItemSelected(String value) {
    final t = value.trim();
    if (t.isEmpty || t == _selectedText) {
      setState(() => _isDropdownExpanded = false);
      return;
    }

    print("📝 History item selected: $t");

    // Save current state before switching
    final currentText = _selectedText?.trim();
    final currentSession = widget.chatService.currentSession;

    if (currentText != null && currentText.isNotEmpty && currentSession != null) {
      _threadsByText[currentText] = currentSession;
      print("💾 Saved current session before switching to history item");

      // Cache messages using the public method
      final currentMessages = widget.chatService.messages;
      if (currentMessages.isNotEmpty) {
        widget.chatService.saveMessagesForSession(currentSession.id, currentMessages);
      }
    }

    _showThreadFor(t);
  }

  // When the FIRST bot answer completes, the session definitely exists → bind it to the selected text
  void _onFirstMessageComplete(bool ok) {
    if (!ok) return;
    final cur = widget.chatService.currentSession;
    if (cur == null) return;
    final sel = _selectedText?.trim();
    if (sel == null || sel.isEmpty) return;

    // CRITICAL: Check if already bound to prevent multiple calls
    if (_threadsByText[sel] == cur) {
      print("🚫 Session already bound to text: $sel - skipping");
      return;
    }

    print("✅ First message complete, binding session ${cur.id} to text: $sel");

    // CRITICAL FIX: Just bind the session, DON'T call setState
    _threadsByText[sel] = cur;
    _currentSession = cur; // Update the field but don't trigger rebuild

    // DON'T call setState here - this was causing the refresh!
    print("💡 Session bound without setState to prevent ChatScreen rebuild");
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownExpanded = !_isDropdownExpanded;
      // No animation trigger here - we only animate on sheet open
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Material(
      color: theme.background,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              spreadRadius: 4
            ),
          ]
        ),
        child: Column(
          children: [
            _buildHeaderWithDropdown(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithDropdown() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final displayText = (_selectedText ?? '').length > 30
        ? '${_selectedText!.substring(0, 27)}...'
        : (_selectedText ?? 'asking');

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header bar WITH animation (triggers once when sheet opens)
          Material(
            color: theme.background,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _history.length > 1 ? _toggleDropdown : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Back arrow
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.cancel_outlined,
                          size: 24,
                          color: theme.icon,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Center content
                    Expanded(
                      child: CirclingBorderWidget(
                        capsuleHeight: 35,
                        duration: Duration(milliseconds: 2000),
                        strokeWidth: 3.5,
                        shouldAnimate: _shouldTriggerAnimation,
                        animateOnce: true, // Ensure it only animates once
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title text
                              Flexible(
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.text,
                                    fontFamily: 'DM Sans',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Dropdown arrow (only show if multiple items)
                              if (_history.length > 1) ...[
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: _isDropdownExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: theme.icon,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Invisible spacer
                    const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
          ),

          // Dropdown list WITHOUT animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _isDropdownExpanded
                ? math.min(300, _history.length * 60.0)
                : 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.background,
              ),
              child: ClipRect(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.background,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (_, index) {
                    final item = _history[index];
                    final isSelected = item.text.trim() == _selectedText?.trim();

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onHistoryItemSelected(item.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Text(
                              item.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: theme.text,
                                fontFamily: 'DM Sans',
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading...')],
        ),
      );
    }

    // CRITICAL FIX: Use stable thread ID that never changes during conversation
    // Don't include _currentSession in the key since it changes from null to session
    final stableKey = _threadId; // This never changes once set

    print("🔑 Using stable key for ChatScreen: $stableKey");
    print("📊 Current session: ${_currentSession?.id ?? 'null'}");

    // CRITICAL: Always show ChatScreen with proper key and session state
    return ChatScreen(
      key: ValueKey(stableKey), // Stable key prevents unnecessary rebuilds
      session: _currentSession, // This can change but key stays same
      chatService: widget.chatService,
      onAskVitty: _onAskVitty,
      isThreadMode: true,
      onFirstMessageComplete: _onFirstMessageComplete,
    );
  }
}

class CirclingBorderWidget extends StatefulWidget {
  final Widget child;
  final bool shouldAnimate;
  final bool animateOnce; // NEW: Add this parameter

  /// Outline thickness
  final double strokeWidth;

  /// Pill corner radius
  final double radius;

  /// FIXED height for the capsule
  final double capsuleHeight;

  /// Side gap from screen edges
  final double horizontalInset;

  /// Inner padding for the child (text/row)
  final EdgeInsetsGeometry contentPadding;

  /// Outline gradient (flows along whole rect)
  final Gradient outlineGradient;

  /// Kitna hissa visible rahe (0–1). 0.5 => exactly half, opposite side open.
  final double visibleFraction;

  /// Animation duration for one full revolution
  final Duration duration;

  /// Start phase (0–1). 0 ~ top-left corner se; 0.75 ~ bottom se approx.
  final double startPhase;

  /// Repeat continuously?
  final bool repeat;

  const CirclingBorderWidget({
    Key? key,
    required this.child,
    required this.shouldAnimate,
    this.animateOnce = true, // NEW: Default to animate once
    this.strokeWidth = 2.0,
    this.radius = 16.0,
    this.capsuleHeight = 76.0,
    this.horizontalInset = 80.0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 18.0),
    this.visibleFraction = 0.5, // one side line, one side open
    this.duration = const Duration(milliseconds: 1200),
    this.startPhase = 0.75, // bottom-ish start by default
    this.repeat = false,
    Gradient? outlineGradient,
  })  : outlineGradient = outlineGradient ??
      const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFF9000), Color(0xFFED4300),Color(0xffF66A0000)],
      ),
        assert(visibleFraction > 0 && visibleFraction < 1,
        'visibleFraction must be between 0 and 1'),
        super(key: key);

  @override
  State<CirclingBorderWidget> createState() => _CirclingBorderWidgetState();
}

class _CirclingBorderWidgetState extends State<CirclingBorderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;
  bool _isAnimating = false;
  bool _hasAnimated = false; // NEW: Track if we've already animated once

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void didUpdateWidget(CirclingBorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    // NEW: Only animate if we haven't already animated (when animateOnce is true)
    if (widget.shouldAnimate && !_isAnimating) {
      if (!widget.animateOnce || !_hasAnimated) {
        _start();
      }
    }
  }

  Future<void> _start() async {
    setState(() => _isAnimating = true);
    _hasAnimated = true; // NEW: Mark as animated

    try {
      if (widget.repeat) {
        _controller.repeat();
        // agar repeat true, to yahin chalta rahega; stop tum handle karna
      } else {
        await _controller.forward(from: 0);
      }
    } finally {
      if (!widget.repeat) {
        if (mounted) {
          _controller.reset();
          setState(() => _isAnimating = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalInset),
      child: SizedBox(
        height: widget.capsuleHeight,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final active = widget.repeat ? true : _isAnimating;
            return CustomPaint(
              foregroundPainter: active
                  ? _HalfSweepPainter(
                progress: _anim.value,
                strokeWidth: widget.strokeWidth,
                radius: widget.radius,
                outlineGradient: widget.outlineGradient,
                visibleFraction: widget.visibleFraction,
                startPhase: widget.startPhase,
              )
                  : null,
              child: Center(
                child: Padding(
                  padding: widget.contentPadding,
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HalfSweepPainter extends CustomPainter {
  final double progress; // 0..1
  final double strokeWidth;
  final double radius;
  final Gradient outlineGradient;
  final double visibleFraction; // 0..1 (use 0.5 for "one side line, one side open")
  final double startPhase; // 0..1

  const _HalfSweepPainter({
    required this.progress,
    required this.strokeWidth,
    required this.radius,
    required this.outlineGradient,
    required this.visibleFraction,
    required this.startPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - strokeWidth),
      math.max(0, size.height - strokeWidth),
    );

    final r = radius.clamp(0.0, math.min(rect.width, rect.height) / 2);

    // Full capsule path (closed)
    final Path capsule = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)));
    final metric = capsule.computeMetrics().first;
    final L = metric.length;

    // Start offset rotates along path; startPhase lets you shift where it begins.
    final double start = ((progress + startPhase) % 1.0) * L;
    final double segLen = (visibleFraction.clamp(0.0, 1.0)) * L;
    final double end = start + segLen;

    final path = _extractCyclic(metric, start, end);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = outlineGradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  // Extracts path segment even if it wraps past L (cyclic)
  Path _extractCyclic(PathMetric m, double start, double end) {
    final L = m.length;
    double s = start % L;
    double e = end % L;
    final p = Path();
    if (e >= s) {
      p.addPath(m.extractPath(s, e), Offset.zero);
    } else {
      p.addPath(m.extractPath(s, L), Offset.zero);
      p.addPath(m.extractPath(0, e), Offset.zero);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _HalfSweepPainter old) {
    return progress != old.progress ||
        strokeWidth != old.strokeWidth ||
        radius != old.radius ||
        outlineGradient != old.outlineGradient ||
        visibleFraction != old.visibleFraction ||
        startPhase != old.startPhase;
  }
}
