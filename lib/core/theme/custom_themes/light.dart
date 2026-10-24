part of '../app_theme.dart';

ThemeData get _lightThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: AppTypography.textTheme,

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      // Uses 'primary' so text buttons stand out as actionable text
      foregroundColor: const Color(0xFFE5A040),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      // Uses 'onSurfaceVariant' for a subtle default icon color that isn't too distracting
      foregroundColor: const Color(0xFF78716C),
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFE5A040),
      foregroundColor: const Color(0xFFFFFFFF),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE5A040),
      side: const BorderSide(color: Color(0xFFE5A040)),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFCFBF9),
      foregroundColor: const Color(0xFFE5A040),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFBE3B5),
    foregroundColor: Color(0xFF4A2E00),
  ),

  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE5A040),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFBE3B5),
    onPrimaryContainer: Color(0xFF4A2E00),
    secondary: Color(0xFFC78532),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFE27777),
    onError: Colors.white,
    surface: Color(0xFFFCFBF9),
    onSurface: Color(0xFF292524),
    onSurfaceVariant: Color(0xFF78716C),
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
  // extensions: const [
  //   NoteTheme(
  //     selectedAppBar: Color(0xFFE5A040),
  //     selectedCheckColor: Color(0xFFC78532),
  //     cardTitleBackground: Color(0xFFF5F4F1),
  //     cardTitleForeground: Color(0xFF292524),
  //     cardContentBackground: Color(0xFFFFFFFF),
  //     cardContentForeground: Color(0xFF57534E),
  //   ),
  // ],
);
