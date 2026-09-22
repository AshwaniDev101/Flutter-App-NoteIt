import 'package:flutter/material.dart';

@immutable
class NoteTheme extends ThemeExtension<NoteTheme> {
  final Color selectedAppBar;
  final Color selectedCheckColor;

  final Color cardTitleBackground;
  final Color cardTitleForeground;

  final Color cardContentBackground;
  final Color cardContentForeground;

  const NoteTheme({
    required this.selectedAppBar,
    required this.selectedCheckColor,
    required this.cardTitleBackground,
    required this.cardTitleForeground,
    required this.cardContentBackground,
    required this.cardContentForeground,
  });

  @override
  NoteTheme copyWith({
    Color? selectedAppBar,
    Color? selectedCheckColor,
    Color? cardTitleBackground,
    Color? cardTitleForeground,
    Color? cardContentBackground,
    Color? cardContentForeground,
  }) {
    return NoteTheme(
      selectedAppBar: selectedAppBar ?? this.selectedAppBar,
      selectedCheckColor: selectedCheckColor ?? this.selectedCheckColor,
      cardTitleBackground: cardTitleBackground ?? this.cardTitleBackground,
      cardTitleForeground: cardTitleForeground ?? this.cardTitleForeground,
      cardContentBackground:
          cardContentBackground ?? this.cardContentBackground,
      cardContentForeground:
          cardContentForeground ?? this.cardContentForeground,
    );
  }

  @override
  NoteTheme lerp(ThemeExtension<NoteTheme>? other, double t) {
    if (other is! NoteTheme) return this;

    return NoteTheme(
      selectedAppBar: Color.lerp(selectedAppBar, other.selectedAppBar, t)!,
      selectedCheckColor: Color.lerp(
        selectedCheckColor,
        other.selectedCheckColor,
        t,
      )!,
      cardTitleBackground: Color.lerp(
        cardTitleBackground,
        other.cardTitleBackground,
        t,
      )!,
      cardTitleForeground: Color.lerp(
        cardTitleForeground,
        other.cardTitleForeground,
        t,
      )!,
      cardContentBackground: Color.lerp(
        cardContentBackground,
        other.cardContentBackground,
        t,
      )!,
      cardContentForeground: Color.lerp(
        cardContentForeground,
        other.cardContentForeground,
        t,
      )!,
    );
  }
}
