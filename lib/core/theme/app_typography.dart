import 'package:flutter/material.dart';

class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1.0),
    displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, height: 1.4),
    bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
  );
}