import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MeltImageBackground extends StatefulWidget {
  final List<String> imagePaths;
  final int page;

  const MeltImageBackground({
    super.key,
    required this.imagePaths,
    required this.page,
  });

  @override
  State<MeltImageBackground> createState() => _MeltImageBackgroundState();
}

class _MeltImageBackgroundState extends State<MeltImageBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  int _prevPage = 0;

  @override
  void initState() {
    super.initState();
    _prevPage = widget.page;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant MeltImageBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page != oldWidget.page) {
      _prevPage = oldWidget.page;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.imagePaths[_prevPage],
          fit: BoxFit.cover,
        ),
        FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            widget.imagePaths[widget.page],
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class AnimatedOnboardingText extends StatelessWidget {
  final String title;
  final String subtitle;

  const AnimatedOnboardingText({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with fade animation
          const SizedBox(height: 156),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeIn,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              key: ValueKey(title),
              style: const TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle with dissolve animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            transitionBuilder: (child, animation) {
              // Dissolve effect: combines fade with scale and slight rotation
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * animation.value),
                    child: Transform.rotate(
                      angle: (1 - animation.value) * 0.1,
                      child: Opacity(
                        opacity: animation.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(animation.value),
                                Colors.white.withOpacity(animation.value * 0.7),
                                Colors.white.withOpacity(animation.value * 0.9),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: child,
              );
            },
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}