part of '../app_theme.dart';

ThemeData get _sepiaThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFFD97757), // Terracotta
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5D0C3), // Soft Terracotta
    onPrimaryContainer: Color(0xFF4A1808),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF7A8B76), // Warm Sage
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE5D8),
    onSecondaryContainer: Color(0xFF1B2B18),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFF8C6E54), // Earthy Brown
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF0E0D0),
    onTertiaryContainer: Color(0xFF332214),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFFEAD9BD),
    surfaceContainerHigh: Color(0xFFEFE1C9), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFFF4E7D2), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFFF7ECD8), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFFFFFBF3), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFFFBF0D9), // * Used for Bottom Layer (Cream paper coloration)

    onSurface: Color(0xFF433422),
    onSurfaceVariant: Color(0xFF78624E),
    surfaceTint: Color(0xFFD97757),

    // OUTLINES & BORDERS
    outline: Color(0xFF9E8873),
    outlineVariant: Color(0xFFE5D5C1),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFF3D3020),
    onInverseSurface: Color(0xFFFBF0D9),
    inversePrimary: Color(0xFFFFB59D),

    // SHADOWS & SCRIMS
    shadow: Colors.black,
    scrim: Colors.black87,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: AppTypography.textTheme,
    colorScheme: colorScheme,

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD97757),
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
        backgroundColor: const Color(0xFFD97757),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD97757),
        side: const BorderSide(color: Color(0xFF9E8873)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF4E7D2),
        foregroundColor: const Color(0xFFD97757),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF5D0C3),
      foregroundColor: Color(0xFF4A1808),
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

    extensions: [
      SyncStatusColors.sepia(),
      FolderThemeColors.sepia(),
      NetworkSignalColors.sepia(),
      WorkspaceThemeColors.sepia(),
    ],
  );
}
