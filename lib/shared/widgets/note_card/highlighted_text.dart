import 'package:flutter/material.dart';

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

    final defaultHighlight = highlightStyle ?? defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );

    if (query.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final String textLower = text.toLowerCase();
    final String queryLower = query.toLowerCase();

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
          text: text.substring(indexOfMatch, indexOfMatch + query.length),
          style: defaultHighlight,
        ),
      );

      start = indexOfMatch + query.length;
      indexOfMatch = textLower.indexOf(queryLower, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans),
    );
  }
}
