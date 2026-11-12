part of '../app_theme.dart';

ThemeData get _nordThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFF88C0D0), // Frost Ice Blue
    onPrimary: Color(0xFF2E3440),
    primaryContainer: Color(0xFF434C5E), // Polar Night Medium
    onPrimaryContainer: Color(0xFFECEFF4),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF81A1C1), // Glacier Blue
    onSecondary: Color(0xFF2E3440),
    secondaryContainer: Color(0xFF3B4252),
    onSecondaryContainer: Color(0xFFD8DEE9),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFB48EAD), // Aurora Purple/Pink
    onTertiary: Color(0xFF2E3440),
    tertiaryContainer: Color(0xFF5B4556),
    onTertiaryContainer: Color(0xFFF3E5F0),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFBF616A), // Nord Red
    onError: Color(0xFF2E3440),
    errorContainer: Color(0xFF632B30),
    onErrorContainer: Color(0xFFFFD1D5),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFF4C566A),
    surfaceContainerHigh: Color(0xFF3B4252), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFF2E3440), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFF292E39), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFF20242D), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFF242933), // * Used for Bottom Layer (Deep Polar Base)

    onSurface: Color(0xFFECEFF4), // Snow Storm White
    onSurfaceVariant: Color(0xFFD8DEE9), // Subtle Ice White
    surfaceTint: Color(0xFF88C0D0),

    // OUTLINES & BORDERS
    outline: Color(0xFF4C566A),
    outlineVariant: Color(0xFF353C4A),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFFECEFF4),
    onInverseSurface: Color(0xFF2E3440),
    inversePrimary: Color(0xFF3B7280),

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
        foregroundColor: const Color(0xFF88C0D0),
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
        backgroundColor: const Color(0xFF88C0D0),
        foregroundColor: const Color(0xFF2E3440),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF88C0D0),
        side: const BorderSide(color: Color(0xFF4C566A)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E3440),
        foregroundColor: const Color(0xFF88C0D0),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF434C5E),
      foregroundColor: Color(0xFFECEFF4),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF242933),
      foregroundColor: Color(0xFFECEFF4),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    extensions: [
      SyncStatusColors.nord(),
      FolderThemeColors.nord(),
      NetworkSignalColors.nord(),
      WorkspaceThemeColors.nord(),
    ],
  );
}
