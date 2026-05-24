import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteit/core/theme/note_theme.dart';

class Themes {
  static ThemeData get lightThemeData => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF111827),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF344871),
      onSecondary: Color(0xFFE4E4E4),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF111827),
      outlineVariant: Color(0xFFEAFFD0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2C3947),
      foregroundColor: Color(0xFFFBFBFB),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Color(0xFF212935),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFF73C566),
        selectedCheckColor: Color(0xFF73C566),

        // cardTitleBackground: Color(0xFF111827),
        cardTitleBackground: Color(0xFFF6F6F6),
        cardTitleForeground: Color(0xFF111827),

        cardContentBackground: Color(0xFFF6F6F6),
        cardContentForeground: Color(0xFF111827),

      )
    ],
  );

  static ThemeData get darkThemeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFAD5C71),
      onPrimary: Colors.white,
      secondary: Color(0xFF72BAA9),
      onSecondary: Color(0xFF1C1917),
      error: Color(0xFFF87171),
      onError: Colors.black,
      surface: Color(0xFF241F21),
      onSurface: Color(0xFFF5F5F4),
      outlineVariant: Color(0xFF44403C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF241F21),
      foregroundColor: Color(0xFFAD5C71),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFF73C566),
        selectedCheckColor: Color(0xFF73C566),

        cardTitleBackground: Color(0xFF111827),
        cardTitleForeground: Color(0xFF111827),

        cardContentBackground: Color(0xFFFFF8B1),
        cardContentForeground: Color(0xFF374151),

      )
    ],
  );
}