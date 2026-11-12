part of '../app_theme.dart';

ThemeData get _cyberpunkThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFFFF2A85), // Neon Pink
    onPrimary: Color(0xFF120E24),
    primaryContainer: Color(0xFF590032), // Deep Neon Pink
    onPrimaryContainer: Color(0xFFFFD1E6),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF00F0FF), // Electric Neon Cyan
    onSecondary: Color(0xFF002B30),
    secondaryContainer: Color(0xFF004D57),
    onSecondaryContainer: Color(0xFFB8F8FF),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFB967FF), // Neon Purple Accent
    onTertiary: Color(0xFF22003D),
    tertiaryContainer: Color(0xFF4A1078),
    onTertiaryContainer: Color(0xFFF2D6FF),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFFF3344), // Neon Red
    onError: Color(0xFF240407),
    errorContainer: Color(0xFF6B0B14),
    onErrorContainer: Color(0xFFFFD6DA),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF2D2447),
    surfaceContainerHigh: Color(0xFF231B39), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFF191333), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFF140F2B), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFF0D091F), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFF0C091A), // * Used for Bottom Layer (Midnight Cosmic Base)

    onSurface: Color(0xFFF1EBF9), // Glowing Pale Cyan-White
    onSurfaceVariant: Color(0xFFA59ABF), // Muted Lavender
    surfaceTint: Color(0xFFFF2A85),

    // OUTLINES & BORDERS
    outline: Color(0xFF7A6B9B),
    outlineVariant: Color(0xFF332A4D),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFF1EBF9),
    onInverseSurface: Color(0xFF0C091A),
    inversePrimary: Color(0xFFB80053),

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
        foregroundColor: const Color(0xFFFF2A85),
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
        backgroundColor: const Color(0xFFFF2A85),
        foregroundColor: const Color(0xFF120E24),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF2A85),
        side: const BorderSide(color: Color(0xFF7A6B9B)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF191333),
        foregroundColor: const Color(0xFFFF2A85),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF590032),
      foregroundColor: Color(0xFFFFD1E6),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0C091A),
      foregroundColor: Color(0xFFF1EBF9),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    extensions: [
      SyncStatusColors.cyberpunk(),
      FolderThemeColors.cyberpunk(),
      NetworkSignalColors.cyberpunk(),
      WorkspaceThemeColors.cyberpunk(),
    ],
  );
}
