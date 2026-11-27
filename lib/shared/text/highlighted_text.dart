import 'package:flutter/material.dart';
import 'package:noteit/core/theme/search_highlight_colors.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? normalStyle;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.normalStyle,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = normalStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    // Safety guardrail: cap text length to 500 characters max to protect against layout/memory spikes
    final String textToDisplay = text.characters.length > 500
        ? '${text.characters.take(500).toString()} …'
        : text;

    final colors = SearchHighlightColors.of(context);
    final defaultHighlight = highlightStyle ?? defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      backgroundColor: colors.passiveBackground,
      color: colors.passiveForeground,
      decoration: TextDecoration.underline,
      decorationColor: colors.passiveUnderline,
      decorationThickness: 1.5,
    );

    if (query.isEmpty) {
      return Text(
        textToDisplay,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final String textLower = textToDisplay.toLowerCase();
    final String queryLower = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = textLower.indexOf(queryLower, start);

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(
          TextSpan(
            text: textToDisplay.substring(start, indexOfMatch),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: textToDisplay.substring(indexOfMatch, indexOfMatch + query.length),
          style: defaultHighlight,
        ),
      );

      start = indexOfMatch + query.length;
      indexOfMatch = textLower.indexOf(queryLower, start);
    }

    if (start < textToDisplay.length) {
      spans.add(TextSpan(text: textToDisplay.substring(start), style: defaultStyle));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans),
    );
  }
}
