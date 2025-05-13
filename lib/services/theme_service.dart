// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rxdart/rxdart.dart';

import '../core/helpers/themes.dart';

class ThemeService {
  static const _themeKey = 'is_dark_mode';

  final _themeController = BehaviorSubject<AppTheme>.seeded(AppTheme.light);
  final _isDarkMode = BehaviorSubject<bool>.seeded(false);

  Stream<AppTheme> get themeStream => _themeController.stream.distinct();

  Stream<bool> get isDarkModeStream => _isDarkMode.stream;

  AppTheme get currentTheme => _themeController.value;
  bool get isDark => _isDarkMode.value;

  /// Call this at app startup (main.dart)
  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_themeKey) ?? false;
    _isDarkMode.add(saved);
    _themeController.add(saved ? AppTheme.dark : AppTheme.light);
  }

  void toggleTheme(bool isDarkMode) async {
    _isDarkMode.add(isDarkMode);
    _themeController.add(isDarkMode ? AppTheme.dark : AppTheme.light);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  /// Reset on logout
  Future<void> resetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);

    _isDarkMode.add(false);
    _themeController.add(AppTheme.light);
  }

  void dispose() {
    _themeController.close();
    _isDarkMode.close();
  }
}
