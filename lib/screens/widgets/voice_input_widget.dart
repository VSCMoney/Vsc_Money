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

import 'dart:async';
import 'package:flutter/material.dart';

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

// ✅ VoiceRecorderWidget - Instant render with pre-started waveforms

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late StreamSubscription _isTranscribingSubscription;
  late StreamSubscription _isSpeakingSubscription;
  late StreamSubscription _displayedRmsSubscription;

  double _currentRms = 0.3; // ✅ Start with mock value immediately!

  @override
  void initState() {
    super.initState();

    // ✅ INSTANT: Start with mock RMS data
    debugPrint('🎬 VoiceRecorderWidget initialized with mock RMS');

    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _isTranscribingSubscription =
        widget.audioService.isTranscribing$.listen((_) {
          if (mounted) setState(() {});
        });

    _isSpeakingSubscription = widget.audioService.isSpeaking$.listen((_) {
      if (mounted) setState(() {});
    });

    _displayedRmsSubscription =
        widget.audioService.displayedRms$.listen((rms) {
          if (mounted && _currentRms != rms) {
            setState(() => _currentRms = rms);
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
    HapticFeedback.mediumImpact();
    await widget.audioService.stopRecordingAndTranscribe();
    widget.onComplete();
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.mediumImpact();
    await widget.audioService.cancelRecording();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isTranscribing = widget.audioService.isTranscribing;
    final isSpeaking = widget.audioService.isSpeaking;

    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    if (isTranscribing) {
      return Row(
        key: const ValueKey('loaderOnly'),
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: Center(
                child: Lottie.asset(
                  'assets/images/mic_loading.json',
                  repeat: true,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ====== ICONS ======
    final leftCircle = Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF734012), width: 1),
      ),
      alignment: Alignment.center,
      child: BoldThickGlyph.icon(
        icon: Icons.close,
        size: 18,
        color: theme.crossIcon,
        spread: 0.55,
        copies: 9,
      ),
    );

    final rightCircle = Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      alignment: Alignment.center,
      child: BoldThickGlyph.builder(
        size: 16,
        spread: 0.55,
        copies: 9,
        builder: (color, size) =>
            Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                size: size, color: theme.background),
        color: theme.background,
      ),
    );

    // ✅ Tap overlay
    Widget _halfTapOverlay() {
      return Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) {
                final dx = d.localPosition.dx;
                if (dx < w / 2) {
                  _cancelRecording();
                } else {
                  _stopRecordingAndTranscribe();
                }
              },
            );
          },
        ),
      );
    }

    // ✅ INSTANT RENDER: Everything visible immediately
    return Stack(
      key: const ValueKey('micMode'),
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            const SizedBox(width: 3),

            // Left icon
            SizedBox(width: 56, child: Center(child: leftCircle)),

            // ✅ WAVEFORM: Immediately visible with mock data
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ChatGPTScrollingWaveform(
                  key: const ValueKey('waveform'),
                  isSpeech: isSpeaking,
                  rms: _currentRms, // ✅ Already has value (0.3)
                ),
              ),
            ),

            // Right icon
            SizedBox(width: 56, child: Center(child: rightCircle)),

            const SizedBox(width: 3),
          ],
        ),
        _halfTapOverlay(),
      ],
    );
  }
}


class BoldThickGlyph extends StatelessWidget {
  final double size;
  final double spread; // offset (in logical px)
  final int copies;    // 9 = center + 8 directions
  final Color color;

  final Widget Function(Color color, double size)? builder;
  final IconData? icon;

  const BoldThickGlyph.builder({
    super.key,
    required this.size,
    required this.spread,
    required this.copies,
    required this.color,
    required this.builder,
  }) : icon = null;

  const BoldThickGlyph.icon({
    super.key,
    required this.icon,
    required this.size,
    required this.spread,
    required this.copies,
    required this.color,
  }) : builder = null;

  @override
  Widget build(BuildContext context) {
    Widget glyph() {
      if (builder != null) return builder!(color, size);
      return Icon(icon!, size: size, color: color);
    }

    // directions: center + 8 neighbors
    final offsets = <Offset>[
      const Offset(0, 0),
      Offset( spread, 0),
      Offset(-spread, 0),
      Offset(0,  spread),
      Offset(0, -spread),
      Offset( spread,  spread),
      Offset(-spread,  spread),
      Offset( spread, -spread),
      Offset(-spread, -spread),
    ];

    final wanted = offsets.take(copies.clamp(1, offsets.length)).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final o in wanted)
          Transform.translate(offset: o, child: glyph()),
      ],
    );
  }
}







