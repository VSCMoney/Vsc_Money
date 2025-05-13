import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import 'package:vscmoney/screens/presentation/search_stock_screen.dart';
import 'package:vscmoney/services/locator.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/session_manager.dart';
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
  late ChatService _chatService;
  late ChatSession _currentSession;
  bool _isLoading = true;
  bool _showNewChatButton = false;

  // List of screens - we'll build this dynamically after initialization
  late List<Widget> _screens;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: theme.background, // 👈 for iOS
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.light
    ));
    _initializeChatService();
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
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Create new session
      final newSession = await _chatService.createSession('New Chat');

      if (!mounted) return;

      // Close dialog IMMEDIATELY after session creation
      Navigator.of(context).pop();

      // Wait a bit for animation
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _currentSession = newSession;
        _showNewChatButton = false;

        _screens = [
          ChatScreen(
            key: ValueKey(newSession.id),
            session: _currentSession,
            chatService: _chatService,
            onNavigateToTab: (int index) {
              setState(() => _currentIndex = index);
            },
            onFirstMessageComplete: _handleFirstMessageComplete,
          ),
          GoalsPage(),
          const Assets(),
        ];

        _currentIndex = 0;
      });
    } catch (e) {
      // Ensure loader is closed on ANY failure
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

  final theme = locator<ThemeService>().currentTheme;

  @override
  // Widget build(BuildContext context) {
  //   // If _chatService or _screens is not ready yet, show loading
  //   if (_isLoading || !_initialized) {
  //     return const Scaffold(
  //       body: Center(child: SizedBox.shrink()),
  //     );
  //   }
  //   print("🏗️ DashboardScreen. build() - _showNewChatButton=$_showNewChatButton");
  //
  //   return Container(
  //     color: Colors.white,
  //     child: SafeArea(
  //       top: true,
  //       bottom: false,
  //       child: Scaffold(
  //         //backgroundColor: Colors.white,
  //         appBar: PreferredSize(
  //           preferredSize: const Size.fromHeight(100),
  //           child: Builder(
  //             builder: (context) {
  //               print("🏗️ About to build appBar with showNewChatButton=$_showNewChatButton");
  //               return appBar(
  //                   context,
  //                   getAppBarTitle(),
  //                       () => _createNewChat(context),
  //                   true,
  //                   showNewChatButton: _showNewChatButton
  //               );
  //             },
  //           ),
  //         ),
  //         drawer: CustomDrawer(
  //           onCreateNewChat: () => _createNewChat(context),
  //           chatService: _chatService,
  //           onSessionTap: (session) async {
  //             // Check if this session already has messages
  //             bool hasMessages = false;
  //             try {
  //               final messages = await _chatService.fetchMessages(session.id);
  //               hasMessages = messages.isNotEmpty && messages.any((m) => m.answer != null && m.answer!.isNotEmpty);
  //             } catch (e) {
  //               print("Error checking session messages: $e");
  //             }
  //
  //             setState(() {
  //               _currentSession = session;
  //               _screens = [
  //                 ChatScreen(
  //                   onFirstMessageComplete: _handleFirstMessageComplete,
  //                   key: ValueKey(session.id),
  //                   session: _currentSession,
  //                   chatService: _chatService,
  //                 ),
  //                 GoalsPage(),
  //                 const Assets(),
  //               ];
  //               _currentIndex = 0;
  //
  //               // Set button visibility based on whether this session already has messages
  //               _showNewChatButton = hasMessages;
  //             });
  //           },
  //         ),
  //         body: _screens[_currentIndex],
  //       ),
  //     ),
  //   );
  // }

  @override
  @override
  Widget build(BuildContext context) {
    print("🏗️ DashboardScreen. build() - _showNewChatButton=$_showNewChatButton");

    return Container(
      color: theme.background,
      child: SafeArea(
        top: true,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: (_isLoading || !_initialized)
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Scaffold(
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
            drawer: CustomDrawer(
              onCreateNewChat: () => _createNewChat(context),
              chatService: _chatService,
              onSessionTap: (session) async {
                bool hasMessages = false;
                try {
                  final messages = await _chatService.fetchMessages(session.id);
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
                      session: _currentSession,
                      chatService: _chatService,
                    ),
                    GoalsPage(),
                    const Assets(),
                  ];
                  _currentIndex = 0;
                  _showNewChatButton = hasMessages;
                });
              },
            ),
            body: _screens[_currentIndex],
          ),
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
          decoration:  BoxDecoration(
            color: theme.background,
            // border: Border(
            //   bottom: BorderSide(
            //     color: Color(0xFFE0E0E0),
            //     width: 0.5,
            //   ),
            // ),
          ),
          child: SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                isDashboard
                    ? Hero(
                  tag: 'penny_logo',
                  child: Image.asset(
                    "assets/images/new_app_logo.png",
                    height: logoHeight,
                  ),
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
                    // Drawer icon
                    Builder(
                      builder: (drawerContext) => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            FocusManager.instance.primaryFocus?.unfocus();
                            FocusScope.of(context).unfocus();

                            // 🛠 Open drawer safely
                            final scaffold = Scaffold.maybeOf(drawerContext);
                            if (scaffold != null && scaffold.hasDrawer) {
                              scaffold.openDrawer();
                            } else {
                              Scaffold.of(drawerContext).openDrawer();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child:Image.asset('assets/images/drawer.png',color: theme.icon,height: 50,)
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        // Notification icon with tooltip
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final overlay = Overlay.of(context);
                            final renderBox = context.findRenderObject() as RenderBox;
                            final size = renderBox.size;
                            final offset = renderBox.localToGlobal(Offset.zero);

                            final entry = OverlayEntry(
                              builder: (context) => Positioned(
                                top: offset.dy + size.height + 8,
                                left: offset.dx + size.width / 1.5 - 60,
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
        );
      },
    ),
  );
}








