import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/watchlist/watchlist_detail.dart';
import '../screens/AskVitty.dart';
import '../screens/presentation/settings/settings_screen.dart';
import '../screens/asset_page/assets_page.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../testpage.dart';



class ChatGPTBottomSheetWrapper extends StatefulWidget {
  final Widget child;

  const ChatGPTBottomSheetWrapper({
    super.key,
    required this.child,
  });

  @override
  ChatGPTBottomSheetWrapperState createState() => ChatGPTBottomSheetWrapperState();
}

class ChatGPTBottomSheetWrapperState extends State<ChatGPTBottomSheetWrapper>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _sheetHeightFactor;

  // Sheet state
  bool _isSheetOpen = false;
  Widget? _currentBottomSheet;
  double _currentSheetHeight = 0.83;
  bool _isOperationInProgress = false; // ✅ Add operation lock

  // Inner navigation for the sheet
  final GlobalKey<NavigatorState> _sheetNavKey = GlobalKey<NavigatorState>();
  Key _sheetRootKey = UniqueKey();

  bool get isSheetOpen => _isSheetOpen;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sheetHeightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  /// ✅ Open bottom sheet with proper locking to prevent conflicts
  Future<void> openSheet(Widget bottomSheetContent, {double heightFactor = 0.93}) async {
    if (_isOperationInProgress) {
      print("⚠️ Sheet operation in progress, ignoring open request");
      return;
    }

    _isOperationInProgress = true;

    try {
      if (_isSheetOpen) {
        // Replace content if already open
        if (mounted) {
          setState(() {
            _currentBottomSheet = bottomSheetContent;
            _currentSheetHeight = heightFactor;
            _sheetRootKey = UniqueKey(); // Reset nav stack
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSheetOpen = true;
          _currentBottomSheet = bottomSheetContent;
          _currentSheetHeight = heightFactor;
          _sheetRootKey = UniqueKey(); // Fresh stack
        });
      }

      if (!_controller.isAnimating && mounted) {
        await _controller.forward();
      }
    } catch (e) {
      print("❌ Error opening sheet: $e");
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// ✅ Close sheet with proper cleanup and locking
  Future<void> closeSheet() async {
    if (!_isSheetOpen || _isOperationInProgress) {
      return;
    }

    _isOperationInProgress = true;

    try {
      // Clean up navigator first
      final nav = _sheetNavKey.currentState;
      if (nav != null && mounted) {
        try {
          // Safely clear navigation stack
          while (nav.canPop()) {
            nav.pop();
          }
        } catch (e) {
          print("⚠️ Error clearing nav stack: $e");
        }
      }

      // Animate close
      if (_controller.isAnimating) {
        _controller.stop();
      }

      if (mounted) {
        await _controller.reverse();
      }

      // Update state
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _currentBottomSheet = null;
        });
      }
    } catch (e) {
      print("❌ Error closing sheet: $e");
      // Force state reset on error
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _currentBottomSheet = null;
        });
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Push a page inside the bottom sheet's navigator
  void pushInSheet(Widget page) {
    if (!_isSheetOpen || _isOperationInProgress) return;

    try {
      _sheetNavKey.currentState?.push(
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      print("❌ Error pushing in sheet: $e");
    }
  }

  /// Pop a page inside the bottom sheet's navigator
  Future<void> popInSheet() async {
    if (_isOperationInProgress) return;

    try {
      final nav = _sheetNavKey.currentState;
      if (nav?.canPop() == true) {
        nav!.pop();
      } else {
        await closeSheet();
      }
    } catch (e) {
      print("❌ Error popping in sheet: $e");
      await closeSheet(); // Fallback to close
    }
  }

  /// Replace root content inside the sheet
  Future<void> replaceRootInSheet(Widget page, {double? heightFactor}) async {
    if (_isOperationInProgress) return;

    if (!_isSheetOpen) {
      await openSheet(page, heightFactor: heightFactor ?? _currentSheetHeight);
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _currentBottomSheet = page;
          if (heightFactor != null) _currentSheetHeight = heightFactor;
          _sheetRootKey = UniqueKey(); // Force new root
        });
      }
    } catch (e) {
      print("❌ Error replacing root in sheet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;

    return Stack(
      children: [
        // Main content scaled when sheet is open
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final topPadding = Tween<double>(begin: 0.0, end: 52.0).transform(_controller.value);
            final horizontalPadding = Tween<double>(begin: 0.0, end: 10.0).transform(_controller.value);

            return Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isSheetOpen ? 20 : 0),
                  child: AbsorbPointer(
                    absorbing: _isSheetOpen,
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),

        // Dim overlay
        if (_isSheetOpen)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => GestureDetector(
              onTap: () {
                if (!_isOperationInProgress) {
                  closeSheet();
                }
              },
              child: Container(
                color: Colors.black.withOpacity(0.3 * _controller.value),
              ),
            ),
          ),

        // ✅ Fixed Bottom Sheet body with safer Navigator handling
        if (_isSheetOpen && _currentBottomSheet != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final maxSheetHeight = screenHeight * _currentSheetHeight;
                final animatedHeight = maxSheetHeight * _sheetHeightFactor.value;
                final finalHeight = animatedHeight.clamp(0.0, screenHeight);

                if (finalHeight < 50) return const SizedBox.shrink();

                return Container(
                  height: finalHeight,
                  decoration: BoxDecoration(
                    color: theme?.background ?? Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: _buildSheetContent(),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// ✅ Separate method to build sheet content with better error handling
  Widget _buildSheetContent() {
    if (_currentBottomSheet == null || !mounted) {
      return const SizedBox.shrink();
    }

    return PopScope( // ✅ Use PopScope instead of WillPopScope (if Flutter 3.12+)
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_isOperationInProgress) return;

        // Android back: try to pop inner route first; else close sheet
        try {
          final nav = _sheetNavKey.currentState;
          if (nav?.canPop() == true) {
            nav!.pop();
          } else {
            await closeSheet();
          }
        } catch (e) {
          print("❌ Error handling back navigation: $e");
          await closeSheet(); // Fallback
        }
      },
      child: Navigator(
        key: _sheetNavKey,
        onGenerateRoute: (settings) {
          try {
            return MaterialPageRoute(
              builder: (_) => KeyedSubtree(
                key: _sheetRootKey,
                child: _currentBottomSheet!,
              ),
              settings: settings,
            );
          } catch (e) {
            print("❌ Error generating route in sheet: $e");
            return MaterialPageRoute(
              builder: (_) => Container(
                color: Colors.white,
                child: Center(
                  child: Text("Error loading content"),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _isOperationInProgress = true; // Prevent any new operations during disposal

    try {
      _controller.dispose();
    } catch (e) {
      print("❌ Error disposing controller: $e");
    }

    super.dispose();
  }
}



// class ChatGPTBottomSheetWrapper extends StatefulWidget {
//   final Widget child;
//
//   const ChatGPTBottomSheetWrapper({
//     super.key,
//     required this.child,
//   });
//
//   @override
//   ChatGPTBottomSheetWrapperState createState() => ChatGPTBottomSheetWrapperState();
// }
//
// class ChatGPTBottomSheetWrapperState extends State<ChatGPTBottomSheetWrapper>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _sheetHeightFactor;
//
//   bool _isSheetOpen = false;
//   Widget? _currentBottomSheet;
//   double _currentSheetHeight = 0.93; // Default height factor
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//
//     _sheetHeightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );
//   }
//
//   Future<void> openSheet(Widget bottomSheetContent, {double heightFactor = 0.93}) async {
//     if (_isSheetOpen) {
//       setState(() {
//         _currentBottomSheet = bottomSheetContent;
//         _currentSheetHeight = heightFactor;
//       });
//       return;
//     }
//     setState(() {
//       _isSheetOpen = true;
//       _currentBottomSheet = bottomSheetContent;
//       _currentSheetHeight = heightFactor;
//     });
//     if (!_controller.isAnimating) {
//       await _controller.forward();
//     }
//   }
//
//   Future<void> closeSheet() async {
//     if (!_isSheetOpen) return;
//     if (_controller.isAnimating) {
//       await _controller.fling();
//     }
//
//     try {
//       await _controller.reverse();
//     } catch (e) {
//       print("❌ Error during sheet animation: $e");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSheetOpen = false;
//           _currentBottomSheet = null;
//         });
//       }
//     }
//   }
//
//   bool get isSheetOpen => _isSheetOpen;
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final screenHeight = mediaQuery.size.height;
//     final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;
//
//     // ⛔️ AnnotatedRegion was here before — removed to stop overriding system UI
//     return Stack(
//       children: [
//         // Main content with scale and slide animation
//         AnimatedBuilder(
//           animation: _controller,
//           builder: (context, child) {
//             final topPadding = Tween<double>(begin: 0.0, end: 55.0).transform(_controller.value);
//             final horizontalPadding = Tween<double>(begin: 0.0, end: 10.0).transform(_controller.value);
//
//             return Padding(
//               padding: EdgeInsets.only(
//                 top: topPadding,
//                 left: horizontalPadding,
//                 right: horizontalPadding,
//               ),
//               child: Transform.scale(
//                 scale: _scaleAnimation.value,
//                 alignment: Alignment.topCenter,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(_isSheetOpen ? 20 : 0),
//                   child: AbsorbPointer(
//                     absorbing: _isSheetOpen,
//                     child: widget.child,
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//
//         // Overlay for dimming
//         if (_isSheetOpen)
//           AnimatedBuilder(
//             animation: _controller,
//             builder: (context, child) => MaterialButton(
//               onPressed: closeSheet,
//               child: Container(
//                 color: Colors.black.withOpacity(0.3 * _controller.value),
//               ),
//             ),
//           ),
//
//         // Bottom sheet with improved constraint handling
//         if (_isSheetOpen && _currentBottomSheet != null)
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) {
//                 final maxSheetHeight = screenHeight * _currentSheetHeight;
//                 final animatedHeight = maxSheetHeight * _sheetHeightFactor.value;
//                 final finalHeight = animatedHeight.clamp(0.0, screenHeight);
//
//                 if (finalHeight < 50) {
//                   return const SizedBox.shrink();
//                 }
//
//                 return Container(
//                   height: finalHeight,
//                   decoration: BoxDecoration(
//                     color: theme?.background ?? Colors.white,
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Handle bar (optional)
//                       // const SizedBox(height: 6),
//
//                       // Content area with safe constraints
//                       Expanded(
//                         child: LayoutBuilder(
//                           builder: (context, constraints) {
//                             if (constraints.maxHeight <= 0) {
//                               return const SizedBox.shrink();
//                             }
//
//                             return ClipRRect(
//                               borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//                               child: SingleChildScrollView(
//                                 physics: const BouncingScrollPhysics(),
//                                 child: ConstrainedBox(
//                                   constraints: BoxConstraints(
//                                     minHeight: constraints.maxHeight,
//                                   ),
//                                   child: IntrinsicHeight(
//                                     child: _currentBottomSheet!,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }ne










class BottomSheetManager {
  static Widget buildSettingsSheet({required VoidCallback onTap}) {
    return SettingsScreen(onTap: onTap);
  }

  static Widget buildStockDetailSheet({
   required assetId,
    required VoidCallback onTap,
  }) {
    return AssetPage(
     assetId: assetId,
      onClose: onTap,
    );
  }

  static Widget buildWachlistDetailSheet({
    required watchlistid,
    required VoidCallback onTap,
  }) {
    return WatchlistDetailPage(
      watchlistId: watchlistid,
onTap: onTap,
    );
  }

  static Widget buildAskVittySheet({
    required String selectedText,
    required VoidCallback onTap,
    required Function(String) onAskVitty,
    required ChatService chatService,
  }) {
    // ✅ FIXED: Use consistent key based on content only
    return VittyThreadSheet(
      key: ValueKey('vitty_thread_${selectedText.trim().hashCode}'),
      chatService: chatService,
      initialText: selectedText,
      onClose: onTap,
    );
  }

  // ✅ NEW: Better sheet wrapper with proper constraints
  static Widget buildCustomSheet({
    required Widget content,
    required BuildContext context, // ✅ FIXED: Add context parameter
    double? height,
    VoidCallback? onTap,
  }) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.85, // ✅ FIXED: Use passed context
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onTap != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance space
                  const Text(
                    'Sheet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
          Expanded(child: content),
        ],
      ),
    );
  }

}


