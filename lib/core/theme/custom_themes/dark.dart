part of '../app_theme.dart';

ThemeData get _darkThemeData => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme: AppTypography.textTheme,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    // PRIMARY COLORS (The Main Brand)
    // The most prominent color, used for prominent active elements like filled buttons, active switches, and selected states.
    primary: Color(0xFFA6ACFF), // Vibrant Lavender
    // Text and icons sitting directly on top of the 'primary' color. Needs high contrast.
    onPrimary: Color(0xFF0B105C),
    // A softer, lower-emphasis version of the primary color. Used for the default Floating Action Button (FAB) background.
    primaryContainer: Color(0xFF262E7A), // Deep, rich violet
    // Text and icons sitting directly on top of 'primaryContainer'.
    onPrimaryContainer: Color(0xFFDFE2FF),

    //  SECONDARY COLORS (The Accent)
    // An accent color for less prominent elements like filter chips, secondary buttons, and checkboxes.
    secondary: Color(0xFF5CE1E6), // Bright Cyan
    // Text and icons sitting directly on top of the 'secondary' color.
    onSecondary: Color(0xFF003739),
    // A softer version of the secondary color, used for tonal buttons or selection backgrounds.
    secondaryContainer: Color(0xFF004F53),
    // Text and icons sitting directly on top of 'secondaryContainer'.
    onSecondaryContainer: Color(0xFF99F5F8),

    // TERTIARY COLORS (The Balancing Accent)
    // A third accent color used to balance primary/secondary colors. Great for contrasting UI elements or illustrations.
    tertiary: Color(0xFFFF9EAA), // Vibrant Pastel Coral/Pink
    // Text and icons sitting directly on top of the 'tertiary' color.
    onTertiary: Color(0xFF530018),
    // A softer version of the tertiary color, used for tertiary tonal buttons or contrasting card backgrounds.
    tertiaryContainer: Color(0xFF75122B),
    // Text and icons sitting directly on top of 'tertiaryContainer'.
    onTertiaryContainer: Color(0xFFFFD9DF),

    // ERROR COLORS (Destructive Actions)
    // Used exclusively to indicate destructive actions, failures, invalid inputs, or critical alerts.
    error: Color(0xFFFF897D),
    // Text and icons sitting directly on top of the 'error' color.
    onError: Color(0xFF601410),
    // A softer error color used for the background of error banners or large error dialogs to avoid being too harsh.
    errorContainer: Color(0xFF8C1D18),
    // Text and icons sitting directly on top of 'errorContainer'.
    onErrorContainer: Color(0xFFFFDAD6),

    // BACKGROUND & SURFACE COLORS (The Canvas)

    // ==== Surface levels ====
    // surfaceContainerHighest :Color(0xFF1B1E27),
    // surfaceContainerHigh :Color(0xFF1B1E27),
    surfaceContainer: Color(0xFF22263A),
    surfaceContainerLow: Color(0xFF1A1D2D), // * Used for card backgrounds

    surfaceContainerLowest: Color(0xFF151724),
    surface: Color(0xFF0F111A), // * Used for Bottom Layer (Deep indigo-black)
    // The vast majority of your app's background space (Scaffold backgrounds).

    // High-emphasis text (headings, standard text) and default icons sitting directly on top of 'surface'.
    onSurface: Color(0xFFE2E6FF), // Crisp, slightly cool white
    // Used for medium-emphasis text (like subtitles, hints, captions) sitting on top of surfaces.
    onSurfaceVariant: Color(0xFF8F95B2),
    // A slightly lighter tint overlay applied to surfaces in Material 3 to indicate elevation instead of using heavy shadows.
    surfaceTint: Color(0xFFA6ACFF),
    // Usually mirrors the primary color

    // OUTLINES & BORDERS
    // A prominent, high-contrast color used for active text field borders, strong dividers, or outlined buttons.
    outline: Color(0xFF757B9A),
    // Outline under the text field
    // outline: Color(0xFF7E8496),
    // A subtle, lower-contrast color for decorative boundaries, unselected card borders, or subtle list dividers.
    outlineVariant: Color(0xFF383E59),

    // INVERSE COLORS (For Snackbars & Tooltips)
    // A background color that sharply contrasts with the main theme (a light color in a dark theme). Used for Snackbars.
    inverseSurface: Color(0xFFE2E6FF),
    // Text and icons sitting on top of 'inverseSurface' (should contrast it, usually a dark color).
    onInverseSurface: Color(0xFF0F111A),
    // Used for actionable elements (like a "Retry" text button) sitting inside an inverseSurface (Snackbar).
    inversePrimary: Color(0xFF3F48B2),

    // SHADOWS & SCRIMS
    // The color used to render drop shadows behind elevated components.
    shadow: Colors.black,
    // The semi-transparent overlay color placed behind modal bottom sheets or dialogs to darken the app content behind it.
    scrim: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F111A),
    foregroundColor: Color(0xFFE2E6FF),
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
);