import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../constants/colors.dart';
import '../../constants/widgets.dart';
import '../../core/helpers/themes.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';
import '../../services/voice_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const VoiceRecorderWidget({
    Key? key,
    required this.audioService,
    required this.onCancel,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late StreamSubscription _isTranscribingSubscription;
  late StreamSubscription _isSpeakingSubscription;
  late StreamSubscription _displayedRmsSubscription;

  double _currentRms = 0.0;

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _isTranscribingSubscription = widget.audioService.isTranscribing$.listen((_) {
      if (mounted) setState(() {});
    });

    _isSpeakingSubscription = widget.audioService.isSpeaking$.listen((_) {
      if (mounted) setState(() {});
    });

    // Add subscription for RMS values
    _displayedRmsSubscription = widget.audioService.displayedRms$.listen((rms) {
      if (mounted && _currentRms != rms) {
        setState(() {
          _currentRms = rms;
        });
      }
    });
  }

  @override
  void dispose() {
    _isTranscribingSubscription.cancel();
    _isSpeakingSubscription.cancel();
    _displayedRmsSubscription.cancel();
    super.dispose();
  }

  Future<void> _stopRecordingAndTranscribe() async {
    await widget.audioService.stopRecordingAndTranscribe();
    widget.onComplete();
  }

  Future<void> _cancelRecording() async {
    await widget.audioService.cancelRecording();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isTranscribing = widget.audioService.isTranscribing;
    final isSpeaking = widget.audioService.isSpeaking;

    if (isTranscribing) {
      return Row(
        key: const ValueKey('loaderOnly'),
        children: [
          Expanded(
            child: Container(
              height: 45,
              alignment: Alignment.center,
              child: Lottie.asset(
                'assets/images/mic_loading.json',
                repeat: true,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      key: const ValueKey('micMode'),
      children: [
        const SizedBox(width: 3),

        // Cancel Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xFF734012),
              width: 1,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            // icon: const Icon(
            //   Icons.close,
            //   color: Color(0xFFAC5F2C),
            //   weight: 900.0,
            // ),
            icon: _BoldThickCrossIcon(),
            onPressed: _cancelRecording,
          ),
        ),

        // Waveform - removed StreamBuilder
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ChatGPTScrollingWaveform(
              key: const ValueKey('waveform'),
              isSpeech: isSpeaking,
              rms: _currentRms,
            ),
          ),
        ),

        // Check Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            // icon: Icon(
            //   PhosphorIcons.check(PhosphorIconsStyle.bold),
            //   color: Colors.white,
            // ),
           icon: _BoldThickCheckIcon(),
            onPressed: _stopRecordingAndTranscribe,
          ),
        ),
        //SizedBox(height: widget.keyboardInset > 0 ? 0 : 16),
      ],
    );
  }
}


class _BoldThickCheckIcon extends StatelessWidget {
  const _BoldThickCheckIcon();

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeService>().currentTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Center icon
        Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),

        // Add more positioned icons for thickness
        Positioned(
          left: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          right: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          top: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          bottom: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),

        // Diagonal positions for even more thickness
        Positioned(
          left: 0.5,
          top: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          right: 0.5,
          top: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          left: 0.5,
          bottom: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          right: 0.5,
          bottom: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
        Positioned(
          right: 0.5,
          bottom: 0.5,
          child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 20, color: theme.background),
        ),
      ],
    );
  }
}

class _BoldThickCrossIcon extends StatelessWidget {
  const _BoldThickCrossIcon();

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeService>().currentTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Center icon
        Icon(Icons.close, size: 20, color: theme.icon),

        // Add more positioned icons for thickness
        Positioned(
          left: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          right: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          top: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          bottom: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),

        // Diagonal positions for even more thickness
        Positioned(
          left: 0.5,
          top: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          right: 0.5,
          top: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          left: 0.5,
          bottom: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          right: 0.5,
          bottom: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
        Positioned(
          right: 0.5,
          bottom: 0.5,
          child: Icon(Icons.close, size: 20, color: theme.icon),
        ),
      ],
    );
  }
}
