import 'package:flutter/material.dart';

import '../../../constants/colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.primary,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: TextStyle(
          fontSize: 18,
          color: AppColors.white,
        ),
      ),
    ),
  );
}
