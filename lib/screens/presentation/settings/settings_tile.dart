import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';

class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool hasSwitch;
  final String? trailingText;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.hasSwitch = false,
    this.trailingText,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  final AuthService _authService = locator<AuthService>();
  final ThemeService _themeService = locator<ThemeService>();

  late StreamSubscription<AuthState> _authSubscription;
  late StreamSubscription<bool> _darkModeSubscription;

  String fullName = "User";
  bool isBiometricEnabled = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();

    final user = _authService.currentState.user;
    if (user != null) {
      fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
    }

    // Setup auth state subscription
    _authSubscription = _authService.authStateStream.listen((state) {
      final user = state.user;
      if (user != null && mounted) {
        setState(() {
          fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
        });
      }
    });

    // Setup dark mode subscription
    isDarkMode = _themeService.isDark; // Get initial value
    _darkModeSubscription = _themeService.isDarkModeStream.listen((darkMode) {
      if (mounted && isDarkMode != darkMode) {
        setState(() {
          isDarkMode = darkMode;
        });
      }
    });

    _loadTogglePrefs();
    _loadBiometricStatus();
  }

  void _loadBiometricStatus() async {
    final status = await _authService.isBiometricEnabledAsync();
    if (mounted) {
      setState(() {
        isBiometricEnabled = status;
      });
    }
  }

  Future<void> _loadTogglePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        // Don't override isDarkMode here since we get it from ThemeService
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _darkModeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(widget.icon, color: theme.icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                color: theme.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.trailingText != null)
            Row(
              children: [
                Text(
                  widget.trailingText!,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: theme.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: theme.icon),
              ],
            ),
          if (widget.hasSwitch)
            widget.title == 'Dark Mode'
                ? CupertinoSwitch(
              value: isDarkMode,
              onChanged: (value) {
                _themeService.toggleTheme(value);
              },
              activeColor: AppColors.primary,
            )
                : CupertinoSwitch(
              activeColor: AppColors.primary,
              value: isBiometricEnabled,
              onChanged: (value) async {

                await Future.delayed(const Duration(milliseconds: 300));
                final updated = await _authService.toggleBiometric(value, context);
                if (mounted) {
                  setState(() {
                    isBiometricEnabled = updated;
                  });
                }
              },
            )
          else if (widget.trailingText == null)
            Icon(Icons.chevron_right, color: theme.icon),
        ],
      ),
    );
  }
}