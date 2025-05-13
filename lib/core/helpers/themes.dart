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

  AppTheme({
    required this.background,
    required this.text,
    required this.primary,
    required this.icon,
    required this.border,
    required this.box,
    required this.message,
    required this.shadow,
  });

  static final light = AppTheme(
    background: Colors.white,
    text: Colors.black,
    primary: Colors.blue,
    icon: Colors.black87,
    border: Color(0xFF00000029),
    box: Colors.white,
    message: Color(0xFFF1EFEF),
    shadow: Colors.grey.shade300
  );

  static final dark = AppTheme(
    background: Color(0XFF1E1F22),
    text: Color(0xFFE0E0E0),
    primary: Colors.tealAccent,
    icon: Colors.white70,
    border: Colors.grey.shade700,
      box: Color(0xFF303030),
    message: Color(0xFF303030),
    shadow: Color(0xFF00000029)
  );
}
