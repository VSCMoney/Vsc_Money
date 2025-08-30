import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sheetHeightFactor;

  bool _isSheetOpen = false;
  Widget? _currentBottomSheet;
  double _currentSheetHeight = 0.93; // Default height factor

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

  Future<void> openSheet(Widget bottomSheetContent, {double heightFactor = 0.93}) async {
    if (_isSheetOpen) {
      setState(() {
        _currentBottomSheet = bottomSheetContent;
        _currentSheetHeight = heightFactor;
      });
      return;
    }
    setState(() {
      _isSheetOpen = true;
      _currentBottomSheet = bottomSheetContent;
      _currentSheetHeight = heightFactor;
    });
    if (!_controller.isAnimating) {
      await _controller.forward();
    }
  }

  Future<void> closeSheet() async {
    if (!_isSheetOpen) return;
    if (_controller.isAnimating) {
      await _controller.fling();
    }

    try {
      await _controller.reverse();
    } catch (e) {
      print("❌ Error during sheet animation: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _currentBottomSheet = null;
        });
      }
    }
  }

  bool get isSheetOpen => _isSheetOpen;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;

    // ⛔️ AnnotatedRegion was here before — removed to stop overriding system UI
    return Stack(
      children: [
        // Main content with scale and slide animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final topPadding = Tween<double>(begin: 0.0, end: 55.0).transform(_controller.value);
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

        // Overlay for dimming
        if (_isSheetOpen)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => GestureDetector(
              onTap: closeSheet,
              child: Container(
                color: Colors.black.withOpacity(0.3 * _controller.value),
              ),
            ),
          ),

        // Bottom sheet with improved constraint handling
        if (_isSheetOpen && _currentBottomSheet != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final maxSheetHeight = screenHeight * _currentSheetHeight;
                final animatedHeight = maxSheetHeight * _sheetHeightFactor.value;
                final finalHeight = animatedHeight.clamp(0.0, screenHeight);

                if (finalHeight < 50) {
                  return const SizedBox.shrink();
                }

                return Container(
                  height: finalHeight,
                  decoration: BoxDecoration(
                    color: theme?.background ?? Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar (optional)
                      // const SizedBox(height: 6),

                      // Content area with safe constraints
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxHeight <= 0) {
                              return const SizedBox.shrink();
                            }

                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: IntrinsicHeight(
                                    child: _currentBottomSheet!,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}



//
// // More robust ChatGPTBottomSheetWrapper with better constraint handling
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
//   // Method to open sheet with specific content and height
//   Future<void> openSheet(Widget bottomSheetContent, {double heightFactor = 0.93}) async {
//     if (_isSheetOpen) {
//       // If already open, just swap content/height without restarting anim
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
//   // Future<void> closeSheet() async {  // <-- was void
//   //   if (!_isSheetOpen) return;
//   //   if (_controller.isAnimating) return;
//   //   try {
//   //     await _controller.reverse();
//   //   } finally {
//   //     if (mounted) {
//   //       setState(() {
//   //         _isSheetOpen = false;
//   //         _currentBottomSheet = null;
//   //       });
//   //     }
//   //   }
//   // }
//
//   Future<void> closeSheet() async {
//     if (!_isSheetOpen) return;
//     if (_controller.isAnimating) {
//       // Wait for current animation to complete
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
//
//
//   // Method to check if sheet is open
//   bool get isSheetOpen => _isSheetOpen;
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final bottomPadding = mediaQuery.padding.bottom;
//     final screenHeight = mediaQuery.size.height;
//     final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;
//
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: _isSheetOpen ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
//       child: Stack(
//         children: [
//           // Main content with scale and slide animation
//           AnimatedBuilder(
//             animation: _controller,
//             builder: (context, child) {
//               final topPadding = Tween<double>(begin: 0.0, end: 55.0).transform(_controller.value);
//               final horizontalPadding = Tween<double>(begin: 0.0, end: 10.0).transform(_controller.value);
//
//               return Padding(
//                 padding: EdgeInsets.only(
//                   top: topPadding,
//                   left: horizontalPadding,
//                   right: horizontalPadding,
//                 ),
//                 child: Transform.scale(
//                   scale: _scaleAnimation.value,
//                   alignment: Alignment.topCenter,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(_isSheetOpen ? 20 : 0),
//                     child: AbsorbPointer(
//                       absorbing: _isSheetOpen,
//                       child: widget.child,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Overlay for dimming
//           if (_isSheetOpen)
//             AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) => GestureDetector(
//                 onTap: closeSheet,
//                 child: Container(
//                   color: Colors.black.withOpacity(0.3 * _controller.value),
//                 ),
//               ),
//             ),
//
//           // Bottom sheet with improved constraint handling
//           if (_isSheetOpen && _currentBottomSheet != null)
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   // Calculate the actual height, ensuring it's never 0 or negative
//                   final maxSheetHeight = screenHeight * _currentSheetHeight;
//                   final animatedHeight = maxSheetHeight * _sheetHeightFactor.value;
//                   final finalHeight = animatedHeight.clamp(0.0, screenHeight);
//
//                   // Don't render if height is too small
//                   if (finalHeight < 50) {
//                     return const SizedBox.shrink();
//                   }
//
//                   return Container(
//                     height: finalHeight,
//                     decoration: BoxDecoration(
//                       color: theme?.background ?? Colors.white,
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Handle bar
//                         Container(
//                           //width: 40,
//                          // height: 4,
//                          // margin: const EdgeInsets.only(top: 0, bottom: 8),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                         // Content area with safe constraints
//                         Expanded(
//                           child: LayoutBuilder(
//                             builder: (context, constraints) {
//                               // Ensure we have valid constraints
//                               if (constraints.maxHeight <= 0) {
//                                 return const SizedBox.shrink();
//                               }
//
//                               return ClipRRect(
//                                 borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//                                 child: SingleChildScrollView(
//                                   physics: const BouncingScrollPhysics(),
//                                   child: ConstrainedBox(
//                                     constraints: BoxConstraints(
//                                       minHeight: constraints.maxHeight,
//                                     ),
//                                     child: IntrinsicHeight(
//                                       child: Padding(
//                                         padding: EdgeInsets.only(
//                                           left: 0,
//                                           right: 0,
//                                           top: 0,
//                                           bottom: 0,
//                                         ),
//                                         child: _currentBottomSheet!,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }






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


// class ChatGPTBottomSheetWrapper extends StatefulWidget {
//   final Widget child;       // Your main screen content
//   final Widget bottomSheet; // The animated bottom sheet
//
//   const ChatGPTBottomSheetWrapper({
//     super.key,
//     required this.child,
//     required this.bottomSheet,
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
//   void openSheet() {
//     if (!_isSheetOpen) {
//       setState(() => _isSheetOpen = true);
//       _controller.forward();
//     }
//   }
//
//   void closeSheet() async {
//     if (_isSheetOpen) {
//       await _controller.reverse();
//       if (mounted) setState(() => _isSheetOpen = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final bottomPadding = mediaQuery.padding.bottom;
//     final screenHeight = mediaQuery.size.height;
//     final maxSheetHeight = screenHeight * 0.93;
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     // 80% of screen height
//
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: _isSheetOpen ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
//       child: Stack(
//         children: [
//           // Main content with scale and slide animation
//           AnimatedBuilder(
//             animation: _controller,
//             builder: (context, child) {
//               final topPadding = Tween<double>(begin: 0.0, end: 55.0).transform(_controller.value);
//               final horizontalPadding = Tween<double>(begin: 0.0, end: 10.0).transform(_controller.value);
//
//               return Padding(
//                 padding: EdgeInsets.only(
//                   top: topPadding,
//                   left: horizontalPadding,
//                   right: horizontalPadding,
//                 ),
//                 child: Transform.scale(
//                   scale: _scaleAnimation.value,
//                   alignment: Alignment.topCenter,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(_isSheetOpen ? 20 : 0),
//                     child: AbsorbPointer(
//                       absorbing: _isSheetOpen,
//                       child: widget.child,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Overlay for dimming
//           if (_isSheetOpen)
//             AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) => GestureDetector(
//                 onTap: closeSheet,
//                 child: Container(
//                   color: Colors.black.withOpacity(0.3 * _controller.value),
//                 ),
//               ),
//             ),
//
//           // Bottom sheet with height animation
//           if (_isSheetOpen)
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   final height = maxSheetHeight * _sheetHeightFactor.value;
//
//                   return Container(
//                     height: height,
//                     decoration:  BoxDecoration(
//                       color: theme.background,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
//                     ),
//                     child: SingleChildScrollView(
//                       child: Padding(
//                         padding: EdgeInsets.only(
//                           left: 20,
//                           right: 20,
//                           top: 20,
//                           bottom: bottomPadding + 20,
//                         ),
//                         child: widget.bottomSheet,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }