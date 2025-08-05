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

  // Audio subscriptions for text updates and errors only
  late StreamSubscription _isListeningSubscription;
  late StreamSubscription _transcriptSubscription;
  late StreamSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioSubscriptions();
  }

  void _setupAudioSubscriptions() {
    _isListeningSubscription = widget.audioService.isListening$.listen((_) {
      if (mounted) setState(() {});
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        widget.audioService.clearError();
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
    HapticFeedback.heavyImpact();
    setState(() {
      _isOverwritingTranscript = widget.controller.text.isNotEmpty;
    });

    await widget.audioService.startRecording(
      existingText: widget.controller.text.trim(),
    );
  }

  void _onRecordingComplete() {
    setState(() {
      _isOverwritingTranscript = false;
    });
    FocusScope.of(context).requestFocus(widget.focusNode);
  }

  void _onRecordingCancel() {
    setState(() {
      _isOverwritingTranscript = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isListening = widget.audioService.isListening;
    final isTranscribing = widget.audioService.isTranscribing;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: theme.background,
        elevation: 20.0,
        child: Container(
          key: widget.textFieldKey,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
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
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  // Text Input Field
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    constraints: BoxConstraints(
                      minHeight: isListening ? 20 : 70,
                      maxHeight: 140,
                    ),
                    child: SingleChildScrollView(
                      child: Scrollbar(
                        child: isListening
                            ? SizedBox.shrink()
                            : TextField(
                          style: TextStyle(
                            fontFamily: ".SF Pro Text",
                            fontSize: 17.5,
                            fontWeight: FontWeight.w400,
                            color: _isOverwritingTranscript
                                ? Colors.grey.shade400
                                : theme.text,
                          ),
                          autofocus: true,
                          minLines: 1,
                          maxLines: null,
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontFamily: ".SF Pro Text",
                              color: Colors.grey.shade600,
                              fontSize: 17.5,
                            ),
                            hintText: 'Ask anything',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 0),
                          ),
                          onChanged: (_) => widget.onTextChanged(),
                          onSubmitted: (_) => widget.onSendMessage(),
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons - Switch between Voice Recorder and Normal Actions
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation);

                      return SlideTransition(
                        position: slideAnimation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: isListening
                        ? VoiceRecorderWidget(
                      audioService: widget.audioService,
                      onCancel: _onRecordingCancel,
                      onComplete: _onRecordingComplete,
                    )
                        : InputActionsBarWidget(
                      isTyping: widget.isTyping,
                      hasText: widget.controller.text.isNotEmpty,
                      isTranscribing: isTranscribing,
                      onStartRecording: _startRecording,
                      onSendMessage: widget.onSendMessage,
                      onStopResponse: widget.onStopResponse,
                      theme: theme,
                    ),
                  ),
                  SizedBox(height: widget.keyboardInset > 0 ? 0 : 25),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}