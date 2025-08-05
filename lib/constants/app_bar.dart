import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vscmoney/constants/widgets.dart';

import '../services/locator.dart';
import '../services/theme_service.dart';

PreferredSize appBar(
    BuildContext context,
    String title,
    VoidCallback onNewChatTap,
    bool isDashboard, {
      bool showNewChatButton = false,
    }) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isTablet = screenWidth > 600;
        final double horizontalPadding = isTablet ? 24.0 : 12.0;
        final double iconSize = isTablet ? 26 : 26;
        final double logoHeight = isTablet ? 50 : 30;
        final double buttonSize = isTablet ? 32 : 28;
        final double spacing = isTablet ? 20 : 12;
        final theme = locator<ThemeService>().currentTheme;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: theme.background,
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  isDashboard
                      ? Hero(
                    tag: 'penny_logo', // ✅ Must match splash screen hero tag
                    child: Image.asset(
                      "assets/images/new_app_logo.png", // ✅ Ensure this image exists
                      height: logoHeight,
                    ),
                  )
                      : Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                      fontSize: isTablet ? 22 : 20,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (drawerContext) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              print("kdd");
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
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset("assets/images/newest.png",color: theme.icon,height: 32,width: 32,),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
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
                          SizedBox(width: spacing),

                          isDashboard && showNewChatButton ?
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: onNewChatTap,
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
                          ): SizedBox.shrink()
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}