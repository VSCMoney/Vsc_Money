import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/constants/widgets.dart';

import '../services/locator.dart';
import '../services/theme_service.dart';


// -------------------------
// 🔁 Shared rotation angle
// -------------------------
// Set this to the SAME angle your splash ends at.
//   math.pi     -> half-turn (180°)
//   2*math.pi   -> full-turn (360°)
//   -math.pi    -> half-turn the other way, if asset looks mirrored
const double kLogoFinalAngle = math.pi;

// ----------------------------------------------------
// AppBar helper that shows a rotated logo on dashboard
// ----------------------------------------------------
PreferredSize appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard, {
      bool showNewChatButton = false,
    }) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: AnimatedAppBar(
      title: title,
      onNewChatTap: onNewChatTap,
      isDashboard: isDashboard,
      showNewChatButton: showNewChatButton,
    ),
  );
}

class AnimatedAppBar extends StatefulWidget {
  final String title;
  final VoidCallback onNewChatTap;
  final bool isDashboard;
  final bool showNewChatButton;

  const AnimatedAppBar({
    Key? key,
    required this.title,
    required this.onNewChatTap,
    required this.isDashboard,
    this.showNewChatButton = false,
  }) : super(key: key);

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<AnimatedAppBar> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final double horizontalPadding = 16.0;
    final double iconSize = isTablet ? 26 : 26;
    final double logoHeight = isTablet ? 50 : 30;
    final double spacing = 12;
    final theme = locator<ThemeService>().currentTheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        color: theme.background,
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ✅ Rotate the AppBar logo by the same final angle as splash
                widget.isDashboard
                    ? Hero(
                  tag: 'penny_logo',
                  child: Transform.rotate(
                    angle: kLogoFinalAngle,
                    child: Image.asset(
                      "assets/images/ying yang.png",
                      height: logoHeight,
                    ),
                  ),
                )
                    : Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                    fontSize: isTablet ? 22 : 20,
                    fontFamily: 'Inter',
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
                            HapticFeedback.vibrate();
                            FocusManager.instance.primaryFocus?.unfocus();
                            FocusScope.of(context).unfocus();
                            final scaffold = Scaffold.maybeOf(drawerContext);
                            if (scaffold != null && scaffold.hasDrawer) {
                              scaffold.openDrawer();
                            } else {
                              Scaffold.of(drawerContext).openDrawer();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              "assets/images/newest.png",
                              color: theme.icon,
                              height: 32,
                              width: 32,
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
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.notifications_none_outlined,
                              color: theme.icon,
                              size: iconSize,
                            ),
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
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  "assets/images/newChat.png",
                                  color: theme.icon,
                                  width: 19,
                                  height: 22,
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
    );
  }
}
