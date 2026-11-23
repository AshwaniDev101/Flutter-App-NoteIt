
import 'package:flutter/material.dart';
import 'package:noteit/core/theme/search_highlight_colors.dart';

class HighlightingTextField extends TextEditingController {
  String _searchQuery = '';
  int _activeMatchStart = -1;

  HighlightingTextField({super.text});

  String get searchQuery => _searchQuery;

  set searchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _activeMatchStart = -1;
      notifyListeners(); // Triggers the TextField to repaint the text
    }
  }

  int get activeMatchStart => _activeMatchStart;

  set activeMatchStart(int start) {
    if (_activeMatchStart != start) {
      _activeMatchStart = start;
      notifyListeners();
    }
  }

  void setActiveMatch(int start) {
    _activeMatchStart = start;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    if (_searchQuery.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    final highlightColors = SearchHighlightColors.of(context);

    // Active match style: High-contrast vibrant amber with strong underline and bold text
    final activeHighlight = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      backgroundColor: highlightColors.activeBackground,
      color: highlightColors.activeForeground,
      decoration: TextDecoration.underline,
      decorationColor: highlightColors.activeUnderline,
      decorationThickness: 2.5,
      decorationStyle: TextDecorationStyle.solid,
    );

    // Passive match style: Translucent highlight with distinct underline
    final passiveHighlight = defaultStyle.copyWith(
      fontWeight: FontWeight.w600,
      backgroundColor: highlightColors.passiveBackground,
      color: highlightColors.passiveForeground,
      decoration: TextDecoration.underline,
      decorationColor: highlightColors.passiveUnderline,
      decorationThickness: 1.5,
    );

    final String textLower = text.toLowerCase();
    final String queryLower = _searchQuery.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = textLower.indexOf(queryLower, start);

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, indexOfMatch),
            style: defaultStyle,
          ),
        );
      }

      final isCurrentActive = indexOfMatch == _activeMatchStart ||
          (selection.isValid && !selection.isCollapsed && selection.baseOffset == indexOfMatch);

      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + _searchQuery.length),
          style: isCurrentActive ? activeHighlight : passiveHighlight,
        ),
      );

      start = indexOfMatch + _searchQuery.length;
      indexOfMatch = textLower.indexOf(queryLower, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
    }

    return TextSpan(style: defaultStyle, children: spans);
  }
}