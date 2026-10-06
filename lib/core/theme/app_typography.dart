import 'package:flutter/material.dart';

class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // Large UI Elements (Empty states, Settings headers)
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0),

    // Dialog Headers & App Bars
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.15),


    // Note Title
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15), // * Card Title
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),

    // Note Body
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.45), // *  Card Body
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),

    // Metadata (Timestamps, bottom row)
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5), // * Card Date/Time
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}