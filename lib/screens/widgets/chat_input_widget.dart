import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vscmoney/screens/widgets/voice_input_widget.dart';
import 'package:vscmoney/services/chat_service.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:vscmoney/testpage.dart';

import '../../constants/colors.dart';
import '../../constants/widgets.dart';
import '../../new_chat_screen.dart';
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


import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NOTE: yeh aapke existing imports/dep hain — same rehne do
// import 'audio_service.dart';
// import 'voice_recorder_widget.dart';
// import 'input_actions_bar_widget.dart';
// import 'app_theme_extension.dart';

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



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
  final bool isEditing;
  final VoidCallback? onCancelEdit;

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
    this.isEditing = false,
    this.onCancelEdit,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  bool _isOverwritingTranscript = false;
  bool _shouldPreventFocus = false;
  bool _preparing = false;
  bool _lockHeightUntilKbGone = false;


  late AnimationController _contentController;
  late Animation<double> _textFieldOpacity;
  late Animation<double> _recorderOpacity;

  late StreamSubscription<bool> _isListeningSubscription;
  late StreamSubscription<String> _transcriptSubscription;
  late StreamSubscription<String> _errorSubscription;

  static const double _singleLineHeight = 44.0;
  static const double _lineHeight = 15.0;
  static const int _kMaxLines = 10;
  static const double _recordingHeight = 16.0;

  // Orb sizes
  static const double _orbSize = 200;
  static const double _lottieSize = 180;

  static const Duration _toVoiceDuration = Duration(milliseconds: 0);
  static const Duration _toTextDuration = Duration(milliseconds: 0);

  int _textLines = 1;
  Duration _heightAnimDuration = _toVoiceDuration;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 0),
      vsync: this,
    );

    _textFieldOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    _recorderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeIn,
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
    _isListeningSubscription =
        widget.audioService.isListening$.listen((listening) {
          if (!mounted) return;
          if (listening) {
            setState(() => _preparing = true);
          } else {
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

  void _updateLineCount() {
    final text = widget.controller.text;
    int lines = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

    if (lines > 1 || text.length > 45) {
      const avgCharsPerLine = 36;
      final wrapped = (text.length / avgCharsPerLine).ceil();
      lines = math.max(lines, wrapped);
    }

    final clamped = lines.clamp(1, _kMaxLines);
    if (clamped != _textLines) setState(() => _textLines = clamped);
  }

  void _startRecording() {
    HapticFeedback.heavyImpact();

    // ✅ Everything happens immediately
    if (mounted) {
      setState(() {
        _preparing = true;
        _isOverwritingTranscript = widget.controller.text.isNotEmpty;
        _shouldPreventFocus = false;
        _heightAnimDuration = const Duration(milliseconds: 50);
      });
    }

    // ✅ Animation starts immediately after setState
    _contentController.stop();
    _contentController.animateTo(1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );

    // ✅ Recording starts asynchronously (non-blocking)
    widget.audioService
        .startRecording(existingText: widget.controller.text.trim())
        .catchError((e) {
      if (mounted) {
        _returnToNormal();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    });
  }

// ✅ Also update return to normal
  void _returnToNormal() {
    setState(() {
      _heightAnimDuration = _toTextDuration;
      _preparing = false;
      _isOverwritingTranscript = false;
      _shouldPreventFocus = false;
    });

    _contentController.animateTo(
      0.0,
      duration: _heightAnimDuration,
      curve: Curves.easeInOutCubic,
    );
  }

// ✅ Update recording complete - keyboard already open
  void _onRecordingComplete() {
    _returnToNormal();

    // ✅ SIMPLIFIED: No need to refocus since keyboard never closed
    Future.delayed(_heightAnimDuration, () {
      if (mounted) {
        setState(() => _shouldPreventFocus = false);
      }
    });
  }

// ✅ Cancel still closes keyboard (as it should)
  void _onRecordingCancel() {
    HapticFeedback.mediumImpact();
    _returnToNormal();

    setState(() => _shouldPreventFocus = true);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final kbBottom = widget.keyboardInset;

    final showRecorder = _preparing || widget.audioService.isListening;
    final isTranscribing = widget.audioService.isTranscribing;

    final visibleLines = _textLines;

    final normalHeight = visibleLines == 1
        ? _singleLineHeight
        : _singleLineHeight + (visibleLines - 1) * _lineHeight;

    final maxAllowed = _singleLineHeight + (_kMaxLines - 1) * _lineHeight;
    final isKeyboardOpen = kbBottom > 0;

    // print('   viewInsets.bottom: $kbBottom');
    // print('   widget.keyboardInset: ${widget.keyboardInset}');
    // ✅ Keep height consistent
    final double targetHeight = showRecorder
        ? 0.0  // ✅ Smaller height for voice UI
        : normalHeight.clamp(_singleLineHeight, maxAllowed);

    final double extraGap = visibleLines >= 2 ? 6.0 : 0.0;
    final showOrb = widget.controller.text.isEmpty && !widget.isTyping;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEditing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: EditingChip(
              onClose: widget.onCancelEdit ?? () {},
              theme: theme,
            ),
          ),

        if (widget.isEditing) const SizedBox(height: 0),

        GestureDetector(
          behavior: HitTestBehavior.opaque, // ✅ Captures all taps within bounds
          onTap: () {
            // ✅ Empty callback - just consume the tap event
            // This prevents tap from bubbling up and closing keyboard
            debugPrint('🖱️ ChatInput tapped - keyboard maintained');
          },
          child: Container(
            key: widget.textFieldKey,
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: showRecorder ? 12 : 10),

            decoration: BoxDecoration(
              color: theme.card,
              boxShadow: [
                BoxShadow(
                  color: theme.shadow,
                  blurRadius: 4,
                  spreadRadius: 2,
                  offset: const Offset(2, 0),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Text field area
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  height: targetHeight,
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _textFieldOpacity.value,
                            child: IgnorePointer(
                              ignoring: _textFieldOpacity.value < 0.15,
                              child: Padding(
                                padding:  EdgeInsets.symmetric(horizontal: 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOutCubic,
                                      width: showOrb ? 62 : 0,
                                      height: 36,
                                      decoration: const BoxDecoration(),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: AnimatedSlide(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOutCubic,
                                          offset: showOrb ? Offset.zero : const Offset(-0.4, 0),
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 180),
                                            curve: Curves.easeInOut,
                                            opacity: showOrb ? 1 : 0,
                                            child: IgnorePointer(
                                              ignoring: !showOrb,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 12),
                                                child: OrbWithBackplate(
                                                  size: 30,
                                                  backplatePad: 14,
                                                  lottie: 'assets/images/retry3.json',
                                                  nudge: const Offset(0, 0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),


                                    // AnimatedContainer(
                                    //   duration: const Duration(milliseconds: 250),
                                    //   curve: Curves.easeInOutCubic,
                                    //   width: showOrb ? 62 : 16, // ✅ 16px (left margin) + 30px (orb) + 16px (gap) = 62px OR just 16px margin
                                    //   height: 36,
                                    //   decoration: const BoxDecoration(),
                                    //   child: Align(
                                    //     alignment: Alignment.centerLeft,
                                    //     child: AnimatedSlide(
                                    //       duration: const Duration(milliseconds: 250),
                                    //             curve: Curves.easeInOutCubic,
                                    //             offset: showOrb ? Offset.zero : const Offset(-0.4, 0),
                                    //       child: AnimatedOpacity(
                                    //         duration: const Duration(milliseconds: 180),
                                    //         curve: Curves.easeInOut,
                                    //         opacity: showOrb ? 1 : 0,
                                    //         child: showOrb
                                    //             ? Padding(
                                    //           padding: const EdgeInsets.only(left: 16),
                                    //           child: OrbWithBackplate(
                                    //             size: 30,
                                    //             backplatePad: 14,
                                    //             lottie: 'assets/images/retry3.json',
                                    //             nudge: const Offset(0, 0),
                                    //           ),
                                    //         )
                                    //             : const SizedBox.shrink(),
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),

                                    Expanded(
                                      child: TextField(
                                        style: TextStyle(
                                          fontFamily: "DM Sans",
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          color: _isOverwritingTranscript
                                              ? Colors.grey.shade400
                                              : theme.text,
                                        ),
                                        textAlignVertical: TextAlignVertical.center,
                                        autofocus: !_shouldPreventFocus && !showRecorder,
                                        minLines: null,
                                        maxLines: null,
                                        expands: true,
                                        controller: widget.controller,
                                        focusNode: widget.focusNode,
                                        decoration: InputDecoration(
                                          hintStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          hintText: 'Ask anything',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.fromLTRB( showOrb ? 0 : 20, 4, 12, 0),
                                          isDense: true,
                                        ),

                                        onChanged: (_) => widget.onTextChanged(),
                                        onSubmitted: (_) => widget.onSendMessage(),
                                        textInputAction: TextInputAction.newline,
                                        keyboardType: TextInputType.multiline,
                                        scrollPadding: EdgeInsets.zero,
                                        onTap: () {
                                          if (_shouldPreventFocus) {
                                            setState(() => _shouldPreventFocus = false);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ✅ FIX: Fixed spacing and container for action bar
                const SizedBox(height: 8), // Fixed gap

                // ✅ Actions bar with FIXED height - no padding changes
                SizedBox(
                  height: 44, // ✅ Fixed height
                  child: Stack(
                    alignment: Alignment.center, // ✅ Center everything
                    children: [
                      // Input actions
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _textFieldOpacity.value,
                            child: IgnorePointer(
                              ignoring: _textFieldOpacity.value < 0.1,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 0),
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
                            ),
                          );
                        },
                      ),

                      // Voice recorder - perfectly centered
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _recorderOpacity.value,
                            child: IgnorePointer(
                              ignoring: _recorderOpacity.value < 0.1,
                              child: (_preparing || widget.audioService.isListening)
                                  ? Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
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

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: (isKeyboardOpen && !widget.audioService.isListening) ? 0 : widget.audioService.isListening ? 20 : 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class OrbWithBackplate extends StatelessWidget {
  final double size;          // total icon box (e.g. 36 for prefix)
  final double backplatePad;  // backplate ka outward spread
  final String? lottie;       // optional animation under glass
  final Offset nudge;         // final pixel shift (positioning tweak)

  const OrbWithBackplate({
    super.key,
    this.size = 36,
    this.backplatePad = 8,
    this.lottie,
    this.nudge = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: nudge,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // warm BACKPLATE (same image you used)
            Positioned(
              left: -backplatePad,
              right: -backplatePad,
              top: -backplatePad,
              bottom: -backplatePad,
              child: Image.asset(
                'assets/images/orb_back.webp',
                fit: BoxFit.cover,
              ),
            ),

            // the glass orb itself (tiny version; no Scaffold)
            Align(
              alignment: Alignment.center,
              child: OrbIcon(
                blur: 4.0,
                size: size,                     // keep same as box
                lottie: lottie,                 // e.g. 'assets/images/retry1.json'
              ),
            ),
          ],
        ),
      ),
    );
  }
}









