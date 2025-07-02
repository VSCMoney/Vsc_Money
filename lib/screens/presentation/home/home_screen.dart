import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import 'package:vscmoney/screens/presentation/search_stock_screen.dart';
import 'package:vscmoney/services/locator.dart';
import '../../../constants/widgets.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/session_manager.dart';
import '../../../main.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/theme_service.dart';
import '../../widgets/drawer.dart';
import 'chat_screen.dart';
import 'assets.dart';


class DashboardScreen extends StatefulWidget {
  final ChatSession? initialSession;
  const DashboardScreen({super.key, this.initialSession});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  ChatService? _chatService; // ✅ Made nullable - no late
  ChatSession? _currentSession; // ✅ Made nullable - no late
  bool _showNewChatButton = false;
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey();

  // ✅ Simple screens list
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens(); // ✅ Immediate initialization
    _loadDataInBackground(); // ✅ Background loading
  }

  // ✅ Initialize screens immediately - no waiting
  void _initializeScreens() {
    _screens = [
      _buildChatScreen(), // ✅ Always build something
      GoalsPage(),
      PortfolioScreen(),
    ];
  }

  // ✅ Build chat screen - handle null service gracefully
  Widget _buildChatScreen() {
    if (_chatService == null || _currentSession == null) {
      // ✅ Return empty container - no default screen
      return Container();
    }

    return ChatScreen(
      session: _currentSession!,
      chatService: _chatService!,
      onFirstMessageComplete: _handleFirstMessageComplete,
    );
  }

  // ✅ Background loading - no UI blocking
  void _loadDataInBackground() async {
    try {
      print("🔄 Starting background initialization...");

      final token = SessionManager.token;
      if (token == null || token.isEmpty) {
        print("⚠️ No token found");
        return;
      }

      final service = ChatService(authToken: token);
      final session = await service.createSession('New Chat');

      if (mounted) {
        setState(() {
          _chatService = service;
          _currentSession = session;

          // ✅ Update chat screen with real data
          _screens[0] = ChatScreen(
            session: _currentSession!,
            chatService: _chatService!,
            onFirstMessageComplete: _handleFirstMessageComplete,
          );

          _showNewChatButton = false;
        });

        print("✅ Background initialization complete");
      }
    } catch (e) {
      print('❌ Background loading error: $e');
      // ✅ Continue with placeholder - no crash!
    }
  }

  void _handleFirstMessageComplete(bool isComplete) {
    print("📲 DashboardScreen received callback with value: $isComplete");

    if (mounted && isComplete) {
      setState(() {
        _showNewChatButton = true;
      });
    }
  }

  void _createNewChat(BuildContext context) async {
    if (_chatService == null) {
      print("⚠️ Chat service not ready yet");
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final newSession = await _chatService!.createSession('New Chat');

      if (!mounted) return;
      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _currentSession = newSession;
        _showNewChatButton = false;

        _screens = [
          ChatScreen(
            key: ValueKey(newSession.id),
            session: _currentSession!,
            chatService: _chatService!,
            onNavigateToTab: (int index) {
              setState(() => _currentIndex = index);
            },
            onFirstMessageComplete: _handleFirstMessageComplete,
          ),
          GoalsPage(),
          PortfolioScreen(),
        ];

        _currentIndex = 0;
      });
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create chat: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      print("❌ Error creating new chat session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ DashboardScreen. build() - _showNewChatButton=$_showNewChatButton");
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    // ✅ Always show UI - no loading checks!
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: ChatGPTBottomSheetWrapper(
          key: _sheetKey,
          bottomSheet: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
            ),
            height: 840,
            child: SettingsScreen(
              onTap: () => _sheetKey.currentState?.closeSheet(),
            ),
          ),
          child: Scaffold(
            backgroundColor: theme.background,
            resizeToAvoidBottomInset: false,
            key: const ValueKey('dashboard'),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Builder(
                builder: (context) {
                  return appBar(
                    context,
                    getAppBarTitle(),
                        () => _createNewChat(context),
                    true,
                    showNewChatButton: _showNewChatButton,
                  );
                },
              ),
            ),
            onDrawerChanged: (isOpened) {
              if (isOpened) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            drawer: _chatService != null
                ? CustomDrawer(
              onTap: () => _sheetKey.currentState?.openSheet(),
              onCreateNewChat: () => _createNewChat(context),
              chatService: _chatService!,
              onSessionTap: (session) async {
                bool hasMessages = false;
                try {
                  final messages = await _chatService!.fetchMessages(session.id);
                  hasMessages = messages.isNotEmpty &&
                      messages.any((m) => m.answer != null && m.answer!.isNotEmpty);
                } catch (e) {
                  print("Error checking session messages: $e");
                }

                setState(() {
                  _currentSession = session;
                  _screens = [
                    ChatScreen(
                      onFirstMessageComplete: _handleFirstMessageComplete,
                      key: ValueKey(session.id),
                      session: _currentSession!,
                      chatService: _chatService!,
                    ),
                    GoalsPage(),
                    PortfolioScreen(),
                  ];
                  _currentIndex = 0;
                  _showNewChatButton = hasMessages;
                });
              },
            )
                : null, // ✅ No drawer until service ready
            body: _screens.isNotEmpty && _chatService != null
                ? _screens[_currentIndex]
                : Container(), // ✅ Empty container until chat service ready
          ),
        ),
      ),
    );
  }

  String getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Penny';
      case 1:
        return 'Goals';
      case 2:
        return 'Assets';
      default:
        return '';
    }
  }
}


// class DashboardScreen extends StatefulWidget {
//   final ChatSession? initialSession;
//   const DashboardScreen({super.key, this.initialSession});
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
//   final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey();
//
//
//   // List of screens - we'll build this dynamically after initialization
//   late List<Widget> _screens;
//   bool _initialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
//     //   statusBarColor: Colors.black, // 👈 for iOS
//     //   statusBarIconBrightness: Brightness.light,
//     //   statusBarBrightness: Brightness.light,
//     //   systemNavigationBarColor: Colors.white,
//     //   systemNavigationBarIconBrightness: Brightness.light
//     // ));
//     _initializeChatService();
//   }
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
//
//
//   Future<void> _initializeChatService() async {
//     try {
//       final token = SessionManager.token;
//       if (token == null || token.isEmpty) throw Exception("Token is null or empty");
//
//       final service = ChatService(authToken: token);
//       final session = await service.createSession('New Chat');
//
//       if (!mounted) return; // ✅ prevent post-dispose setState
//
//       setState(() {
//         _chatService = service;
//         _currentSession = session;
//         _screens = [
//           ChatScreen(
//             session: _currentSession!,
//             chatService: _chatService!,
//             onFirstMessageComplete: _handleFirstMessageComplete,
//           ),
//         ];
//         _showNewChatButton = false;
//         _isLoading = false;
//         _initialized = true;
//       });
//     } catch (e) {
//       print('❌ Error initializing chat: $e');
//       if (!mounted) return; // ✅ prevent crash on error path too
//
//       setState(() {
//         _isLoading = false;
//         _initialized = false;
//       });
//     }
//   }
//
//
//
//   // Future<void> _initializeChatService() async {
//   //   try {
//   //     // ✅ Get custom backend JWT (await required)
//   //     final token = SessionManager.token; // your backend JWT
//   //
//   //     if (token == null || token.isEmpty) throw Exception("Token is null or empty");
//   //
//   //     _chatService = ChatService(authToken: token);
//   //
//   //     final sessions = await _chatService.fetchSessions();
//   //
//   //     if (sessions.isNotEmpty) {
//   //       _currentSession = sessions.first;
//   //
//   //       // Check if the session already has messages
//   //       try {
//   //         final messages = await _chatService.fetchMessages(_currentSession.id);
//   //         if (messages.isNotEmpty && messages.any((m) => m.answer != null && m.answer!.isNotEmpty)) {
//   //           _showNewChatButton = true;
//   //         }
//   //       } catch (e) {
//   //         print("Error checking session messages: $e");
//   //       }
//   //     } else {
//   //       _currentSession = await _chatService.createSession('New Chat');
//   //     }
//   //
//   //     _screens = [
//   //       ChatScreen(
//   //         session: _currentSession,
//   //         chatService: _chatService,
//   //         onFirstMessageComplete: _handleFirstMessageComplete,
//   //       ),
//   //     ];
//   //
//   //     if (mounted) {
//   //       setState(() {
//   //         _isLoading = false;
//   //         _initialized = true;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     print('❌ Error initializing chat: $e');
//   //     if (mounted) {
//   //       setState(() {
//   //         _isLoading = false;
//   //         _initialized = false;
//   //       });
//   //     }
//   //   }
//   // }
//
//
//
//
//   void _createNewChat(BuildContext context) async {
//     try {
//       // Show loading dialog
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
//
//       // Close dialog IMMEDIATELY after session creation
//       Navigator.of(context).pop();
//
//       // Wait a bit for animation
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       if (!mounted) return;
//
//       setState(() {
//         _currentSession = newSession;
//         _showNewChatButton = false;
//
//         _screens = [
//           ChatScreen(
//             key: ValueKey(newSession.id),
//             session: _currentSession,
//             chatService: _chatService,
//             onNavigateToTab: (int index) {
//               setState(() => _currentIndex = index);
//             },
//             onFirstMessageComplete: _handleFirstMessageComplete,
//           ),
//           GoalsPage(),
//            PortfolioScreen(),
//         ];
//
//         _currentIndex = 0;
//       });
//     } catch (e) {
//       // Ensure loader is closed on ANY failure
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to create chat: $e"),
//             backgroundColor: Colors.red.shade600,
//           ),
//         );
//       }
//       print("❌ Error creating new chat session: $e");
//     }
//   }
//
//   //final theme = locator<ThemeService>().currentTheme;
//
//   @override
//   // Widget build(BuildContext context) {
//   //   // If _chatService or _screens is not ready yet, show loading
//   //   if (_isLoading || !_initialized) {
//   //     return const Scaffold(
//   //       body: Center(child: SizedBox.shrink()),
//   //     );
//   //   }
//   //   print("🏗️ DashboardScreen. build() - _showNewChatButton=$_showNewChatButton");
//   //
//   //   return Container(
//   //     color: Colors.white,
//   //     child: SafeArea(
//   //       top: true,
//   //       bottom: false,
//   //       child: Scaffold(
//   //         //backgroundColor: Colors.white,
//   //         appBar: PreferredSize(
//   //           preferredSize: const Size.fromHeight(100),
//   //           child: Builder(
//   //             builder: (context) {
//   //               print("🏗️ About to build appBar with showNewChatButton=$_showNewChatButton");
//   //               return appBar(
//   //                   context,
//   //                   getAppBarTitle(),
//   //                       () => _createNewChat(context),
//   //                   true,
//   //                   showNewChatButton: _showNewChatButton
//   //               );
//   //             },
//   //           ),
//   //         ),
//   //         drawer: CustomDrawer(
//   //           onCreateNewChat: () => _createNewChat(context),
//   //           chatService: _chatService,
//   //           onSessionTap: (session) async {
//   //             // Check if this session already has messages
//   //             bool hasMessages = false;
//   //             try {
//   //               final messages = await _chatService.fetchMessages(session.id);
//   //               hasMessages = messages.isNotEmpty && messages.any((m) => m.answer != null && m.answer!.isNotEmpty);
//   //             } catch (e) {
//   //               print("Error checking session messages: $e");
//   //             }
//   //
//   //             setState(() {
//   //               _currentSession = session;
//   //               _screens = [
//   //                 ChatScreen(
//   //                   onFirstMessageComplete: _handleFirstMessageComplete,
//   //                   key: ValueKey(session.id),
//   //                   session: _currentSession,
//   //                   chatService: _chatService,
//   //                 ),
//   //                 GoalsPage(),
//   //                 const Assets(),
//   //               ];
//   //               _currentIndex = 0;
//   //
//   //               // Set button visibility based on whether this session already has messages
//   //               _showNewChatButton = hasMessages;
//   //             });
//   //           },
//   //         ),
//   //         body: _screens[_currentIndex],
//   //       ),
//   //     ),
//   //   );
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     print("🏗️ DashboardScreen. build() - _showNewChatButton=$_showNewChatButton");
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//
//     return Container(
//       color: theme.bottombackground,
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 400),
//         switchInCurve: Curves.easeOut,
//         switchOutCurve: Curves.easeIn,
//         child: ChatGPTBottomSheetWrapper(
//           key: _sheetKey,
//           bottomSheet: Container(
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
//             ),
//             height: 840,
//             child: SettingsScreen(
//               onTap: () => _sheetKey.currentState?.closeSheet(),
//             ),
//           ),
//           child: Scaffold(
//             backgroundColor: theme.background,
//             resizeToAvoidBottomInset: false,
//             key: const ValueKey('dashboard'),
//             appBar: PreferredSize(
//               preferredSize: const Size.fromHeight(100),
//               child: Builder(
//                 builder: (context) {
//                   return appBar(
//                     context,
//                     getAppBarTitle(),
//                         () => _createNewChat(context),
//                     true,
//                     showNewChatButton: _showNewChatButton,
//                   );
//                 },
//               ),
//             ),
//             onDrawerChanged: (isOpened) {
//               if (isOpened) {
//                 FocusManager.instance.primaryFocus?.unfocus();
//               }
//             },
//             drawer: CustomDrawer(
//               onTap: () => _sheetKey.currentState?.openSheet(),
//               onCreateNewChat: () => _createNewChat(context),
//               chatService: _chatService,
//               onSessionTap: (session) async {
//                 bool hasMessages = false;
//                 try {
//                   final messages = await _chatService.fetchMessages(session.id);
//                   hasMessages = messages.isNotEmpty &&
//                       messages.any((m) => m.answer != null && m.answer!.isNotEmpty);
//                 } catch (e) {
//                   print("Error checking session messages: $e");
//                 }
//
//                 setState(() {
//                   _currentSession = session;
//                   _screens = [
//                     ChatScreen(
//                       onFirstMessageComplete: _handleFirstMessageComplete,
//                       key: ValueKey(session.id),
//                       session: _currentSession,
//                       chatService: _chatService,
//                     ),
//                     GoalsPage(),
//                     PortfolioScreen(),
//                   ];
//                   _currentIndex = 0;
//                   _showNewChatButton = hasMessages;
//                 });
//               },
//             ),
//             body: _screens[_currentIndex],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//
//
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
// }




// 1. CREATE ANIMATED TOOLTIP WIDGET
// 1. SIMPLE BLACK TOOLTIP WIDGET
// 1. TOOLTIP WITH ARROW POINTER
class ArrowTooltip extends StatefulWidget {
  final String message;

  const ArrowTooltip({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<ArrowTooltip> createState() => _ArrowTooltipState();
}

class _ArrowTooltipState extends State<ArrowTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main tooltip container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D), // Dark gray
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),

                // Arrow pointing down
                CustomPaint(
                  size: const Size(12, 6),
                  painter: ArrowPainter(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 2. ARROW PAINTER
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom center (tip)
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 3. UPDATED APP BAR WITH FIXED POSITIONING
PreferredSize appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard, {
      bool showNewChatButton = false,
    }) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isTablet = screenWidth > 600;
        final double horizontalPadding = isTablet ? 24.0 : 12.0;
        final double iconSize = isTablet ? 26 : 26;
        final double logoHeight = isTablet ? 50 : 30;
        final double buttonSize = isTablet ? 32 : 28;
        final double spacing = isTablet ? 20 : 12;
        final theme = locator<ThemeService>().currentTheme;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: theme.background,
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  isDashboard
                      ?
                HeroLogo(
                width: logoHeight, // Or specific width if needed
                height: logoHeight,
                asset: 'assets/images/new_app_logo.png', // 🔁 same image as splash
              )


              : Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                      fontSize: isTablet ? 22 : 20,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (drawerContext) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              FocusManager.instance.primaryFocus?.unfocus();
                              FocusScope.of(context).unfocus();

                              final scaffold = Scaffold.maybeOf(drawerContext);
                              if (scaffold != null && scaffold.hasDrawer) {
                                scaffold.openDrawer();
                              } else {
                                Scaffold.of(drawerContext).openDrawer();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                "assets/images/new_drawer.png",
                                color: theme.icon,
                                height: 32,
                                width: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Row(
                        children: [
                          // ✅ NOTIFICATION WITH FIXED POSITION TOOLTIP
                          InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.lightImpact();

                              final overlay = Overlay.of(context);
                              final mediaQuery = MediaQuery.of(context);
                              late OverlayEntry entry;

                              entry = OverlayEntry(
                                builder: (context) => Positioned(
                                  // ✅ Fixed position - works even if icon moves
                                  right: 20, // From right edge
                                  top: 90,   // From top (below app bar)
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ArrowTooltip(
                                      message: "Coming Soon",
                                    ),
                                  ),
                                ),
                              );

                              overlay.insert(entry);

                              // Remove after animation completes
                              Future.delayed(const Duration(milliseconds: 2750), () {
                                entry.remove();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.notifications_none_outlined,
                                color: theme.icon,
                                size: iconSize,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing),

                          isDashboard && showNewChatButton ?
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: onNewChatTap,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  "assets/images/newChat.png",
                                  color: theme.icon,
                                  width: 19,
                                  height: 22,
                                ),
                              ),
                            ),
                          ): SizedBox.shrink()
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

// 4. ALTERNATIVE: CENTER POSITIONED TOOLTIP
void showCenterTooltip(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final mediaQuery = MediaQuery.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      // Center of screen
      left: mediaQuery.size.width / 2 - 60, // Half tooltip width
      top: 120, // Below app bar
      child: Material(
        color: Colors.transparent,
        child: ArrowTooltip(
          message: message,
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(milliseconds: 2750), () {
    entry.remove();
  });
}


// PreferredSize appBar(
//     BuildContext context,
//     String title,
//     VoidCallback onNewChatTap,
//     bool isDashboard, {
//       bool showNewChatButton = false,
//     }) {
//   return PreferredSize(
//     preferredSize: const Size.fromHeight(100),
//     child: LayoutBuilder(
//       builder: (context, constraints) {
//         final double screenWidth = constraints.maxWidth;
//         final bool isTablet = screenWidth > 600;
//         final double horizontalPadding = isTablet ? 24.0 : 12.0;
//         final double iconSize = isTablet ? 26 : 26;
//         final double logoHeight = isTablet ? 50 : 30;
//         final double buttonSize = isTablet ? 32 : 28;
//         final double spacing = isTablet ? 20 : 12;
//         final theme = locator<ThemeService>().currentTheme;
//
//         return Container(
//           padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//           decoration: BoxDecoration(
//             color: theme.background,
//           ),
//           child: SafeArea(
//             child: SizedBox(
//               height: 60,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   isDashboard
//                       ? Hero(
//                     tag: 'penny_logo', // ✅ Must match splash screen hero tag
//                     child: Image.asset(
//                       "assets/images/new_app_logo.png", // ✅ Ensure this image exists
//                       height: logoHeight,
//                     ),
//                   )
//                       : Text(
//                     title,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: theme.text,
//                       fontSize: isTablet ? 22 : 20,
//                       fontFamily: 'SF Pro Display',
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Builder(
//                         builder: (drawerContext) => Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(24),
//                             onTap: () {
//                               print("kdd");
//                               HapticFeedback.heavyImpact();
//                               FocusManager.instance.primaryFocus?.unfocus();
//                               FocusScope.of(context).unfocus();
//
//                               final scaffold = Scaffold.maybeOf(drawerContext);
//                               if (scaffold != null && scaffold.hasDrawer) {
//                                 scaffold.openDrawer();
//                               } else {
//                                 Scaffold.of(drawerContext).openDrawer();
//                               }
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.all(10.0),
//                               child: Image.asset("assets/images/new_drawer.png",color: theme.icon,height: 32,width: 32,),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 10),
//                       Row(
//                         children: [
//                           InkWell(
//                             borderRadius: BorderRadius.circular(24),
//                             onTap: () {
//                               HapticFeedback.lightImpact();
//                               final overlay = Overlay.of(context);
//                               final renderBox = context.findRenderObject() as RenderBox;
//                               final size = renderBox.size;
//                               final offset = renderBox.localToGlobal(Offset.zero);
//
//                               final entry = OverlayEntry(
//                                 builder: (context) => Positioned(
//                                   top: offset.dy + size.height + 8,
//                                   left: offset.dx + size.width / 1.5 - 60,
//                                   child: Material(
//                                     color: Colors.transparent,
//                                     child: AnimatedComingSoonTooltip(),
//                                   ),
//                                 ),
//                               );
//
//                               overlay.insert(entry);
//                               Future.delayed(const Duration(seconds: 2), () {
//                                 entry.remove();
//                               });
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.all(4.0),
//                               child: Icon(
//                                 Icons.notifications_none_outlined,
//                                 color: theme.icon,
//                                 size: iconSize,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: spacing),
//
//                           isDashboard && showNewChatButton ?
//                           Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(24),
//                               onTap: onNewChatTap,
//                               child: Padding(
//                                 padding: const EdgeInsets.all(4.0),
//                                 child: Image.asset(
//                                   "assets/images/newChat.png",
//                                   color: theme.icon,
//                                   width: 19,
//                                   height: 22,
//                                 ),
//                               ),
//                             ),
//                           ): SizedBox.shrink()
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }







