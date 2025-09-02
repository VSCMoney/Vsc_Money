import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_bar.dart';
import '../../../constants/bottomsheet.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/theme_service.dart';
import '../../widgets/drawer.dart';
import '../settings/settings_screen.dart';
import 'chat_screen.dart';




class HomeScreen extends StatefulWidget {
  final String? initialSession;
  const HomeScreen({super.key, this.initialSession});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final ChatService _chatService;
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  // NEW: Add divider state management
  bool _showDivider = false;

  @override
  void initState() {
    super.initState();
    print("👀 HomeScreen received initial session: ${widget.initialSession}");
    _chatService = ChatService();
    _initializeService();

    // NEW: Setup divider listener
    _setupDividerListener();
  }

  // NEW: Listen for messages to control divider
  void _setupDividerListener() {
    _chatService.messagesStream.listen((messages) {
      final hasUserMessage = messages.any((m) => m['role'] == 'user');

      if (hasUserMessage != _showDivider) {
        setState(() {
          _showDivider = hasUserMessage;
        });
      }
    });
  }

  Future<void> _initializeService() async {
    await _chatService.initializeForDashboard(initialSessionId: widget.initialSession);
    if (mounted) setState(() {});
  }

  void _handleFirstMessageComplete(String newTitle) {
    print("📲 DashboardScreen received title: $newTitle");
    if (mounted && newTitle.trim().isNotEmpty) {
      _chatService.onFirstMessageComplete(newTitle);
      setState(() {});
    }
  }

  Future<void> _closeSheet() async {
    debugPrint("🏠 HomeScreen._closeSheet() called - START");
    final wrapper = _sheetKey.currentState;
    debugPrint("🏠 wrapper: $wrapper, isSheetOpen: ${wrapper?.isSheetOpen}");

    if (wrapper != null && wrapper.isSheetOpen) {
      debugPrint("🏠 Calling wrapper.closeSheet()");

      if (Platform.isIOS) {
        HapticFeedback.lightImpact();
      }

      await wrapper.closeSheet();
      debugPrint("🏠 wrapper.closeSheet() finished - SUCCESS");
    } else {
      debugPrint("🏠 No sheet to close or wrapper null");
    }
    debugPrint("🏠 HomeScreen._closeSheet() - END");
  }

  Future<void> _createNewChat() async {
    try {
      print("Creating new chat - clearing UI state");

      // Use the public method to reset state
      _chatService.resetForNewChat();

      // NEW: Reset divider when creating new chat
      setState(() {
        _showDivider = false;
        _currentIndex = 0; // Switch to chat tab
      });

      print("New chat state ready - session will be created on first message");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to start a new chat: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _switchToSession(ChatSession session) async {
    try {
      await _chatService.switchToSession(session);
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          // Keep divider state based on whether session has messages
          // The listener will handle this automatically
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to switch session: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  // NEW: Method called when send button is clicked (for immediate divider)
  void _onSendMessageStarted() {
    if (!_showDivider) {
      setState(() {
        _showDivider = true;
      });
    }
  }

  void _openSettingsSheet() {
    final settingsSheet = BottomSheetManager.buildSettingsSheet(
      onTap: () async => await _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(settingsSheet);
  }

  void _openStockDetailSheet(String assetId) {
    print("📈 Opening stock detail for: $assetId - DEBUG");

    final stockSheet = BottomSheetManager.buildStockDetailSheet(
      assetId: assetId,
      onTap: () {
        print("📈 Stock sheet onTap called - about to close");
        _closeSheet();
      },
    );

    print("📈 About to call openSheet");
    _sheetKey.currentState?.openSheet(stockSheet);
    print("📈 openSheet called successfully");
  }

  void _openAskVittySheet(String selectedText) {
    // Close any existing sheet first
    _sheetKey.currentState?.closeSheet();

    // Small delay to ensure clean state
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (mounted) {
        try {
          // ✅ NEW: Create a new session specifically for the ask vitty thread
          print("🤖 Creating new Ask Vitty session for: $selectedText");

          // Create a dedicated ChatService instance for the thread
          final threadChatService = ChatService();
          await threadChatService.createNewChatSession();

          final askVittySheet = BottomSheetManager.buildAskVittySheet(
            chatService: threadChatService, // ✅ Use new service instance
            selectedText: selectedText,
            onTap: () {
              _sheetKey.currentState?.closeSheet();
              // ✅ Clean up the thread service when closing
              threadChatService.dispose();
            },
            onAskVitty: (String question) {
              print("🤖 Ask Vitty follow-up: $question");
              // The VittyThreadSheet will handle creating new sessions for follow-ups
            },
          );
          _sheetKey.currentState?.openSheet(askVittySheet);

        } catch (e) {
          print("❌ Error creating Ask Vitty session: $e");
          // Fallback: show error or use existing service
          final askVittySheet = BottomSheetManager.buildAskVittySheet(
            chatService: _chatService, // Fallback to main service
            selectedText: selectedText,
            onTap: () => _sheetKey.currentState?.closeSheet(),
            onAskVitty: (String question) {
              print("🤖 Ask Vitty (fallback): $question");
            },
          );
          _sheetKey.currentState?.openSheet(askVittySheet);
        }
      }
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Vitty';
      case 1: return 'Goals';
      case 2: return 'Assets';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ DashboardScreen.build() - showNewChatButton=${_chatService.showNewChatButton}");

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final backgroundColor = themeExtension?.theme?.background ??
        Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: Colors.black,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: ChatGPTBottomSheetWrapper(
            key: _sheetKey,
            child: _buildContent(backgroundColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color backgroundColor) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBody: true,
      key: const ValueKey('dashboard'),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(
          builder: (context) {
            return appBar(
              context,
              _getAppBarTitle(),
              _createNewChat,
              true,
              showNewChatButton: _chatService.showNewChatButton,
              showDivider: _showDivider, // NEW: Pass divider state
            );
          },
        ),
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          FocusManager.instance.primaryFocus?.unfocus();
        } else {
          HapticFeedback.heavyImpact();
        }
      },
      drawer: _chatService.isInitialized
          ? CustomDrawer(
        onTap: _openSettingsSheet,
        onCreateNewChat: _createNewChat,
        chatService: _chatService,
        onSessionTap: _switchToSession,
      )
          : null,
      body: _chatService.isInitialized
          ? ChatScreen(
        key: const ValueKey('chat-screen'), // <- stable
        session: _chatService.currentSession, // <- nullable allowed
        chatService: _chatService,
        onFirstMessageComplete: (isComplete) {
          if (isComplete) setState(() {});
        },
        onSendMessageStarted: _onSendMessageStarted, // NEW: Pass callback
        onStockTap: _openStockDetailSheet,
        onAskVitty: _openAskVittySheet,
      )
          : SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}


// class HomeScreen extends StatefulWidget {
//   final String? initialSession;
//   const HomeScreen({super.key, this.initialSession});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0;
//   late final ChatService _chatService;
//   final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
//   GlobalKey(debugLabel: 'BottomSheetWrapper');
//
//   @override
//   void initState() {
//     super.initState();
//     print("👀 HomeScreen received initial session: ${widget.initialSession}");
//     _chatService = ChatService();
//     _initializeService();
//   }
//
//   Future<void> _initializeService() async {
//     await _chatService.initializeForDashboard(initialSessionId: widget.initialSession);
//     if (mounted) setState(() {});
//   }
//
//   void _handleFirstMessageComplete(String newTitle) {
//     print("📲 DashboardScreen received title: $newTitle");
//     if (mounted && newTitle.trim().isNotEmpty) {
//       _chatService.onFirstMessageComplete(newTitle);
//       setState(() {});
//     }
//   }
//
//   Future<void> _closeSheet() async {
//     debugPrint("🏠 HomeScreen._closeSheet() called - START");
//     final wrapper = _sheetKey.currentState;
//     debugPrint("🏠 wrapper: $wrapper, isSheetOpen: ${wrapper?.isSheetOpen}");
//
//     if (wrapper != null && wrapper.isSheetOpen) {
//       debugPrint("🏠 Calling wrapper.closeSheet()");
//
//       if (Platform.isIOS) {
//         HapticFeedback.lightImpact();
//       }
//
//       await wrapper.closeSheet();
//       debugPrint("🏠 wrapper.closeSheet() finished - SUCCESS");
//     } else {
//       debugPrint("🏠 No sheet to close or wrapper null");
//     }
//     debugPrint("🏠 HomeScreen._closeSheet() - END");
//   }
//
//
//
//   Future<void> _createNewChat() async {
//     try {
//       print("Creating new chat - clearing UI state");
//
//       // Use the public method to reset state
//       _chatService.resetForNewChat();
//
//       if (!mounted) return;
//       setState(() {
//         _currentIndex = 0; // Switch to chat tab
//       });
//
//       print("New chat state ready - session will be created on first message");
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Failed to start a new chat: $e"),
//           backgroundColor: Colors.red.shade600,
//         ),
//       );
//     }
//   }
//
//
//   Future<void> _switchToSession(ChatSession session) async {
//     try {
//       await _chatService.switchToSession(session);
//       if (mounted) {
//         setState(() {
//           _currentIndex = 0;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to switch session: $e"),
//             backgroundColor: Colors.red.shade600,
//           ),
//         );
//       }
//     }
//   }
//
//   void _openSettingsSheet() {
//     final settingsSheet = BottomSheetManager.buildSettingsSheet(
//       onTap: () async => await _sheetKey.currentState?.closeSheet(),
//     );
//     _sheetKey.currentState?.openSheet(settingsSheet);
//   }
//
//
//   // void _openStockDetailSheet(String assetId) {
//   //   print(assetId);
//   //   final stockSheet = BottomSheetManager.buildStockDetailSheet(
//   //     assetId: assetId,
//   //     onTap: _closeSheet
//   //   );
//   //   _sheetKey.currentState?.openSheet(stockSheet);
//   // }
//
//   void _openStockDetailSheet(String assetId) {
//     print("📈 Opening stock detail for: $assetId - DEBUG");
//
//     final stockSheet = BottomSheetManager.buildStockDetailSheet(
//       assetId: assetId,
//       onTap: () {
//         print("📈 Stock sheet onTap called - about to close");
//         _closeSheet();
//       },
//     );
//
//     print("📈 About to call openSheet");
//     _sheetKey.currentState?.openSheet(stockSheet);
//     print("📈 openSheet called successfully");
//   }
//
//
//
//   void _openAskVittySheet(String selectedText) {
//     // Close any existing sheet first
//     _sheetKey.currentState?.closeSheet();
//
//     // Small delay to ensure clean state
//     Future.delayed(const Duration(milliseconds: 100), () async {
//       if (mounted) {
//         try {
//           // ✅ NEW: Create a new session specifically for the ask vitty thread
//           print("🤖 Creating new Ask Vitty session for: $selectedText");
//
//           // Create a dedicated ChatService instance for the thread
//           final threadChatService = ChatService();
//           await threadChatService.createNewChatSession();
//
//           final askVittySheet = BottomSheetManager.buildAskVittySheet(
//             chatService: threadChatService, // ✅ Use new service instance
//             selectedText: selectedText,
//             onTap: () {
//               _sheetKey.currentState?.closeSheet();
//               // ✅ Clean up the thread service when closing
//               threadChatService.dispose();
//             },
//             onAskVitty: (String question) {
//               print("🤖 Ask Vitty follow-up: $question");
//               // The VittyThreadSheet will handle creating new sessions for follow-ups
//             },
//           );
//           _sheetKey.currentState?.openSheet(askVittySheet);
//
//         } catch (e) {
//           print("❌ Error creating Ask Vitty session: $e");
//           // Fallback: show error or use existing service
//           final askVittySheet = BottomSheetManager.buildAskVittySheet(
//             chatService: _chatService, // Fallback to main service
//             selectedText: selectedText,
//             onTap: () => _sheetKey.currentState?.closeSheet(),
//             onAskVitty: (String question) {
//               print("🤖 Ask Vitty (fallback): $question");
//             },
//           );
//           _sheetKey.currentState?.openSheet(askVittySheet);
//         }
//       }
//     });
//   }
//
//   String _getAppBarTitle() {
//     switch (_currentIndex) {
//       case 0: return 'Vitty';
//       case 1: return 'Goals';
//       case 2: return 'Assets';
//       default: return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("🏗️ DashboardScreen.build() - showNewChatButton=${_chatService.showNewChatButton}");
//
//     final themeExtension = Theme.of(context).extension<AppThemeExtension>();
//     final backgroundColor = themeExtension?.theme?.background ??
//         Theme.of(context).scaffoldBackgroundColor;
//
//     return SafeArea(
//       top: false,
//       bottom: false,
//       child: Container(
//         color: Colors.black,
//         child: AnimatedSwitcher(
//           duration: const Duration(milliseconds: 400),
//           switchInCurve: Curves.easeOut,
//           switchOutCurve: Curves.easeIn,
//           child: ChatGPTBottomSheetWrapper(
//             key: _sheetKey,
//             child: _buildContent(backgroundColor),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContent(Color backgroundColor) {
//     return Scaffold(
//         backgroundColor: backgroundColor,
//         resizeToAvoidBottomInset: true,
//         extendBody: true,
//         key: const ValueKey('dashboard'),
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(100),
//           child: Builder(
//             builder: (context) {
//               return appBar(
//                 context,
//                 _getAppBarTitle(),
//                 _createNewChat,
//                 true,
//                 showNewChatButton: _chatService.showNewChatButton,
//               );
//             },
//           ),
//         ),
//         onDrawerChanged: (isOpened) {
//           if (isOpened) {
//             FocusManager.instance.primaryFocus?.unfocus();
//           }else{
//             HapticFeedback.heavyImpact();
//           }
//         },
//         drawer: _chatService.isInitialized
//             ? CustomDrawer(
//           onTap: _openSettingsSheet,
//           onCreateNewChat: _createNewChat,
//           chatService: _chatService,
//           onSessionTap: _switchToSession,
//         )
//             : null,
//         // body: _chatService.currentSession != null
//         //     ? ChatScreen(
//         //   key: ValueKey(_chatService.currentSession!.id),
//         //   session: _chatService.currentSession!,
//         //   chatService: _chatService,
//         //   onFirstMessageComplete: (bool isComplete) {  // ✅ UNCOMMENT AND FIX THIS
//         //     if (isComplete) {
//         //       print("📲 First message completed, showing new chat button");
//         //       setState(() {}); // ✅ Trigger rebuild to show new chat button
//         //     }
//         //   },
//         //   onStockTap: _openStockDetailSheet,
//         //   onAskVitty: _openAskVittySheet,
//         // )
//         //     : Container(
//         //   color: backgroundColor,
//         //   child: const Center(
//         //     child: CircularProgressIndicator(
//         //       color: Color(0xFFF66A00),
//         //     ),
//         //   ),
//         // ),
//         body: _chatService.isInitialized
//             ? ChatScreen(
//           key: const ValueKey('chat-screen'),     // <- stable
//           session: _chatService.currentSession,   // <- nullable allowed
//           chatService: _chatService,
//           onFirstMessageComplete: (isComplete) { if (isComplete) setState(() {}); },
//           onStockTap: _openStockDetailSheet,
//           onAskVitty: _openAskVittySheet,
//         )
//             :
//         // Container(
//         //   color: backgroundColor,
//         //   child: const Center(
//         //     child: CircularProgressIndicator(color: Color(0xFFF66A00)),
//         //   ),
//         // ),
//         SizedBox.shrink()
//
//     );
//   }
//
//   @override
//   void dispose() {
//     _chatService.dispose();
//     super.dispose();
//   }
// }













