part of '../app_theme.dart';

ThemeData get _catppuccinThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFFCBA6F7), // Mauve Accent
    onPrimary: Color(0xFF181825),
    primaryContainer: Color(0xFF313244), // Surface0
    onPrimaryContainer: Color(0xFFCDD6F4),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF74C7EC), // Sapphire
    onSecondary: Color(0xFF181825),
    secondaryContainer: Color(0xFF233645),
    onSecondaryContainer: Color(0xFFC5EEFF),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFF2CDCD), // Flamingo
    onTertiary: Color(0xFF311F24),
    tertiaryContainer: Color(0xFF563941),
    onTertiaryContainer: Color(0xFFFFE3E3),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFF38BA8), // Catppuccin Red
    onError: Color(0xFF181825),
    errorContainer: Color(0xFF612638),
    onErrorContainer: Color(0xFFFFD1DC),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF45475A), // Surface1
    surfaceContainerHigh: Color(0xFF313244), // * Used for card backgrounds Folder menu (Surface0)
    surfaceContainer: Color(0xFF1E1E2E), // app bar color, sort-button color (Base)
    surfaceContainerLow: Color(0xFF181825), // * Used for card backgrounds, Bottom slider color, + search bar color (Mantle)
    surfaceContainerLowest: Color(0xFF11111B), // Main Folder_Manager & Folder_selector background Color (Crust)
    surface: Color(0xFF181825), // * Used for Bottom Layer (Mantle Base)

    onSurface: Color(0xFFCDD6F4), // Main Text
    onSurfaceVariant: Color(0xFFA6ADC8), // Subtext0
    surfaceTint: Color(0xFFCBA6F7),

    // OUTLINES & BORDERS
    outline: Color(0xFF6C7086), // Overlay0
    outlineVariant: Color(0xFF313244), // Surface0

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFCDD6F4),
    onInverseSurface: Color(0xFF181825),
    inversePrimary: Color(0xFF764BB5),

    // SHADOWS & SCRIMS
    shadow: Colors.black,
    scrim: Colors.black87,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: AppTypography.textTheme,
    colorScheme: colorScheme,

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFCBA6F7),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onSurface;
            }
            return colorScheme.onSurfaceVariant;
          },
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFCBA6F7),
        foregroundColor: const Color(0xFF181825),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFCBA6F7),
        side: const BorderSide(color: Color(0xFF6C7086)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: const Color(0xFFCBA6F7),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF313244),
      foregroundColor: Color(0xFFCDD6F4),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181825),
      foregroundColor: Color(0xFFCDD6F4),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    extensions: [SyncStatusColors.catppuccin()],
  );
}
