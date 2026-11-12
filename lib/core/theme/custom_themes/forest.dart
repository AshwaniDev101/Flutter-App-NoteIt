part of '../app_theme.dart';

ThemeData get _forestThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFF52B788), // Emerald Mint
    onPrimary: Color(0xFF081C15),
    primaryContainer: Color(0xFF1B4332), // Deep Botanical
    onPrimaryContainer: Color(0xFFD8F3DC),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFFD8A47F), // Warm Wood Accent
    onSecondary: Color(0xFF24150C),
    secondaryContainer: Color(0xFF482D1D),
    onSecondaryContainer: Color(0xFFF9E7DB),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFF95D5B2), // Soft Mint
    onTertiary: Color(0xFF0D2818),
    tertiaryContainer: Color(0xFF2D6A4F),
    onTertiaryContainer: Color(0xFFE8F5E9),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFE56B6F), // Soft Crimson
    onError: Color(0xFF2B0A0C),
    errorContainer: Color(0xFF641E22),
    onErrorContainer: Color(0xFFFFD1D3),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF2D3C33),
    surfaceContainerHigh: Color(0xFF223028), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFF18241D), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFF121B16), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFF0D1410), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFF0D1410), // * Used for Bottom Layer (Deep Forest Black)

    onSurface: Color(0xFFE8F5E9), // Crisp Pale Mint
    onSurfaceVariant: Color(0xFF94A89A), // Muted Sage Grey
    surfaceTint: Color(0xFF52B788),

    // OUTLINES & BORDERS
    outline: Color(0xFF5B7365),
    outlineVariant: Color(0xFF27362E),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFE8F5E9),
    onInverseSurface: Color(0xFF0D1410),
    inversePrimary: Color(0xFF2D8A5F),

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
        foregroundColor: const Color(0xFF52B788),
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
        backgroundColor: const Color(0xFF52B788),
        foregroundColor: const Color(0xFF081C15),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF52B788),
        side: const BorderSide(color: Color(0xFF5B7365)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18241D),
        foregroundColor: const Color(0xFF52B788),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1B4332),
      foregroundColor: Color(0xFFD8F3DC),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1410),
      foregroundColor: Color(0xFFE8F5E9),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    extensions: [
      SyncStatusColors.forest(),
      FolderThemeColors.forest(),
      NetworkSignalColors.forest(),
      WorkspaceThemeColors.forest(),
    ],
  );
}
