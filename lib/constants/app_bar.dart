import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/constants/widgets.dart';

import '../services/locator.dart';
import '../services/theme_service.dart';



const double kLogoFinalAngle = math.pi;
const String kSplashLogoAsset = "assets/images/ying yang.png";     // current splash
//const String kHomeLogoAsset   = "assets/images/Vitty.ai2.png";


PreferredSize appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard, {
      bool showNewChatButton = false,
      bool showDivider = false,
    }) {
  final double height = showDivider ? 101.0 : 100.0;

  return PreferredSize(
    preferredSize: Size.fromHeight(height),

    child: AnimatedAppBar(
      title: title,
      onNewChatTap: onNewChatTap,
      isDashboard: isDashboard,
      showNewChatButton: showNewChatButton,
      showDivider: showDivider,
    ),
  );
}

// ======= AnimatedAppBar (normal Hero target; NO rotation here) =======
class AnimatedAppBar extends StatefulWidget {
  final String title;
  final VoidCallback onNewChatTap;
  final bool isDashboard;
  final bool showNewChatButton;
  final bool showDivider;

  const AnimatedAppBar({
    Key? key,
    required this.title,
    required this.onNewChatTap,
    required this.isDashboard,
    this.showNewChatButton = false,
    this.showDivider = false,
  }) : super(key: key);

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<AnimatedAppBar>
    with TickerProviderStateMixin {
  late final AnimationController _logoChangeCtrl;

  // Yin–Yang out
  late final Animation<double> _yinFadeOut;
  late final Animation<double> _yinScaleOut;

  // Vitty text in
  late final Animation<double> _textReveal;
  late final Animation<double> _textFadeIn;
  late final Animation<double> _textScaleIn;

  bool _transitionStarted = false;
  bool _isDropdownVisible = false;

  // Dropdown animation
  late final AnimationController _dropdownController;
  late final Animation<double> _dropdownAnimation;

  // Dropdown state for Cupertino-style menu
  final GlobalKey _titleAnchorKey = GlobalKey();
  OverlayEntry? _dropdownEntry;

  @override
  void initState() {
    super.initState();

    _logoChangeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _dropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dropdownAnimation = CurvedAnimation(
      parent: _dropdownController,
      curve: Curves.easeInOut,
    );

    _yinFadeOut = CurvedAnimation(
      parent: _logoChangeCtrl,
      curve: const Interval(0.00, 0.45, curve: Curves.easeInQuad),
    );
    _yinScaleOut = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _logoChangeCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.easeInOut),
      ),
    );

    _textReveal = CurvedAnimation(
      parent: _logoChangeCtrl,
      curve: const Interval(0.20, 1.00, curve: Curves.easeOutCubic),
    );
    _textFadeIn = CurvedAnimation(
      parent: _logoChangeCtrl,
      curve: const Interval(0.35, 1.00, curve: Curves.easeOutQuad),
    );
    _textScaleIn = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoChangeCtrl,
        curve: const Interval(0.35, 1.00, curve: Curves.easeOutBack),
      ),
    );

    if (widget.isDashboard) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_transitionStarted) {
          _transitionStarted = true;
          _logoChangeCtrl.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideDropdown();
    _logoChangeCtrl.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    HapticFeedback.mediumImpact();
    if (_isDropdownVisible) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_dropdownEntry != null) return;

    final anchorCtx = _titleAnchorKey.currentContext;
    if (anchorCtx == null) return;

    final rb = anchorCtx.findRenderObject() as RenderBox;
    final anchorOffset = rb.localToGlobal(Offset.zero);
    final anchorSize = rb.size;

    final Size screen = MediaQuery.of(context).size;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    // Card sizing (same as appbar dropdown)
    final double cardWidth = math.min(screen.width - 32, 320);
    final double estHeight = 2 * 56.0; // Share + Copy

    // Center under the title (clamped)
    final double left = ((anchorOffset.dx + anchorSize.width / 2) - cardWidth / 2)
        .clamp(16.0, screen.width - cardWidth - 16.0);

    double top = anchorOffset.dy + anchorSize.height + 8.0;
    final bool overflowBottom = (top + estHeight + 24) > screen.height;
    if (overflowBottom) {
      top = math.max(24.0, anchorOffset.dy - estHeight - 8.0);
    }

    _dropdownEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // Dim background — tap to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideDropdown,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: 1.0,
                  child: Container(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ),

            // iOS-style popover (exactly like appbar)
            Positioned(
              left: left,
              top: top,
              width: cardWidth,
              child: _CupertinoAppbarPopover(
                bgColor: theme.box,          // your card/bg color
                borderColor: theme.border,   // thin border
                textColor: theme.text,
                iconColor: theme.icon,
                // pointer center aligned with title
                pointerCenterX: (anchorOffset.dx + anchorSize.width / 2) - left,
                items: [
                  _AppbarMenuEntry(
                    title: 'Share',
                    onTap: () {
                      _hideDropdown();
                      _onShareTap();
                    },
                  ),
                  _AppbarMenuEntry(
                    title: 'Copy',
                    onTap: () {
                      _hideDropdown();
                      _onCopyTap();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_dropdownEntry!);
    setState(() => _isDropdownVisible = true);
  }


  void _hideDropdown() {
    _dropdownEntry?.remove();
    _dropdownEntry = null;
    if (_isDropdownVisible) {
      setState(() => _isDropdownVisible = false);
    }
  }

  void _onShareTap() {
    HapticFeedback.mediumImpact();
    debugPrint("Share tapped");
  }

  void _onCopyTap() {
    HapticFeedback.mediumImpact();
    debugPrint("Copy tapped");
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final double horizontalPadding = 23.0;
    final double logoHeight = isTablet ? 50 : 46;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          color: theme.background,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center: Logo with dropdown
                  widget.isDashboard
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'penny_logo',
                        transitionOnUserGestures: true,
                        child: AnimatedBuilder(
                          animation: _logoChangeCtrl,
                          builder: (context, _) {
                            return SizedBox(
                              height: logoHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Yin-Yang base
                                  Opacity(
                                    opacity: 1.0 - _yinFadeOut.value,
                                    child: Transform.scale(
                                      scale: _yinScaleOut.value,
                                      child: Image.asset(
                                        "assets/images/ying yang.png",
                                        height: 36,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  // Vitty text reveal
                                  Opacity(
                                    opacity: _textFadeIn.value,
                                    child: Transform.scale(
                                      scale: _textScaleIn.value,
                                      child: ClipRect(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _textReveal.value.clamp(0.0, 1.0),
                                          child: Transform.translate(
                                            offset: const Offset(8, 0),
                                            child: GestureDetector(
                                              onTap: _toggleDropdown,
                                              child: Row(
                                                key: _titleAnchorKey, // Anchor for dropdown
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Vitty',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontFamily: "Josefin Sans",
                                                      fontSize: 22,
                                                      color: theme.icon,
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 0),
                                                  AnimatedRotation(
                                                    turns: _isDropdownVisible ? 0.5 : 0.0,
                                                    duration: const Duration(milliseconds: 200),
                                                    child: Icon(
                                                      Icons.keyboard_arrow_down_rounded,
                                                      size: 28,
                                                      color: theme.icon?.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                      : Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                      fontSize: isTablet ? 22 : 20,
                      fontFamily: 'DM Sans',
                    ),
                  ),

                  // Left + Right actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Drawer
                      Builder(
                        builder: (drawerContext) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              FocusManager.instance.primaryFocus?.unfocus();
                              FocusScope.of(context).unfocus();
                              _hideDropdown();
                              final scaffold = Scaffold.maybeOf(drawerContext);
                              if (scaffold != null && scaffold.hasDrawer) {
                                scaffold.openDrawer();
                              } else {
                                Scaffold.of(drawerContext).openDrawer();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: SvgPicture.asset(
                                "assets/images/drawer.svg",
                                height: 36,
                                width: 36,
                                color: theme.icon,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right: Actions
                      Row(
                        children: [
                          // InkWell(
                          //   borderRadius: BorderRadius.circular(24),
                          //   onTap: () {
                          //     HapticFeedback.lightImpact();
                          //     _hideDropdown();
                          //     final overlay = Overlay.of(context);
                          //     final renderBox = context.findRenderObject() as RenderBox;
                          //     final size = renderBox.size;
                          //     final offset = renderBox.localToGlobal(Offset.zero);
                          //
                          //     final entry = OverlayEntry(
                          //       builder: (context) => Positioned(
                          //         top: offset.dy + size.height + 8,
                          //         left: offset.dx + size.width / 1.5 - 60,
                          //         child: Material(
                          //           color: Colors.transparent,
                          //           child: AnimatedComingSoonTooltip(),
                          //         ),
                          //       ),
                          //     );
                          //
                          //     overlay.insert(entry);
                          //     Future.delayed(const Duration(seconds: 2), () {
                          //       entry.remove();
                          //     });
                          //   },
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(4.0),
                          //     child: SvgPicture.asset(
                          //       "assets/images/new_notification.svg",
                          //       width: 20,
                          //       height: 20,
                          //       color: theme.icon,
                          //     ),
                          //   ),
                          // ),
                          if (widget.isDashboard) ...[
                            const SizedBox(width: 15),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  _hideDropdown();
                                  if (widget.showNewChatButton) {
                                    widget.onNewChatTap();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  // ✅ Show different icon based on showNewChatButton
                                  child: widget.showNewChatButton
                                      ? const _BoldNewChatIcon()  // When chat exists
                                      : SvgPicture.asset(              // When no chat (empty state)
                                    'assets/images/secret_chat.svg',  // Replace with your icon
                                    width: 21,
                                    height: 21,
                                    color: theme.icon,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 1,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            width: double.infinity,
          ),
      ],
    );
  }
}

class _BoldNewChatIcon extends StatelessWidget {
  const _BoldNewChatIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset("assets/images/newChat.svg", width: 32, height: 32,color: theme.icon,),
        Positioned(
          left: 0.5,
          top: 0.5,
          child: SvgPicture.asset("assets/images/newChat.svg", height: 32, width: 32, color: theme.icon),
        ),
      ],
    );
  }
}

class _AppbarMenuEntry {
  final String title;
  final VoidCallback onTap;
  _AppbarMenuEntry({required this.title, required this.onTap});
}

class _CupertinoAppbarPopover extends StatefulWidget {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final double pointerCenterX; // where the little arrow should point
  final List<_AppbarMenuEntry> items;

  const _CupertinoAppbarPopover({
    Key? key,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.pointerCenterX,
    required this.items,
  }) : super(key: key);

  @override
  State<_CupertinoAppbarPopover> createState() => _CupertinoAppbarPopoverState();
}

class _CupertinoAppbarPopoverState extends State<_CupertinoAppbarPopover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 160))
    ..forward();
  late final Animation<double> _scale =
  CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  late final Animation<double> _fade =
  CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(12);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        alignment: Alignment.topCenter,
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card
              Container(
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: radius,
                  border: Border.all(color: widget.borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (i) {
                    final it = widget.items[i];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: i == 0
                              ? const BorderRadius.vertical(top: Radius.circular(12))
                              : (i == widget.items.length - 1
                              ? const BorderRadius.vertical(bottom: Radius.circular(12))
                              : BorderRadius.zero),
                          onTap: it.onTap,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                            child: Text(
                              it.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: widget.textColor,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ),
                        ),
                        if (i != widget.items.length - 1)
                          Container(
                            height: 1,
                            color: widget.borderColor.withOpacity(0.3),
                          ),
                      ],
                    );
                  }),
                ),
              ),

              // Little pointer (triangle) — like appbar menu
              Positioned(
                top: -7,
                left: (widget.pointerCenterX - 7).clamp(12.0, (MediaQuery.of(context).size.width - 12.0)),
                child: CustomPaint(
                  size: const Size(14, 7),
                  painter: _TrianglePainter(
                    fillColor: widget.bgColor,
                    strokeColor: widget.borderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  _TrianglePainter({required this.fillColor, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    // stroke (thin)
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = strokeColor
      ..strokeWidth = 1;
    canvas.drawPath(p, stroke);

    // fill
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(p, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}





