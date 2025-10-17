import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/colors.dart';
import '../../../services/theme_service.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/common_button.dart';


const _brown       = Color(0xFF6A4B2E);
const _chipStroke  = Color(0xFFC8983B); // warm gold outline
const _cardBorder  = Color(0xFFC8C8C8);


class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});
  final VoidCallback? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}


class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pc = PageController();
  int _index = 0;

  final List<double> _progressByIndex = const [0.18, 0.48, 0.78, 1.0];
  late final List<ValueNotifier<bool>> _canContinue =
  List.generate(4, (_) => ValueNotifier(false));

  String? _knowledge;
  final Set<String> _interests = {};
  final Set<String> _strong = {};
  final Set<String> _weak = {};
  bool isLoading = false;

  @override
  void dispose() {
    _pc.dispose();
    for (final n in _canContinue) n.dispose();
    super.dispose();
  }

  double get _progress =>
      _progressByIndex[_index.clamp(0, _progressByIndex.length - 1)];

  // ✅ Check if all interests are marked as strong
  bool get _allAreStrong => _strong.length == _interests.length && _interests.isNotEmpty;

  Future<void> _next() async {
    if (_index > 0 && !_canContinue[_index].value) return;

    // ✅ Step 2 (Strong Points): Skip to finish if all selected
    if (_index == 2 && _allAreStrong) {
      final next = Uri.encodeComponent('/premium');
      if (!mounted) return;
      debugPrint('✅ All interests marked as strong - skipping weak points');
      context.go('/biometric?next=$next');
      return;
    }

    // ✅ Step 3 (Weak Points): Normal finish
    if (_index == 3) {
      final next = Uri.encodeComponent('/premium');
      if (!mounted) return;
      context.go('/biometric?next=$next');
      return;
    }

    HapticFeedback.selectionClick();
    await _pc.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNextImmediate() {
    _pc.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.background;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
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
                      canContinue: _canContinue[0],
                      onSelect: (level) {
                        _knowledge = level;
                        _goNextImmediate();
                      },
                    );

                  case 1:
                    return _StepInterests(
                      initialSelected: _interests,
                      canContinue: _canContinue[1],
                      onChanged: (sel) {
                        _interests..clear()..addAll(sel);

                        // Cleanup strong/weak
                        _strong.removeWhere((s) => !_interests.contains(s));
                        _weak.removeWhere((s) => !_interests.contains(s));

                        _canContinue[1].value = _interests.length >= 3;

                        debugPrint('✅ Selected ${_interests.length} interests');
                      },
                    );

                  case 2:
                    return _StepPickFromChosen(
                      title: 'Pick your strong points',
                      options: _interests.toList(),
                      initialSelected: _strong,
                      canContinue: _canContinue[2],
                      onChanged: (sel) {
                        _strong..clear()..addAll(sel);
                        _canContinue[2].value = _strong.isNotEmpty;

                        // ✅ Remove from weak if added to strong
                        _weak.removeWhere((w) => _strong.contains(w));

                        debugPrint('✅ Strong: ${_strong.length}/${_interests.length}');
                        if (_allAreStrong) {
                          debugPrint('🎯 All are strong - will skip weak points');
                        }
                      },
                    );

                  case 3:
                  // ✅ Filter out strong points from options
                    final weakOptions = _interests
                        .where((interest) => !_strong.contains(interest))
                        .toList();

                    return _StepPickFromChosen(
                      title: 'Pick your weak points',
                      options: weakOptions, // ✅ Only non-strong interests
                      initialSelected: _weak,
                      canContinue: _canContinue[3],
                      onChanged: (sel) {
                        _weak..clear()..addAll(sel);
                        _canContinue[3].value = _weak.isNotEmpty;

                        debugPrint('✅ Weak: ${_weak.length} from ${weakOptions.length} available');
                      },
                    );

                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),

          // Bottom chrome
          if (_index == 0)
            const SizedBox.shrink()
          else
            ValueListenableBuilder<bool>(
              valueListenable: _canContinue[_index],
              builder: (context, canContinue, _) {
                // ✅ Dynamic button label
                String buttonLabel;
                if (_index == 3) {
                  buttonLabel = 'Finish';
                } else if (_index == 2 && _allAreStrong) {
                  buttonLabel = 'Finish'; // ✅ Skip weak points
                } else {
                  buttonLabel = 'Continue';
                }

                return Column(
                  children: [
                    Divider(color: Colors.grey.withOpacity(0.35), height: 1),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _index == 1
                                ? 'Please select at least 3 topics to continue'
                                : _index == 2 && _allAreStrong
                                ? 'All marked as strong! 🎉'
                                : '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.text
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: canContinue ? 1.0 : 0.5,
                            child: CommonButton(
                              label: buttonLabel, // ✅ Dynamic label
                              onPressed: canContinue ? _next : null,
                              child: isLoading
                                  ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              },
            ),
        ],
      ),
    );
  }
}


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
    HapticFeedback.mediumImpact();
    setState(() => _selected = v);
    widget.onSelect(v); // parent will push next immediately
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    var titleStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      color: theme.text,
      fontSize: 24,
      height: 1.25,
      letterSpacing: -0.2,
    );
    var cardTitle = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      fontSize: 22,
      color: theme.text,
    );
    var cardSub = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: theme.text,
      height: 1.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
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
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // gradient: const LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [Color(0xFFF1EAE4), Color(0xFFFFFFFF)],
            //   stops: [0.0, 1.0],
            // ),
            gradient: appBackgroundGradients(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? [const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            border: widget.selected ? Border.all(color: theme.border, width: 2) : null,
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

LinearGradient appBackgroundGradients(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (!isDark) {
    // LIGHT (tumhara wala)
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF1EAE4), Color(0xFFFFFFFF)],
      stops: [0.0, 1.0],
    );
  }

  // DARK — charcoal with a cool tint, denser stops for smoother falloff
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF303030),
      Color(0xFF303030),
    ],
    // Slightly tighter early blend, longer tail in the lows
    stops: [0.0, 0.03],
  );
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
    // ✅ Changed: At least 1 selection required (no upper limit)
    widget.canContinue.value = _selected.isNotEmpty;
  }

  void _toggle(String t) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selected.contains(t)) {
        _selected.remove(t);
      } else {
        // ✅ Removed limit: Can select unlimited items
        _selected.add(t);
      }
      // ✅ Changed: At least 1 selection required
      widget.canContinue.value = _selected.isNotEmpty;
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    var title = TextStyle(
      fontFamily: 'DM Sans',
      fontWeight: FontWeight.w700,
      fontSize: 22,
      color: theme.text
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
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
                return _TopicChip(
                  label: t,
                  selected: sel,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _toggle(t);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        // ✅ Optional: Show selection count (without limit)
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 8, left: 20),
        //   child: Text(
        //     'Selected: ${_selected.length}',
        //     style: TextStyle(
        //       color: Colors.black.withOpacity(0.6),
        //       fontSize: 14,
        //     ),
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
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

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
              style:  TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500, // Medium/Semibold
                fontSize: 14,
                letterSpacing: 0.15,
                color: selected ? Colors.black : theme.text,
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
    widget.canContinue.value = _selected.isNotEmpty;
  }

  void _toggle(String t) {
    HapticFeedback.mediumImpact();
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
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(widget.title, style: titleStyle),
        ),

        // ✅ Chips - Natural height, no Expanded
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

        // ✅ This pushes content to top, button stays at bottom
        const Spacer(),

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
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

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
            style:  TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color:selected ? Colors.black : theme.text,
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
