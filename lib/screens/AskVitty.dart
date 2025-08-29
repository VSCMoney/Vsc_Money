import 'package:flutter/material.dart';
import 'package:vscmoney/screens/AskVittyChat.dart';
import 'package:vscmoney/screens/presentation/home/chat_screen.dart';

import '../models/chat_session.dart';
import '../services/chat_service.dart';



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
  ChatSession? _currentSession;
  late List<ThreadHistoryItem> _history;
  String? _selectedText;
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectedText = widget.initialText.trim();
    _initializeHistory();
    _startSession(_selectedText!);
  }

  void _initializeHistory() {
    // ✅ FIXED: Better history initialization
    final originalHistory = widget.history ?? <ThreadHistoryItem>[];

    // Create a copy of the original history
    _history = List<ThreadHistoryItem>.from(originalHistory);

    // Add initial text only if it's not already in history
    final initialText = widget.initialText.trim();
    if (initialText.isNotEmpty &&
        !_history.any((item) => item.text.trim() == initialText)) {

      final initialItem = ThreadHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: initialText,
        createdAt: DateTime.now(),
      );

      // Add to beginning of history
      _history.insert(0, initialItem);
    }

    print("📚 Initialized history with ${_history.length} items:");
    for (int i = 0; i < _history.length; i++) {
      print("  $i: ${_history[i].text}");
    }
  }

  Future<void> _startSession(String prompt) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentSession = null;
    });

    try {
      final title = prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt;
      final session = await widget.chatService.createSession('Thread: $title');

      if (mounted) {
        setState(() {
          _currentSession = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error creating session: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onAskVitty(String newText) async {
    if (!mounted) return;

    print('🤖 _onAskVitty called with: "$newText"');

    final trimmedNewText = newText.trim();
    if (trimmedNewText.isEmpty) return;

    // ✅ FIXED: Add the current selected text to history BEFORE switching
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      _addToHistory(_selectedText!);
    }

    // ✅ FIXED: Add the new text to history as well
    _addToHistory(trimmedNewText);

    // Update selected text
    setState(() {
      _selectedText = trimmedNewText;
      _isDropdownExpanded = false;
    });

    await _startSession(_selectedText!);
  }

  void _onHistoryItemSelected(String value) async {
    if (!mounted || value == _selectedText?.trim()) return;

    print('📖 History item selected: "$value"');

    // ✅ FIXED: Add current text to history before switching
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      _addToHistory(_selectedText!);
    }

    setState(() {
      _selectedText = value.trim();
      _isDropdownExpanded = false;
    });

    await _startSession(_selectedText!);
  }

  // ✅ NEW: Helper method to properly add items to history
  void _addToHistory(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // Check if item already exists
    final existingIndex = _history.indexWhere((item) => item.text.trim() == trimmedText);

    if (existingIndex != -1) {
      // ✅ FIXED: Move existing item to top instead of creating duplicate
      final existingItem = _history.removeAt(existingIndex);
      _history.insert(0, existingItem);
      print("📝 Moved existing item to top: \"$trimmedText\"");
    } else {
      // Add new item to top
      final newItem = ThreadHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: trimmedText,
        createdAt: DateTime.now(),
      );

      _history.insert(0, newItem);
      print("📝 Added new item to history: \"$trimmedText\"");
    }

    // ✅ OPTIONAL: Limit history size to prevent memory issues
    if (_history.length > 20) {
      _history = _history.take(20).toList();
    }

    print("📚 History now has ${_history.length} items:");
    for (int i = 0; i < _history.length && i < 5; i++) { // Show first 5
      print("  $i: ${_history[i].text}");
    }
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownExpanded = !_isDropdownExpanded;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildExpandableHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ENHANCED: Show history items in dropdown
  Widget _buildExpandableHeader() {
    final displayText = _selectedText != null && _selectedText!.length > 30
        ? '${_selectedText!.substring(0, 27)}...'
        : _selectedText ?? 'asking';

    return Column(
      children: [
        // Header bar
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.brown,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title + dropdown icon
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Show history count
                          if (_history.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_history.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(width: 4),

                          // Animated dropdown icon
                          AnimatedRotation(
                            turns: _isDropdownExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black,
                              size: 22,
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
        ),

        // ✅ ENHANCED: Show history dropdown with proper list
        if (_isDropdownExpanded && _history.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: const Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _history.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                final isSelected = item.text.trim() == _selectedText?.trim();

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onHistoryItemSelected(item.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                      ),
                      child: Row(
                        children: [
                          // Selection indicator
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Text content
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontFamily: "SF Pro",
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Time indicator
                          Text(
                            _formatTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ✅ NEW: Helper method to format time
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating new session...'),
          ],
        ),
      );
    }

    if (_currentSession == null) {
      return const Center(
        child: Text('Failed to create session'),
      );
    }

    return ChatScreen(
      key: ValueKey(_currentSession!.id),
      session: _currentSession!,
      chatService: widget.chatService,
      onAskVitty: _onAskVitty,
      isThreadMode: true,
    );
  }
}
