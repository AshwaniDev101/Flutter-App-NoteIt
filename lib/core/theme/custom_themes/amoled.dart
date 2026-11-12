part of '../app_theme.dart';

ThemeData get _amoledThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFF939BEA), // Soft Violet
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF252850), // Deep Violet
    onPrimaryContainer: Color(0xFFD0D4F7),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF73C5A8), // Cool Mint Cyan
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1E3A30),
    onSecondaryContainer: Color(0xFF9FE7CE),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFE5989B), // Soft Muted Rose
    onTertiary: Color(0xFF411015),
    tertiaryContainer: Color(0xFF5E2127),
    onTertiaryContainer: Color(0xFFFFD9DD),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFCF6679),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFFFDAD6),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF242424),
    surfaceContainerHigh: Color(0xFF1A1A1A), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFF121212), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFF0A0A0A), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFF000000), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFF000000), // * Used for Bottom Layer (Pure deep black)

    onSurface: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFFA0A0A0),
    surfaceTint: Color(0xFF939BEA),

    // OUTLINES & BORDERS
    outline: Color(0xFF6E6E6E),
    outlineVariant: Color(0xFF1F1F1F),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFE0E0E0),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF3B449B),

    // SHADOWS & SCRIMS
    shadow: Colors.black,
    scrim: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: AppTypography.textTheme,
    colorScheme: colorScheme,

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF939BEA),
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
        backgroundColor: const Color(0xFF939BEA),
        foregroundColor: Colors.black,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF939BEA),
        side: const BorderSide(color: Color(0xFF6E6E6E)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: const Color(0xFF939BEA),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF252850),
      foregroundColor: Color(0xFFD0D4F7),
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

    extensions: [
      SyncStatusColors.amoled(),
      FolderThemeColors.amoled(),
      NetworkSignalColors.amoled(),
      WorkspaceThemeColors.amoled(),
    ],
  );
}
