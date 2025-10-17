import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../constants/bottomsheet.dart';
import '../../constants/colors.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';

import '../presentation/search_stock_screen.dart';


import '../presentation/settings/drawer_footer.dart';




class CustomDrawer extends StatefulWidget {
  final ChatService? chatService;
  final Function(ChatSession)? onSessionTap;
  final VoidCallback? onCreateNewChat;
  final String selectedRoute;
  final GlobalKey<ChatGPTBottomSheetWrapperState>? sheetKey;
  final VoidCallback? onTap;

  const CustomDrawer({
    Key? key,
    this.chatService,
    this.onSessionTap,
    this.onCreateNewChat,
    this.selectedRoute = 'Vitty',
    this.sheetKey,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late String _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedRoute;
    // debugPrint('CustomDrawer initState: selectedRoute = ${widget.selectedRoute}');
  }

  @override
  void didUpdateWidget(CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute != widget.selectedRoute) {
      setState(() => _selectedItem = widget.selectedRoute);
      // debugPrint('CustomDrawer didUpdateWidget: selectedRoute = ${widget.selectedRoute}');
    }
  }

  void _handleTap(String title, VoidCallback onTap) {
    setState(() => _selectedItem = title);
    // debugPrint('CustomDrawer _handleTap: selected = $title');
    onTap();
  }

  // ---------- Helper: gradient stops ----------
  List<double>? _stopsForColors(List<Color> colors) {
    if (colors.isEmpty) return null;

    switch (colors.length) {
      case 4:
      // Dark example: 0%, 11%, 18%, 100%  → normalized to 0–1
        return const [0.00, 0.00, 0.00, 0.390];
      case 3:
        return const [0.00, 0.50, 1.00];
      case 2:
      // Light example: start at ~38% then to 100%
        return const [0.38, 1.00];
      default:
      // Evenly spread for any other count
        if (colors.length == 1) return const [1.0];
        final n = colors.length;
        return List<double>.generate(n, (i) => i / (n - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always trust parent selection
    final actualSelectedItem = widget.selectedRoute;
    if (_selectedItem != actualSelectedItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedItem = actualSelectedItem);
      });
    }

    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // Footer gradient pieces
    final List<Color> footerColors = theme.footergradient;
    final List<double>? footerStops = _stopsForColors(footerColors);

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: theme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: w * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── SEARCH + RIGHT ICONS (row) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 15),
                child: Row(
                  children: [
                    // Search box (Expanded)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StockSearchScreen()),
                          );
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.searchBox,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: theme.box, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: theme.icon, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search',
                                style: TextStyle(
                                  color: theme.text.withOpacity(.55),
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                   // const SizedBox(width: 10),

                    // Bell with badge
                    _RoundIconButton(
                      size: 36,
                      bg: Colors.white,
                      borderColor: const Color(0xFF734012),
                      icon: "assets/images/new_notification.svg",
                      iconColor: theme.icon,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // TODO: open notifications
                      },
                    ),

                    const SizedBox(width: 0),

                    // History/Recent
                    _RoundIconButton(
                      size: 36,
                      bg: Colors.white,
                      borderColor: const Color(0xFF734012),
                      icon: "assets/images/convo.svg",
                      iconColor: theme.icon,
    onTap: () => _handleTap('Conversations', () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 200), () {
          context.pushNamed('conversations', extra: widget.onSessionTap);
        });
      }),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 18),
              const Divider(color: Color(0xFFE8E8E8), height: 1),
              const SizedBox(height: 12),

              // --- Items ---
              _drawerItem(
                icon: 'assets/images/ying yang.png',
                title: 'Vitty',
                isActive: _selectedItem == 'Vitty',
                onTap: () {
                  if (_selectedItem == 'Vitty') {
                    Navigator.pop(context);
                  } else {
                    _handleTap('Vitty', () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 180), () {
                        context.go('/home');
                      });
                    });
                  }
                },
              ),

              _drawerItem(
                icon: 'assets/images/wealth.svg',
                title: 'Wealth',
                isActive: _selectedItem == 'Wealth',
                onTap: () {
                  context.push("/warm");
                },
              ),


              _drawerItem(
                icon: 'assets/images/research.svg',
                title: 'Research',
                isActive: _selectedItem == 'Research',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 180), () {
                    context.push('/watchlist');
                  });
                },
              ),

              _drawerItem(
                icon: 'assets/images/Vector.svg',
                title: 'Goals',
                isActive: _selectedItem == 'Goals',
                onTap: () => _handleTap('Goals', () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 180), () {
                    context.push('/goals');
                  });
                }),
              ),

              // _drawerItem(
              //   icon: 'assets/images/conversations_new.svg',
              //   title: 'Conversations',
              //   isActive: _selectedItem == 'Conversations',
              //   onTap: () => _handleTap('Conversations', () {
              //     HapticFeedback.mediumImpact();
              //     Navigator.pop(context);
              //     Future.delayed(const Duration(milliseconds: 200), () {
              //       context.pushNamed('conversations', extra: widget.onSessionTap);
              //     });
              //   }),
              // ),

              const Spacer(),

              // --- Footer (settings) ---
              GestureDetector(
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!.call();
                    return;
                  }
                  final key = widget.sheetKey;
                  if (key?.currentState != null) {
                    final sheet = BottomSheetManager.buildSettingsSheet(
                      onTap: () => key!.currentState?.closeSheet(),
                    );
                    key!.currentState?.openSheet(sheet);
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    builder: (_) => SafeArea(
                      top: false,
                      child: BottomSheetManager.buildSettingsSheet(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: footerColors,
                      stops: footerStops,               // ✅ fixed (0–1 range, length matches)
                      begin: Alignment.topLeft,         // looks closer to your screenshot
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: DrawerFooter(
                    onTap: () {
                      if (widget.onTap != null) {
                        widget.onTap!.call();
                        return;
                      }
                      final key = widget.sheetKey;
                      if (key?.currentState != null) {
                        final sheet = BottomSheetManager.buildSettingsSheet(
                          onTap: () => key!.currentState?.closeSheet(),
                        );
                        key!.currentState?.openSheet(sheet);
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.background,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        builder: (_) => SafeArea(
                          top: false,
                          child: BottomSheetManager.buildSettingsSheet(
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: h * 0.00),
            ],
          ),
        ),
      ),
    );
  }

  // --- ChatGPT-style row ---
  Widget _drawerItem({
    required String icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final w = MediaQuery.of(context).size.width;
    final isSvg = icon.toLowerCase().endsWith('.svg');

    final row = Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: isSvg
              ? SvgPicture.asset(
            icon,
            height: 22,
            width: 22,
            color: title == 'Vitty' ? null : theme.icon,
          )
              : Image.asset(
            icon,
            height: 24,
            width: 24,
            color: title == 'Vitty' ? null : theme.icon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: w * 0.045,
              color: theme.text,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xff734012).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: row,
        ),
      ),
    );
  }
}





class _RoundIconButton extends StatelessWidget {
  final double size;
  final Color bg;
  final Color borderColor;
  final String icon;
  final Color iconColor;
  final int? badgeCount;
  final VoidCallback onTap;

  const _RoundIconButton({
    Key? key,
    required this.size,
    required this.bg,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    this.badgeCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            child: Center(
              child: SvgPicture.asset(icon),
            ),
          ),
        ],
      ),
    );
  }
}









