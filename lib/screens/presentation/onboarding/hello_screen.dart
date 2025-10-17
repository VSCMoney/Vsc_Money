import 'dart:async';
import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';
import 'level_screen.dart';

// import 'onboarding_flow.dart'; // <-- your flow

class WarmHelloScreen extends StatefulWidget {
  const WarmHelloScreen({
    super.key,
    required this.name,
    this.subtitle = "Let's get to know you better",
    this.initialDelay = const Duration(seconds: 1), // ✅ NEW: Delay before title
    this.subtitleDelay = const Duration(seconds: 1), // After title
    this.startFlowDelayAfterSubtitle = const Duration(seconds: 2),
    this.onboardingFinishedRoute,
  });

  final String name;
  final String subtitle;
  final Duration initialDelay; // ✅ NEW
  final Duration subtitleDelay;
  final Duration startFlowDelayAfterSubtitle;
  final String? onboardingFinishedRoute;

  @override
  State<WarmHelloScreen> createState() => _WarmHelloScreenState();
}

class _WarmHelloScreenState extends State<WarmHelloScreen>
    with TickerProviderStateMixin {
  // 1) Title in
  late final AnimationController _titleIn;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  // 2) Subtitle in
  late final AnimationController _subIn;
  late final Animation<double> _subOpacity;
  late final Animation<Offset> _subSlide;

  // 3) Hello block slide up to notch & fade out
  late final AnimationController _helloExit;
  late final Animation<double> _helloFadeOut;
  late final Animation<Offset> _helloSlideUp;

  // 4) Flow in
  late final AnimationController _flowIn;
  late final Animation<double> _flowFadeIn;
  late final Animation<Offset> _flowSlideUp;

  bool _showFlowLayer = false;

  @override
  void initState() {
    super.initState();

    // Title enter
    _titleIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _titleOpacity = CurvedAnimation(parent: _titleIn, curve: Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: const Offset(0, .10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _titleIn, curve: Curves.easeOutCubic));

    // Subtitle enter
    _subIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _subOpacity = CurvedAnimation(parent: _subIn, curve: Curves.easeOut);
    _subSlide = Tween<Offset>(begin: const Offset(0, .14), end: Offset.zero)
        .animate(CurvedAnimation(parent: _subIn, curve: Curves.easeOutCubic));

    // Hello exit (to notch)
    _helloExit = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _helloFadeOut = CurvedAnimation(parent: _helloExit, curve: Curves.easeOut);
    _helloSlideUp = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.05))
        .animate(CurvedAnimation(parent: _helloExit, curve: Curves.easeOutCubic));

    // Flow enter
    _flowIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _flowFadeIn = CurvedAnimation(parent: _flowIn, curve: Curves.easeOut);
    _flowSlideUp = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _flowIn, curve: Curves.easeOutCubic));

    _playSequence();
  }

  Future<void> _playSequence() async {
    // ✅ NEW: Wait 1 second before showing anything
    await Future.delayed(widget.initialDelay);

    // 1) Title in
    await _titleIn.forward();

    // 2) wait -> Subtitle in
    await Future.delayed(widget.subtitleDelay);
    await _subIn.forward();

    // tiny buffer (optional for natural pacing)
    await Future.delayed(widget.startFlowDelayAfterSubtitle);

    // 3) Hello slide up to notch & fade out
    setState(() => _showFlowLayer = true);
    await _helloExit.forward();

    // 4) Flow in
    await _flowIn.forward();
  }

  @override
  void dispose() {
    _titleIn.dispose();
    _subIn.dispose();
    _helloExit.dispose();
    _flowIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const creamLeft = Color(0xFFF1EAE4);
    const whiteRight = Color(0xFFFFFFFF);
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final h = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [creamLeft, whiteRight],
          stops: [0.0, 0.55],
        ),
      ),
      child: CustomPaint(
        painter: _RadialGlowPainter(),
        child: Scaffold(
          backgroundColor: theme.background,
          body: Padding(
            padding:  EdgeInsets.symmetric(vertical: 50),
            child: Stack(
              children: [
                // 4) FLOW LAYER
                if (_showFlowLayer)
                  FadeTransition(
                    opacity: _flowFadeIn,
                    child: SlideTransition(
                      position: _flowSlideUp,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: (h * 0.00)),
                        child: OnboardingFlow(
                          onFinished: () {
                            final route = widget.onboardingFinishedRoute;
                            if (route != null && context.mounted) {
                              Navigator.of(context).pushReplacementNamed(route);
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                // 1–3) HELLO LAYER
                Align(
                  alignment: const Alignment(-1, 0.08),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_titleIn, _subIn, _helloExit]),
                    builder: (context, _) {
                      final helloOpacity = (1.0 - _helloFadeOut.value).clamp(0.0, 1.0);

                      return Opacity(
                        opacity: helloOpacity,
                        child: SlideTransition(
                          position: _helloExit.isDismissed
                              ? const AlwaysStoppedAnimation(Offset.zero)
                              : _helloSlideUp,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: _HelloBlock(
                              name: widget.name,
                              subtitle: widget.subtitle,
                              titleOpacity: _titleOpacity,
                              titleSlide: _titleSlide,
                              subOpacity: _subOpacity,
                              subSlide: _subSlide,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Rest of the code remains same (_HelloBlock, _RadialGlowPainter)
class _HelloBlock extends StatelessWidget {
  const _HelloBlock({
    required this.name,
    required this.subtitle,
    required this.titleOpacity,
    required this.titleSlide,
    required this.subOpacity,
    required this.subSlide,
  });

  final String name;
  final String subtitle;
  final Animation<double> titleOpacity;
  final Animation<Offset> titleSlide;
  final Animation<double> subOpacity;
  final Animation<Offset> subSlide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    const titleSize = 38.0;
    const subSize = 16.5;

    final titleStyle =  TextStyle(
      fontFamily: 'DM Sans',
      fontSize: titleSize,
      height: 1.05,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.2,
      color: theme.text,
    );
    final subStyle =  TextStyle(
      fontFamily: 'DM Sans',
      fontSize: subSize,
      height: 1.35,
      fontWeight: FontWeight.w400,
      color: theme.text,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: titleOpacity,
          child: SlideTransition(
            position: titleSlide,
            child: RichText(
              text: TextSpan(
                style: titleStyle,
                children: [
                  const TextSpan(text: 'Hi, '),
                  TextSpan(text: _trimName(name)),
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: titleSize * 0.10),
                      child: const Text('👋🏻', style: TextStyle(fontSize: titleSize * 0.82)),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeTransition(
          opacity: subOpacity,
          child: SlideTransition(
            position: subSlide,
            child: Text(
              subtitle,
              style: subStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  static String _trimName(String s) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.isEmpty ? 'there' : t;
  }
}

class _RadialGlowPainter extends CustomPainter {
  const _RadialGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const RadialGradient(
      center: Alignment(0.75, 0.85),
      radius: 0.75,
      colors: [Color(0x00FFFFFF), Color(0x11FFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.55, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




