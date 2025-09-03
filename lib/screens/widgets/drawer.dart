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
  }

  @override
  void didUpdateWidget(CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute != widget.selectedRoute) {
      setState(() => _selectedItem = widget.selectedRoute);
    }
  }

  void _handleTap(String title, VoidCallback onTap) {
    setState(() => _selectedItem = title);
    onTap();
  }

  String _getCurrentRoute() {
    final p = GoRouter.of(context).routeInformationProvider.value.uri.path;
    switch (p) {
      case '/home':
        return 'Vitty';
      case '/goals':
        return 'Goals';
      case '/conversations':
        return 'Conversations';
      default:
        return 'Vitty';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _getCurrentRoute();
    if (_selectedItem != currentRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedItem = currentRoute);
      });
    }

    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
              // --- Search pill (tappable) ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StockSearchScreen()),
                    );
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      //color: theme.searchBox,
                      color: Color(0xff734012).withOpacity(0.075),
                      borderRadius: BorderRadius.circular(15), // was 14 → more rectangular
                      border: Border.all(
                        color: theme.box, // subtle edge
                        width: 1,
                      ),
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


              const SizedBox(height: 18),
              const Divider(color: Color(0xFFE8E8E8), height: 1),
              const SizedBox(height: 12),

              // --- Items (ChatGPT-style “pill” active row) ---
              _drawerItem(
                icon: 'assets/images/ying yang.png',
                title: 'Vitty',
                isActive: _selectedItem == 'Vitty',
                onTap: () {
                  if (_selectedItem == 'Vitty') {
                    Navigator.pop(context);
                  } else {
                    _handleTap('Vitty', () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 180), () {
                        context.go('/home');
                      });
                    });
                  }
                },
              ),

              _drawerItem(
                icon: 'assets/images/Vector.svg',
                title: 'Goals',
                isActive: _selectedItem == 'Goals',
                onTap: () => _handleTap('Goals', () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 180), () {
                    context.go('/goals');
                  });
                }),
              ),

              _drawerItem(
                icon: 'assets/images/Vector.png',
                title: 'Conversations',
                isActive: _selectedItem == 'Conversations',
                onTap: () => _handleTap('Conversations', () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    context.goNamed('conversations', extra: widget.onSessionTap);
                  });
                }),
              ),

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
                    gradient: LinearGradient(colors: [
                      Color(0xff734012).withOpacity(0.0015),
                      theme.background
                    ])
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
        // icon
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
            height: 22,
            width: 22,
            color: title == 'Vitty' ? null : theme.icon,
          ),
        ),
        const SizedBox(width: 12),
        // label
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

    return  Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Color(0xff734012).withOpacity(0.15) : Colors.transparent, // 15% opacity
            borderRadius: BorderRadius.circular(14),
          ),
          child: row,
        ),
      ),
    );
  }
}












