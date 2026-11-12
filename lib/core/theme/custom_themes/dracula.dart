part of '../app_theme.dart';

ThemeData get _draculaThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFFBD93F9), // Vibrant Purple
    onPrimary: Color(0xFF1E1F29),
    primaryContainer: Color(0xFF44475A), // Current Selection/Container
    onPrimaryContainer: Color(0xFFF8F8F2),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF8BE9FD), // Cyan Accent
    onSecondary: Color(0xFF1E1F29),
    secondaryContainer: Color(0xFF283A42),
    onSecondaryContainer: Color(0xFFA4F0FF),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFFF79C6), // Pink Accent
    onTertiary: Color(0xFF280018),
    tertiaryContainer: Color(0xFF581D43),
    onTertiaryContainer: Color(0xFFFFD1EC),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFFF5555), // Dracula Red
    onError: Color(0xFF1E1F29),
    errorContainer: Color(0xFF661414),
    onErrorContainer: Color(0xFFFFD1D1),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF383A4D),
    surfaceContainerHigh: Color(0xFF2E303E), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFF282A36), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFF21222C), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFF191A21), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFF1E1F29), // * Used for Bottom Layer (Dracula Dark Base)

    onSurface: Color(0xFFF8F8F2), // Foreground White
    onSurfaceVariant: Color(0xFF6272A4), // Muted Blue-Grey
    surfaceTint: Color(0xFFBD93F9),

    // OUTLINES & BORDERS
    outline: Color(0xFF6272A4),
    outlineVariant: Color(0xFF343746),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFF8F8F2),
    onInverseSurface: Color(0xFF1E1F29),
    inversePrimary: Color(0xFF6B4AA8),

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
        foregroundColor: const Color(0xFFBD93F9),
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
        backgroundColor: const Color(0xFFBD93F9),
        foregroundColor: const Color(0xFF1E1F29),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFBD93F9),
        side: const BorderSide(color: Color(0xFF6272A4)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF282A36),
        foregroundColor: const Color(0xFFBD93F9),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF44475A),
      foregroundColor: Color(0xFFF8F8F2),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1F29),
      foregroundColor: Color(0xFFF8F8F2),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    extensions: [SyncStatusColors.dracula()],
  );
}
