import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/colors.dart';
import '../../../services/theme_service.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/common_button.dart';

/// ------------------------------------------------------------
/// Shared look & feel
/// ------------------------------------------------------------
const _creamTop    = Color(0xFFF4E6D8);
const _creamMid    = Color(0xFFF6ECDF);
const _creamBottom = Color(0xFFF9F2E8);
const _brown       = Color(0xFF6A4B2E);
const _brownSoft   = Color(0xCC6A4B2E);
const _chipStroke  = Color(0xFFC8983B); // warm gold outline
const _cardBorder  = Color(0xFFC8C8C8);

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_creamTop, _creamMid, _creamBottom],
        ),
      ),
      child: CustomPaint(
        painter: _RadialGlowPainter(),
        child: child,
      ),
    );
  }
}

class _RadialGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const RadialGradient(
      center: Alignment(0.78, 0.88), radius: 0.9,
      colors: [Color(0x00FFFFFF), Color(0x11FFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.55, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// coin logo + progress at the very top
// class _TopBar extends StatelessWidget {
//   const _TopBar({required this.progress}); // 0..1
//   final double progress;
//
//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//       child: Column(
//         children: [
//           // coin/logo
//           SizedBox(
//             height: 44,
//             child: Center(
//               child: ClipOval(
//                 child: Container(
//                   width: 48, height: 48,
//                   child: Image.asset(
//                     'assets/images/ying yang.png', // put your small coin here
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 26),
//           // thin progress
//           SizedBox(
//             height: 6,
//             child: Stack(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 LayoutBuilder(
//                   builder: (_, c) {
//                     final pw = c.maxWidth * progress;
//                     return AnimatedContainer(
//                       duration: const Duration(milliseconds: 350),
//                       curve: Curves.easeOutCubic,
//                       width: pw,
//                       decoration: BoxDecoration(
//                         color: _brown.withOpacity(0.8),
//                         borderRadius: BorderRadius.circular(3),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: (w * 0.04).clamp(12, 18).toDouble()),
//         ],
//       ),
//     );
//   }
// }

/// ------------------------------------------------------------
/// Screen 1: Financial knowledge (three cards)
/// ------------------------------------------------------------
class OnboardingKnowledgeScreen extends StatefulWidget {
  const OnboardingKnowledgeScreen({super.key});

  @override
  State<OnboardingKnowledgeScreen> createState() =>
      _OnboardingKnowledgeScreenState();
}

class _OnboardingKnowledgeScreenState extends State<OnboardingKnowledgeScreen> {
  bool _navigating = false;

  Future<void> _goNext() async {
    if (_navigating) return;
    HapticFeedback.selectionClick();
    setState(() => _navigating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const OnboardingTopicsScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    ).then((_) => setState(() => _navigating = false));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width, h = mq.size.height;
    final scale = (w / 390).clamp(0.85, 1.2);

    final titleStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.bold,
      color: AppColors.black,
      fontSize: 20,
      letterSpacing: -0.2,
    );
    final cardTitle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: AppColors.black,

    );
    final cardSub = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: Color(0xff373737),
    );
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(progress: 0.18), // first screen progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
              child: Text(
                'How would you describe your\nfinancial knowledge?',
                style: titleStyle,
              ),
            ),
            SizedBox(height: (h * 0.02).clamp(8, 16)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _LevelCard(
                    title: 'Beginner',
                    subtitle:
                    "I’m just getting started and want the basics explained clearly.",
                    titleStyle: cardTitle,
                    subStyle: cardSub,
                    onTap: _goNext,
                  ),
                  const SizedBox(height: 14),
                  _LevelCard(
                    title: 'Intermediate',
                    subtitle:
                    "I understand the fundamentals and want to grow my skills.",
                    titleStyle: cardTitle,
                    subStyle: cardSub,
                    onTap: _goNext,
                  ),
                  const SizedBox(height: 14),
                  _LevelCard(
                    title: 'Expert',
                    subtitle:
                    "I’m confident in my knowledge and want advanced insights.",
                    titleStyle: cardTitle,
                    subStyle: cardSub,
                    onTap: _goNext,
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
//
// class _LevelCard extends StatefulWidget {
//   const _LevelCard({
//     required this.title,
//     required this.subtitle,
//     required this.titleStyle,
//     required this.subStyle,
//     required this.onTap,
//   });
//
//   final String title;
//   final String subtitle;
//   final TextStyle titleStyle;
//   final TextStyle subStyle;
//   final VoidCallback onTap;
//
//   @override
//   State<_LevelCard> createState() => _LevelCardState();
// }
//
// class _LevelCardState extends State<_LevelCard> {
//   bool _pressed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent, // ✅ Transparent for gradient to show
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(7),
//         side: const BorderSide(color: _cardBorder, width: 2),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTapDown: (_) => setState(() => _pressed = true),
//         onTapCancel: () => setState(() => _pressed = false),
//         onTap: () {
//           setState(() => _pressed = false);
//           widget.onTap();
//         },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 120),
//           padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//           decoration: BoxDecoration(
//             // ✅ GRADIENT ADDED
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFFF1EAE4), // 0% - Peachy beige
//                 Color(0xFFFFFFFF), // 100% - White
//               ],
//               stops: [0.0, 1.0],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: _pressed
//                 ? [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))]
//                 : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(widget.title, style: widget.titleStyle),
//               const SizedBox(height: 8),
//               Text(widget.subtitle, style: widget.subStyle),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

/// ------------------------------------------------------------
/// Screen 2: Topics chips, validation + disabled Continue
/// ------------------------------------------------------------
class OnboardingTopicsScreen extends StatefulWidget {
  const OnboardingTopicsScreen({super.key});

  @override
  State<OnboardingTopicsScreen> createState() => _OnboardingTopicsScreenState();
}

class _OnboardingTopicsScreenState extends State<OnboardingTopicsScreen> {
  static const _topics = [
    'Investment Research',
    'Tax Planning',
    'Insurance Planning',
    'Portfolio Analysis',
    'Budget Planning',
    'Loan Planning',
    'Credit Card',
    'Investment & Wealth',
    'Tax & Compliance',
  ];

  final Set<String> _selected = {};
bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width, h = mq.size.height;
    final scale = (w / 390).clamp(0.85, 1.2);

    final titleStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      color: AppColors.black,
      fontSize: (26 * scale).clamp(22, 30).toDouble(),
      height: 1.25,
      letterSpacing: -0.2,
    );

    final subTextStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: (13.5 * scale).clamp(12, 15),
      color: _brown.withOpacity(0.75),
    );

    final canContinue = _selected.length >= 3;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;


    Future<void> _onContinue() async {
      if (_selected.length < 3 || isLoading) return;

      HapticFeedback.mediumImpact();
      setState(() => isLoading = true);

      // (optional) tiny UX delay to feel responsive
      await Future.delayed(const Duration(milliseconds: 200));

      final topics = _selected.toList(growable: false);

      // Navigator:
      await Navigator.of(context).push(
        // MaterialPageRoute(
        //   builder: (_) => StrongPointsScreen(
        //     topics: topics,          // ✅ only selected chips
        //     initialProgress: 0.55,   // ✅ matches your mock's progress step
        //   ),
        // ),
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) =>  StrongPointsScreen(
                topics: topics,          // ✅ only selected chips
                initialProgress: 0.55,   // ✅ matches your mock's progress step
              ),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );

      if (mounted) setState(() => isLoading = false);
    }



    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(progress: 0.42), // progressed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 16),
              child: Text('How can Vitty help you?', style: titleStyle),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: Wrap(
                    spacing: 11,
                    runSpacing: 16,
                    children: _topics.map((t) {
                      final selected = _selected.contains(t);
                      return _TopicChip(
                        label: t,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selected.remove(t);
                            } else {
                              _selected.add(t);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Divider(
              color: Colors.grey.withOpacity(0.4),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Please select at least 3 topics to continue',
                    textAlign: TextAlign.center,
                    style: subTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: canContinue ? 1.0 : 0.5,
                    child:
                    // ElevatedButton(
                    //   onPressed: canContinue ? () {
                    //     HapticFeedback.mediumImpact();
                    //     // TODO: proceed to next onboarding step
                    //   } : null,
                    //   style: ElevatedButton.styleFrom(
                    //     elevation: 0,
                    //     backgroundColor: _brown,
                    //     disabledBackgroundColor: const Color(0xFFB0B0B0),
                    //     foregroundColor: Colors.white,
                    //     padding: const EdgeInsets.symmetric(vertical: 14),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //   ),
                    //   child: const Text(
                    //     'Continue',
                    //     style: TextStyle(
                    //       fontFamily: 'DM Sans',
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),
                    CommonButton(
                      label: 'Continue',
                       onPressed: canContinue ? _onContinue : null, // ✅ guard

                      child: isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : null,
                    ),
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

// class _TopicChip extends StatelessWidget {
//   const _TopicChip({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//     this.radius = 16, // 👈 tighter corners; use 8 for even squarer
//   });
//
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//   final double radius;
//
//   @override
//   Widget build(BuildContext context) {
//     final shape = RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(radius),
//       side: BorderSide(
//         style: BorderStyle.solid,
//         color: selected ? const Color(0xFFC8983B) : _chipStroke,
//         width: 1.2,
//       ),
//     );
//
//     return Material(
//       color: selected ? const Color(0xFFFCEFD4) : Colors.transparent,
//       shape: shape,
//       child: InkWell(
//         customBorder: shape, // ✅ ripple matches new shape
//         onTap: onTap,
//         child: const Padding(
//           // keep spacing as-is; tweak if needed
//           padding: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
//           child: _ChipText(),
//         ),
//       ),
//     );
//   }
// }

class _ChipText extends StatelessWidget {
  const _ChipText();

  @override
  Widget build(BuildContext context) {
    return Text(
      // label injected via parent; we preserve your typography
      (context.findAncestorWidgetOfExactType<_TopicChip>()!).label,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontWeight: FontWeight.w500, // slightly firmer for crisp chip text
        fontSize: 14,
        color: AppColors.black,
        height: 1.0,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}


























const _gold     = Color(0xFFC8A355); // button + progress
const _goldLine = Color(0xFFB8893C); // chip outline
const _textDark = Color(0xFF121212);
const _chipFill = Color(0x0FC8A355);
const _track    = Color(0xFFE9E6E1);

TextStyle _titleStyle(double scale) => TextStyle(
  fontFamily: 'DM Sans',
  fontWeight: FontWeight.bold,
  color: AppColors.black,
  fontSize: 20,
  height: 1.25,
  letterSpacing: -0.2,
);





class StrongPointsScreen extends StatefulWidget {
  const StrongPointsScreen({
    super.key,
    required this.topics,         // <- topics selected in the previous step
    this.initialProgress = 0.55,  // as in your mock (thin bar ~ half)
  });

  final List<String> topics;
  final double initialProgress;

  @override
  State<StrongPointsScreen> createState() => _StrongPointsScreenState();
}

class _StrongPointsScreenState extends State<StrongPointsScreen> {
  late final Set<String> _selected; // strong points

  @override
  void initState() {
    super.initState();
    _selected = <String>{};
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final scale = (w / 390).clamp(0.85, 1.20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(progress: 0.72), // progressed
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('What are your strong points?', style: _titleStyle(scale)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: Wrap(
                    spacing: 11,
                    runSpacing: 16,
                    children: widget.topics.map((t) {
                      final selected = _selected.contains(t);
                      return _TopicChip(
                        label: t,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) {
                              _selected.remove(t);
                            } else {
                              _selected.add(t);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: CommonButton(
                label: 'Continue',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 280),
                      pageBuilder: (_, __, ___) => WeakPointsScreen(
                        topics: widget.topics,
                        strongPoints: _selected,
                        progressOnThisPage: (widget.initialProgress + 0.22).clamp(0, 1),
                      ),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =================================================================
/// SCREEN 2 — WEAK POINTS
/// Uses the same topic set. You can choose any (even overlapping,
/// if you want to allow—toggle logic is independent).
/// Progress advances relative to screen 1.
/// =================================================================

class WeakPointsScreen extends StatefulWidget {
  const WeakPointsScreen({
    super.key,
    required this.topics,
    required this.strongPoints,
    this.progressOnThisPage = 0.77,
  });

  final List<String> topics;
  final Set<String> strongPoints;     // in case you need it for submission
  final double progressOnThisPage;

  @override
  State<WeakPointsScreen> createState() => _WeakPointsScreenState();
}

class _WeakPointsScreenState extends State<WeakPointsScreen> {
  final Set<String> _weakSelected = {};

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final scale = (w / 390).clamp(0.85, 1.20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           _TopBar(progress: 0.95),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Text('What are your weak points?', style: _titleStyle(scale)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: Wrap(
                    spacing: 11,
                    runSpacing: 16,
                    children: widget.topics.map((t) {
                      final selected = _weakSelected.contains(t);
                      return _TopicChip(
                        label: t,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) {
                              _weakSelected.remove(t);
                            } else {
                              _weakSelected.add(t);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: CommonButton(
                label: 'Continue',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // TODO: Submit strong/weak selections to your service.
                  // print(widget.strongPoints);
                  // print(_weakSelected);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////















// Public entry ---------------------------------------------------------------
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});
  final VoidCallback? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pc = PageController();
  int _index = 0;

  // Progress per page (0..3)
  final List<double> _progressByIndex = const [0.18, 0.48, 0.78, 1.0];

  // Only steps 1..3 need "continue" gating
  late final List<ValueNotifier<bool>> _canContinue =
  List.generate(4, (_) => ValueNotifier(false));

  // Collected answers
  String? _knowledge;
  final Set<String> _interests = {};        // EXACTLY 3
  final Set<String> _strong = {};           // subset of _interests
  final Set<String> _weak = {};
  bool isLoading = false;// subset of _interests

  @override
  void dispose() {
    _pc.dispose();
    for (final n in _canContinue) n.dispose();
    super.dispose();
  }

  double get _progress =>
      _progressByIndex[_index.clamp(0, _progressByIndex.length - 1)];

  Future<void> _next() async {
    // step-0 me continue dikhaya hi nahi jaata
    if (_index > 0 && !_canContinue[_index].value) return;

    if (_index == 3) {
      widget.onFinished?.call();
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    await _pc.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNextImmediate() {
    // knowledge pick -> immediately go to interests
    _pc.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipOval(
                child: SizedBox(
                  width: 48, height: 48,
                  child: Image.asset('assets/images/ying yang.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _TopBar(progress: _progress),

            // common logo


            // pages -----------------------------------------------------------
            Expanded(
              child: PageView.builder(
                controller: _pc,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: 4,
                itemBuilder: (_, i) {
                  switch (i) {
                    case 0:
                      return _StepKnowledge(
                        canContinue: _canContinue[0], // unused but kept
                        onSelect: (level) {
                          _knowledge = level;
                          _goNextImmediate(); // no continue on this page
                        },
                      );
                    case 1:
                      return _StepInterests(
                        initialSelected: _interests,
                        canContinue: _canContinue[1],
                        onChanged: (sel) {
                          // enforce ≤3
                          _interests
                            ..clear()
                            ..addAll(sel.take(3));
                          // reset strong/weak if they contain removed ones
                          _strong.removeWhere((s) => !_interests.contains(s));
                          _weak.removeWhere((s) => !_interests.contains(s));
                        },
                      );
                    case 2:
                      return _StepPickFromChosen(
                        title: 'Pick your strong points',
                        options: _interests.toList(),
                        initialSelected: _strong,
                        canContinue: _canContinue[2],
                        onChanged: (sel) {
                          _strong
                            ..clear()
                            ..addAll(sel);
                        },
                      );
                    case 3:
                      return _StepPickFromChosen(
                        title: 'Pick your weak points',
                        options: _interests.toList(),
                        initialSelected: _weak,
                        canContinue: _canContinue[3],
                        onChanged: (sel) {
                          _weak
                            ..clear()
                            ..addAll(sel);
                        },
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),

            // bottom chrome ---------------------------------------------------


            // STEP-0: no Continue (auto next on tap)
            if (_index == 0)
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              //   child: Row(
              //     children: [
              //       IconButton(
              //         onPressed: null,
              //         icon: const Icon(Icons.arrow_back_ios_new_rounded),
              //       ),
              //       const Spacer(),
              //       Opacity(
              //         opacity: 0.4,
              //         child: _ctaButton(disabled: true, label: 'Continue'),
              //       ),
              //     ],
              //   ),
              // )
              SizedBox.shrink()
            else
              ValueListenableBuilder<bool>(
                valueListenable: _canContinue[_index],
                builder: (context, canContinue, _) {
                  return Column(
                    children: [
                      _index == 0 ? SizedBox.shrink() :  Divider(color: Colors.grey.withOpacity(0.35), height: 1),
                      Container(
                        // decoration: BoxDecoration(
                        //   color: Colors.white.withOpacity(0.5),
                        //   border: const Border(
                        //     top: BorderSide(color: Color(0x22FFFFFF)),
                        //   ),
                        // ),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Please select at least 3 topics to continue',
                              textAlign: TextAlign.center,
                             // style: subTextStyle,
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: canContinue ? 1.0 : 0.5,
                              child:
                              CommonButton(
                                label: 'Continue',
                                onPressed: canContinue ? _next : null,

                                child: isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  //   Padding(
                  //   padding:  EdgeInsets.symmetric(horizontal: 20),
                  //   child: Row(
                  //     children: [
                  //       // IconButton(
                  //       //   onPressed: _index == 0
                  //       //       ? null
                  //       //       : () => _pc.previousPage(
                  //       //     duration: const Duration(milliseconds: 200),
                  //       //     curve: Curves.easeOutCubic,
                  //       //   ),
                  //       //   icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  //       // ),
                  //       const Spacer(),
                  //       Opacity(
                  //         opacity: canContinue ? 1 : 0.5,
                  //         child: _ctaButton(
                  //           disabled: !canContinue,
                  //           label: _index == 3 ? 'Finish' : 'Continue',
                  //           onPressed: canContinue ? _next : null,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _ctaButton({required bool disabled, String label = 'Continue', VoidCallback? onPressed}) {
    return  CommonButton(
      label: 'Continue',
      onPressed: disabled ? null : onPressed,
    );
    //   FilledButton(
    //   onPressed: disabled ? null : onPressed,
    //   style: FilledButton.styleFrom(
    //     backgroundColor: _brown,
    //     padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    //   ),
    //   child: Text(
    //     label,
    //     style: const TextStyle(
    //       fontFamily: 'DM Sans',
    //       fontWeight: FontWeight.w700,
    //       fontSize: 16,
    //       color: Colors.white,
    //     ),
    //   ),
    // );

  }
}

// Top progress bar ------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                LayoutBuilder(
                  builder: (_, c) {
                    final pw = c.maxWidth * progress;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      width: pw,
                      decoration: BoxDecoration(
                        color: _brown.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: (w * 0.04).clamp(12, 18).toDouble()),
        ],
      ),
    );
  }
}

// Step 0: Knowledge (tap -> auto next) ---------------------------------------
class _StepKnowledge extends StatefulWidget {
  const _StepKnowledge({
    required this.canContinue,
    required this.onSelect,
  });

  final ValueNotifier<bool> canContinue; // unused (kept for API symmetry)
  final ValueChanged<String> onSelect;

  @override
  State<_StepKnowledge> createState() => _StepKnowledgeState();
}

class _StepKnowledgeState extends State<_StepKnowledge> {
  String? _selected;

  void _pick(String v) {
    setState(() => _selected = v);
    widget.onSelect(v); // parent will push next immediately
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      color: Colors.black,
      fontSize: 24,
      height: 1.25,
      letterSpacing: -0.2,
    );
    const cardTitle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      fontSize: 22,
      color: Colors.black,
    );
    const cardSub = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: Color(0xFF373737),
      height: 1.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text(
            'How would you describe your\nfinancial knowledge?',
            style: titleStyle,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [

              _LevelCard(
                title: 'Beginner',
                subtitle:
                'I’m just getting started and want the basics explained clearly.',
                titleStyle: cardTitle,
                subStyle: cardSub,
                selected: _selected == 'Beginner',
                onTap: () => _pick('Beginner'),
              ),
              const SizedBox(height: 14),
              _LevelCard(
                title: 'Intermediate',
                subtitle:
                'I understand the fundamentals and want to grow my skills.',
                titleStyle: cardTitle,
                subStyle: cardSub,
                selected: _selected == 'Intermediate',
                onTap: () => _pick('Intermediate'),
              ),
              const SizedBox(height: 14),
              _LevelCard(
                title: 'Expert',
                subtitle:
                'I’m confident in my knowledge and want advanced insights.',
                titleStyle: cardTitle,
                subStyle: cardSub,
                selected: _selected == 'Expert',
                onTap: () => _pick('Expert'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatefulWidget {
  const _LevelCard({
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subStyle,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subStyle;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1EAE4), Color(0xFFFFFFFF)],
              stops: [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? [const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            border: widget.selected ? Border.all(color: _brown, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: widget.titleStyle),
              const SizedBox(height: 8),
              Text(widget.subtitle, style: widget.subStyle),
            ],
          ),
        ),
      ),
    );
  }
}

// Step 1: Interests (select EXACTLY 3) ---------------------------------------
class _StepInterests extends StatefulWidget {
  const _StepInterests({
    required this.initialSelected,
    required this.canContinue,
    required this.onChanged,
  });

  final Set<String> initialSelected;
  final ValueNotifier<bool> canContinue;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_StepInterests> createState() => _StepInterestsState();
}

class _StepInterestsState extends State<_StepInterests> {
  static const _all = [
    'Investment Research',
    'Tax Planning',
    'Insurance Planning',
    'Portfolio Analysis',
    'Budget Planning',
    'Loan Planning',
    'Credit Card',
    'Investment & Wealth',
    'Tax & Compliance',
  ];

  late final Set<String> _selected = {...widget.initialSelected};

  @override
  void initState() {
    super.initState();
    widget.canContinue.value = _selected.length == 3;
  }

  void _toggle(String t) {
    setState(() {
      if (_selected.contains(t)) {
        _selected.remove(t);
      } else {
        if (_selected.length < 3) _selected.add(t); // cap 3
      }
      widget.canContinue.value = _selected.length == 3;
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    const title = TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700, fontSize: 22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('How can Vitty help you?', style: title),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _all.map((t) {
                final sel = _selected.contains(t);
                return _TopicChip(label: t, selected: sel, onTap: () => _toggle(t));
              }).toList(),
            ),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 8),
        //   child: Text(
        //     'Selected: ${_selected.length}/3',
        //     style: TextStyle(color: Colors.black.withOpacity(0.6)),
        //   ),
        // ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.radius = 16,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double radius;

  static const _gold = Color(0xFFCDA85A); // softer stroke
  static const _selectedBg = Color(0xFFFCEFD4);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: selected ? _gold : _gold, width: 1.2),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44), // Figma height
      child: Material(
        color: selected ? _selectedBg : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            // Figma-ish spacing
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500, // Medium/Semibold
                fontSize: 14,
                letterSpacing: 0.15,
                color: AppColors.black,
                height: 1.2, // tighter line box
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Step 2 & 3: Pick from chosen (Strong / Weak) — now using _TopPickChip
class _StepPickFromChosen extends StatefulWidget {
  const _StepPickFromChosen({
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.canContinue,
    required this.onChanged,
  });

  final String title;
  final List<String> options;               // from interests
  final Set<String> initialSelected;
  final ValueNotifier<bool> canContinue;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_StepPickFromChosen> createState() => _StepPickFromChosenState();
}

class _StepPickFromChosenState extends State<_StepPickFromChosen> {
  late final Set<String> _selected = {...widget.initialSelected};

  @override
  void initState() {
    super.initState();
    widget.canContinue.value = _selected.isNotEmpty; // ≥1 needed
  }

  void _toggle(String t) {
    setState(() {
      if (_selected.contains(t)) {
        _selected.remove(t);
      } else {
        _selected.add(t);
      }
      widget.canContinue.value = _selected.isNotEmpty;
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      fontSize: 22,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(widget.title, style: titleStyle),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.options.map((s) {
                final sel = _selected.contains(s);
                return _TopPickChip(
                  label: s,
                  selected: sel,
                  onTap: () => _toggle(s),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Reusable top-pick chip (same visual language as _TopicChip)
class _TopPickChip extends StatelessWidget {
  const _TopPickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.radius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: selected ? _brown : _chipStroke,
        width: 1.2,
      ),
    );

    return Material(
      color: selected ? const Color(0xFFFCEFD4) : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
