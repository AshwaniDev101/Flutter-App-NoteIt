part of '../app_theme.dart';

ThemeData get _sepiaThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: AppTypography.textTheme,

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      // Uses 'primary' so text buttons stand out as actionable text
      foregroundColor: const Color(0xFFD97757),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      // Uses 'onSurfaceVariant' for a subtle default icon color that isn't too distracting
      foregroundColor: const Color(0xFF78624E),
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFD97757),
      foregroundColor: Colors.white,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFD97757),
      side: const BorderSide(color: Color(0xFFD97757)),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFBF0D9),
      foregroundColor: const Color(0xFFD97757),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFF5D0C3),
    foregroundColor: Color(0xFF4A1808),
  ),

  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD97757),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFF5D0C3),
    onPrimaryContainer: Color(0xFF4A1808),
    secondary: Color(0xFF7A8B76),
    onSecondary: Colors.white,
    error: Color(0xFFB00020),
    onError: Colors.white,
    surface: Color(0xFFFBF0D9), // Cream paper coloration
    onSurface: Color(0xFF433422),
    onSurfaceVariant: Color(0xFF78624E),
    outlineVariant: Color(0xFFE5D5C1),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFBF0D9),
    foregroundColor: Color(0xFF433422),
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  ),
  // extensions: const [
  //   NoteTheme(
  //     selectedAppBar: Color(0xFFD97757),
  //     selectedCheckColor: Color(0xFFD97757),
  //     cardTitleBackground: Color(0xFFF3E3C8),
  //     cardTitleForeground: Color(0xFF433422),
  //     cardContentBackground: Color(0xFFFDF6E3),
  //     cardContentForeground: Color(0xFF5C4435),
  //   ),
  // ],
);
