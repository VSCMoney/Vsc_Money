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

  // Animation controllers
  late AnimationController _heightController;
  late AnimationController _contentController;

  // Animations
  late Animation<double> _heightAnimation;
  late Animation<double> _textFieldOpacity;
  late Animation<double> _recorderOpacity;

  late StreamSubscription<bool> _isListeningSubscription;
  late StreamSubscription<String> _transcriptSubscription;
  late StreamSubscription<String> _errorSubscription;

  // Height constants
  static const double _normalHeight = 55.0;
  static const double _recordingHeight = 26.0;

  // Speeds
  static const Duration _toVoiceDuration = Duration(milliseconds: 240);
  static const Duration _toTextDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioSubscriptions();
  }

  void _setupAnimations() {
    // Main height animation controller
    _heightController = AnimationController(
      duration: _toVoiceDuration,
      vsync: this,
    );

    // Content fade controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Height animation
    _heightAnimation = Tween<double>(
      begin: _normalHeight,
      end: _recordingHeight,
    ).animate(CurvedAnimation(
      parent: _heightController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOut,
    ));

    // Text field opacity - fades out fast, fades in ONLY after height is done
    _textFieldOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut, // fast fade out to voice
        reverseCurve: Curves.easeIn, // slow fade in from voice
      ),
    );

    // Recorder opacity
    _recorderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  void _setupAudioSubscriptions() {
    _isListeningSubscription = widget.audioService.isListening$.listen((listening) {
      if (!mounted) return;

      if (listening) {
        // Actually listening now - finish transition
        setState(() {
          _preparing = false;
        });
      } else if (!_preparing) {
        // Not listening and not preparing - return to normal
        _returnToNormal();
      }
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
        _returnToNormal();
      }
    });
  }

  // Helper to set durations depending on direction
  void _setDurations({required bool toVoice}) {
    _heightController.duration = toVoice ? _toVoiceDuration : _toTextDuration;
    _contentController.duration = toVoice ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 360);
  }

  void _startRecordingTransition() {
    // Going TEXT -> VOICE: run simultaneously since we're shrinking
    _setDurations(toVoice: true);

    setState(() {
      _preparing = true;
      _isOverwritingTranscript = widget.controller.text.isNotEmpty;
      _shouldPreventFocus = false;
    });

    // Run both animations in sync for going to voice
    if (!_heightController.isAnimating) _heightController.forward(from: 0);
    if (!_contentController.isAnimating) _contentController.forward(from: 0);
  }

  void _returnToNormal() {
    // Going VOICE -> TEXT: HEIGHT FIRST, then content
    _setDurations(toVoice: false);

    setState(() {
      _preparing = false;
      _isOverwritingTranscript = false;
      _shouldPreventFocus = false;
    });

    // Step 1: Expand height first
    if (!_heightController.isAnimating) {
      _heightController.reverse();
    }

    // Step 2: Wait for height animation to complete, then fade in content
    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.dismissed && !_contentController.isAnimating) {
        // Height expansion is done (dismissed = reverse completed), now fade in content
        _contentController.reverse();
        _heightController.removeStatusListener(statusListener);
      }
    }

    _heightController.addStatusListener(statusListener);
  }

  @override
  void dispose() {
    _isListeningSubscription.cancel();
    _transcriptSubscription.cancel();
    _errorSubscription.cancel();
    _heightController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.heavyImpact();

    // Hide keyboard first so viewInsets animation doesn't fight our height change
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // Start UI transition on next frame (avoids layout jank vs keyboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startRecordingTransition();
    });

    // Start recording asynchronously
    Future.microtask(() async {
      try {
        await widget.audioService.startRecording(
          existingText: widget.controller.text.trim(),
        );
      } catch (_) {
        if (!mounted) return;
        _returnToNormal();
      }
    });
  }

  void _onRecordingComplete() {
    _returnToNormal();

    // Focus after both animations complete
    Future.delayed(Duration(milliseconds: _toTextDuration.inMilliseconds + 200), () {
      if (mounted) {
        setState(() => _shouldPreventFocus = false);
        FocusScope.of(context).requestFocus(widget.focusNode);
      }
    });
  }

  void _onRecordingCancel() {
    HapticFeedback.heavyImpact();
    _returnToNormal();

    // Close any current focus
    widget.focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _shouldPreventFocus = true;
    });

    // Don't refocus after cancellation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isListening = widget.audioService.isListening;
    final isTranscribing = widget.audioService.isTranscribing;
    final showRecorder = _preparing || isListening;

    return Container(
      key: widget.textFieldKey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          // Smoothly animated text field container (height)
          AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: Container(
                  height: _heightAnimation.value,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    children: [
                      // Text field with smooth opacity transition
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFieldOpacity.value,
                            child: IgnorePointer(
                              ignoring: _textFieldOpacity.value < 0.15,
                              child: Scrollbar(
                                child: TextField(
                                  style: TextStyle(
                                    fontFamily: "DM Sans",
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w400,
                                    color: _isOverwritingTranscript
                                        ? Colors.grey.shade400
                                        : theme.text,
                                  ),
                                  autofocus: !_shouldPreventFocus && !showRecorder,
                                  minLines: 1,
                                  maxLines: 6,
                                  controller: widget.controller,
                                  focusNode: widget.focusNode,
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade600,
                                    ),
                                    hintText: 'Ask anything',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      bottom: 8.0,
                                      top: 12.0,
                                      left: 5,
                                    ),
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Actions bar with smooth content switching
          Padding(
            padding: EdgeInsets.only(
              bottom: 0.0,
              top: 0.0,
              left: showRecorder ? 0 : 10,
              right: 0,
            ),
            child: Stack(
              children: [
                // Input actions (attach, mic, send) with fade out / in
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFieldOpacity.value, // mirrors textField
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

                // Voice recorder with fade in/out
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _recorderOpacity.value,
                      child: IgnorePointer(
                        ignoring: _recorderOpacity.value < 0.1,
                        child: showRecorder
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

          // Remove dynamic spacing to prevent bouncing
          const SizedBox(height: 10), // Static spacing instead
        ],
      ),
    );
  }
}

