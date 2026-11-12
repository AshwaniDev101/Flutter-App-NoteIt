part of '../app_theme.dart';

ThemeData get _oceanThemeData {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,

    // PRIMARY COLORS (The Main Brand)
    primary: Color(0xFF1E6091), // Deep Oceanic Blue
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD0E6F7), // Sea Foam Light
    onPrimaryContainer: Color(0xFF0B2545),

    // SECONDARY COLORS (The Accent)
    secondary: Color(0xFF48CAE4), // Turquoise Azure
    onSecondary: Color(0xFF002D38),
    secondaryContainer: Color(0xFFB9F2FD),
    onSecondaryContainer: Color(0xFF003643),

    // TERTIARY COLORS (The Balancing Accent)
    tertiary: Color(0xFFF77F00), // Sunset Coral
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBC7),
    onTertiaryContainer: Color(0xFF331400),

    // ERROR COLORS (Destructive Actions)
    error: Color(0xFFD90429), // Marine Red
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    surfaceContainerHighest: Color(0xFFDDE6ED),
    surfaceContainerHigh: Color(0xFFE4EDF5), // * Used for card backgrounds Folder menu
    surfaceContainer: Color(0xFFEEF4F8), // app bar color, sort-button color
    surfaceContainerLow: Color(0xFFF4F8FC), // * Used for card backgrounds, Bottom slider color, + search bar color
    surfaceContainerLowest: Color(0xFFFFFFFF), // Main Folder_Manager & Folder_selector background Color
    surface: Color(0xFFF0F4F8), // * Used for Bottom Layer (Clean Sky White)

    onSurface: Color(0xFF102A43), // Deep Navy Slate
    onSurfaceVariant: Color(0xFF486581), // Muted Steel Blue
    surfaceTint: Color(0xFF1E6091),

    // OUTLINES & BORDERS
    outline: Color(0xFF829AB1),
    outlineVariant: Color(0xFFD9E2EC),

    // INVERSE COLORS (For Snackbars & Tooltips)
    inverseSurface: Color(0xFF102A43),
    onInverseSurface: Color(0xFFF0F4F8),
    inversePrimary: Color(0xFF88C4EE),

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
        foregroundColor: const Color(0xFF1E6091),
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
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E6091),
        side: const BorderSide(color: Color(0xFF829AB1)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEEF4F8),
        foregroundColor: const Color(0xFF1E6091),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD0E6F7),
      foregroundColor: Color(0xFF0B2545),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F4F8),
      foregroundColor: Color(0xFF102A43),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    extensions: [SyncStatusColors.ocean()],
  );
}
