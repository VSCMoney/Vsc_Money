import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/auth/phone_otp_scree.dart';
import 'package:vscmoney/screens/presentation/home/assets.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';

import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../constants/colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_manager.dart';
import '../presentation/search_stock_screen.dart';
import 'package:http/http.dart' as http;
// class CustomDrawer extends StatelessWidget {
//   final ChatService chatService;
//   final Function(ChatSession) onSessionTap;
//
//   const CustomDrawer({
//     Key? key,
//     required this.chatService,
//     required this.onSessionTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: SafeArea(
//         child: Column(
//           children: [
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: SearchBar(),
//             ),
//             const Divider(),
//             // Use StreamBuilder to listen to chat sessions
//             Expanded(
//               child: FutureBuilder<List<ChatSession>>(
//                 future: chatService.fetchSessions(),
//                 builder: (context, snapshot) {
//                   final sessions = snapshot.data ?? [];
//
//                   return ListView.separated(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: sessions.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 12),
//                     itemBuilder: (context, index) {
//                       final session = sessions[index];
//                       return GestureDetector(
//                         onTap: () {
//                           Navigator.pop(context);
//                           onSessionTap(session);
//                           print(session.title);
//                         },
//                         child: Text(
//                           session.title ?? 'New Chat',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             const DrawerFooter(),
//           ],
//         ),
//       ),
//     );
//   }
// }




class CustomDrawer extends StatefulWidget {
  final ChatService chatService;
  final Function(ChatSession) onSessionTap;
  final VoidCallback onCreateNewChat;

  const CustomDrawer({
    Key? key,
    required this.chatService,
    required this.onSessionTap,
    required this.onCreateNewChat,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _selectedItem = 'Vitty';

  void _handleTap(String title, VoidCallback onTap) {
    setState(() => _selectedItem = title);
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StockSearchScreen()),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text('Search', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
             SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 20),
            _buildDrawerItem(
              icon: 'assets/images/new_app_logo.png', // replace with actual icons
              title: 'Vitty',
              isActive: _selectedItem == 'Vitty',
              onTap: () => _handleTap('Vitty', () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              }),
            ),
            _buildDrawerItem(
              icon: "assets/images/port.png",
              title: 'Portfolio',
              isActive: _selectedItem == 'Portfolio',
              onTap: () => _handleTap('Portfolio', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Assets()),
                );
              }),
            ),
            _buildDrawerItem(
              icon: "assets/images/Vector.svg",
              title: 'Goals',
              isActive: _selectedItem == 'Goals',
              onTap: () => _handleTap('Goals', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalsPage()),
                );
              }),
            ),
            _buildDrawerItem(
              icon: "assets/images/Vector.png",
              title: 'Conversations',
              isActive: _selectedItem == 'Conversations',
              onTap: () => _handleTap('Conversations', () {
                Navigator.pop(context);
                Future.delayed(Duration(milliseconds: 100), () async {
                  final selectedSession = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Conversations(
                        chatService: widget.chatService,
                        onSessionTap: widget.onSessionTap,
                        onCreateNewChat: widget.onCreateNewChat,
                      ),
                    ),
                  );

                  if (selectedSession != null && selectedSession is ChatSession) {
                    widget.onSessionTap(selectedSession);
                  }
                });
              }),
            ),
            const Spacer(),
            const DrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final bool isSvg = icon.toLowerCase().endsWith('.svg');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
            child: Row(
              children: [
                if (icon.isNotEmpty)
                  isSvg
                      ? SvgPicture.asset(
                    icon,
                    height: 16,
                    width: 22,
                    color: isActive ? Colors.white : Colors.black,
                  )
                      : Image.asset(
                    icon,
                    height: 26,
                    width: 26,
                    color: isActive ? Colors.white : null,
                  ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}


class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class DrawerFooter extends StatefulWidget {
  const DrawerFooter({super.key});

  @override
  State<DrawerFooter> createState() => _DrawerFooterState();
}

class _DrawerFooterState extends State<DrawerFooter> {
  String fullName = "User";

  Future<void> _loadUserProfile() async {
    try {
      final token = await SessionManager.token; // Get JWT token
      final response = await http.get(
        Uri.parse('https://fastapi-chatbot-717280964807.asia-south1.run.app//auth/get_profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final firstName = data['first_name'] ?? '';
        final lastName = data['last_name'] ?? '';
        setState(() {
          fullName = "$firstName $lastName".trim();
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }




  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    final name = user != null
        ? "${user.firstName ?? ''} ${user.lastName ?? ''}".trim()
        : "User";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () => _showLogoutMenu(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutMenu(BuildContext context) {
    Future.microtask(() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context); // close bottom sheet
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }


  void _confirmLogout(BuildContext context) {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await FirebaseAuth.instance.signOut();

                // ✅ Navigate to Auth screen
                _navigateTo(PhoneOtpScreen());


              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}



// class Conversations extends StatefulWidget {
//   final ChatService chatService;
//   final Function(ChatSession) onSessionTap;
//   const Conversations({super.key, required this.chatService, required this.onSessionTap});
//
//   @override
//   State<Conversations> createState() => _ConversationsState();
// }
//
// class _ConversationsState extends State<Conversations> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Builder(
//           builder: (context) => appBars(context, "Converations", (){}),
//         ),
//       ),
//       body: FutureBuilder<List<ChatSession>>(
//         future: widget.chatService.fetchSessions(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading sessions'));
//           }
//
//           final sessions = snapshot.data ?? [];
//
//           if (sessions.isEmpty) {
//             return const Center(child: Text('No conversations yet.'));
//           }
//
//           return ListView.builder(
//             itemCount: sessions.length,
//             itemBuilder: (context, index) {
//               final session = sessions[index];
//               return ListTile(
//                 title: Text(session.title),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                 onTap: () {
//                   if (Navigator.canPop(context)) {
//                     Navigator.pop(context);
//                   }
//                   // Close AllChatsPage
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     if (mounted) {
//                       setState(() {
//                        widget.onSessionTap(session);
//                       });
//                     }
//                   });
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



class Conversations extends StatefulWidget {
  final ChatService chatService;
  final Function(ChatSession) onSessionTap;
  final VoidCallback onCreateNewChat;

  const Conversations({
    super.key,
    required this.chatService,
    required this.onSessionTap,
    required this.onCreateNewChat,
  });

  @override
  State<Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  Map<String, List<ChatSession>> groupedSessions = {};
  TextEditingController _searchController = TextEditingController();
  List<ChatSession> _allSessions = [];
  List<ChatSession> _filteredSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _searchController.addListener(_onSearchChanged);
  }


  void _loadSessions([List<ChatSession>? sessionsList]) async {
    final sessions = sessionsList ?? await widget.chatService.fetchSessions();
    final Map<String, List<ChatSession>> grouped = {};

    for (var session in sessions) {
      final dt = session.createdAt ?? DateTime.now();
      final label = _getLabelForDate(dt);
      grouped.putIfAbsent(label, () => []).add(session);
    }

    setState(() {
      _allSessions = sessions;
      groupedSessions = grouped;
    });
  }



  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      _loadSessions(_allSessions); // show all if empty
      return;
    }

    final filtered = _allSessions.where(
          (session) => session.title.toLowerCase().contains(query),
    ).toList();

    _loadSessions(filtered);
  }

  Future<void> _fetchSessions() async {
    final sessions = await widget.chatService.fetchSessions();
    setState(() {
      _allSessions = sessions;
      _filteredSessions = sessions;
    });
  }

  String _getLabelForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compare = DateTime(date.year, date.month, date.day);

    if (compare == today) return 'Today';
    if (compare == today.subtract(const Duration(days: 1))) return 'Yesterday';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: appBar(context, "Conversations", widget.onCreateNewChat, false),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onCreateNewChat();
          },
          backgroundColor: Colors.black,
          child: SvgPicture.asset('assets/images/addnewchat.svg'),
          shape: const CircleBorder(),
          elevation: 4,
        ),
      ),
      body: _filteredSessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFEF),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(

                    controller: _searchController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries.map((entry) {
                  final label = entry.key;
                  final sessions = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...sessions.map((session) => GestureDetector(
                        onTap: () {
                          widget.onSessionTap(session);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          margin: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





