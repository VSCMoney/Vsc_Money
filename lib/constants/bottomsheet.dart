// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class ChatGPTBottomSheetWrapper extends StatefulWidget {
//   final Widget child;
//   final Widget bottomSheet;
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
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   bool _isSheetOpen = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 350),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//   }
//
//   void openSheet() {
//     HapticFeedback.selectionClick();
//     setState(() => _isSheetOpen = true);
//     _controller.forward();
//   }
//
//   void closeSheet() {
//     _controller.reverse().then((_) {
//       if (mounted) {
//         setState(() => _isSheetOpen = false);
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         widget.child,
//         if (_isSheetOpen)
//           AnimatedBuilder(
//             animation: _animation,
//             builder: (context, _) {
//               return Opacity(
//                 opacity: _animation.value,
//                 child: GestureDetector(
//                   onTap: closeSheet,
//                   child: Container(
//                     color: Colors.black.withOpacity(0.4 * _animation.value),
//                   ),
//                 ),
//               );
//             },
//           ),
//         if (_isSheetOpen)
//           AnimatedBuilder(
//             animation: _animation,
//             builder: (context, _) {
//               final double slideY = (1 - _animation.value) * 300;
//
//               return Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Transform.translate(
//                   offset: Offset(0, slideY),
//                   child: Material(
//                     color: Colors.white,
//                     elevation: 12,
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//                     child: widget.bottomSheet,
//                   ),
//                 ),
//               );
//             },
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
// }
