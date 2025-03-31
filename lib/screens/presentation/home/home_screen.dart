import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../widgets/drawer.dart';
import 'chat_screen.dart';
import 'assets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();
  late ChatSession _currentSession;
  bool _isLoading = true;

  // List of screens - we'll build this dynamically after initialization
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
  }

  Future<void> _initializeChatService() async {
    try {
      // Initialize the chat service
      await _chatService.initialize();

      // Create or get an existing session
      final sessions = _chatService.getAllSessions();

      // Use most recent session or create a new one
      if (sessions.isNotEmpty) {
        _currentSession = sessions.first;
      } else {
        _currentSession = _chatService.createNewSession();
      }

      // Now build screens list with initialized chat service and session
      _screens = [
        ChatScreen(
          session: _currentSession,
          chatService: _chatService,
        ),
        const Assets(),
        GoalsPage(),
      ];

      // Update state to show screens
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing chat service: $e');
      // Handle error state
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Create empty screens as fallback
          _screens = [
            const Center(child: Text('Chat unavailable')),
            GoalsPage(),
            const Assets(),
          ];
        });
      }
    }
  }


  void _createNewChat(BuildContext context) {
    final newSession = _chatService.createNewSession();

    setState(() {
      _currentSession = newSession;

      // Rebuild the screens with the new session
      _screens = [
        ChatScreen(
          session: _currentSession,
          chatService: _chatService,
          onNavigateToTab: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        GoalsPage(),
        const Assets(),
      ];

      // Optional: go back to Chat tab
      _currentIndex = 0;
    });
  }


  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(
          builder: (context) => appBar(context, getAppBarTitle(), () => _createNewChat(context)),
        ),
      ),
      drawer: CustomDrawer(
        chatService: _chatService,
        onSessionTap: (session) {
          setState(() {
            _currentSession = session;

            // 👇 Recreate the _screens list with the new session
            _screens = [
              ChatScreen(
                key: ValueKey(session.id), // 🔑 force rebuild
                session: _currentSession,
                chatService: _chatService,
              ),
              GoalsPage(),
              const Assets(),
            ];

            _currentIndex = 0; // optional: switch to Chat tab
          });
        },
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.message_outlined,
                isSelected: _currentIndex == 0,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.analytics_outlined,
                isSelected: _currentIndex == 1,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                isSelected: _currentIndex == 2,
                svgPath: 'assets/images/Vector.svg',
              ),
              label: '',
            ),
          ],
        ),
      ),


    );
  }
  String getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Penny'; // or 'Chat'
      case 1:
        return 'Goals';
      case 2:
        return 'Assets';
      default:
        return '';
    }
  }

}



Widget _buildNavIcon({
  IconData? icon,
  String? svgPath,
  required bool isSelected,
}) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: isSelected
        ? BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(20),
    )
        : null,
    child: icon != null
        ? Icon(
      icon,
      size: 18,
      color: isSelected ? Colors.white : Colors.black,
    )
        : SvgPicture.asset(
      svgPath!,
      width: 18,
      height: 18,
      color: isSelected ? Colors.white : Colors.black,
    ),
  );
}




PreferredSizeWidget appBar(BuildContext context, String title, VoidCallback onNewChatTap) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Left drawer icon
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu, color: Colors.black),
              ),

              const Spacer(),

              // Logo + Title
              Row(
                children: [
                  Image.asset(
                    'assets/images/Group.png', // update with your logo
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Notification
              const Icon(Icons.notifications_none_outlined, color: Colors.black),
              const SizedBox(width: 16),

              // Chat add icon (SVG)
              GestureDetector(
                onTap: onNewChatTap,
                child: SvgPicture.asset(
                  "assets/images/Frame 38.svg", // ensure this SVG is accurate
                  width: 28,
                  height: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

