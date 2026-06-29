part of '../../app_theme.dart';

ThemeData get _darkThemeData => ThemeData(
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