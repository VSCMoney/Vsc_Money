import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/presentation/settings/settings_screen.dart';
import '../screens/presentation/stock_detail_screen.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../testpage.dart';




// More robust ChatGPTBottomSheetWrapper with better constraint handling
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

  // Method to open sheet with specific content and height
  void openSheet(Widget bottomSheetContent, {double heightFactor = 0.93}) {
    if (!_isSheetOpen) {
      setState(() {
        _isSheetOpen = true;
        _currentBottomSheet = bottomSheetContent;
        _currentSheetHeight = heightFactor;
      });
      _controller.forward();
    } else {
      // If sheet is already open, just update the content
      setState(() {
        _currentBottomSheet = bottomSheetContent;
        _currentSheetHeight = heightFactor;
      });
    }
  }

  // Method to close sheet
  void closeSheet() async {
    if (_isSheetOpen) {
      await _controller.reverse();
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _currentBottomSheet = null;
        });
      }
    }
  }

  // Method to check if sheet is open
  bool get isSheetOpen => _isSheetOpen;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()?.theme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isSheetOpen ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
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
                  // Calculate the actual height, ensuring it's never 0 or negative
                  final maxSheetHeight = screenHeight * _currentSheetHeight;
                  final animatedHeight = maxSheetHeight * _sheetHeightFactor.value;
                  final finalHeight = animatedHeight.clamp(0.0, screenHeight);

                  // Don't render if height is too small
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
                        // Handle bar
                        Container(
                          //width: 40,
                         // height: 4,
                         // margin: const EdgeInsets.only(top: 0, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Content area with safe constraints
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Ensure we have valid constraints
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
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 0,
                                          right: 0,
                                          top: 0,
                                          bottom: 0,
                                        ),
                                        child: _currentBottomSheet!,
                                      ),
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
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}






class BottomSheetManager {

  static Widget buildSettingsSheet({required VoidCallback onTap}) {
    return SettingsScreen(onTap: onTap);
  }

  static Widget buildStockDetailSheet({
    required String stockSymbol,
    required String stockName,
    required VoidCallback onTap,
  }) {
    return StockDetailPage(
      stockSymbol: stockSymbol,
      stockName: stockName,
      onClose: onTap,
    );
  }

  static Widget buildAskVittySheet({
    required String selectedText,
    required VoidCallback onTap,
    required Function(String) onAskVitty,
    required ChatService chatService,
  }) {
    // Create a unique key for each instance
    final uniqueKey = ValueKey('vitty_thread_${selectedText.hashCode}_${DateTime.now().millisecondsSinceEpoch}');

    return VittyThreadSheet(
      key: uniqueKey,
      chatService: chatService,
      initialText: selectedText,
      onClose: onTap,
    );
  }

  // Add more sheet builders as needed
  static Widget buildCustomSheet({
    required Widget content,
    double? height,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap != null) ...[
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(), // Empty space for alignment
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // Custom content
        Flexible(child: content),
      ],
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