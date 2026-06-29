part of '../../app_theme.dart';

ThemeData get _lightThemeData => ThemeData(
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