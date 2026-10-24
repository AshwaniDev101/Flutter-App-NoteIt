part of '../app_theme.dart';

ThemeData get _amoledThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme: AppTypography.textTheme,

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      // Uses 'primary' so text buttons stand out as actionable text
      foregroundColor: const Color(0xFF939BEA),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      // Uses 'onSurfaceVariant' for a subtle default icon color that isn't too distracting
      foregroundColor: const Color(0xFFA0A0A0),
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF939BEA),
      foregroundColor: Colors.black,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF939BEA),
      side: const BorderSide(color: Color(0xFF939BEA)),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF121212),
      foregroundColor: const Color(0xFF939BEA),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF252850),
    foregroundColor: Color(0xFFD0D4F7),
  ),

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF939BEA),
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF252850),
    onPrimaryContainer: Color(0xFFD0D4F7),
    secondary: Color(0xFF73C5A8),
    onSecondary: Colors.black,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Colors.black, // Pure deep black layout
    onSurface: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFFA0A0A0),
    outlineVariant: Color(0xFF1F1F1F),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Color(0xFFE0E0E0),
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  // extensions: const [
  //   NoteTheme(
  //     selectedAppBar: Color(0xFF939BEA),
  //     selectedCheckColor: Color(0xFF73C5A8),
  //     cardTitleBackground: Color(0xFF0F0F0F),
  //     cardTitleForeground: Color(0xFFE0E0E0),
  //     cardContentBackground: Colors.black,
  //     cardContentForeground: Color(0xFFA0A0A0),
  //   ),
  // ],
);
