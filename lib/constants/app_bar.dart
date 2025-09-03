import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vscmoney/constants/widgets.dart';

import '../services/locator.dart';
import '../services/theme_service.dart';



const double kLogoFinalAngle = math.pi;



PreferredSize appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard, {
      bool showNewChatButton = false,
      bool showDivider = false, // NEW: Control divider separately
    }) {
  final double height = showDivider ? 101.0 : 100.0;

  return PreferredSize(
    preferredSize: Size.fromHeight(height),
    child: AnimatedAppBar(
      title: title,
      onNewChatTap: onNewChatTap,
      isDashboard: isDashboard,
      showNewChatButton: showNewChatButton,
      showDivider: showDivider, // Pass the divider flag
    ),
  );
}

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoSpinCtrl;
  late final Animation<double> _logoSpin;

  @override
  void initState() {
    super.initState();
    _logoSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _logoSpin = CurvedAnimation(
      parent: _logoSpinCtrl,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _logoSpinCtrl.dispose();
    super.dispose();
  }

  void _spinLogoOnce() {
    if (_logoSpinCtrl.isAnimating) return;
    HapticFeedback.heavyImpact();
    _logoSpinCtrl.forward(from: 0).whenComplete(() => _logoSpinCtrl.reset());
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final double horizontalPadding = 16.0;
    final double logoHeight = isTablet ? 50 : 36;
    final double spacing = 12;
    final theme = locator<ThemeService>().currentTheme;

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
                  // —— Center: Logo or Title (logo now spins on tap) ——
                  widget.isDashboard
                      ? Hero(
                    tag: 'penny_logo',
                    child: GestureDetector(
                      onTap: _spinLogoOnce,
                      child: AnimatedBuilder(
                        animation: _logoSpin,
                        builder: (context, child) {
                          final double angle =
                              kLogoFinalAngle + (_logoSpin.value * 2 * math.pi);
                          return Transform.rotate(angle: angle, child: child);
                        },
                        child: Image.asset(
                          "assets/images/ying yang.png",
                          height: logoHeight,
                        ),
                      ),
                    ),
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

                  // —— Left + Right actions (unchanged) ——
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
                              HapticFeedback.heavyImpact();
                              FocusManager.instance.primaryFocus?.unfocus();
                              FocusScope.of(context).unfocus();
                              final scaffold = Scaffold.maybeOf(drawerContext);
                              if (scaffold != null && scaffold.hasDrawer) {
                                scaffold.openDrawer();
                              } else {
                                Scaffold.of(drawerContext).openDrawer();
                              }
                            },
                            child:  Padding(
                              padding: EdgeInsets.all(10.0),
                              child: SvgPicture.asset(
                                "assets/images/drawer.svg",
                                height: 38,
                                width: 38,
                                color: theme.icon,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right: Actions
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final overlay = Overlay.of(context);
                              final renderBox = context.findRenderObject() as RenderBox;
                              final size = renderBox.size;
                              final offset = renderBox.localToGlobal(Offset.zero);

                              final entry = OverlayEntry(
                                builder: (context) => Positioned(
                                  top: offset.dy + size.height + 8,
                                  left: offset.dx + size.width / 1.5 - 60,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: AnimatedComingSoonTooltip(),
                                  ),
                                ),
                              );

                              overlay.insert(entry);
                              Future.delayed(const Duration(seconds: 2), () {
                                entry.remove();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: _BoldNotificationIcon(),
                            ),
                          ),
                          if (widget.isDashboard && widget.showNewChatButton) ...[
                            SizedBox(width: spacing),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: widget.onNewChatTap,
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  // child: Image.asset(
                                  //   "assets/images/newChat.png",
                                  //   color: theme.icon,
                                  //   width: 22,
                                  //   height: 22,
                                  // ),
                                  child: _BoldNewChatIcon(),
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
            color: Colors.grey.withOpacity(0.1),
            width: double.infinity,
          ),
      ],
    );
  }
}

// Pulled out as a const widget so it can be const-constructed above
class _BoldNotificationIcon extends StatelessWidget {
  const _BoldNotificationIcon();

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeService>().currentTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset("assets/images/notify.svg", width: 24, height: 24,color: theme.icon,),
        Positioned(
          left: 0.5,
          top: 0.5,
          child: SvgPicture.asset("assets/images/notify.svg", height: 24, width: 24,color: theme.icon,),
        ),
      ],
    );
  }
}


class _BoldNewChatIcon extends StatelessWidget {
  const _BoldNewChatIcon();

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeService>().currentTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset("assets/images/newChat.png", width: 22, height: 22,color: theme.icon,),
        Positioned(
          left: 0.5,
          top: 0.5,
          child: Image.asset("assets/images/newChat.png", height: 22, width: 22, color: theme.icon),
        ),
      ],
    );
  }
}

