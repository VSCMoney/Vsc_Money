import 'dart:async';
import 'dart:math' as math;

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
// class _ChatInputWidgetState extends State<ChatInputWidget>
//     with TickerProviderStateMixin {
//   bool _isOverwritingTranscript = false;
//   bool _shouldPreventFocus = false;
//   bool _preparing = false;
//   int _textLines = 1; // Track current line count
//
//   // Animation controllers
//   late AnimationController _heightController;
//   late AnimationController _contentController;
//
//   // Animations
//   late Animation<double> _heightAnimation;
//   late Animation<double> _textFieldOpacity;
//   late Animation<double> _recorderOpacity;
//
//   late StreamSubscription<bool> _isListeningSubscription;
//   late StreamSubscription<String> _transcriptSubscription;
//   late StreamSubscription<String> _errorSubscription;
//
//   // Height constants - updated for multiline support
//   static const double _singleLineHeight = 55.0;
//   static const double _lineHeight = 20.0; // Height per line
//   static const double _recordingHeight = 26.0;
//
//   // Speeds
//   static const Duration _toVoiceDuration = Duration(milliseconds: 240);
//   static const Duration _toTextDuration = Duration(milliseconds: 480);
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _setupAudioSubscriptions();
//
//     // Listen to text changes to calculate lines
//     widget.controller.addListener(_updateLineCount);
//   }
//
//   void _updateLineCount() {
//     final text = widget.controller.text;
//
//     // Calculate lines based on text content
//     int newLineCount = 1;
//     if (text.isNotEmpty) {
//       // Count explicit line breaks
//       newLineCount = text.split('\n').length;
//
//       // Also account for text wrapping (rough estimate)
//       const avgCharsPerLine = 35; // Adjust based on your font size and width
//       final textLength = text.length;
//       final wrappedLines = (textLength / avgCharsPerLine).ceil();
//
//       newLineCount = math.max(newLineCount, wrappedLines);
//     }
//
//     // Clamp between 1 and 6 lines
//     newLineCount = newLineCount.clamp(1, 6);
//
//     if (newLineCount != _textLines) {
//       setState(() {
//         _textLines = newLineCount;
//       });
//       _updateAnimationHeights();
//     }
//   }
//
//   void _updateAnimationHeights() {
//     // Calculate dynamic height based on line count
//     final normalHeight = _singleLineHeight + (_textLines - 1) * _lineHeight;
//
//     _heightAnimation = Tween<double>(
//       begin: normalHeight,
//       end: _recordingHeight,
//     ).animate(CurvedAnimation(
//       parent: _heightController,
//       curve: Curves.easeInOut,
//       reverseCurve: Curves.easeOut,
//     ));
//   }
//
//   void _setupAnimations() {
//     // Main height animation controller
//     _heightController = AnimationController(
//       duration: _toVoiceDuration,
//       vsync: this,
//     );
//
//     // Content fade controller
//     _contentController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//
//     // Initial height animation
//     _updateAnimationHeights();
//
//     // Text field opacity - fades out fast, fades in ONLY after height is done
//     _textFieldOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
//       CurvedAnimation(
//         parent: _contentController,
//         curve: Curves.easeOut, // fast fade out to voice
//         reverseCurve: Curves.easeIn, // slow fade in from voice
//       ),
//     );
//
//     // Recorder opacity
//     _recorderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _contentController,
//         curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
//         reverseCurve: Curves.easeOut,
//       ),
//     );
//   }
//
//   void _setupAudioSubscriptions() {
//     _isListeningSubscription = widget.audioService.isListening$.listen((listening) {
//       if (!mounted) return;
//
//       if (listening) {
//         // Actually listening now - finish transition
//         setState(() {
//           _preparing = false;
//         });
//       } else if (!_preparing) {
//         // Not listening and not preparing - return to normal
//         _returnToNormal();
//       }
//     });
//
//     _transcriptSubscription = widget.audioService.transcript$.listen((transcript) {
//       if (mounted && transcript.isNotEmpty) {
//         setState(() {
//           widget.controller.text = transcript;
//           widget.controller.selection = TextSelection.fromPosition(
//             TextPosition(offset: transcript.length),
//           );
//           _isOverwritingTranscript = false;
//         });
//         widget.onTextChanged();
//       }
//     });
//
//     _errorSubscription = widget.audioService.error$.listen((error) {
//       if (mounted && error.isNotEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
//         widget.audioService.clearError();
//         _returnToNormal();
//       }
//     });
//   }
//
//   // Helper to set durations depending on direction
//   void _setDurations({required bool toVoice}) {
//     _heightController.duration = toVoice ? _toVoiceDuration : _toTextDuration;
//     _contentController.duration = toVoice ? const Duration(milliseconds: 400)
//         : const Duration(milliseconds: 360);
//   }
//
//   void _startRecordingTransition() {
//     // Going TEXT -> VOICE: run simultaneously since we're shrinking
//     _setDurations(toVoice: true);
//
//     setState(() {
//       _preparing = true;
//       _isOverwritingTranscript = widget.controller.text.isNotEmpty;
//       _shouldPreventFocus = false;
//     });
//
//     // Run both animations in sync for going to voice
//     if (!_heightController.isAnimating) _heightController.forward(from: 0);
//     if (!_contentController.isAnimating) _contentController.forward(from: 0);
//   }
//
//   void _returnToNormal() {
//     // Going VOICE -> TEXT: HEIGHT FIRST, then content
//     _setDurations(toVoice: false);
//
//     setState(() {
//       _preparing = false;
//       _isOverwritingTranscript = false;
//       _shouldPreventFocus = false;
//     });
//
//     // Update heights before animation
//     _updateAnimationHeights();
//
//     // Step 1: Expand height first
//     if (!_heightController.isAnimating) {
//       _heightController.reverse();
//     }
//
//     // Step 2: Wait for height animation to complete, then fade in content
//     void statusListener(AnimationStatus status) {
//       if (status == AnimationStatus.dismissed && !_contentController.isAnimating) {
//         // Height expansion is done (dismissed = reverse completed), now fade in content
//         _contentController.reverse();
//         _heightController.removeStatusListener(statusListener);
//       }
//     }
//
//     _heightController.addStatusListener(statusListener);
//   }
//
//   @override
//   void dispose() {
//     widget.controller.removeListener(_updateLineCount);
//     _isListeningSubscription.cancel();
//     _transcriptSubscription.cancel();
//     _errorSubscription.cancel();
//     _heightController.dispose();
//     _contentController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _startRecording() async {
//     HapticFeedback.mediumImpact();
//
//     // Hide keyboard first so viewInsets animation doesn't fight our height change
//     widget.focusNode.unfocus();
//     FocusManager.instance.primaryFocus?.unfocus();
//
//     // Start UI transition on next frame (avoids layout jank vs keyboard)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       _startRecordingTransition();
//     });
//
//     // Start recording asynchronously
//     Future.microtask(() async {
//       try {
//         await widget.audioService.startRecording(
//           existingText: widget.controller.text.trim(),
//         );
//       } catch (_) {
//         if (!mounted) return;
//         _returnToNormal();
//       }
//     });
//   }
//
//   void _onRecordingComplete() {
//     _returnToNormal();
//
//     // Focus after both animations complete
//     Future.delayed(Duration(milliseconds: _toTextDuration.inMilliseconds + 200), () {
//       if (mounted) {
//         setState(() => _shouldPreventFocus = false);
//         FocusScope.of(context).requestFocus(widget.focusNode);
//       }
//     });
//   }
//
//   void _onRecordingCancel() {
//     HapticFeedback.mediumImpact();
//     _returnToNormal();
//
//     // Close any current focus
//     widget.focusNode.unfocus();
//     FocusManager.instance.primaryFocus?.unfocus();
//
//     setState(() {
//       _shouldPreventFocus = true;
//     });
//
//     // Don't refocus after cancellation
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final isListening = widget.audioService.isListening;
//     final isTranscribing = widget.audioService.isTranscribing;
//     final showRecorder = _preparing || isListening;
//
//     return Container(
//       key: widget.textFieldKey,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       decoration: BoxDecoration(
//         color: theme.background,
//         boxShadow: [
//           BoxShadow(
//             color: theme.shadow,
//             blurRadius: 7,
//             spreadRadius: 1,
//             offset: const Offset(0, 1),
//           ),
//         ],
//         border: Border.all(color: theme.box),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Smoothly animated text field container with dynamic height
//           AnimatedBuilder(
//             animation: _heightAnimation,
//             builder: (context, child) {
//               final animatedHeight = _heightAnimation.value;
//               final currentHeight = _singleLineHeight + (_textLines - 1) * _lineHeight;
//
//               // ✅ FIX: Ensure valid constraints by using proper min/max logic
//               final minHeight = showRecorder ? _recordingHeight : currentHeight;
//               final maxHeight = showRecorder ? _recordingHeight : math.max(currentHeight, animatedHeight);
//
//               return RepaintBoundary(
//                 child: Container(
//                   height: showRecorder ? animatedHeight : null, // Fixed height only when recording
//                   constraints: showRecorder
//                       ? null // No constraints when recording - use fixed height
//                       : BoxConstraints(
//                     minHeight: minHeight,
//                     maxHeight: maxHeight,
//                   ),
//                   clipBehavior: showRecorder ? Clip.hardEdge : Clip.none,
//                   decoration: const BoxDecoration(),
//                   child: Stack(
//                     children: [
//                       // Text field with smooth opacity transition
//                       AnimatedBuilder(
//                         animation: _contentController,
//                         builder: (context, child) {
//                           return Opacity(
//                             opacity: _textFieldOpacity.value,
//                             child: IgnorePointer(
//                               ignoring: _textFieldOpacity.value < 0.15,
//                               child: TextField(
//                                 style: TextStyle(
//                                   fontFamily: "DM Sans",
//                                   fontSize: 17.5,
//                                   fontWeight: FontWeight.w400,
//                                   color: _isOverwritingTranscript ? Colors.grey.shade400 : theme.text,
//                                   height: 1.2,
//                                 ),
//                                 textAlignVertical: TextAlignVertical.top,
//                                 autofocus: !_shouldPreventFocus && !showRecorder,
//                                 minLines: 1,
//                                 maxLines: 6,
//                                 controller: widget.controller,
//                                 focusNode: widget.focusNode,
//                                 decoration: InputDecoration(
//                                   prefixIconConstraints: BoxConstraints(
//                                     minWidth: widget.controller.text.isEmpty ? 40 : 0,
//                                     maxWidth: widget.controller.text.isEmpty ? 40 : 0,
//                                     minHeight: 40,
//                                     maxHeight: 40,
//                                   ),
//                                   hintStyle: TextStyle(
//                                     fontWeight: FontWeight.w400,
//                                     fontSize: 17.5,
//                                     color: Colors.grey.shade600,
//                                   ),
//                                   hintText: 'Ask anything',
//                                   border: InputBorder.none,
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 12.0,
//                                     horizontal: 0.0, // Removed all horizontal padding
//                                   ),
//                                   isDense: false,
//                                 ),
//                                 onChanged: (_) => widget.onTextChanged(),
//                                 onSubmitted: (_) => widget.onSendMessage(),
//                                 textInputAction: TextInputAction.newline,
//                                 keyboardType: TextInputType.multiline,
//                                 scrollPadding: const EdgeInsets.all(20),
//                                 onTap: () {
//                                   if (_shouldPreventFocus) {
//                                     setState(() => _shouldPreventFocus = false);
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Dynamic spacing based on line count (only when multiline)
//           if (_textLines > 1) const SizedBox(height: 8),
//
//           // Actions bar with smooth content switching
//           Padding(
//             padding: EdgeInsets.only(
//               bottom: 0.0,
//               top: 0.0,
//               left: showRecorder ? 0 : 2, // Reduced from 10 to 2
//               right: 0,
//             ),
//             child: Stack(
//               children: [
//                 // Input actions (attach, mic, send) with fade out / in
//                 AnimatedBuilder(
//                   animation: _contentController,
//                   builder: (context, child) {
//                     return Opacity(
//                       opacity: _textFieldOpacity.value, // mirrors textField
//                       child: IgnorePointer(
//                         ignoring: _textFieldOpacity.value < 0.1,
//                         child: InputActionsBarWidget(
//                           isTyping: widget.isTyping,
//                           hasText: widget.controller.text.isNotEmpty,
//                           isTranscribing: isTranscribing,
//                           onStartRecording: _startRecording,
//                           onSendMessage: widget.onSendMessage,
//                           onStopResponse: widget.onStopResponse,
//                           theme: theme,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//
//                 // Voice recorder with fade in/out
//                 AnimatedBuilder(
//                   animation: _contentController,
//                   builder: (context, child) {
//                     return Opacity(
//                       opacity: _recorderOpacity.value,
//                       child: IgnorePointer(
//                         ignoring: _recorderOpacity.value < 0.1,
//                         child: showRecorder
//                             ? Center(
//                           heightFactor: 0.2,
//                           child: VoiceRecorderWidget(
//                             audioService: widget.audioService,
//                             onCancel: _onRecordingCancel,
//                             onComplete: _onRecordingComplete,
//                           ),
//                         )
//                             : const SizedBox.shrink(),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//           // Static spacing at bottom
//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// imports for your theme/services/widgets remain same

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

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  bool _isOverwritingTranscript = false;
  bool _shouldPreventFocus = false;
  bool _preparing = false;

  // Sirf content fade ke liye controller rakha
  late AnimationController _contentController;
  late Animation<double> _textFieldOpacity;
  late Animation<double> _recorderOpacity;

  late StreamSubscription<bool> _isListeningSubscription;
  late StreamSubscription<String> _transcriptSubscription;
  late StreamSubscription<String> _errorSubscription;

  // ---- sizing ----
  static const double _singleLineHeight = 55.0;
  static const double _lineHeight = 15.0; // per extra line
  static const int _kMaxLines = 10;       // ✅ > 6 lines allowed
  static const double _recordingHeight = 26.0;

  // Speeds
  static const Duration _toVoiceDuration = Duration(milliseconds: 240);
  static const Duration _toTextDuration  = Duration(milliseconds: 380);

  int _textLines = 1;
  Duration _heightAnimDuration = _toVoiceDuration;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _textFieldOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _recorderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );

    _setupAudioSubscriptions();
    widget.controller.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    _isListeningSubscription.cancel();
    _transcriptSubscription.cancel();
    _errorSubscription.cancel();
    _contentController.dispose();
    super.dispose();
  }

  void _setupAudioSubscriptions() {
    _isListeningSubscription = widget.audioService.isListening$.listen((listening) {
      if (!mounted) return;
      if (listening) {
        setState(() => _preparing = true); // already in voice UI
      } else {
        // voice → text
        _returnToNormal();
      }
    });

    _transcriptSubscription = widget.audioService.transcript$.listen((t) {
      if (!mounted || t.isEmpty) return;
      setState(() {
        widget.controller.text = t;
        widget.controller.selection =
            TextSelection.fromPosition(TextPosition(offset: t.length));
        _isOverwritingTranscript = false;
      });
      widget.onTextChanged();
    });

    _errorSubscription = widget.audioService.error$.listen((e) {
      if (!mounted || e.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
      widget.audioService.clearError();
      _returnToNormal();
    });
  }

  // ---------- line count & dynamic height ----------
  void _updateLineCount() {
    final text = widget.controller.text;
    int lines = text.isEmpty ? 1 : text.split('\n').length;
    const avgCharsPerLine = 36; // tune per font/width
    final wrapped = (text.length / avgCharsPerLine).ceil();
    lines = math.max(lines, wrapped);
    final clamped = lines.clamp(1, _kMaxLines);
    if (clamped != _textLines) setState(() => _textLines = clamped);
  }

  // ---------- transitions ----------
  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();

    // hide keyboard first
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // text → voice
    setState(() {
      _heightAnimDuration = _toVoiceDuration;
      _preparing = true;
      _isOverwritingTranscript = widget.controller.text.isNotEmpty;
      _shouldPreventFocus = false;
    });

    // fade text out, show recorder
    _contentController.forward(from: 0);

    // start mic
    try {
     // await Future.delayed(Duration(seconds: 1));
      await widget.audioService.startRecording(
        existingText: widget.controller.text.trim(),
      );
    } catch (_) {
      if (!mounted) return;
      _returnToNormal();
    }
  }

  void _returnToNormal() {
    // voice → text
    setState(() {
      _heightAnimDuration = _toTextDuration; // thoda slow for smoothness
      _preparing = false;
      _isOverwritingTranscript = false;
      _shouldPreventFocus = false;
    });

    // height animate hotey hi content ko reverse fade-in karao
    Future.delayed(_heightAnimDuration, () {
      if (mounted) _contentController.reverse();
    });
  }

  void _onRecordingComplete() {
    _returnToNormal();
    // after animations, refocus
    Future.delayed(_heightAnimDuration + const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _shouldPreventFocus = false);
      FocusScope.of(context).requestFocus(widget.focusNode);
    });
  }

  void _onRecordingCancel() {
    HapticFeedback.mediumImpact();
    _returnToNormal();
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _shouldPreventFocus = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final showRecorder   = _preparing || widget.audioService.isListening;
    final isTranscribing = widget.audioService.isTranscribing;

    final visibleLines   = _textLines;
    final normalHeight   = _singleLineHeight + (visibleLines - 1) * _lineHeight;
    final maxAllowed     = _singleLineHeight + (_kMaxLines - 1) * _lineHeight;

    // 👉 ab dono states me numeric height
    final double targetHeight = showRecorder
        ? _recordingHeight
        : normalHeight.clamp(_singleLineHeight, maxAllowed);

    final double extraGap = visibleLines >= 2 ? 6.0 : 0.0;

    return Container(
      key: widget.textFieldKey,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: theme.card,
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 7,
            spreadRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        //border: Border.all(color: theme.box),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------- HEIGHT ANIMATION (smooth both ways) -------
          AnimatedContainer(
            duration: _heightAnimDuration,
            curve: Curves.easeInOut,
            height: targetHeight,
            // no clipBehavior here (no assertion)
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _textFieldOpacity.value,
                      child: IgnorePointer(
                        ignoring: _textFieldOpacity.value < 0.15,
                        child: TextField(
                          style: TextStyle(
                            fontFamily: "DM Sans",
                            fontSize: 17.5,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: _isOverwritingTranscript
                                ? Colors.grey.shade400
                                : theme.text,
                          ),
                          textAlignVertical: TextAlignVertical.top,
                          autofocus: !_shouldPreventFocus && !showRecorder,
                          minLines: 1,
                          maxLines: _kMaxLines, // scroll after 10 lines
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          decoration: InputDecoration(
                            prefixIconConstraints: BoxConstraints(
                              minWidth: widget.controller.text.isEmpty ? 40 : 0,
                              maxWidth: widget.controller.text.isEmpty ? 40 : 0,
                              minHeight: 40,
                              maxHeight: 40,
                            ),
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17.5,
                              color: Colors.grey.shade600,
                            ),
                            hintText: 'Ask anything',
                            border: InputBorder.none,
                            // zyada comfortable bottom padding
                            contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            isDense: false,
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
                    );
                  },
                ),
              ],
            ),
          ),

          // ------- Actions row -------
          Padding(
            padding: EdgeInsets.only(
              bottom: 0.0,
              top: 0.0,
              left: showRecorder ? 0 : 10,
              right: 0,
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _textFieldOpacity.value,
                      child: IgnorePointer(
                        ignoring: _textFieldOpacity.value < 0.1,
                        child: InputActionsBarWidget(
                          isTyping: widget.isTyping,
                          hasText: widget.controller.text.isNotEmpty,
                          isTranscribing: isTranscribing,
                          onStartRecording: _startRecording,
                          onSendMessage: widget.onSendMessage,
                          onStopResponse: widget.onStopResponse,
                          theme: theme,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _recorderOpacity.value,
                      child: IgnorePointer(
                        ignoring: _recorderOpacity.value < 0.1,
                        child: (_preparing || widget.audioService.isListening)
                            ? Center(
                          heightFactor: 0.2,
                          child: VoiceRecorderWidget(
                            audioService: widget.audioService,
                            onCancel: _onRecordingCancel,
                            onComplete: _onRecordingComplete,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Stable spacing + extra when multiline
          SizedBox(height: 10 + extraGap),
        ],
      ),
    );
  }
}

