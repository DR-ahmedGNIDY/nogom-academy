import 'package:basketball_academy/core/theme/light_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Cairo';

  static ThemeData get lightTheme => buildLightTheme(fontFamily, _textTheme);

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w800),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
  );
}
