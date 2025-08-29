import 'package:flutter/material.dart';

class AppTheme {
  final Color background;
  final Color text;
  final Color primary;
  final Color icon;
  final Color border;
  final Color box;
  final Color message;
  final Color shadow;
  final Color secondaryText;
  final Color searchBox;
  final Color bottombackground;
  List<Color> gradient;
  final Color google;
  final Color stocksearch;
  final Color card;

  AppTheme({
    required this.background,
    required this.text,
    required this.primary,
    required this.icon,
    required this.border,
    required this.box,
    required this.message,
    required this.shadow,
    required this.secondaryText,
    required this.searchBox,
    required this.bottombackground,
    required this.gradient,
    required this.google,
    required this.stocksearch,
    required this.card,
  });

  static final light = AppTheme(
    gradient: [
      Color(0xFFF1EAE4),
      Color(0xFFFFFFFF),
    ],
    card: Color(0xffFAF9F7),
    stocksearch: Color(0xFFFAF9F7),
    google: Color(0xFFC8C8C8),
    bottombackground: Colors.black,
    searchBox: Color(0xFFF1EFEF),
    secondaryText: Color(0xFF6E6E73),
    background: Color(0xFFFAF9F7),
    text: Color(0xFF000000),
    primary: Colors.blue,
    icon: Color(0xFF734012),
    border: Color(0xFF00000029),
    box: Colors.white,
    // message: Color(0xFFF1EFEF),
      message: Color(0xFFF8F1EC),
    shadow: Colors.grey.shade300
  );

  static final dark = AppTheme(
      gradient: [
        Color(0xFF303030),
        Color(0xFF303030),
      ],
    bottombackground: Colors.white,
    stocksearch: Color(0XFF1E1F22),
    searchBox: Color(0xFF303030),
    secondaryText: Color(0xFFB0B0B0),
    background: Color(0XFF1E1F22),
    text: Color(0xFFE0E0E0),
    primary: Colors.tealAccent,
    icon: Color(0xFFE0E0E0),
    border: Colors.grey.shade700,
      box: Color(0xFF303030),
    message: Color(0xFF303030),
    shadow: Color(0xFF00000029),
      google: Colors.white,
    card: Color(0xFF303030),
  );
}
