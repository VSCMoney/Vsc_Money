import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vscmoney/constants/colors.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/services/theme_service.dart';

import '../../constants/app_bar.dart';
import '../../constants/bottomsheet.dart';
import '../../models/chat_session.dart';
import '../../services/chat_service.dart';
import '../../services/conversation_service.dart';
import '../widgets/drawer.dart';
import 'home/home_screen.dart';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';

// import 'package:intl/intl.dart'; // <-- make sure this import exists

class Conversations extends StatefulWidget {
  final Function(ChatSession)? onSessionTap;

  const Conversations({
    super.key,
    required this.onSessionTap,
  });

  @override
  State<Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  final ConversationsService _conversationsService = locator<ConversationsService>();
  final ChatService chat = locator<ChatService>();
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _sessionsSubscription;
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _conversationsService.loadSessions();
    _searchController.addListener(_onSearchChanged);
    _sessionsSubscription = _conversationsService.sessionsStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _sessionsSubscription.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _conversationsService.searchSessions(_searchController.text.trim());
  }

  void _openSettingsSheet() {
    final settingsSheet = BottomSheetManager.buildSettingsSheet(
      onTap: () => _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(settingsSheet);
  }

  void _onSessionTap(ChatSession session) {
    if (_isNavigating) return;
    _isNavigating = true;

    final future = context.push('/home?sessionId=${session.id}');
    future.whenComplete(() {
      if (mounted) _isNavigating = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _isNavigating = false;
    });
  }

  /// FAB just goes to Home. No chat creation here.
  void _onNewChatFabPressed() {
    if (_isNavigating) return;
    _isNavigating = true;

    FocusManager.instance.primaryFocus?.unfocus();
    context.go('/home');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _isNavigating = false;
    });
  }

  // ------------------------
  // Group header formatting
  // ------------------------
  String _formatGroupLabel(dynamic key) {
    // If your ConversationsService already provides a label string, just return it.
    if (key is String) {
      // Try to parse as date first (ISO or yyyy-MM-dd), else use as-is.
      final parsed = DateTime.tryParse(key);
      if (parsed == null) return key;
      return _formatDateLabel(parsed);
    }

    if (key is DateTime) {
      return _formatDateLabel(key);
    }

    return key?.toString() ?? 'Unknown';
  }

  String _formatDateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d); // e.g., Monday
    return DateFormat('MMM d, yyyy').format(d); // e.g., Aug 30, 2025
  }

  @override
  Widget build(BuildContext context) {
    final state = _conversationsService.currentState;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 28.0;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return ChatGPTBottomSheetWrapper(
      key: _sheetKey,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          drawer: CustomDrawer(
            onTap: _openSettingsSheet,
            chatService: chat,
            onSessionTap: widget.onSessionTap,
            selectedRoute: "Conversations",
          ),
          backgroundColor: theme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Builder(
              builder: (context) => appBar(
                context,
                "Conversations",
                    () {}, // no AppBar new-chat button here
                false,
                showNewChatButton: false,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _onNewChatFabPressed,
            backgroundColor: AppColors.primary,
            child: Image.asset('assets/images/newChat.png', height: 20),
            shape: const CircleBorder(),
            elevation: 4,
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
            child: RefreshIndicator(
              onRefresh: _conversationsService.loadSessions,
              color: theme.text,
              child: CustomScrollView(
                slivers: [
                  // Search box
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.searchBox,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF7E7E7E), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  color: theme.text,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF7E7E7E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'DM Sans',
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Empty state
                  if (state.filteredSessions.isEmpty && !state.isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No conversations found",
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.text,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    )
                  else
                  // Grouped list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final entries = state.groupedSessions.entries.toList();

                          // Optional: sort groups newest-first when keys are DateTime/parseable
                          entries.sort((a, b) {
                            DateTime? da = a.key is DateTime ? a.key as DateTime : DateTime.tryParse(a.key.toString());
                            DateTime? db = b.key is DateTime ? b.key as DateTime : DateTime.tryParse(b.key.toString());
                            if (da != null && db != null) return db.compareTo(da);
                            return 0;
                          });

                          if (index >= entries.length) return null;

                          final entry = entries[index];
                          final headerLabel = _formatGroupLabel(entry.key);

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                                  child: Text(
                                    headerLabel, // <-- dynamic label now
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff7E7E7E),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                                ...entry.value
                                    .map((session) => _buildConversationItem(session))
                                    .toList(),
                              ],
                            ),
                          );
                        },
                        childCount: state.groupedSessions.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(ChatSession session) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return InkWell(
      onTap: () => _onSessionTap(session),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                session.title.trim().isEmpty ? "Untitled Chat" : session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: theme.text,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


