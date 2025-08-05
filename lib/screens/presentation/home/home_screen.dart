import 'dart:async';
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
  final ChatSession? initialSession;
  const HomeScreen({super.key, this.initialSession});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final ChatService _chatService;
  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey(debugLabel: 'BottomSheetWrapper');

  @override
  void initState() {
    super.initState();
    print("👀 HomeScreen received initial session: ${widget.initialSession?.id}");
    _chatService = ChatService();
    _initializeService();

  }

  Future<void> _initializeService() async {
    await _chatService.initializeForDashboard(initialSession: widget.initialSession);
    if (mounted) setState(() {});
  }


  void _handleFirstMessageComplete(String newTitle) {
    print("📲 DashboardScreen received title: $newTitle");
    if (mounted && newTitle.trim().isNotEmpty) {
      _chatService.onFirstMessageComplete(newTitle);
      setState(() {});
    }
  }


  Future<void> _createNewChat() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: SizedBox.shrink()),
      );

      await _chatService.createNewChatSession();

      if (!mounted) return;
      Navigator.of(context).pop();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _currentIndex = 0;
        });
      }
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
    }
  }

  Future<void> _switchToSession(ChatSession session) async {
    try {
      await _chatService.switchToSession(session);
      if (mounted) {
        setState(() {
          _currentIndex = 0;
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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Vitty';
      case 1:
        return 'Goals';
      case 2:
        return 'Assets';
      default:
        return '';
    }
  }

  // Method to open settings sheet
  void _openSettingsSheet() {
    final settingsSheet = BottomSheetManager.buildSettingsSheet(
      onTap: () => _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(settingsSheet);
  }

  // Method to open stock detail sheet
  void _openStockDetailSheet(String stockSymbol, String stockName) {
    final stockSheet = BottomSheetManager.buildStockDetailSheet(
      stockSymbol: stockSymbol,
      stockName: stockName,
      onTap: () => _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(stockSheet);
  }

  // Method to open ask vitty sheet
  void _openAskVittySheet(String selectedText) {
    final askVittySheet = BottomSheetManager.buildAskVittySheet(
      chatService: _chatService,
      selectedText: selectedText,
      onTap: () => _sheetKey.currentState?.closeSheet(),
      onAskVitty: (String question) {
        // Handle the ask vitty action
        print("Ask Vitty: $question");
        // You can implement your ask vitty logic here
      },
    );
    _sheetKey.currentState?.openSheet(askVittySheet);
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ DashboardScreen.build() - showNewChatButton=${_chatService.showNewChatButton}");

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final backgroundColor = themeExtension?.theme?.background ??
        Theme.of(context).scaffoldBackgroundColor;

    return Container(
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
    );
  }

  Widget _buildContent(Color backgroundColor) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
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
            );
          },
        ),
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      drawer: _chatService.isInitialized
          ? CustomDrawer(
        onTap: _openSettingsSheet, // Use the new method
        onCreateNewChat: _createNewChat,
        chatService: _chatService,
        onSessionTap: _switchToSession,
      )
          : null,
      body: _chatService.currentSession != null
          ? ChatScreen(
        key: ValueKey(_chatService.currentSession!.id),
        session: _chatService.currentSession!,
        chatService: _chatService,
        onFirstMessageComplete: _handleFirstMessageComplete,
        onStockTap: _openStockDetailSheet, // Pass the method
        onAskVitty: _openAskVittySheet, // Pass the method
      )
          : Container(
        color: backgroundColor,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF66A00),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}

// class HomeScreen extends StatefulWidget {
//   final ChatSession? initialSession;
//   const HomeScreen({super.key, this.initialSession});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0;
//   late final ChatService _chatService;
//   final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey = GlobalKey<ChatGPTBottomSheetWrapperState>();
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService();
//     _initializeService();
//   }
//
//   Future<void> _initializeService() async {
//     await _chatService.initializeForDashboard();
//     if (mounted) setState(() {}); // Trigger rebuild after initialization
//   }
//
//   void _handleFirstMessageComplete(bool isComplete) {
//     print("📲 DashboardScreen received callback with value: $isComplete");
//     if (mounted && isComplete) {
//       // Notify the ChatService about first message completion
//       _chatService.onFirstMessageComplete();
//       setState(() {}); // Trigger rebuild to update UI
//     }
//   }
//
//   Future<void> _createNewChat() async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: SizedBox.shrink()),
//       );
//
//       await _chatService.createNewChatSession();
//
//       if (!mounted) return;
//       Navigator.of(context).pop();
//
//       // Small delay for smooth transition
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       if (mounted) {
//         setState(() {
//           _currentIndex = 0;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to create chat: $e"),
//             backgroundColor: Colors.red.shade600,
//           ),
//         );
//       }
//     }
//   }
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
//   String _getAppBarTitle() {
//     switch (_currentIndex) {
//       case 0:
//         return 'Vitty';
//       case 1:
//         return 'Goals';
//       case 2:
//         return 'Assets';
//       default:
//         return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("🏗️ DashboardScreen.build() - showNewChatButton=${_chatService.showNewChatButton}");
//
//     final themeExtension = Theme.of(context).extension();
//     final backgroundColor = themeExtension?.theme?.background ??
//         Theme.of(context).scaffoldBackgroundColor;
//
//     return Container(
//       color: backgroundColor,
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
//           child: _buildContent(backgroundColor),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContent(Color backgroundColor) {
//     // Show loading screen during initialization
//     if (!_chatService.isInitialized && _chatService.isLoadingSession) {
//       return Container(
//         child: SizedBox.shrink(),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       resizeToAvoidBottomInset: false,
//       key: const ValueKey('dashboard'),
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Builder(
//           builder: (context) {
//             return appBar(
//               context,
//               _getAppBarTitle(),
//               _createNewChat,
//               true,
//               showNewChatButton: _chatService.showNewChatButton,
//             );
//           },
//         ),
//       ),
//       onDrawerChanged: (isOpened) {
//         if (isOpened) {
//           FocusManager.instance.primaryFocus?.unfocus();
//         }
//       },
//       drawer: _chatService.isInitialized
//           ? CustomDrawer(
//         onTap: () => _sheetKey.currentState?.openSheet(),
//         onCreateNewChat: _createNewChat,
//         chatService: _chatService,
//         onSessionTap: _switchToSession,
//       )
//           : null,
//       body: _chatService.currentSession != null
//           ? ChatScreen(
//         key: ValueKey(_chatService.currentSession!.id),
//         sheetKey: _sheetKey,
//         session: _chatService.currentSession!,
//         chatService: _chatService,
//         onFirstMessageComplete: _handleFirstMessageComplete,
//       )
//           : Container(
//         color: backgroundColor,
//         child: const Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFFF66A00),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _chatService.dispose();
//     super.dispose();
//   }
// }











