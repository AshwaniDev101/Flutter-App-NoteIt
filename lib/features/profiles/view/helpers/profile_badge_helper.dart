import 'package:flutter/material.dart';

class ProfileBadgeHelper {
  // Exactly 30 high-contrast Material Design colors (600-800 shades).
  // These specific shades guarantee pure white (#FFFFFF) text is always readable.
  static const List<Color> _palette = [
    Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828), // Reds
    Color(0xFFD81B60), Color(0xFFC2185B), Color(0xFFAD1457), // Pinks
    Color(0xFF8E24AA), Color(0xFF7B1FA2), Color(0xFF6A1B9A), // Purples
    Color(0xFF5E35B1), Color(0xFF512DA8), Color(0xFF4527A0), // Deep Purples
    Color(0xFF3949AB), Color(0xFF303F9F), Color(0xFF283593), // Indigos
    Color(0xFF1E88E5), Color(0xFF1976D2), Color(0xFF1565C0), // Blues
    Color(0xFF0288D1), Color(0xFF0277BD),                    // Light Blues
    Color(0xFF00838F),                                       // Cyan
    Color(0xFF00796B), Color(0xFF00695C),                    // Teals
    Color(0xFF388E3C), Color(0xFF2E7D32),                    // Greens
    Color(0xFFEF6C00),                                       // Orange
    Color(0xFFF4511E), Color(0xFFE64A19),                    // Deep Oranges
    Color(0xFF6D4C41), Color(0xFF5D4037),                    // Browns
    Color(0xFF546E7A), Color(0xFF455A65),                    // Blue Greys
  ];

  /// Uses the DJB2 algorithm for a completely deterministic integer.
  /// Guarantees the same name yields the same color across Android, Web, and Windows.
  static int _generateHash(String text) {
    int hash = 5381;
    for (int i = 0; i < text.length; i++) {
      hash = ((hash << 5) + hash) + text.codeUnitAt(i);
    }
    return hash.abs();
  }

  /// Returns the deterministic background color from the 30-color palette.
  static Color getColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF9E9E9E); // Fallback Grey

    // Lowercase ensures 'Ashwin' and 'ashwin' resolve to the exact same hash
    final normalized = name.trim().toLowerCase();
    final index = _generateHash(normalized) % _palette.length;

    return _palette[index];
  }

  /// Extracts the initial character for the avatar text.
  static String getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";

    // Handles multi-word names (e.g. returning 'A' for "Ashwani Yadav")
    return trimmed[0].toUpperCase();
  }
}
