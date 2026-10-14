
import 'package:flutter/material.dart';

class HighlightingTextEditingController extends TextEditingController {
  String _searchQuery = '';

  HighlightingTextEditingController({super.text});

  String get searchQuery => _searchQuery;

  set searchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners(); // Triggers the TextField to repaint the text
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();


    final defaultHighlight = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );

    if (_searchQuery.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

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

      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + _searchQuery.length),
          style: defaultHighlight,
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