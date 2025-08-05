// lib/widgets/drawer/drawer_footer.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';


class DrawerFooter extends StatefulWidget {
  final VoidCallback onTap;

  const DrawerFooter({
    super.key,
    required this.onTap,
  });

  @override
  State<DrawerFooter> createState() => _DrawerFooterState();
}

class _DrawerFooterState extends State<DrawerFooter> {
  final AuthService _authService = locator<AuthService>();
  late StreamSubscription<AuthState> _subscription;
  String _fullName = "User";

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _subscribeToAuthChanges();
    print("piyush");
    print(_authService.currentState.user);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _initializeUserData() {
    final user = _authService.currentState.user;
    if (user != null) {
      _fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
      if (_fullName.isEmpty) _fullName = "User";
    }
  }

  void _subscribeToAuthChanges() {
    _subscription = _authService.authStateStream.listen((state) {
      final user = state.user;
      if (user != null && mounted) {
        setState(() {
          _fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
          if (_fullName.isEmpty) _fullName = "User";
        });
      }
    });
  }

  String get _userInitials {
    if (_fullName.isEmpty || _fullName == "User") return 'U';

    final nameParts = _fullName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return _fullName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0XFFC4765E),
            child: Text(
              _userInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // User Name
          Expanded(
            child: Text(
              _fullName,
              style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                fontFamily: 'SF Pro Text',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Settings Button
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: theme.icon,
              size: 24,
            ),
            onPressed: widget.onTap,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}