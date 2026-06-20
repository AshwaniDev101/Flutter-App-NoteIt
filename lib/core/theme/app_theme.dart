import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteit/core/theme/note_theme.dart';

class Themes {
  static ThemeData get lightThemeData => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFE5A040),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFC78532),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFE27777),
      onError: Colors.white,
      surface: Color(0xFFFCFBF9),
      onSurface: Color(0xFF292524),
      outlineVariant: Color(0xFFE7E5E4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFCFBF9),
      foregroundColor: Color(0xFF292524),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFFE5A040),
        selectedCheckColor: Color(0xFFC78532),
        cardTitleBackground: Color(0xFFF5F4F1),
        cardTitleForeground: Color(0xFF292524),
        cardContentBackground: Color(0xFFFFFFFF),
        cardContentForeground: Color(0xFF57534E),
      )
    ],
  );

  static ThemeData get darkThemeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF939BEA),
      onPrimary: Color(0xFF1B1D3D),
      secondary: Color(0xFF73C5A8),
      onSecondary: Color(0xFF0B2C1F),
      error: Color(0xFFE27777),
      onError: Colors.black,
      surface: Color(0xFF14161C),
      onSurface: Color(0xFFE2E4E9),
      outlineVariant: Color(0xFF2E323D),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF14161C),
      foregroundColor: Color(0xFFE2E4E9),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    extensions: const [
      NoteTheme(
        selectedAppBar: Color(0xFF939BEA),
        selectedCheckColor: Color(0xFF73C5A8),
        cardTitleBackground: Color(0xFF232733),
        cardTitleForeground: Color(0xFFE2E4E9),
        cardContentBackground: Color(0xFF1B1E26),
        cardContentForeground: Color(0xFFA3A8B5),
      )
    ],
  );
}