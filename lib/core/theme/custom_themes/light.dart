part of '../app_theme.dart';

ThemeData get _lightThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFFE5A040), // Warm Amber
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFBE3B5), // Soft Amber
    onPrimaryContainer: Color(0xFF4A2E00),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFFC78532), // Warm Copper
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFDECD2),
    onSecondaryContainer: Color(0xFF402700),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFF6E8B6B), // Soft Sage
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD6E8CE),
    onTertiaryContainer: Color(0xFF111F10),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFE27777),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCDADA),
    onErrorContainer: Color(0xFF410E0E),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFFEDEAE6),
    surfaceContainerHigh: Color(0xFFF3F0EC), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFFF8F5F1), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFFFAF8F5), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFFFFFFFF), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFFFCFBF9), // * Used for Bottom Layer (Crisp warm white)

    onSurface: Color(0xFF292524),
    onSurfaceVariant: Color(0xFF78716C),
    surfaceTint: Color(0xFFE5A040),

    // OUTLINES & BORDERS
    outline: Color(0xFFA8A29E),
    outlineVariant: Color(0xFFE7E5E4),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFF34302E),
    onInverseSurface: Color(0xFFF8F5F1),
    inversePrimary: Color(0xFFFFB960),

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
        foregroundColor: const Color(0xFFE5A040),
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
        backgroundColor: const Color(0xFFE5A040),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE5A040),
        side: const BorderSide(color: Color(0xFFA8A29E)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF8F5F1),
        foregroundColor: const Color(0xFFE5A040),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFBE3B5),
      foregroundColor: Color(0xFF4A2E00),
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

    extensions: [
      SyncStatusColors.light(),
      FolderThemeColors.light(),
      NetworkSignalColors.light(),
      WorkspaceThemeColors.light(),
    ],
  );
}
