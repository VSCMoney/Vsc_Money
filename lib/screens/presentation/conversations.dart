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
import '../../models/chat_session.dart';
import '../../services/chat_service.dart';
import '../../services/conversation_service.dart';
import '../widgets/drawer.dart';
import 'home/home_screen.dart';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';

class Conversations extends StatefulWidget {
  final Function(ChatSession)? onSessionTap;
  final VoidCallback? onCreateNewChat;

  const Conversations({
    super.key,
    required this.onSessionTap,
    this.onCreateNewChat,
  });

  @override
  State<Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  final ChatService _chatService = locator<ChatService>();
  final ConversationsService _conversationsService = locator<ConversationsService>();
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _sessionsSubscription;

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

  @override
  Widget build(BuildContext context) {
    final state = _conversationsService.currentState;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 28.0;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: CustomDrawer(
          chatService: _chatService,
          onSessionTap: widget.onSessionTap,
          onCreateNewChat: widget.onCreateNewChat,
          selectedRoute: "Conversations",
        ),
        backgroundColor: theme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Builder(
            builder: (context) => appBar(context, "Conversations", () {}, false, showNewChatButton: false),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            widget.onCreateNewChat?.call();
            Navigator.pop(context);
          },
          backgroundColor: AppColors.primary,
          child: Image.asset('assets/images/newChat.png', height: 20),
          shape: const CircleBorder(),
          elevation: 4,
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: RefreshIndicator(
            onRefresh: _conversationsService.loadSessions,
            color: theme.text,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.shadow,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: theme.icon, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                color: theme.text,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'SF Pro Display',
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.filteredSessions.isEmpty && !state.isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "No conversations found",
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.text,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final entries = state.groupedSessions.entries.toList();
                        if (index >= entries.length) return null;

                        final entry = entries[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.text,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ),
                              ...entry.value.map((session) => _buildConversationItem(session)),
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
    );
  }

  Widget _buildConversationItem(ChatSession session) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Builder(
      builder: (innerContext) => InkWell(
        onTap: () {
          context.push('/home', extra: {
            'session': session
          });


          if (Scaffold.of(innerContext).isDrawerOpen) {
            Navigator.pop(innerContext);
          }
        },
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
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),
    ],
    ),

    ),
      ),
    );
  }
}

