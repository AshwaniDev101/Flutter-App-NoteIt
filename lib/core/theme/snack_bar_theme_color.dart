import 'package:flutter/material.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';


@immutable
class SnackBarThemeColor extends ThemeExtension<SnackBarThemeColor> {
  final Color errorBackground;
  final Color errorForeground;

  final Color infoBackground;
  final Color infoForeground;

  final Color acknowledgmentBackground;
  final Color acknowledgmentForeground;

  final Color suggestionBackground;
  final Color suggestionForeground;

  final Color warningBackground;
  final Color warningForeground;

  const SnackBarThemeColor({
    required this.errorBackground,
    required this.errorForeground,
    required this.infoBackground,
    required this.infoForeground,
    required this.acknowledgmentBackground,
    required this.acknowledgmentForeground,
    required this.suggestionBackground,
    required this.suggestionForeground,
    required this.warningBackground,
    required this.warningForeground,
  });

  /// Resolves (backgroundColor, foregroundColor) for a given [SnackBarMessageType].
  (Color, Color) getColors(SnackBarMessageType type) {
    switch (type) {
      case SnackBarMessageType.error:
        return (errorBackground, errorForeground);
      case SnackBarMessageType.info:
        return (infoBackground, infoForeground);
      case SnackBarMessageType.acknowledgment:
        return (acknowledgmentBackground, acknowledgmentForeground);
      case SnackBarMessageType.suggestion:
        return (suggestionBackground, suggestionForeground);
      case SnackBarMessageType.warning:
        return (warningBackground, warningForeground);
    }
  }

  /// Retrieves (backgroundColor, foregroundColor) pair for a [SnackBarMessageType]
  /// using the active theme's [SnackBarThemeColor] extension or fallback colors.
  static (Color, Color) of(BuildContext? context, SnackBarMessageType type) {
    if (context != null) {
      final theme = Theme.of(context);
      final ext = theme.extension<SnackBarThemeColor>();
      if (ext != null) {
        // Return existing theme color
        return ext.getColors(type);
      }
      // Return generated
      return SnackBarThemeColor.fromColorScheme(theme.colorScheme).getColors(type);
    }
    return SnackBarThemeColor.light().getColors(type);
  }



  /// Dynamic factory generating snackBar colors automatically from a [ColorScheme].
  factory SnackBarThemeColor.fromColorScheme(ColorScheme scheme) => SnackBarThemeColor(
        errorBackground: scheme.errorContainer,
        errorForeground: scheme.onErrorContainer,
        infoBackground: scheme.secondaryContainer,
        infoForeground: scheme.onSecondaryContainer,
        acknowledgmentBackground: scheme.primaryContainer,
        acknowledgmentForeground: scheme.onPrimaryContainer,
        suggestionBackground: scheme.tertiaryContainer,
        suggestionForeground: scheme.onTertiaryContainer,
        warningBackground: scheme.surfaceContainerHighest,
        warningForeground: scheme.onSurfaceVariant,
      );

  factory SnackBarThemeColor.light() => const SnackBarThemeColor(
        errorBackground: Color(0xFFFCDADA),
        errorForeground: Color(0xFF8C1D18),
        infoBackground: Color(0xFFE0F2FE),
        infoForeground: Color(0xFF0369A1),
        acknowledgmentBackground: Color(0xFFDCFCE7),
        acknowledgmentForeground: Color(0xFF15803D),
        suggestionBackground: Color(0xFFFDECD2),
        suggestionForeground: Color(0xFF8A4B00),
        warningBackground: Color(0xFFFEF08A),
        warningForeground: Color(0xFF854D0E),
      );

  factory SnackBarThemeColor.dark() => const SnackBarThemeColor(

    errorBackground: Color(0xFF421C1A),
    errorForeground: Color(0xFFFF897D),

    infoBackground: Color(0xFF1D375C),
    infoForeground: Color(0xFFABC7D3),

    acknowledgmentBackground: Color(0xFF004F53),
    acknowledgmentForeground: Color(0xFF5CE1E6),

    suggestionBackground: Color(0xFF3C4BA2),
    suggestionForeground: Color(0xFFCACDF5),

    warningBackground: Color(0xFF4A3B10),
    warningForeground: Color(0xFFE2C53A),
  );

  factory SnackBarThemeColor.amoled() => const SnackBarThemeColor(
        errorBackground: Color(0xFF2C0B0E),
        errorForeground: Color(0xFFFF6B6B),
        infoBackground: Color(0xFF0A2540),
        infoForeground: Color(0xFF339AF0),
        acknowledgmentBackground: Color(0xFF0A2E1C),
        acknowledgmentForeground: Color(0xFF51CF66),
        suggestionBackground: Color(0xFF332000),
        suggestionForeground: Color(0xFFFCC419),
        warningBackground: Color(0xFF3D1F00),
        warningForeground: Color(0xFFFF922B),
      );

  factory SnackBarThemeColor.sepia() => const SnackBarThemeColor(
        errorBackground: Color(0xFFF4DCD6),
        errorForeground: Color(0xFFB0533C),
        infoBackground: Color(0xFFD6E4F0),
        infoForeground: Color(0xFF3B678A),
        acknowledgmentBackground: Color(0xFFD8E6D5),
        acknowledgmentForeground: Color(0xFF437A55),
        suggestionBackground: Color(0xFFF2E6C9),
        suggestionForeground: Color(0xFF8A723B),
        warningBackground: Color(0xFFF5E0C3),
        warningForeground: Color(0xFF9E5C38),
      );

  factory SnackBarThemeColor.dracula() => const SnackBarThemeColor(
        errorBackground: Color(0xFF44272E),
        errorForeground: Color(0xFFFF5555),
        infoBackground: Color(0xFF213B4D),
        infoForeground: Color(0xFF8BE9FD),
        acknowledgmentBackground: Color(0xFF1B3B2B),
        acknowledgmentForeground: Color(0xFF50FA7B),
        suggestionBackground: Color(0xFF44422B),
        suggestionForeground: Color(0xFFF1FA8C),
        warningBackground: Color(0xFF443327),
        warningForeground: Color(0xFFFFB86C),
      );

  factory SnackBarThemeColor.nord() => const SnackBarThemeColor(
        errorBackground: Color(0xFF4C3A42),
        errorForeground: Color(0xFFBF616A),
        infoBackground: Color(0xFF3B4856),
        infoForeground: Color(0xFF88C0D0),
        acknowledgmentBackground: Color(0xFF3D4C43),
        acknowledgmentForeground: Color(0xFFA3BE8C),
        suggestionBackground: Color(0xFF4F4B41),
        suggestionForeground: Color(0xFFEBCB8B),
        warningBackground: Color(0xFF4F433E),
        warningForeground: Color(0xFFD08770),
      );

  factory SnackBarThemeColor.catppuccin() => const SnackBarThemeColor(
        errorBackground: Color(0xFF452735),
        errorForeground: Color(0xFFF38BA8),
        infoBackground: Color(0xFF263952),
        infoForeground: Color(0xFF89B4FA),
        acknowledgmentBackground: Color(0xFF293E39),
        acknowledgmentForeground: Color(0xFFA6E3A1),
        suggestionBackground: Color(0xFF453D32),
        suggestionForeground: Color(0xFFF9E2AF),
        warningBackground: Color(0xFF453532),
        warningForeground: Color(0xFFFAB387),
      );

  factory SnackBarThemeColor.forest() => const SnackBarThemeColor(
        errorBackground: Color(0xFF422326),
        errorForeground: Color(0xFFE56B6F),
        infoBackground: Color(0xFF1E3A45),
        infoForeground: Color(0xFF74C7EC),
        acknowledgmentBackground: Color(0xFF1F4434),
        acknowledgmentForeground: Color(0xFF52B788),
        suggestionBackground: Color(0xFF3D3A26),
        suggestionForeground: Color(0xFFD8F3DC),
        warningBackground: Color(0xFF3D2E24),
        warningForeground: Color(0xFFD8A47F),
      );

  factory SnackBarThemeColor.cyberpunk() => const SnackBarThemeColor(
        errorBackground: Color(0xFF3D0017),
        errorForeground: Color(0xFFFF0055),
        infoBackground: Color(0xFF003344),
        infoForeground: Color(0xFF00F0FF),
        acknowledgmentBackground: Color(0xFF003D24),
        acknowledgmentForeground: Color(0xFF00FF9D),
        suggestionBackground: Color(0xFF33003D),
        suggestionForeground: Color(0xFFB967FF),
        warningBackground: Color(0xFF3D2C00),
        warningForeground: Color(0xFFFFB800),
      );

  factory SnackBarThemeColor.ocean() => const SnackBarThemeColor(
        errorBackground: Color(0xFF3B1219),
        errorForeground: Color(0xFFE63946),
        infoBackground: Color(0xFF0D3B66),
        infoForeground: Color(0xFF48CAE4),
        acknowledgmentBackground: Color(0xFF134035),
        acknowledgmentForeground: Color(0xFF52B788),
        suggestionBackground: Color(0xFF3D2912),
        suggestionForeground: Color(0xFFF77F00),
        warningBackground: Color(0xFF3D1B12),
        warningForeground: Color(0xFFFF9F1C),
      );

  @override
  SnackBarThemeColor copyWith({
    Color? errorBackground,
    Color? errorForeground,
    Color? infoBackground,
    Color? infoForeground,
    Color? acknowledgmentBackground,
    Color? acknowledgmentForeground,
    Color? suggestionBackground,
    Color? suggestionForeground,
    Color? warningBackground,
    Color? warningForeground,
  }) {
    return SnackBarThemeColor(
      errorBackground: errorBackground ?? this.errorBackground,
      errorForeground: errorForeground ?? this.errorForeground,
      infoBackground: infoBackground ?? this.infoBackground,
      infoForeground: infoForeground ?? this.infoForeground,
      acknowledgmentBackground: acknowledgmentBackground ?? this.acknowledgmentBackground,
      acknowledgmentForeground: acknowledgmentForeground ?? this.acknowledgmentForeground,
      suggestionBackground: suggestionBackground ?? this.suggestionBackground,
      suggestionForeground: suggestionForeground ?? this.suggestionForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
    );
  }

  @override
  SnackBarThemeColor lerp(ThemeExtension<SnackBarThemeColor>? other, double t) {
    if (other is! SnackBarThemeColor) return this;
    return SnackBarThemeColor(
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorForeground: Color.lerp(errorForeground, other.errorForeground, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      acknowledgmentBackground: Color.lerp(acknowledgmentBackground, other.acknowledgmentBackground, t)!,
      acknowledgmentForeground: Color.lerp(acknowledgmentForeground, other.acknowledgmentForeground, t)!,
      suggestionBackground: Color.lerp(suggestionBackground, other.suggestionBackground, t)!,
      suggestionForeground: Color.lerp(suggestionForeground, other.suggestionForeground, t)!,
      warningBackground: Color.lerp(warningBackground, other.warningBackground, t)!,
      warningForeground: Color.lerp(warningForeground, other.warningForeground, t)!,
    );
  }
}

extension SnackBarThemeContextX on BuildContext {
  /// Convenient accessor for active [SnackBarThemeColor] extension
  SnackBarThemeColor get snackBarTheme =>
      Theme.of(this).extension<SnackBarThemeColor>() ?? SnackBarThemeColor.light();

  /// Convenient accessor for background & foreground color pair for a message type
  (Color background, Color foreground) snackBarColors(SnackBarMessageType type) =>
      snackBarTheme.getColors(type);
}
