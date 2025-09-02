import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/constants/widgets.dart';

import '../services/locator.dart';
import '../services/theme_service.dart';



const double kLogoFinalAngle = math.pi;


// Update your AppBar function to accept a new parameter
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
  final bool showDivider; // NEW: Add divider control

  const AnimatedAppBar({
    Key? key,
    required this.title,
    required this.onNewChatTap,
    required this.isDashboard,
    this.showNewChatButton = false,
    this.showDivider = false, // NEW: Default to false
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
                  // Logo or Title (unchanged)
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
                      fontFamily: 'SF Pro',
                    ),
                  ),

                  // Left + Right actions (unchanged)
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
                              child: _boldNotificationIcon()
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

        // UPDATED: Show divider based on showDivider flag
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




  Widget _boldNotificationIcon() {
    final theme = locator<ThemeService>().currentTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
         Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26), // center
        // Positioned(left: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        //  Positioned(right: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        //  Positioned(top: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        //  Positioned(bottom: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),

        // corners for extra boldness
         Positioned(left: 0.5, top: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        // Positioned(left: 0.5, bottom: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        // Positioned(right: 0.5, top: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
        //  Positioned(right: 0.5, bottom: 0.5, child: Icon(Icons.notifications_none_outlined, color: theme.icon, size: 26)),
      ],
    );
  }
}
