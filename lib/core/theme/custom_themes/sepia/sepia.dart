part of '../../app_theme.dart';

ThemeData get _sepiaThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD97757),
    onPrimary: Colors.white,
    secondary: Color(0xFF7A8B76),
    onSecondary: Colors.white,
    error: Color(0xFFB00020),
    onError: Colors.white,
    surface: Color(0xFFFBF0D9), // Cream paper coloration
    onSurface: Color(0xFF433422),
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
  extensions: const [
    NoteTheme(
      selectedAppBar: Color(0xFFD97757),
      selectedCheckColor: Color(0xFFD97757),
      cardTitleBackground: Color(0xFFF3E3C8),
      cardTitleForeground: Color(0xFF433422),
      cardContentBackground: Color(0xFFFDF6E3),
      cardContentForeground: Color(0xFF5C4435),
    )
  ],
);