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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authService.ensureProfileLoaded();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _initializeUserData() {
    final user = _authService.currentState.user;
    setState(() {
      _fullName = _displayName(user?.firstName, user?.lastName);
    });
  }

  void _subscribeToAuthChanges() {
    _subscription = _authService.authStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _fullName = _displayName(state.user?.firstName, state.user?.lastName);
      });
    });
  }

  String _displayName(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    final full = [f, l].where((s) => s.isNotEmpty).join(' ').trim();
    return full.isEmpty ? 'User' : full;
  }

  String get _userInitials {
    if (_fullName.isEmpty || _fullName == "User") return 'U';
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // Add margin to lift the footer higher from bottom
        margin: const EdgeInsets.only(bottom: 20), // Adjust this value
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fullName,
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // IconButton(
            //   icon: Icon(Icons.more_horiz, color: theme.icon, size: 24),
            //   onPressed: widget.onTap,
            //   tooltip: 'Settings',
            // ),
          ],
        ),
      ),
    );
  }
}
