part of '../app_theme.dart';

ThemeData get _darkThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme: AppTypography.textTheme,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    // The most prominent color, used for prominent active elements like filled buttons, active switches, and selected states.
    primary: Color(0xFF939BEA),
    // Text and icons sitting directly on top of the 'primary' color. Needs high contrast.
    onPrimary: Color(0xFF1B1D3D),
    // A softer, lower-emphasis version of the primary color. Used for the default Floating Action Button (FAB) background.
    primaryContainer: Color(0xFF3b3d44),
    // Text and icons sitting directly on top of 'primaryContainer'.
    onPrimaryContainer: Color(0xFFD6DBFF),

    //  SECONDARY COLORS (The Accent)
    // An accent color for less prominent elements like filter chips, secondary buttons, and checkboxes.
    secondary: Color(0xFF73C5A8),
    // Text and icons sitting directly on top of the 'secondary' color.
    onSecondary: Color(0xFF0B2C1F),
    // A softer version of the secondary color, used for tonal buttons or selection backgrounds.
    secondaryContainer: Color(0xFF1A4C3A),
    // Text and icons sitting directly on top of 'secondaryContainer'.
    onSecondaryContainer: Color(0xFFAEF3D3),

    // TERTIARY COLORS (The Balancing Accent)
    // A third accent color used to balance primary/secondary colors. Great for contrasting UI elements or illustrations.
    tertiary: Color(0xFFDF9E7B),
    // Text and icons sitting directly on top of the 'tertiary' color.
    onTertiary: Color(0xFF3B1808),
    // A softer version of the tertiary color, used for tertiary tonal buttons or contrasting card backgrounds.
    tertiaryContainer: Color(0xFF5A2A14),
    // Text and icons sitting directly on top of 'tertiaryContainer'.
    onTertiaryContainer: Color(0xFFFFDBC8),

    // ERROR COLORS (Destructive Actions)
    // Used exclusively to indicate destructive actions, failures, invalid inputs, or critical alerts.
    error: Color(0xFFE27777),
    // Text and icons sitting directly on top of the 'error' color.
    onError: Color(0xFF3E0000),
    // A softer error color used for the background of error banners or large error dialogs to avoid being too harsh.
    errorContainer: Color(0xFF731A1A),
    // Text and icons sitting directly on top of 'errorContainer'.
    onErrorContainer: Color(0xFFFFDAD6),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    // surfaceContainerHighest :Color(0xFF1B1E27),
    // surfaceContainerHigh :Color(0xFF1B1E27),
    surfaceContainer :Color(0xFF222733),
    surfaceContainerLow: Color(0xFF1B1E27), // * Used for card backgrounds

    surfaceContainerLowest: Color(0xFF1B1E27),
    surface: Color(0xFF14161C), // * Used for Bottom Layer
    // The vast majority of your app's background space (Scaffold backgrounds).

    // High-emphasis text (headings, standard text) and default icons sitting directly on top of 'surface'.
    onSurface: Color(0xFFE2E4E9),
    // Used for medium-emphasis text (like subtitles, hints, captions) sitting on top of surfaces.
    onSurfaceVariant: Color(0xFF8A90A2),
    // A slightly lighter tint overlay applied to surfaces in Material 3 to indicate elevation instead of using heavy shadows.
    surfaceTint: Color(0xFF939BEA),
    // Usually mirrors the primary color

    // OUTLINES & BORDERS
    // A prominent, high-contrast color used for active text field borders, strong dividers, or outlined buttons.
    outline: Color(0xFF7E8496),
    // Outline under the text field
    // outline: Color(0xFF7E8496),
    // A subtle, lower-contrast color for decorative boundaries, unselected card borders, or subtle list dividers.
    outlineVariant: Color(0xFF2E323D),

    // INVERSE COLORS (For Snackbars & Tooltips)
    // A background color that sharply contrasts with the main theme (a light color in a dark theme). Used for Snackbars.
    inverseSurface: Color(0xFFE2E4E9),
    // Text and icons sitting on top of 'inverseSurface' (should contrast it, usually a dark color).
    onInverseSurface: Color(0xFF14161C),
    // Used for actionable elements (like a "Retry" text button) sitting inside an inverseSurface (Snackbar).
    inversePrimary: Color(0xFF3F479C),

    // SHADOWS & SCRIMS
    // The color used to render drop shadows behind elevated components.
    shadow: Colors.black,
    // The semi-transparent overlay color placed behind modal bottom sheets or dialogs to darken the app content behind it.
    scrim: Colors.black87,
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

);
