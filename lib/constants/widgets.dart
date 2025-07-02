import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';







class AnimatedComingSoonTooltip extends StatefulWidget {
  @override
  _AnimatedComingSoonTooltipState createState() => _AnimatedComingSoonTooltipState();
}

class _AnimatedComingSoonTooltipState extends State<AnimatedComingSoonTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Coming Soon!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}



class AddShortcutCard extends StatelessWidget {
  const AddShortcutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        final entry = OverlayEntry(
          builder: (context) => Positioned(
            top: offset.dy + size.height + 8,
            left: offset.dx + size.width / 2 - 60,
            child: Material(
              color: Colors.transparent,
              child: _ComingSoonTooltip(),
            ),
          ),
        );

        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), () => entry.remove());
      },
      child: Container(
        height: 94,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  "Add Shortcut",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 16,fontFamily: 'SF Pro Text'),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              " Create your own quick prompt",
              style: TextStyle(fontSize: 14, color: Colors.white,fontFamily: "SF Pro Text"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Text(
        "Coming soon",
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}




// class ChatGPTScrollingWaveform extends StatefulWidget {
//   final bool isSpeech;
//   final double rms;
//
//   const ChatGPTScrollingWaveform({
//     Key? key,
//     required this.isSpeech,
//     required this.rms,
//   }) : super(key: key);
//
//   @override
//   State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
// }
//
// class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform> {
//   final int maxBars = 30; // reduced to fit better
//   final Duration frameRate = Duration(milliseconds: 60);
//   final double flatHeight = 6;
//   final List<double> _waveform = [];
//
//   Timer? _waveformTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _waveform.addAll(List.generate(maxBars, (_) => flatHeight));
//     _startWaveformLoop();
//   }
//
//   void _startWaveformLoop() {
//     _waveformTimer = Timer.periodic(frameRate, (_) {
//       if (!mounted) return;
//
//       double nextHeight = widget.isSpeech
//           ? (widget.rms * 350).clamp(10.0, 70.0)
//           : flatHeight;
//
//       setState(() {
//         _waveform.add(nextHeight);
//         if (_waveform.length > maxBars) {
//           _waveform.removeAt(0);
//         }
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _waveformTimer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRect(
//       child: SizedBox(
//         height: 40,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: _waveform.map((barHeight) {
//             final isActive = barHeight > flatHeight;
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 1.5),
//               child: AnimatedContainer(
//                 duration: frameRate,
//                 width: 3,
//                 height: barHeight,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }


class OverlayContainerClipper extends CustomClipper<Path> {
  final double rms;
  final bool isSpeaking;

  OverlayContainerClipper({required this.rms, required this.isSpeaking});

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final path = Path();

    final animatedRms = isSpeaking ? rms : 0.0;

    final baseHeight = 80.0;
    final additionalHeight = (animatedRms * 210).clamp(0.0, 20.0);
    final curveHeight = baseHeight - additionalHeight;

    final basePeakHeight = 20.0;
    final additionalPeakHeight = (animatedRms * 100).clamp(0.0, 20.0);
    final peakHeight = basePeakHeight - additionalPeakHeight;

    path.moveTo(0, height);
    path.lineTo(0, curveHeight);

    path.quadraticBezierTo(
      width / 2,
      peakHeight,
      width,
      curveHeight,
    );

    path.lineTo(width, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant OverlayContainerClipper oldClipper) {
    return oldClipper.rms != rms || oldClipper.isSpeaking != isSpeaking;
  }
}

class InnerOverlayContainerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final path = Path();

    // Fixed curve values (adjust as per your UI)
    final curveHeight = 90.0;  // Lower value = curve up, higher = curve down
    final peakHeight = 38.0;   // Lower = more dramatic peak

    path.moveTo(0, height);
    path.lineTo(0, curveHeight);

    path.quadraticBezierTo(
      width / 2,
      peakHeight,
      width,
      curveHeight,
    );

    path.lineTo(width, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant InnerOverlayContainerClipper oldClipper) {
    return false; // Static, so never reclip
  }
}

class ChatGPTScrollingWaveform extends StatefulWidget {
  final bool isSpeech;
  final double rms;

  const ChatGPTScrollingWaveform({
    Key? key,
    required this.isSpeech,
    required this.rms,
  }) : super(key: key);

  @override
  State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
}

class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform>
    with SingleTickerProviderStateMixin {
  final int maxBars = 30;
  final Duration frameRate = Duration(milliseconds: 80);
  final double flatHeight = 2;
  final List<double> _waveform = [];

  Timer? _waveformTimer;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // 🔄 Speech continuity tracking
  bool _wasRecentlySpeaking = false;
  DateTime _lastSpeechTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Start with empty waveform
    _waveform.clear();

    // Setup slide animation for smooth right-to-left movement
    _slideController = AnimationController(
      duration: frameRate,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0, // Distance each bar slides (width + padding)
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.linear,
    ));

    _startWaveformLoop();
  }

  void _startWaveformLoop() {
    _waveformTimer = Timer.periodic(frameRate, (_) {
      if (!mounted) return;

      final now = DateTime.now();

      // 🎯 LOWER threshold for better continuity
      const double minRmsThreshold = 0.005; // Reduced from 0.015 for better detection
      bool actualSpeechDetected = widget.isSpeech && widget.rms > minRmsThreshold;

      // 🔄 Update speech tracking
      if (actualSpeechDetected) {
        _lastSpeechTime = now;
        _wasRecentlySpeaking = true;
      }

      // 📏 LONGER grace period for better continuity
      bool withinGracePeriod = now.difference(_lastSpeechTime) < Duration(milliseconds: 300); // Increased from 150ms

      // 🌊 More lenient continuity check
      bool hasAnyAudio = widget.rms > 0.003; // Very low threshold for minimal audio
      bool shouldShowWaves = actualSpeechDetected ||
          (_wasRecentlySpeaking && withinGracePeriod && hasAnyAudio) ||
          (_wasRecentlySpeaking && withinGracePeriod && widget.isSpeech); // Keep going if isSpeech is still true

      if (!withinGracePeriod) {
        _wasRecentlySpeaking = false;
      }

      double nextHeight;

      if (shouldShowWaves) {
        double effectiveRms = widget.rms;

        // During grace period, maintain minimum wave height
        if (!actualSpeechDetected && _wasRecentlySpeaking) {
          effectiveRms = max(effectiveRms, 0.010); // Guarantee minimum during gaps
          effectiveRms = effectiveRms * 0.9; // Slight fade during gap
        }

        nextHeight = (pow(effectiveRms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0);
      } else {
        // 🔇 IMMEDIATE FLAT - no background waves
        nextHeight = flatHeight;
      }

      setState(() {
        // Add new bar on the LEFT side (index 0)
        _waveform.insert(0, nextHeight);
        // Remove from RIGHT side when max capacity reached
        if (_waveform.length > maxBars) {
          _waveform.removeLast();
        }
      });

      // Always animate the sliding motion
      _slideController.forward().then((_) {
        _slideController.reset();
      });
    });
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55, // Accommodates up to 50px waves
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            // Buttery smooth slide with custom curve
            offset: Offset(_slideAnimation.value.clamp(-300.0, 0.0), 0),

            child: ListView.builder(
              reverse: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),

              // Performance optimizations
              cacheExtent: 500, // Cache more items for smooth scroll
              addRepaintBoundaries: false, // Reduce repaint boundaries
              addAutomaticKeepAlives: false, // Don't keep items alive

              itemCount: _waveform.length,
              itemBuilder: (context, index) {
                final barHeight = _waveform[index];
                final isActive = barHeight > flatHeight;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.4),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      // Smooth height animation with custom curve
                      duration: const Duration(milliseconds: 80), // Faster response
                      curve: Curves.easeOutCubic, // Smooth easing
                      tween: Tween(begin: flatHeight, end: barHeight),
                      builder: (context, animatedHeight, child) {
                        return Container(
                          width: 3,
                          height: animatedHeight,
                          decoration: BoxDecoration(
                            color: Color(0xFF8C571F),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


// class ChatGPTScrollingWaveform extends StatefulWidget {
//   final bool isSpeech;
//   final double rms;
//
//   const ChatGPTScrollingWaveform({
//     Key? key,
//     required this.isSpeech,
//     required this.rms,
//   }) : super(key: key);
//
//   @override
//   State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
// }
//
// class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform>
//     with SingleTickerProviderStateMixin {
//   final int maxBars = 30;
//   final Duration frameRate = Duration(milliseconds: 80);
//   final double flatHeight = 2;
//   final List<double> _waveform = [];
//
//   Timer? _waveformTimer;
//   late AnimationController _slideController;
//   late Animation<double> _slideAnimation;
//
//   // 🔄 Speech continuity tracking
//   bool _wasRecentlySpeaking = false;
//   DateTime _lastSpeechTime = DateTime.now();
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Start with empty waveform
//     _waveform.clear();
//
//     // Setup slide animation for smooth right-to-left movement
//     _slideController = AnimationController(
//       duration: frameRate,
//       vsync: this,
//     );
//
//     _slideAnimation = Tween<double>(
//       begin: 0.0,
//       end: 6.0, // Distance each bar slides (width + padding)
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.linear,
//     ));
//
//     _startWaveformLoop();
//   }
//
//   void _startWaveformLoop() {
//     _waveformTimer = Timer.periodic(frameRate, (_) {
//       if (!mounted) return;
//
//       final now = DateTime.now();
//
//       // 🎯 STRICT DETECTION: Both isSpeech AND significant RMS required
//       const double minRmsThreshold = 0.015; // Higher threshold to avoid background noise
//       bool actualSpeechDetected = widget.isSpeech && widget.rms > minRmsThreshold;
//
//       // 🔄 Update speech tracking
//       if (actualSpeechDetected) {
//         _lastSpeechTime = now;
//         _wasRecentlySpeaking = true;
//       }
//
//       // 📏 Grace period for continuity (short to avoid background noise)
//       bool withinGracePeriod = now.difference(_lastSpeechTime) < Duration(milliseconds: 150);
//
//       // 🎯 Show waves if currently speaking OR within grace period
//       bool shouldShowWaves = actualSpeechDetected || (_wasRecentlySpeaking && withinGracePeriod);
//
//       if (!withinGracePeriod) {
//         _wasRecentlySpeaking = false;
//       }
//
//       double nextHeight;
//
//       if (shouldShowWaves) {
//         double effectiveRms = widget.rms;
//         // During grace period, use slightly reduced height if no current speech
//         if (!actualSpeechDetected && _wasRecentlySpeaking) {
//           effectiveRms = effectiveRms * 0.8; // Slight fade during gap
//         }
//         nextHeight = (pow(effectiveRms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0);
//       } else {
//         // 🔇 IMMEDIATE FLAT - no background waves
//         nextHeight = flatHeight;
//       }
//
//       setState(() {
//         // Add new bar on the LEFT side (index 0)
//         _waveform.insert(0, nextHeight);
//         // Remove from RIGHT side when max capacity reached
//         if (_waveform.length > maxBars) {
//           _waveform.removeLast();
//         }
//       });
//
//       // Always animate the sliding motion
//       _slideController.forward().then((_) {
//         _slideController.reset();
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _waveformTimer?.cancel();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 40, // Reasonable height for waveform
//       child: AnimatedBuilder(
//         animation: _slideAnimation,
//         builder: (context, child) {
//           return Transform.translate(
//             // Buttery smooth slide with custom curve
//             offset: Offset(_slideAnimation.value.clamp(-300.0, 0.0), 0),
//
//             child: ListView.builder(
//               reverse: true,
//               scrollDirection: Axis.horizontal,
//               physics: const NeverScrollableScrollPhysics(),
//
//               // Performance optimizations
//               cacheExtent: 500, // Cache more items for smooth scroll
//               addRepaintBoundaries: false, // Reduce repaint boundaries
//               addAutomaticKeepAlives: false, // Don't keep items alive
//
//               itemCount: _waveform.length,
//               itemBuilder: (context, index) {
//                 final barHeight = _waveform[index];
//                 final isActive = barHeight > flatHeight;
//
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 3.4),
//                   child: Center(
//                     child: TweenAnimationBuilder<double>(
//                       // Smooth height animation with custom curve
//                       duration: const Duration(milliseconds: 80), // Faster response
//                       curve: Curves.easeOutCubic, // Smooth easing
//                       tween: Tween(begin: flatHeight, end: barHeight),
//                       builder: (context, animatedHeight, child) {
//                         return Container(
//                           width: 3,
//                           height: animatedHeight,
//                           decoration: BoxDecoration(
//                             color: Color(0xFF8C571F),
//                             borderRadius: BorderRadius.circular(32),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class ChatGPTScrollingWaveform extends StatefulWidget {
//   final bool isSpeech;
//   final double rms;
//
//   const ChatGPTScrollingWaveform({
//     Key? key,
//     required this.isSpeech,
//     required this.rms,
//   }) : super(key: key);
//
//   @override
//   State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
// }
//
// class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform>
//     with SingleTickerProviderStateMixin {
//   final int maxBars = 30;
//   final Duration frameRate = Duration(milliseconds: 80);
//   final double flatHeight = 2;
//   final List<double> _waveform = [];
//
//   Timer? _waveformTimer;
//   late AnimationController _slideController;
//   late Animation<double> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Start with empty waveform
//     _waveform.clear();
//
//     // Setup slide animation for smooth right-to-left movement
//     _slideController = AnimationController(
//       duration: frameRate,
//       vsync: this,
//     );
//
//     _slideAnimation = Tween<double>(
//       begin: 0.0,
//       end: 6.0, // Distance each bar slides (width + padding)
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.linear,
//     ));
//
//     _startWaveformLoop();
//   }
//
//   // void _startWaveformLoop() {
//   //   _waveformTimer = Timer.periodic(frameRate, (_) {
//   //     if (!mounted) return;
//   //
//   //     // Better sensitivity for low RMS, full height only for loud speech
//   //     double nextHeight = widget.isSpeech
//   //         ? (pow(widget.rms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0)
//   //         : flatHeight;
//   //
//   //     setState(() {
//   //       // Add new bar on the LEFT side (index 0)
//   //       _waveform.insert(0, nextHeight);
//   //       // Remove from RIGHT side when max capacity reached
//   //       if (_waveform.length > maxBars) {
//   //         _waveform.removeLast();
//   //       }
//   //     });
//   //
//   //     // Always animate the sliding motion
//   //     _slideController.forward().then((_) {
//   //       _slideController.reset();
//   //     });
//   //   });
//   // }
//
//
//
//   void _startWaveformLoop() {
//     _waveformTimer = Timer.periodic(frameRate, (_) {
//       if (!mounted) return;
//
//       // 🎯 CRITICAL: Check both isSpeech AND actual RMS level
//       const double minRmsThreshold = 0.01; // Adjust this based on your RMS values
//       bool actuallyDetectingAudio = widget.isSpeech && widget.rms > minRmsThreshold;
//
//       double nextHeight = actuallyDetectingAudio
//           ? (pow(widget.rms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0)
//           : flatHeight;
//
//       setState(() {
//         // Add new bar on the LEFT side (index 0)
//         _waveform.insert(0, nextHeight);
//         // Remove from RIGHT side when max capacity reached
//         if (_waveform.length > maxBars) {
//           _waveform.removeLast();
//         }
//       });
//
//       // Always animate the sliding motion
//       _slideController.forward().then((_) {
//         _slideController.reset();
//       });
//     });
//   }
//
//
//
//
//
//   // void _startWaveformLoop() {
//   //   _waveformTimer = Timer.periodic(frameRate, (_) {
//   //     if (!mounted) return;
//   //
//   //     // Normalize RMS
//   //     final normalizedRms = (widget.rms / 0.04).clamp(0.0, 1.0);
//   //
//   //     // Nonlinear scale for better visual effect
//   //     double nextHeight = widget.isSpeech
//   //         ? (pow(normalizedRms + 0.03, 0.68).toDouble() * 85 + 12).clamp(8.0, 35.0)
//   //         : flatHeight;
//   //
//   //     setState(() {
//   //       _waveform.insert(0, nextHeight);
//   //       if (_waveform.length > maxBars) {
//   //         _waveform.removeLast();
//   //       }
//   //     });
//   //
//   //     _slideController.forward().then((_) => _slideController.reset());
//   //   });
//   // }
//
//
//
//
//
//
//   //
//   // void _startWaveformLoop() {
//   //   _waveformTimer = Timer.periodic(frameRate, (_) {
//   //     if (!mounted) return;
//   //
//   //    // ALWAYS add new bars, but height depends on isSpeech
//   //    //  double nextHeight = widget.isSpeech
//   //    //      ? (widget.rms * 350).clamp(10.0, 40.0)  // Animate with RMS when speaking
//   //    //      : flatHeight;
//   //     final scaled = pow(widget.rms + 0.02, 0.72).toDouble();
//   //     double nextHeight = (scaled * 65).clamp(flatHeight, 35.0);
//   //
//   //     //  double nextHeight = widget.isSpeech
//   //    //      ? (pow(widget.rms + 0.01, 0.72).toDouble() * 40 + 10).clamp(6.0, 30.0)
//   //    //      : flatHeight;
//   //
//   //
//   //
//   //
//   //     // Flat when not speaking
//   //
//   //     setState(() {
//   //       // Add new bar on the LEFT side (index 0)
//   //       _waveform.insert(0, nextHeight);
//   //       // Remove from RIGHT side when max capacity reached
//   //       if (_waveform.length > maxBars) {
//   //         _waveform.removeLast();
//   //       }
//   //     });
//   //
//   //     // Always animate the sliding motion
//   //     _slideController.forward().then((_) {
//   //       _slideController.reset();
//   //     });
//   //   });
//   // }
//
//
//   @override
//   void dispose() {
//     _waveformTimer?.cancel();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 40, // Reasonable height for waveform
//       child: // Ultra Smooth Waveform Animation with Multiple Optimizations
//
//       AnimatedBuilder(
//         animation: _slideAnimation,
//         builder: (context, child) {
//           return Transform.translate(
//             // Buttery smooth slide with custom curve
//             offset: Offset(_slideAnimation.value.clamp(-300.0, 0.0), 0),
//
//             child: ListView.builder(
//               reverse: true,
//               scrollDirection: Axis.horizontal,
//               physics: const NeverScrollableScrollPhysics(),
//
//               // Performance optimizations
//               cacheExtent: 500, // Cache more items for smooth scroll
//               addRepaintBoundaries: false, // Reduce repaint boundaries
//               addAutomaticKeepAlives: false, // Don't keep items alive
//
//               itemCount: _waveform.length,
//               itemBuilder: (context, index) {
//                 final barHeight = _waveform[index];
//                 final isActive = barHeight > flatHeight;
//
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 3.4),
//                   child: Center(
//                     child: TweenAnimationBuilder<double>(
//                       // Smooth height animation with custom curve
//                       duration: const Duration(milliseconds: 80), // Faster response
//                       curve: Curves.easeOutCubic, // Smooth easing
//                       tween: Tween(begin: flatHeight, end: barHeight),
//                       builder: (context, animatedHeight, child) {
//                         return Container(
//                           width: 3,
//                           height: animatedHeight,
//                           decoration: BoxDecoration(
//                             color: Color(0xFF8C571F),
//                             borderRadius: BorderRadius.circular(32),
//
//                             // Add subtle shadow for depth
//                             // boxShadow: isActive ? [
//                             //   BoxShadow(
//                             //     color: Colors.white.withOpacity(0.3),
//                             //     blurRadius: 2,
//                             //     spreadRadius: 0.5,
//                             //   )
//                             // ] : null,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 );
//               },
//
//                 // itemBuilder: (context, index) {
//                 //   final barHeight = _waveform[index];
//                 //
//                 //   return TweenAnimationBuilder<double>(
//                 //     key: ValueKey(index),
//                 //     tween: Tween(begin: flatHeight, end: barHeight),
//                 //     duration: const Duration(milliseconds: 1200),
//                 //     curve: Curves.easeOutBack, // 🔥 THIS is the curvy feel
//                 //     builder: (context, animatedHeight, child) {
//                 //       return Padding(
//                 //         padding: const EdgeInsets.symmetric(horizontal: 2.8),
//                 //         child: SlideTransition(
//                 //           position: Tween<Offset>(
//                 //             begin: const Offset(0.6, 0), // 👈 slide in from right
//                 //             end: Offset.zero,
//                 //           ).animate(
//                 //             CurvedAnimation(
//                 //               parent: _slideController,
//                 //               curve: Curves.easeOutCubic,
//                 //             ),
//                 //           ),
//                 //           child: Column(
//                 //             mainAxisAlignment: MainAxisAlignment.center,
//                 //             children: [
//                 //             Container(
//                 //             width: 2,
//                 //             height: animatedHeight,
//                 //             decoration: BoxDecoration(
//                 //               color: Colors.black,
//                 //               borderRadius: BorderRadius.circular(100),
//                 //             ),
//                 //           ),
//                 //             ],
//                 //           ),
//                 //         ),
//                 //       );
//                 //     },
//                 //   );
//                 // }
//
//             ),
//           );
//         },
//       )
//
//     );
//   }
//
//
// }


class BlackSlidingWaveform extends StatefulWidget {
  final bool isSpeaking;
  final double rms;
  final bool isActive;

  const BlackSlidingWaveform({
    super.key,
    required this.isSpeaking,
    required this.rms,
    required this.isActive,
  });

  @override
  State<BlackSlidingWaveform> createState() => _BlackSlidingWaveformState();
}

class _BlackSlidingWaveformState extends State<BlackSlidingWaveform> {
  final ScrollController _scrollController = ScrollController();
  final List<double> _bars = [];

  final double flatHeight = 6;
  final int maxBars = 100;
  final Duration frameRate = Duration(milliseconds: 60);

  Timer? _timer;
  bool _waveStarted = false;

  @override
  void initState() {
    super.initState();

    _bars.addAll(List.generate(maxBars, (_) => flatHeight));

    _timer = Timer.periodic(frameRate, (_) {
      if (!mounted || !widget.isActive) return;

      if (!_waveStarted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _waveStarted = true);
        });
        return;
      }

      final nextHeight = widget.isSpeaking
          ? (widget.rms * 350).clamp(10.0, 60.0)
          : flatHeight;

      setState(() {
        _bars.add(nextHeight);
        if (_bars.length > 250) {
          _bars.removeRange(0, _bars.length - 150);
        }
      });

      // Auto-scroll to right so content appears moving left
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 36,
        color: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bars.length,
          itemBuilder: (context, index) {
            final barHeight = _waveStarted ? _bars[index] : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AnimatedContainer(
                duration: frameRate,
                width: 3,
                height: barHeight.toDouble(),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ConvexTopClipper extends CustomClipper<Path> {
  final double modulation; // 0.0 (flat) to 1.0 (fully curved)

  ConvexTopClipper({required this.modulation});

  @override
  // Path getClip(Size size) {
  //   final path = Path();
  //
  //   // Aggressive scaling with ease-out curve
  //   double t = Curves.easeOut.transform(modulation);
  //
  //   // Increase dip intensity
  //   double dip = lerpDouble(0, size.height * 0.3, t)!;
  //
  //   // Lower side anchors more at high modulation
  //   double leftY = lerpDouble(size.height * 0.2, size.height * 0.05, t)!;
  //   double rightY = leftY;
  //
  //   path.moveTo(-1, size.height);
  //   path.lineTo(0, leftY);
  //   path.quadraticBezierTo(
  //     size.width * 0.5, 0 - dip, // deeper dip
  //     size.width, rightY,
  //   );
  //   path.lineTo(size.width, size.height);
  //   path.close();
  //
  //   return path;
  // }

  @override
  Path getClip(Size size) {
    final path = Path();

    // Aggressively boost modulation with exponential scale
    double boosted = pow(modulation + 0.1, 1.6).clamp(0.0, 1.0).toDouble();

    // Deeper dip at center (up to 45% of height)
    double dip = lerpDouble(0, size.height * 0.45, boosted)!;

    // Pull side anchors higher for a tighter curve
    double sideAnchor = lerpDouble(size.height * 0.25, size.height * 0.02, boosted)!;

    path.moveTo(-1, size.height);
    path.lineTo(0, sideAnchor);
    path.quadraticBezierTo(
      size.width * 0.5, -dip,  // aggressive negative dip
      size.width, sideAnchor,
    );
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }


  @override
  bool shouldReclip(covariant ConvexTopClipper oldClipper) =>
      oldClipper.modulation != modulation;
}


// class ConvexTopClipper extends CustomClipper<Path> {
//   final double modulation; // 0.0 (flat) se 1.0 (max curve)
//
//   ConvexTopClipper({required this.modulation});
//
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//
//     // Curve ka dip: RMS ke basis pe change hota hai
//     double dip = lerpDouble(0, size.height * 0.22, modulation)!;
//     double leftY = lerpDouble(size.height * 0.19, size.height * 0.08, modulation)!;
//     double rightY = lerpDouble(size.height * 0.19, size.height * 0.08, modulation)!;
//
//     path.moveTo(-1, size.height);
//     path.lineTo(0, leftY);
//     path.quadraticBezierTo(
//       size.width / 2, 0 - dip,
//       size.width, rightY,
//     );
//     path.lineTo(size.width, size.height);
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(covariant ConvexTopClipper oldClipper) =>
//       oldClipper.modulation != modulation;
// }


// class ConvexTopClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//
//     // Start from bottom left
//     path.moveTo(0, size.height);
//
//     // Left side up to higher (e.g. 10% of height for deeper dip)
//     path.lineTo(0, size.height * 0.13);
//
//     // Big convex curve (peak even higher)
//     path.quadraticBezierTo(
//       size.width / 2, -size.height * 0.16,  // Move control point higher for more dip
//       size.width, size.height * 0.13,
//     );
//
//     // Right side down to bottom right
//     path.lineTo(size.width, size.height);
//
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }


class ButteryMeshPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Color> colors;
  final bool showShapes;

  ButteryMeshPainter({
    required this.positions,
    required this.colors,
    this.showShapes = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create visible buttery mesh shapes
    for (int i = 0; i < positions.length; i++) {
      final position = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height,
      );

      // Create organic blob shapes with higher opacity
      _drawButteryBlob(canvas, size, position, colors[i], i);
    }
  }

  void _drawButteryBlob(
      Canvas canvas,
      Size size,
      Offset position,
      Color color,
      int index,
      ) {
    // JSON se extract kiye gaye exact shapes for each layer
    List<List<List<double>>> meshShapes = [
      // Layer 1 - JSON shape vertices
      [
        [150.84, 16.74],
        [254.8, 7.42],
        [313.45, 111.32],
        [277.6, 238.02],
        [150.84, 229.34],
        [62.09, 200.03],
        [0.45, 111.32],
        [83.11, 43.63],
      ],
      // Layer 2 - JSON shape vertices
      [
        [198.8, 51.91],
        [336.87, 63.84],
        [383.95, 201.92],
        [382.4, 385.51],
        [198.8, 357.86],
        [34.99, 365.73],
        [59.44, 201.92],
        [12.92, 16.04],
      ],
      // Layer 3 - JSON shape vertices
      [
        [220.19, 28.25],
        [380.16, 52.67],
        [381.77, 212.27],
        [417.19, 408.82],
        [220.19, 363.9],
        [46.98, 385.09],
        [15.55, 212.27],
        [26.51, 19.03],
      ],
      // Layer 4 - JSON shape vertices
      [
        [305.04, 4.98],
        [456.78, 92.24],
        [586.41, 243.98],
        [508.63, 447.58],
        [305.04, 610.61],
        [128.71, 420.31],
        [0.45, 243.98],
        [102.29, 41.23],
      ],
    ];

    // Use the corresponding mesh shape for this layer
    final vertices = meshShapes[index % meshShapes.length];
    final path = Path();

    // Scale and position the mesh shape
    final scaleX = size.width * 0.3 / 375; // Scale from original 375px width
    final scaleY = size.height * 0.6 / 812; // Scale from original 812px height

    for (int i = 0; i < vertices.length; i++) {
      final x =
          position.dx +
              (vertices[i][0] - 187.5) * scaleX; // Center around position
      final y =
          position.dy +
              (vertices[i][1] - 400) * scaleY; // Center around position

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Add smooth curves between points (JSON has bezier curves)
        final prevX = position.dx + (vertices[i - 1][0] - 187.5) * scaleX;
        final prevY = position.dy + (vertices[i - 1][1] - 400) * scaleY;
        final controlX = (prevX + x) / 2 + (math.sin(i * 0.5) * 5);
        final controlY = (prevY + y) / 2 + (math.cos(i * 0.5) * 5);

        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }
    path.close();

    // Multiple gradient layers for buttery effect - higher opacity for visibility
    final paint =
    Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          color.withOpacity(0.8), // Higher opacity for better visibility
          color.withOpacity(0.6),
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: position, radius: size.width * 0.3),
      );

    canvas.drawPath(path, paint);

    // Add soft glow effect around the mesh shape
    final glowPaint =
    Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.5,
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.2),
          color.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: position, radius: size.width * 0.4),
      );

    canvas.drawCircle(position, size.width * 0.4, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class AdvancedSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const AdvancedSplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<AdvancedSplashScreen> createState() => _AdvancedSplashScreenState();
}

class _AdvancedSplashScreenState extends State<AdvancedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _primaryController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startSequence() async {
    // Start particle animation
    _particleController.repeat();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Start main logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _primaryController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Navigate after everything is done
    await Future.delayed(const Duration(milliseconds: 3500));
    _navigateToNext();
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Particle Background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Container
                  AnimatedBuilder(
                    animation: _primaryController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * math.pi * 2,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00F5FF),
                                          Color(0xFF0099FF),
                                          Color(0xFF6600FF),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F5FF).withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.rocket_launch,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Animated Text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textController.value,
                          child: Column(
                            children: [
                              const Text(
                                'AWESOME APP',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Loading Experience...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Animated Progress Bar
                  AnimatedBuilder(
                    animation: _primaryController,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            stops: [0.0, _primaryController.value, _primaryController.value, 1.0],
                            colors: const [
                              Color(0xFF00F5FF),
                              Color(0xFF00F5FF),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = (animationValue + i * 0.1) % 1.0;

      final particleX = x + math.sin(animationValue * 2 * math.pi + i) * 20;
      final particleY = y + math.cos(animationValue * 2 * math.pi + i) * 20;

      final opacity = (math.sin(animationValue * 4 * math.pi + i) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity * 0.3);

      canvas.drawCircle(
        Offset(particleX, particleY),
        2.0 + math.sin(animationValue * 3 * math.pi + i) * 1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



class HeartbeatGlowBorderPainter extends CustomPainter {
  final double glowIntensity;
  final Color borderColor;
  final double borderWidth;
  final double modulation;

  HeartbeatGlowBorderPainter({
    required this.glowIntensity,
    required this.borderColor,
    required this.borderWidth,
    required this.modulation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = ConvexTopClipper(modulation: modulation).getClip(size);

    // Draw Glow (multiple blurred strokes for strong glow)
    for (double i = 0; i < 5; i++) {
      final glowPaint = Paint()
        ..color = borderColor.withOpacity(0.06 * (1 - i / 6) * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 12 + i * 4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + i * 2.5);
      canvas.drawPath(path, glowPaint);
    }

    // Draw Border (top and solid)
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.60 + 0.20 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatGlowBorderPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity ||
          oldDelegate.borderColor != borderColor ||
          oldDelegate.borderWidth != borderWidth ||
          oldDelegate.modulation != modulation;
}



// class OverlayContainerClipper extends CustomClipper<Path> {
//   final double rms;
//   final bool isSpeaking;
//
//   OverlayContainerClipper({required this.rms, required this.isSpeaking});
//
//   @override
//   Path getClip(Size size) {
//     final width = size.width;
//     final height = size.height;
//     final path = Path();
//
//     // Only animate when isSpeaking is true
//     final animatedRms = isSpeaking ? rms : 0.0;
//
//     // Normal base height remains same, add height based on RMS
//     final baseHeight = 90.0; // Normal height
//     final additionalHeight = (animatedRms * 200).clamp(0.0, 150.0); // Increased range
//     final curveHeight = baseHeight - additionalHeight; // Subtract to go UP more
//
//     final basePeakHeight = 15.0; // Normal peak height
//     final additionalPeakHeight = (animatedRms * 100).clamp(0.0, 60.0); // Increased range
//     final peakHeight = basePeakHeight - additionalPeakHeight; // Subtract to go UP more
//
//     path.moveTo(0, height);
//     path.lineTo(0, curveHeight);
//
//     path.quadraticBezierTo(
//       width / 2,
//       peakHeight,
//       width,
//       curveHeight,
//     );
//
//     path.lineTo(width, height);
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(covariant OverlayContainerClipper oldClipper) {
//     return oldClipper.rms != rms || oldClipper.isSpeaking != isSpeaking;
//   }
// }
// // Inner clipper - smaller and different curve
// class InnerOverlayContainerClipper extends CustomClipper<Path> {
//   final double rms;
//   final bool isSpeaking;
//
//   InnerOverlayContainerClipper({required this.rms, required this.isSpeaking});
//
//   @override
//   Path getClip(Size size) {
//     final width = size.width;
//     final height = size.height;
//     final path = Path();
//
//     // Only animate when isSpeaking is true
//     final animatedRms = isSpeaking ? rms : 0.0;
//
//     // Smaller curve that fits inside the outer one - HEIGHT INCREASES with RMS
//     final curveHeight = 110.0 - (animatedRms * 80).clamp(0.0, 25.0); // Subtract to go UP
//     final peakHeight = 35.0 - (animatedRms * 35).clamp(0.0, 20.0); // Subtract to go UP
//
//     path.moveTo(0, height);
//     path.lineTo(0, curveHeight);
//
//     path.quadraticBezierTo(
//       width / 2,
//       peakHeight,
//       width,
//       curveHeight,
//     );
//
//     path.lineTo(width, height);
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(covariant InnerOverlayContainerClipper oldClipper) {
//     return oldClipper.rms != rms || oldClipper.isSpeaking != isSpeaking;
//   }
// }