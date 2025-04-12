import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import 'package:vscmoney/screens/presentation/search_stock_screen.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/session_manager.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../widgets/drawer.dart';
import 'chat_screen.dart';
import 'assets.dart';

// class DashboardScreen extends StatefulWidget {
//   final ChatSession? initialSession;
//   const DashboardScreen({super.key,this.initialSession});
//
//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }
//
// class _DashboardScreenState extends State<DashboardScreen> {
//   int _currentIndex = 0;
//   late ChatService _chatService;
//   late ChatSession _currentSession;
//   bool _isLoading = true;
//   bool _showNewChatButton = false;
//
//
//   // List of screens - we'll build this dynamically after initialization
//   late List<Widget> _screens;
//   bool _initialized = false;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeChatService();
//   }
//
//
//
//   // In DashboardScreen.dart
//   void _handleFirstMessageComplete(bool isComplete) {
//     print("📲 DashboardScreen received callback with value: $isComplete");
//     print("📲 Current state values: _showNewChatButton=$_showNewChatButton, mounted=$mounted");
//
//     if (mounted && isComplete) {
//       print("📲 About to update state...");
//       setState(() {
//         _showNewChatButton = true;
//         print("📲 State updated! _showNewChatButton is now: $_showNewChatButton");
//       });
//     }
//   }
//
//   Future<void> _initializeChatService() async {
//     try {
//       // ✅ Get custom backend JWT (await required)
//       final token = SessionManager.token; // your backend JWT
//
//       if (token == null || token.isEmpty) throw Exception("Token is null or empty");
//
//       _chatService = ChatService(authToken: token);
//
//       final sessions = await _chatService.fetchSessions();
//
//       if (sessions.isNotEmpty) {
//         _currentSession = sessions.first;
//       } else {
//         _currentSession = await _chatService.createSession('New Chat');
//       }
//
//       _screens = [
//         ChatScreen(session: _currentSession, chatService: _chatService),
//       ];
//
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _initialized = true;
//         });
//       }
//     } catch (e) {
//       print('❌ Error initializing chat: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _initialized = false;
//         });
//       }
//     }
//   }
//
//
//
//
//   // void _createNewChat(BuildContext context) async {
//   //   try {
//   //     // Perform async work first: create new session
//   //     final newSession = await _chatService.createSession('New Chat');
//   //
//   //     // Update the UI state with setState
//   //     if (mounted) {
//   //       setState(() {
//   //         // Update the current session with the newly created session
//   //         _currentSession = newSession;
//   //
//   //         // Rebuild the screens with the new session
//   //         _screens = [
//   //           ChatScreen(
//   //             session: _currentSession,
//   //             chatService: _chatService,
//   //             onNavigateToTab: (int index) {
//   //               setState(() {
//   //                 _currentIndex = index;
//   //               });
//   //             },
//   //           ),
//   //           GoalsPage(),
//   //           const Assets(),
//   //         ];
//   //
//   //         // Optionally go back to Chat tab
//   //         _currentIndex = 0;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     print("❌ Error creating new chat session: $e");
//   //   }
//   // }
//
//
//   void _createNewChat(BuildContext context) async {
//     try {
//       // Show loading dialog or progress indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator()),
//       );
//
//       // Create new session
//       final newSession = await _chatService.createSession('New Chat');
//
//       if (!mounted) return;
//       Navigator.of(context).pop(); // Close the loading dialog
//       //
//       // // Show animated feedback
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(
//       //     content: const Text("✅ New chat created"),
//       //     backgroundColor: Colors.green.shade600,
//       //     behavior: SnackBarBehavior.floating,
//       //     duration: const Duration(seconds: 2),
//       //   ),
//       // );
//
//       // Add animation when switching screens
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       if (!mounted) return;
//
//       setState(() {
//         _currentSession = newSession;
//
//         _screens = [
//           // AnimatedSwitcher will add fade/scale animation when changing sessions
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 500),
//             transitionBuilder: (child, animation) => FadeTransition(
//               opacity: animation,
//               child: ScaleTransition(
//                 scale: animation,
//                 child: child,
//               ),
//             ),
//             child: ChatScreen(
//               key: ValueKey(newSession.id),
//               session: _currentSession,
//               chatService: _chatService,
//               onNavigateToTab: (int index) {
//                 setState(() {
//                   _currentIndex = index;
//                 });
//               },
//             ),
//           ),
//           GoalsPage(),
//           const Assets(),
//         ];
//
//         _currentIndex = 0;
//       });
//     } catch (e) {
//       if (mounted) Navigator.of(context).pop();
//       print("❌ Error creating new chat session: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed to create chat: $e"),
//           backgroundColor: Colors.red.shade600,
//         ),
//       );
//     }
//   }
//
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     // If _chatService or _screens is not ready yet, show loading
//     if (_isLoading || !_initialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     print("🏗️ DashboardScreen.build() - _showNewChatButton=$_showNewChatButton");
//
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Builder(
//           builder: (context) => appBar(context, getAppBarTitle(), () => _createNewChat(context),true, showNewChatButton: _showNewChatButton),
//         ),
//       ),
//       drawer: CustomDrawer(
//         onCreateNewChat: () => _createNewChat(context),
//         chatService: _chatService,
//         onSessionTap: (session) {
//           setState(() {
//             _currentSession = session;
//             _screens = [
//               ChatScreen(
//                 onFirstMessageComplete: _handleFirstMessageComplete,
//                 key: ValueKey(session.id),
//                 session: _currentSession,
//                 chatService: _chatService,
//               ),
//               GoalsPage(),
//               const Assets(),
//             ];
//             _currentIndex = 0;
//             _showNewChatButton = false;
//           });
//         },
//       ),
//       body: _screens[_currentIndex],
//
//
//     );
//   }
//   String getAppBarTitle() {
//     switch (_currentIndex) {
//       case 0:
//         return 'Penny'; // or 'Chat'
//       case 1:
//         return 'Goals';
//       case 2:
//         return 'Assets';
//       default:
//         return '';
//     }
//   }
//
// }

class DashboardScreen extends StatefulWidget {
  final ChatSession? initialSession;
  const DashboardScreen({super.key, this.initialSession});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late ChatService _chatService;
  late ChatSession _currentSession;
  bool _isLoading = true;
  bool _showNewChatButton = false;

  // List of screens - we'll build this dynamically after initialization
  late List<Widget> _screens;
  bool _initialized = false;
  bool _isInitCalled = false;


  @override
  void initState() {
    super.initState();
    if (!_isInitCalled) {
      _isInitCalled = true;
      print("✅ First-time init");
      _initializeChatService();
    } else {
      print("🚫 Already initialized, skipping");
    }
  }

  // In DashboardScreen.dart
  void _handleFirstMessageComplete(bool isComplete) {
    print("📲 DashboardScreen received callback with value: $isComplete");
    print("📲 Current state values: _showNewChatButton=$_showNewChatButton, mounted=$mounted");

    if (mounted && isComplete) {
      print("📲 About to update state...");
      setState(() {
        _showNewChatButton = true;
        print("📲 State updated! _showNewChatButton is now: $_showNewChatButton");
      });
    }
  }

  Future<void> _initializeChatService() async {
    print("CALLED AGAIN");
    try {
      // ✅ Get custom backend JWT (await required)
      final token = SessionManager.token; // your backend JWT

      if (token == null || token.isEmpty) throw Exception("Token is null or empty");

      _chatService = ChatService(authToken: token);

      final sessions = await _chatService.fetchSessions();

      if (sessions.isNotEmpty) {
        _currentSession = sessions.first;

        // Check if the session already has messages
        try {
          final messages = await _chatService.fetchMessages(_currentSession.id);
          if (messages.isNotEmpty && messages.any((m) => m.answer != null && m.answer!.isNotEmpty)) {
            _showNewChatButton = true;
          }
        } catch (e) {
          print("Error checking session messages: $e");
        }
      } else {
        _currentSession = await _chatService.createSession('New Chat');
      }

      _screens = [
        ChatScreen(
          session: _currentSession,
          chatService: _chatService,
          onFirstMessageComplete: _handleFirstMessageComplete,
        ),
      ];

      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialized = true;
        });
      }
    } catch (e) {
      print('❌ Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialized = false;
        });
      }
    }
  }

  void _createNewChat(BuildContext context) async {
    print("CreateNew Chat called");
    try {
      // Show loading dialog or progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Create new session
      final newSession = await _chatService.createSession('New Chat');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close the loading dialog

      // Add animation when switching screens
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _currentSession = newSession;
        _showNewChatButton = false; // Reset button visibility for new chat

        _screens = [
          // AnimatedSwitcher will add fade/scale animation when changing sessions
          ChatScreen(
            key: ValueKey(newSession.id),
            session: _currentSession,
            chatService: _chatService,
            onNavigateToTab: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            onFirstMessageComplete: _handleFirstMessageComplete, // Add callback here
          ),
          GoalsPage(),
          const Assets(),
        ];

        _currentIndex = 0;
      });
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print("❌ Error creating new chat session: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create chat: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If _chatService or _screens is not ready yet, show loading
    if (_isLoading || !_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print("🏗️ DashboardScreen.build() - _showNewChatButton=$_showNewChatButton");

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(
          builder: (context) {
            print("🏗️ About to build appBar with showNewChatButton=$_showNewChatButton");
            return appBar(
                context,
                getAppBarTitle(),
                    () => _createNewChat(context),
                true,
                showNewChatButton: _showNewChatButton
            );
          },
        ),
      ),
      drawer: CustomDrawer(
        onCreateNewChat: () => _createNewChat(context),
        chatService: _chatService,
        onSessionTap: (session) async {
          // Check if this session already has messages
          bool hasMessages = false;
          try {
            final messages = await _chatService.fetchMessages(session.id);
            hasMessages = messages.isNotEmpty && messages.any((m) => m.answer != null && m.answer!.isNotEmpty);
          } catch (e) {
            print("Error checking session messages: $e");
          }

          setState(() {
            _currentSession = session;
            _screens = [
              ChatScreen(
                onFirstMessageComplete: _handleFirstMessageComplete,
                key: ValueKey(session.id),
                session: _currentSession,
                chatService: _chatService,
              ),
              GoalsPage(),
              const Assets(),
            ];
            _currentIndex = 0;

            // Set button visibility based on whether this session already has messages
            _showNewChatButton = hasMessages;
          });
        },
      ),
      body: _screens[_currentIndex],
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




PreferredSizeWidget appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard,
{
  bool showNewChatButton = false,
}
    ) {
  print("Building appBar with showNewChatButton: $showNewChatButton");
  print("🔍 Button visibility check: isDashboard=$isDashboard, showNewChatButton=$showNewChatButton");
  if (isDashboard && showNewChatButton) {
    print("✅ SHOULD SHOW BUTTON!");
  } else {
    print("❌ NOT showing button. isDashboard=$isDashboard, showNewChatButton=$showNewChatButton");
  }

  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 👇 Title or Logo in center
              isDashboard
                  ? Image.asset("assets/images/new_app_logo.png", height: 40)
                  : Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),

              // 👇 Left and right controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔓 Safe drawer context using Builder
                  Builder(
                    builder: (BuildContext scaffoldContext) => GestureDetector(
                      onTap: () {
                        Scaffold.of(scaffoldContext).openDrawer();
                      },
                      child: SvgPicture.asset('assets/images/drawer.svg'),
                    ),
                  ),

                  Row(
                    children: [
                      // 🔔 Notification tap with coming soon tooltip
                      GestureDetector(
                        onTap: () {
                          final overlay = Overlay.of(context);
                          final RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                          final size = renderBox.size;
                          final offset = renderBox.localToGlobal(Offset.zero);

                          final entry = OverlayEntry(
                            builder: (context) => Positioned(
                              top: offset.dy + size.height + 8,
                              left: offset.dx + size.width / 2 - 60,
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedComingSoonTooltip(),
                              ),
                            ),
                          );

                          overlay.insert(entry);

                          Future.delayed(const Duration(seconds: 2), () {
                            entry.remove();
                          });
                        },
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ➕ New chat only on Dashboard
                      if (isDashboard && showNewChatButton)
                        GestureDetector(
                          onTap: onNewChatTap,
                          child: SvgPicture.asset(
                            "assets/images/Frame 38.svg",
                            width: 28,
                            height: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}








