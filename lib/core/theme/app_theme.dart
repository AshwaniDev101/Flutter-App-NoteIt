import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteit/core/theme/note_theme.dart';

class Themes {
  static ThemeData get lightThemeData => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFF59E0B),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFD97706),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: Color(0xFFFFFDF8),
      onSurface: Color(0xFF1C1917),
      outlineVariant: Color(0xFFFDE68A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF59E0B),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFFD97706),
        selectedCheckColor: Color(0xFFD97706),
        cardTitleBackground: Color(0xFFFEF3C7),
        cardTitleForeground: Color(0xFF1C1917),
        cardContentBackground: Color(0xFFFFFFFF),
        cardContentForeground: Color(0xFF3F3F46),
      )
    ],
  );

  static ThemeData get darkThemeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF818CF8),
      onPrimary: Color(0xFF1E1B4B),
      secondary: Color(0xFF34D399),
      onSecondary: Color(0xFF022C22),
      error: Color(0xFFF87171),
      onError: Colors.black,
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF8FAFC),
      outlineVariant: Color(0xFF334155),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Color(0xFF818CF8),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFF818CF8),
        selectedCheckColor: Color(0xFF34D399),
        cardTitleBackground: Color(0xFF1E293B),
        cardTitleForeground: Color(0xFFF8FAFC),
        cardContentBackground: Color(0xFF1E293B),
        cardContentForeground: Color(0xFFCBD5E1),
      )
    ],
  );
}