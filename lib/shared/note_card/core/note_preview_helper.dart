import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:noteit/database/drift/local_database.dart';

/// High-performance utility for computing lightweight, safety-capped note previews.
///
/// Prevents heavy text layout computations and memory spikes by capping
/// preview strings and centering search hits within a context window.
class NotePreviewHelper {
  /// Returns a lightweight, length-capped preview string from [note].
  ///
  /// Safe against Unicode surrogate splitting, heavy JSON parsing overhead,
  /// and index range errors. Centers previews around [searchQuery] if present.
  static String getPreviewText(
    Note note, {
    String searchQuery = '',
    int maxChars = 300,
  }) {
    final rawContent = note.content;
    if (rawContent.isEmpty) return '';

    String textToUse = rawContent;

    // Fast handling for Checklist JSON content (contentVersion == 2)
    if (note.contentVersion == 2 && rawContent.startsWith('[')) {
      textToUse = _formatChecklistPreview(rawContent, maxItems: 4);
    } else {
      // Normalize consecutive newlines for clean card layout
      textToUse = textToUse.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    }

    if (textToUse.isEmpty) return '';

    final query = searchQuery.trim();

    // 1. Search Mode: Find match position and window snippet around it
    if (query.isNotEmpty) {
      final String textLower = textToUse.toLowerCase();
      final String queryLower = query.toLowerCase();
      final int matchIndex = textLower.indexOf(queryLower);

      if (matchIndex != -1) {
        // Extract window around match: ~40 chars before, ~160 after
        final int targetStart = (matchIndex - 40).clamp(0, textToUse.length);
        final int targetEnd = (matchIndex + query.length + 160).clamp(0, textToUse.length);

        String snippet = _safeSubstring(textToUse, targetStart, targetEnd);

        if (targetStart > 0) {
          snippet = '… $snippet';
        }
        if (targetEnd < textToUse.length) {
          snippet = '$snippet …';
        }

        return _safeTruncate(snippet, maxChars + 20);
      }
    }

    // 2. Normal Mode: Cap at maxChars
    return _safeTruncate(textToUse, maxChars);
  }

  /// Formats JSON checklist strings into a lightweight preview (e.g. "◆ Item 1\n◇ Item 2").
  static String _formatChecklistPreview(String jsonString, {int maxItems = 4}) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      if (decoded.isEmpty) return '';

      final buffer = StringBuffer();
      int count = 0;

      for (final item in decoded) {
        if (count >= maxItems) break;
        if (item is Map) {
          final isChecked = item['isChecked'] == true;
          final text = (item['text'] as String? ?? '').trim();
          if (text.isNotEmpty) {
            if (count > 0) buffer.write('\n');
            buffer.write('${isChecked ? "◆" : "◇"} $text');
            count++;
          }
        }
      }

      return buffer.toString();
    } catch (_) {
      // Fall back to raw content if JSON parsing fails
      return jsonString;
    }
  }

  /// Substrings safely using character count to avoid splitting UTF-16 surrogate pairs (emojis).
  static String _safeSubstring(String text, int start, int end) {
    if (start <= 0 && end >= text.length) return text;

    final chars = text.characters;
    final length = chars.length;

    final safeStart = start.clamp(0, length);
    final safeEnd = end.clamp(safeStart, length);

    return chars.getRange(safeStart, safeEnd).toString();
  }

  /// Truncates string at character boundary and appends '…' if truncated.
  static String _safeTruncate(String text, int maxChars) {
    final chars = text.characters;
    if (chars.length <= maxChars) return text;

    return '${chars.take(maxChars).toString().trimRight()} …';
  }
}
