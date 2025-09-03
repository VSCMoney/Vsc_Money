// common_text.dart
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final double? lineHeight;

  const AppText(
      this.text, {
        Key? key,
        this.style = AppTextStyle.body,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.fontWeight,
        this.letterSpacing,
        this.lineHeight,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getTextStyle(context),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    TextStyle baseStyle;

    switch (style) {
      case AppTextStyle.h1:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        );
        break;
      case AppTextStyle.h2:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        );
        break;
      case AppTextStyle.h3:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        );
        break;
      case AppTextStyle.h4:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 22,
          fontWeight: FontWeight.w600,
        );
        break;
      case AppTextStyle.h5:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
        );
        break;
      case AppTextStyle.bodyLarge:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 18,
          fontWeight: FontWeight.normal,
        );
        break;
      case AppTextStyle.body:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.normal,
        );
        break;
      case AppTextStyle.bodySmall:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.normal,
        );
        break;
      case AppTextStyle.caption:
        baseStyle = const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.normal,
        );
        break;
    }

    return baseStyle.copyWith(
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
  }
}

enum AppTextStyle {
  h1,
  h2,
  h3,
  h4,
  h5,
  bodyLarge,
  body,
  bodySmall,
  caption,
}

// Convenience widgets for common use cases
class AppHeading extends StatelessWidget {
  final String text;
  final int level;
  final Color? color;
  final TextAlign? textAlign;

  const AppHeading(
      this.text, {
        Key? key,
        this.level = 1,
        this.color,
        this.textAlign,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppTextStyle style;
    switch (level) {
      case 1:
        style = AppTextStyle.h1;
        break;
      case 2:
        style = AppTextStyle.h2;
        break;
      case 3:
        style = AppTextStyle.h3;
        break;
      case 4:
        style = AppTextStyle.h4;
        break;
      case 5:
        style = AppTextStyle.h5;
        break;
      default:
        style = AppTextStyle.h1;
    }

    return AppText(
      text,
      style: style,
      color: color,
      textAlign: textAlign,
    );
  }
}

class AppBodyText extends StatelessWidget {
  final String text;
  final bool isLarge;
  final bool isSmall;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const AppBodyText(
      this.text, {
        Key? key,
        this.isLarge = false,
        this.isSmall = false,
        this.color,
        this.textAlign,
        this.maxLines,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppTextStyle style = AppTextStyle.body;
    if (isLarge) style = AppTextStyle.bodyLarge;
    if (isSmall) style = AppTextStyle.bodySmall;

    return AppText(
      text,
      style: style,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

class AppCaption extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const AppCaption(
      this.text, {
        Key? key,
        this.color,
        this.textAlign,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      style: AppTextStyle.caption,
      color: color ?? Colors.grey[600],
      textAlign: textAlign,
    );
  }
}

// Theme configuration for your app
class AppTextTheme {
  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}

// Usage examples:
/*
// Basic usage
AppText('Hello World', style: AppTextStyle.h1)
AppText('Body content here', style: AppTextStyle.body)

// Convenience widgets
AppHeading('Main Title', level: 1)
AppHeading('Subtitle', level: 2)
AppBodyText('This is body text')
AppBodyText('Large body text', isLarge: true)
AppBodyText('Small body text', isSmall: true)
AppCaption('Caption or helper text')

// With customization
AppText(
  'Custom text',
  style: AppTextStyle.body,
  color: Colors.blue,
  fontWeight: FontWeight.bold,
  textAlign: TextAlign.center,
)

// In your main.dart, apply the theme:
MaterialApp(
  theme: ThemeData(
    textTheme: AppTextTheme.textTheme,
    fontFamily: 'DM Sans',
  ),
  // ... rest of your app
)
*/