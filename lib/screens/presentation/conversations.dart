// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:intl/intl.dart';
//
// import '../../models/chat_session.dart';
// import '../../services/chat_service.dart';
// import '../widgets/drawer.dart';
// import 'home/home_screen.dart';
//
// class Conversations extends StatefulWidget {
//   final ChatService chatService;
//   final Function(ChatSession) onSessionTap;
//   final VoidCallback onCreateNewChat;
//
//   const Conversations({
//     super.key,
//     required this.chatService,
//     required this.onSessionTap,
//     required this.onCreateNewChat,
//   });
//
//   @override
//   State<Conversations> createState() => _ConversationsState();
// }
//
// class _ConversationsState extends State<Conversations> {
//   Map<String, List<ChatSession>> groupedSessions = {};
//   TextEditingController _searchController = TextEditingController();
//   List<ChatSession> _allSessions = [];
//   List<ChatSession> _filteredSessions = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSessions();
//     _searchController.addListener(_onSearchChanged);
//     _loadSessions();
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _loadSessions([List<ChatSession>? sessionsList]) async {
//     final sessions = sessionsList ?? await widget.chatService.fetchSessions();
//     final Map<String, List<ChatSession>> grouped = {};
//
//     for (var session in sessions) {
//       final dt = session.createdAt ?? DateTime.now();
//       final label = _getLabelForDate(dt);
//       grouped.putIfAbsent(label, () => []).add(session);
//     }
//
//     if (mounted) {
//       setState(() {
//         _allSessions = sessions;
//         _filteredSessions = sessions;
//         groupedSessions = grouped;
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _onSearchChanged() {
//     final query = _searchController.text.trim().toLowerCase();
//
//     if (query.isEmpty) {
//       setState(() {
//         _filteredSessions = _allSessions;
//       });
//       return;
//     }
//
//     final filtered = _allSessions.where(
//           (session) => session.title.toLowerCase().contains(query),
//     ).toList();
//
//     setState(() {
//       _filteredSessions = filtered;
//     });
//   }
//
//   Future<void> _fetchSessions() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final sessions = await widget.chatService.fetchSessions();
//       if (mounted) {
//         setState(() {
//           _allSessions = sessions;
//           _filteredSessions = sessions;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//       print("Error fetching sessions: $e");
//     }
//   }
//
//   String _getLabelForDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final compare = DateTime(date.year, date.month, date.day);
//
//     if (compare == today) return 'Today';
//     if (compare == today.subtract(const Duration(days: 1))) return 'Yesterday';
//     if (compare.isAfter(today.subtract(const Duration(days: 7)))) {
//       // If within the last week, show "X days ago"
//       final daysAgo = today.difference(compare).inDays;
//       return '$daysAgo days ago';
//     }
//     return DateFormat('dd MMM yyyy').format(date);
//   }
//
//   Map<String, List<ChatSession>> _groupByDate(List<ChatSession> sessions) {
//     final Map<String, List<ChatSession>> grouped = {};
//     for (var session in sessions) {
//       final dt = session.createdAt ?? DateTime.now();
//       final label = _getLabelForDate(dt);
//       grouped.putIfAbsent(label, () => []).add(session);
//     }
//     return grouped;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final grouped = _groupByDate(_filteredSessions);
//
//     // Get screen dimensions for responsive layout
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isTablet = screenWidth > 600;
//
//     // Adjust padding based on device size
//     final horizontalPadding = isTablet ? 24.0 : 16.0;
//
//     return Scaffold(
//       drawer: CustomDrawer(chatService: widget.chatService, onSessionTap: widget.onSessionTap, onCreateNewChat: widget.onCreateNewChat),
//       backgroundColor: Colors.white,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Builder(
//           builder: (context) => appBar(context, "Conversations", (){},false,showNewChatButton: false),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pop(context);
//           widget.onCreateNewChat();
//         },
//         backgroundColor: Colors.black,
//         child: SvgPicture.asset('assets/images/addnewchat.svg'),
//         shape: CircleBorder(),
//         elevation: 4,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SafeArea(
//         child: RefreshIndicator(
//           onRefresh: _fetchSessions,
//           color: Colors.black,
//           child: CustomScrollView(
//             slivers: [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: horizontalPadding,
//                     vertical: 16,
//                   ),
//                   child: Container(
//                     height: 44,
//                     decoration: BoxDecoration(
//                       color: Color(0xFFF5F5F5),
//                       borderRadius: BorderRadius.circular(22),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Row(
//                       children: [
//                         Icon(Icons.search, color: Colors.grey, size: 22),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextField(
//                             controller: _searchController,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontFamily: 'SF Pro Display',
//                               color: Colors.black,
//                             ),
//                             decoration: const InputDecoration(
//                               hintText: 'Search',
//                               hintStyle: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 16,
//                                 fontFamily: 'SF Pro Display',
//                               ),
//                               border: InputBorder.none,
//                               contentPadding: EdgeInsets.symmetric(vertical: 12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//
//               if (_filteredSessions.isEmpty && !_isLoading)
//                 SliverFillRemaining(
//                   child: Center(
//                     child: Text(
//                       "No conversations found",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                         fontFamily: 'SF Pro Display',
//                       ),
//                     ),
//                   ),
//                 )
//               else
//                 SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                         (context, index) {
//                       final entries = grouped.entries.toList();
//                       if (index >= entries.length) return null;
//
//                       final entry = entries[index];
//                       final label = entry.key;
//                       final sessions = entry.value;
//
//                       return Padding(
//                         padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(top: 16, bottom: 8),
//                               child: Text(
//                                 label,
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                   color: Color(0xFF8E8E93),
//                                   fontFamily: 'SF Pro Display',
//                                 ),
//                               ),
//                             ),
//                             ...sessions.map((session) => _buildConversationItem(session)),
//                           ],
//                         ),
//                       );
//                     },
//                     childCount: grouped.length,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildConversationItem(ChatSession session) {
//     return InkWell(
//       onTap: () {
//         widget.onSessionTap(session);
//         Navigator.pop(context);
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 session.title,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black,
//                   fontFamily: 'SF Pro Display',
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:vscmoney/constants/colors.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/services/theme_service.dart';

import '../../models/chat_session.dart';
import '../../services/chat_service.dart';
import '../widgets/drawer.dart';
import 'home/home_screen.dart';

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

  Map<String, List<ChatSession>> groupedSessions = {};
  TextEditingController _searchController = TextEditingController();
  List<ChatSession> _allSessions = [];
  List<ChatSession> _filteredSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _searchController.addListener(_onSearchChanged);
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadSessions([List<ChatSession>? sessionsList]) async {
    final sessions = sessionsList ?? await _chatService.fetchSessions();
    final Map<String, List<ChatSession>> grouped = {};

    for (var session in sessions) {
      final dt = session.createdAt ?? DateTime.now();
      final label = _getLabelForDate(dt);
      grouped.putIfAbsent(label, () => []).add(session);
    }

    if (mounted) {
      setState(() {
        _allSessions = sessions;
        _filteredSessions = sessions;
        groupedSessions = grouped;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredSessions = _allSessions;
      });
      return;
    }

    final filtered = _allSessions.where(
          (session) => session.title.toLowerCase().contains(query),
    ).toList();

    setState(() {
      _filteredSessions = filtered;
    });
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _chatService.fetchSessions();
      if (mounted) {
        setState(() {
          _allSessions = sessions;
          _filteredSessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error fetching sessions: $e");
    }
  }

  String _getLabelForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compare = DateTime(date.year, date.month, date.day);

    if (compare == today) return 'Today';
    if (compare == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (compare.isAfter(today.subtract(const Duration(days: 7)))) {
      final daysAgo = today.difference(compare).inDays;
      return '$daysAgo days ago';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  Map<String, List<ChatSession>> _groupByDate(List<ChatSession> sessions) {
    final Map<String, List<ChatSession>> grouped = {};
    for (var session in sessions) {
      final dt = session.createdAt ?? DateTime.now();
      final label = _getLabelForDate(dt);
      grouped.putIfAbsent(label, () => []).add(session);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_filteredSessions);
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
            if (widget.onCreateNewChat != null) {
              widget.onCreateNewChat!();
            }
            Navigator.pop(context);
          },
          backgroundColor: AppColors.primary, // 👈 your desired color here
          child: Image.asset(
            'assets/images/newChat.png',
            height: 20,
          ),
          shape: const CircleBorder(),
          elevation: 4,
        ),

        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchSessions,
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
                        color: theme.border,
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
                              style:  TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                color: theme.text,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
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
                if (_filteredSessions.isEmpty && !_isLoading)
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
                        final entries = grouped.entries.toList();
                        if (index >= entries.length) return null;

                        final entry = entries[index];
                        final label = entry.key;
                        final sessions = entry.value;

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  label,
                                  style:  TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.text,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ),
                              ...sessions.map((session) => _buildConversationItem(session)),
                            ],
                          ),
                        );
                      },
                      childCount: grouped.length,
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

    return InkWell(
      onTap: () {
        if (widget.onSessionTap != null) {
          widget.onSessionTap!(session);
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context); // ✅ only close drawer, not route stack
          }
        }
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
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
    );
  }
}