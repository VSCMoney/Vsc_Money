import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vscmoney/screens/widgets/voice_input_widget.dart';

import '../../constants/colors.dart';
import '../../constants/widgets.dart';
import '../../services/theme_service.dart';
import '../../services/voice_service.dart';
import 'input_actions_widget.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vscmoney/screens/widgets/voice_input_widget.dart';

import '../../constants/colors.dart';
import '../../services/theme_service.dart';
import '../../services/voice_service.dart';
import 'input_actions_widget.dart';




//
// class ChatInputWidget extends StatefulWidget {
//   final TextEditingController controller;
//   final FocusNode focusNode;
//   final GlobalKey textFieldKey;
//   final bool isTyping;
//   final double keyboardInset;
//   final VoidCallback onSendMessage;
//   final VoidCallback onStopResponse;
//   final VoidCallback onTextChanged;
//   final AudioService audioService;
//
//   const ChatInputWidget({
//     Key? key,
//     required this.controller,
//     required this.focusNode,
//     required this.textFieldKey,
//     required this.isTyping,
//     required this.keyboardInset,
//     required this.onSendMessage,
//     required this.onStopResponse,
//     required this.onTextChanged,
//     required this.audioService,
//   }) : super(key: key);
//
//   @override
//   State<ChatInputWidget> createState() => _ChatInputWidgetState();
// }
//
// class _ChatInputWidgetState extends State<ChatInputWidget> {
//   bool _isOverwritingTranscript = false;
//   bool _shouldPreventFocus = false;
//   bool _preparing = false; // show recorder immediately while mic spins up
//
//   late StreamSubscription<bool> _isListeningSubscription;
//   late StreamSubscription<String> _transcriptSubscription;
//   late StreamSubscription<String> _errorSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _isListeningSubscription = widget.audioService.isListening$.listen((listening) {
//       if (!mounted) return;
//       if (listening) setState(() => _preparing = false);
//     });
//     _transcriptSubscription = widget.audioService.transcript$.listen((t) {
//       if (!mounted || t.isEmpty) return;
//       setState(() {
//         widget.controller.text = t;
//         widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: t.length));
//         _isOverwritingTranscript = false;
//       });
//       widget.onTextChanged();
//     });
//     _errorSubscription = widget.audioService.error$.listen((e) {
//       if (!mounted || e.isEmpty) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
//       widget.audioService.clearError();
//       setState(() => _preparing = false);
//     });
//   }
//
//   @override
//   void dispose() {
//     _isListeningSubscription.cancel();
//     _transcriptSubscription.cancel();
//     _errorSubscription.cancel();
//     super.dispose();
//   }
//
//   Future<void> _startRecording() async {
//     HapticFeedback.lightImpact();
//     setState(() {
//       _isOverwritingTranscript = widget.controller.text.isNotEmpty;
//       _shouldPreventFocus = false;
//       _preparing = true; // flip UI instantly
//     });
//     widget.focusNode.unfocus();
//     FocusManager.instance.primaryFocus?.unfocus();
//
//     Future.microtask(() async {
//       try {
//         await widget.audioService.startRecording(
//           existingText: widget.controller.text.trim(),
//         );
//       } catch (_) {
//         if (mounted) setState(() => _preparing = false);
//       }
//     });
//   }
//
//   void _onRecordingComplete() {
//     setState(() {
//       _isOverwritingTranscript = false;
//       _shouldPreventFocus = false;
//       _preparing = false;
//     });
//     FocusScope.of(context).requestFocus(widget.focusNode);
//   }
//
//   void _onRecordingCancel() {
//     setState(() {
//       _isOverwritingTranscript = false;
//       _shouldPreventFocus = true;
//       _preparing = false;
//     });
//     widget.focusNode.unfocus();
//     FocusManager.instance.primaryFocus?.unfocus();
//     Future.delayed(const Duration(milliseconds: 400), () {
//       if (mounted) setState(() => _shouldPreventFocus = false);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appTheme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final isListening = widget.audioService.isListening;
//     final isTranscribing = widget.audioService.isTranscribing;
//     final showRecorder = _preparing || isListening;
//
//     // Card chrome like screenshot
//     final card = Container(
//       key: widget.textFieldKey,
//       margin: const EdgeInsets.only(left: 0, right: 0, bottom: 0,),
//       padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
//       decoration: BoxDecoration(
//        color: appTheme.background,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 24,
//             offset: Offset(0, 9),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Top row: big hint input
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             curve: Curves.easeOut,
//             constraints: BoxConstraints(
//               minHeight: showRecorder ? 0 : 55, // keep roomy like screenshot
//               maxHeight: showRecorder ? 0 : 190,
//             ),
//             child: showRecorder
//                 ? const SizedBox.shrink()
//                 : TextField(
//               controller: widget.controller,
//               focusNode: widget.focusNode,
//               autofocus: !_shouldPreventFocus && !showRecorder,
//               minLines: 1,
//               maxLines: 5,
//               onChanged: (_) => widget.onTextChanged(),
//               onSubmitted: (_) => widget.onSendMessage(),
//               keyboardType: TextInputType.multiline,
//               textInputAction: TextInputAction.newline,
//               style: TextStyle(
//                 fontFamily: "Inter",
//                 fontSize: 20.5, // large like the mock
//                 fontWeight: FontWeight.w400,
//                 color: _isOverwritingTranscript ? Colors.grey.shade400 : appTheme.text,
//                 height: 1.25,
//               ),
//               decoration: InputDecoration(
//                 isCollapsed: true,
//                 hintText: 'Ask anything',
//                 hintStyle: TextStyle(
//                   fontFamily: "Inter",
//                   fontSize: 20.5,
//                   color: Colors.black.withOpacity(0.35),
//                   height: 1.25,
//                 ),
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.zero,
//               ),
//             ),
//           ),
//
//           // Bottom actions row: + ……   mic  •(round)
//           Row(
//             children: [
//               // Plus button (left)
//               _SmallIconButton(
//                 onTap: () {
//                   HapticFeedback.selectionClick();
//                   // open attachments sheet here
//                 },
//                 child: const Icon(Icons.add, size: 26, color: Colors.black),
//               ),
//
//               const Spacer(),
//
//               // Mic icon
//               GestureDetector(
//                 onTap: _startRecording,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
//                   child: Image.asset(
//                     "assets/images/bold_mic.png",
//                     height: 23,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//
//               const SizedBox(width: 10),
//
//               // Big round action: send OR start voice (if no text)
//               _RoundActionButton(
//                 busy: isTranscribing,
//                 filledColor: Colors.black,
//                 icon: widget.isTyping
//                     ? const Icon(Icons.arrow_upward, color: Colors.white, size: 20)
//                     : (widget.controller.text.isNotEmpty
//                     ? const Icon(Icons.arrow_upward, color: Colors.white, size: 20)
//                     : _BarsIcon(color: Colors.white)), // matches “equalizer dots” look
//                 onTap: () {
//                   HapticFeedback.mediumImpact();
//                   if (widget.isTyping) {
//                     widget.onStopResponse();
//                   } else if (widget.controller.text.isNotEmpty) {
//                     widget.onSendMessage();
//                   } else {
//                     _startRecording();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//
//     // Recorder swaps in place of the content (same card chrome)
//     final recorder = Container(
//       margin: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
//       padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x14000000),
//             blurRadius: 24,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child:  VoiceRecorderWidget(
//         audioService: widget.audioService,
//         onCancel: _onRecordingCancel,
//         onComplete: _onRecordingComplete,
//       ),
//     );
//
//     return SafeArea(
//       top: false,
//       bottom: false,
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 150),
//         switchInCurve: Curves.easeOut,
//         switchOutCurve: Curves.easeIn,
//         child: showRecorder ? recorder : card,
//       ),
//     );
//   }
// }
//
// // Small touch-friendly icon button (the “+”)
// class _SmallIconButton extends StatelessWidget {
//   final Widget child;
//   final VoidCallback onTap;
//   const _SmallIconButton({required this.child, required this.onTap});
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       shape: const CircleBorder(),
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(6.0),
//           child: child,
//         ),
//       ),
//     );
//   }
// }
//
// // Big round button on the right
// class _RoundActionButton extends StatelessWidget {
//   final Widget icon;
//   final VoidCallback onTap;
//   final Color filledColor;
//   final bool busy;
//   const _RoundActionButton({
//     required this.icon,
//     required this.onTap,
//     required this.filledColor,
//     this.busy = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 140),
//       child: SizedBox(
//         key: ValueKey<bool>(busy),
//         height: 46,
//         width: 46,
//         child: Material(
//           color: filledColor,
//           shape: const CircleBorder(),
//           child: InkWell(
//             customBorder: const CircleBorder(),
//             onTap: busy ? null : onTap,
//             child: Center(
//               child: busy
//                   ? const SizedBox(
//                 height: 18,
//                 width: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
//               )
//                   : icon,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Simple “vertical bars” glyph for the round button when there’s no text
// class _BarsIcon extends StatelessWidget {
//   final Color color;
//   const _BarsIcon({required this.color});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _bar(8),
//         const SizedBox(width: 2.5),
//         _bar(14),
//         const SizedBox(width: 2.5),
//         _bar(10),
//       ],
//     );
//   }
//
//   Widget _bar(double h) => Container(width: 3, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
// }



class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey textFieldKey;
  final bool isTyping;
  final double keyboardInset;
  final VoidCallback onSendMessage;
  final VoidCallback onStopResponse;
  final VoidCallback onTextChanged;
  final AudioService audioService;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.textFieldKey,
    required this.isTyping,
    required this.keyboardInset,
    required this.onSendMessage,
    required this.onStopResponse,
    required this.onTextChanged,
    required this.audioService,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _isOverwritingTranscript = false;
  bool _shouldPreventFocus = false;

  /// New: show recorder immediately while we spin up mic/session
  bool _preparing = false;

  late StreamSubscription<bool> _isListeningSubscription;
  late StreamSubscription<String> _transcriptSubscription;
  late StreamSubscription<String> _errorSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioSubscriptions();
  }

  void _setupAudioSubscriptions() {
    // Listen to real bool values so we can end "preparing" instantly
    _isListeningSubscription = widget.audioService.isListening$.listen((listening) {
      if (!mounted) return;
      setState(() {
        // once the service is listening, we’re no longer preparing
        if (listening) _preparing = false;
      });
    });

    _transcriptSubscription = widget.audioService.transcript$.listen((transcript) {
      if (mounted && transcript.isNotEmpty) {
        setState(() {
          widget.controller.text = transcript;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: transcript.length),
          );
          _isOverwritingTranscript = false;
        });
        widget.onTextChanged();
      }
    });

    _errorSubscription = widget.audioService.error$.listen((error) {
      if (mounted && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        widget.audioService.clearError();
        setState(() {
          _preparing = false; // stop spinner state on error
        });
      }
    });
  }

  @override
  void dispose() {
    _isListeningSubscription.cancel();
    _transcriptSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.selectionClick();

    // 1) Flip UI immediately
    setState(() {
      _isOverwritingTranscript = widget.controller.text.isNotEmpty;
      _shouldPreventFocus = false;
      _preparing = true; // show VoiceRecorderWidget right away
    });

    // 2) Hide keyboard without waiting for its animation to finish
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // 3) Kick off mic start asynchronously (don’t block the frame)
    Future.microtask(() async {
      try {
        await widget.audioService.startRecording(
          existingText: widget.controller.text.trim(),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _preparing = false);
      }
    });
  }

  void _onRecordingComplete() {
    setState(() {
      _isOverwritingTranscript = false;
      _shouldPreventFocus = false;
      _preparing = false;
    });
    FocusScope.of(context).requestFocus(widget.focusNode);
  }

  void _onRecordingCancel() {
    setState(() {
      _isOverwritingTranscript = false;
      _shouldPreventFocus = true;
      _preparing = false;
    });
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _shouldPreventFocus = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isListening = widget.audioService.isListening;
    final isTranscribing = widget.audioService.isTranscribing;

    final bool showRecorder = _preparing || isListening;

    return Container(
      key: widget.textFieldKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 7,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: theme.box),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keep height stable while switching to avoid layout jank
          AnimatedContainer(
            duration:  Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints:  BoxConstraints(
              minHeight: isListening ? 20 :55,
              maxHeight: isListening ? 20 :  190,
            ),
            child: showRecorder
                ? const SizedBox.shrink() // we hide field but keep space stable above via constraints
                : Scrollbar(
              child: TextField(
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 17.5,
                  fontWeight: FontWeight.w400,
                  color: _isOverwritingTranscript ? Colors.grey.shade400 : theme.text,
                ),
                // Don’t focus while preparing/listening to prevent keyboard flashes
                autofocus: !_shouldPreventFocus && !showRecorder,
                minLines: 1,
                maxLines: 6,
                controller: widget.controller,
                focusNode: widget.focusNode,
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontFamily: "SF Pro",
                    color: Colors.grey.shade600,
                  ),
                  hintText: 'Ask anything',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
                  isDense: true,
                ),
                onChanged: (_) => widget.onTextChanged(),
                onSubmitted: (_) => widget.onSendMessage(),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                scrollPadding: const EdgeInsets.all(20),
                onTap: () {
                  if (_shouldPreventFocus) {
                    setState(() => _shouldPreventFocus = false);
                  }
                },
              ),
            ),
          ),

          // Actions / Recorder
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: showRecorder
                ? VoiceRecorderWidget(
              key: const ValueKey('recorder'),
              audioService: widget.audioService,
              onCancel: _onRecordingCancel,
              onComplete: _onRecordingComplete,
              // (Optional) you can show a tiny "preparing…" state inside the widget using _preparing
            )
                : InputActionsBarWidget(
              key: const ValueKey('actions'),
              isTyping: widget.isTyping,
              hasText: widget.controller.text.isNotEmpty,
              isTranscribing: isTranscribing,
              onStartRecording: _startRecording,
              onSendMessage: widget.onSendMessage,
              onStopResponse: widget.onStopResponse,
              theme: theme,
            ),
          ),
          SizedBox(height: widget.keyboardInset > 0 ? 0 : 16),
        ],
      ),
    );
  }
}
