part of '../../app_theme.dart';

ThemeData get _amoledThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF939BEA),
    onPrimary: Colors.black,
    secondary: Color(0xFF73C5A8),
    onSecondary: Colors.black,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Colors.black, // Pure deep black layout
    onSurface: Color(0xFFE0E0E0),
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
  extensions: const [
    NoteTheme(
      selectedAppBar: Color(0xFF939BEA),
      selectedCheckColor: Color(0xFF73C5A8),
      cardTitleBackground: Color(0xFF0F0F0F),
      cardTitleForeground: Color(0xFFE0E0E0),
      cardContentBackground: Colors.black,
      cardContentForeground: Color(0xFFA0A0A0),
    )
  ],
);