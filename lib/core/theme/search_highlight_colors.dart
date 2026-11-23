import 'package:flutter/material.dart';

@immutable
class SearchHighlightColors extends ThemeExtension<SearchHighlightColors> {
  final Color activeBackground;
  final Color activeForeground;
  final Color activeUnderline;

  final Color passiveBackground;
  final Color passiveForeground;
  final Color passiveUnderline;

  const SearchHighlightColors({
    required this.activeBackground,
    required this.activeForeground,
    required this.activeUnderline,
    required this.passiveBackground,
    required this.passiveForeground,
    required this.passiveUnderline,
  });

  /// Retrieves the active theme's [SearchHighlightColors] extension or fallback
  static SearchHighlightColors of(BuildContext context) {
    return Theme.of(context).extension<SearchHighlightColors>() ?? SearchHighlightColors.light();
  }

  factory SearchHighlightColors.light() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFD54F),
        activeForeground: Color(0xFF000000),
        activeUnderline: Color(0xFFE65100),
        passiveBackground: Color(0x99FFF176),
        passiveForeground: Color(0xDE000000),
        passiveUnderline: Color(0xFFF57F17),
      );

  factory SearchHighlightColors.dark() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFB74D),
        activeForeground: Color(0xFF000000),
        activeUnderline: Color(0xFFFF6D00),
        passiveBackground: Color(0x59FFD54F),
        passiveForeground: Color(0xFFFFF59D),
        passiveUnderline: Color(0xFFFFD54F),
      );

  factory SearchHighlightColors.amoled() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFB74D),
        activeForeground: Color(0xFF000000),
        activeUnderline: Color(0xFFFF6D00),
        passiveBackground: Color(0x59FFD54F),
        passiveForeground: Color(0xFFFFF59D),
        passiveUnderline: Color(0xFFFFD54F),
      );

  factory SearchHighlightColors.sepia() => const SearchHighlightColors(
        activeBackground: Color(0xFFF6D55C),
        activeForeground: Color(0xFF2C1D11),
        activeUnderline: Color(0xFFD97706),
        passiveBackground: Color(0x80FDE047),
        passiveForeground: Color(0xFF433422),
        passiveUnderline: Color(0xFFCA8A04),
      );

  factory SearchHighlightColors.dracula() => const SearchHighlightColors(
        activeBackground: Color(0xFFF1FA8C),
        activeForeground: Color(0xFF282A36),
        activeUnderline: Color(0xFFFFB86C),
        passiveBackground: Color(0x59F1FA8C),
        passiveForeground: Color(0xFFF8F8F2),
        passiveUnderline: Color(0xFFF1FA8C),
      );

  factory SearchHighlightColors.nord() => const SearchHighlightColors(
        activeBackground: Color(0xFFEBCB8B),
        activeForeground: Color(0xFF2E3440),
        activeUnderline: Color(0xFFD08770),
        passiveBackground: Color(0x59EBCB8B),
        passiveForeground: Color(0xFFECEFF4),
        passiveUnderline: Color(0xFFEBCB8B),
      );

  factory SearchHighlightColors.catppuccin() => const SearchHighlightColors(
        activeBackground: Color(0xFFF9E2AF),
        activeForeground: Color(0xFF1E1E2E),
        activeUnderline: Color(0xFFFAB387),
        passiveBackground: Color(0x59F9E2AF),
        passiveForeground: Color(0xFFCDD6F4),
        passiveUnderline: Color(0xFFF9E2AF),
      );

  factory SearchHighlightColors.forest() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFE082),
        activeForeground: Color(0xFF1B2A20),
        activeUnderline: Color(0xFFD8A47F),
        passiveBackground: Color(0x59FFE082),
        passiveForeground: Color(0xFFE8F5E9),
        passiveUnderline: Color(0xFF95D5B2),
      );

  factory SearchHighlightColors.cyberpunk() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFB800),
        activeForeground: Color(0xFF000000),
        activeUnderline: Color(0xFFFF0055),
        passiveBackground: Color(0x59FFB800),
        passiveForeground: Color(0xFFF1EBF9),
        passiveUnderline: Color(0xFF00F0FF),
      );

  factory SearchHighlightColors.ocean() => const SearchHighlightColors(
        activeBackground: Color(0xFFFFD54F),
        activeForeground: Color(0xFF0F172A),
        activeUnderline: Color(0xFFE65100),
        passiveBackground: Color(0x59FFD54F),
        passiveForeground: Color(0xFFE2E8F0),
        passiveUnderline: Color(0xFF38BDF8),
      );

  @override
  SearchHighlightColors copyWith({
    Color? activeBackground,
    Color? activeForeground,
    Color? activeUnderline,
    Color? passiveBackground,
    Color? passiveForeground,
    Color? passiveUnderline,
  }) {
    return SearchHighlightColors(
      activeBackground: activeBackground ?? this.activeBackground,
      activeForeground: activeForeground ?? this.activeForeground,
      activeUnderline: activeUnderline ?? this.activeUnderline,
      passiveBackground: passiveBackground ?? this.passiveBackground,
      passiveForeground: passiveForeground ?? this.passiveForeground,
      passiveUnderline: passiveUnderline ?? this.passiveUnderline,
    );
  }

  @override
  SearchHighlightColors lerp(ThemeExtension<SearchHighlightColors>? other, double t) {
    if (other is! SearchHighlightColors) return this;
    return SearchHighlightColors(
      activeBackground: Color.lerp(activeBackground, other.activeBackground, t)!,
      activeForeground: Color.lerp(activeForeground, other.activeForeground, t)!,
      activeUnderline: Color.lerp(activeUnderline, other.activeUnderline, t)!,
      passiveBackground: Color.lerp(passiveBackground, other.passiveBackground, t)!,
      passiveForeground: Color.lerp(passiveForeground, other.passiveForeground, t)!,
      passiveUnderline: Color.lerp(passiveUnderline, other.passiveUnderline, t)!,
    );
  }
}

extension SearchHighlightColorsContextX on BuildContext {
  SearchHighlightColors get searchHighlightColors => SearchHighlightColors.of(this);
}
