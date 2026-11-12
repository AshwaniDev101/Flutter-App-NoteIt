import 'package:flutter/material.dart';

@immutable
class FolderThemeColors extends ThemeExtension<FolderThemeColors> {
  final List<Color> palette;

  const FolderThemeColors({required this.palette});

  static Color of(BuildContext context, int index) {
    final ext = Theme.of(context).extension<FolderThemeColors>();
    if (ext != null && ext.palette.isNotEmpty) {
      return ext.palette[index.abs() % ext.palette.length];
    }
    return Colors.primaries[index.abs() % Colors.primaries.length];
  }

  factory FolderThemeColors.dark() => const FolderThemeColors(
        palette: [
          Color(0xFFE57373),
          Color(0xFFF06292),
          Color(0xFFBA68C8),
          Color(0xFF9575CD),
          Color(0xFF7986CB),
          Color(0xFF64B5F6),
          Color(0xFF4FC3F7),
          Color(0xFF4DD0E1),
          Color(0xFF4DB6AC),
          Color(0xFF81C784),
          Color(0xFFFFB74D),
          Color(0xFFFF8A65),
        ],
      );

  factory FolderThemeColors.light() => const FolderThemeColors(
        palette: [
          Color(0xFFD32F2F),
          Color(0xFFC2185B),
          Color(0xFF7B1FA2),
          Color(0xFF512DA8),
          Color(0xFF303F9F),
          Color(0xFF1976D2),
          Color(0xFF0288D1),
          Color(0xFF0097A7),
          Color(0xFF00796B),
          Color(0xFF388E3C),
          Color(0xFFF57C00),
          Color(0xFFE64A19),
        ],
      );

  factory FolderThemeColors.amoled() => const FolderThemeColors(
        palette: [
          Color(0xFFFF6B6B),
          Color(0xFFFF8E72),
          Color(0xFFCC5DE8),
          Color(0xFF845EF7),
          Color(0xFF5C7CFA),
          Color(0xFF339AF0),
          Color(0xFF22B8CF),
          Color(0xFF20C997),
          Color(0xFF51CF66),
          Color(0xFF94D82D),
          Color(0xFFFCC419),
          Color(0xFFFF922B),
        ],
      );

  factory FolderThemeColors.sepia() => const FolderThemeColors(
        palette: [
          Color(0xFFB0533C),
          Color(0xFFA04860),
          Color(0xFF824B72),
          Color(0xFF624B82),
          Color(0xFF4B5B82),
          Color(0xFF3B678A),
          Color(0xFF3B7280),
          Color(0xFF38726A),
          Color(0xFF437A55),
          Color(0xFF677A43),
          Color(0xFF8A723B),
          Color(0xFF9E5C38),
        ],
      );

  factory FolderThemeColors.dracula() => const FolderThemeColors(
        palette: [
          Color(0xFFFF5555),
          Color(0xFFFF79C6),
          Color(0xFFBD93F9),
          Color(0xFF8BE9FD),
          Color(0xFF50FA7B),
          Color(0xFFF1FA8C),
          Color(0xFFFFB86C),
          Color(0xFFA4F0FF),
          Color(0xFFD6ACFF),
          Color(0xFFFF92D0),
          Color(0xFF69FF94),
          Color(0xFFFFFFA5),
        ],
      );

  factory FolderThemeColors.nord() => const FolderThemeColors(
        palette: [
          Color(0xFFBF616A),
          Color(0xFFD08770),
          Color(0xFFEBCB8B),
          Color(0xFFA3BE8C),
          Color(0xFFB48EAD),
          Color(0xFF88C0D0),
          Color(0xFF81A1C1),
          Color(0xFF5E81AC),
          Color(0xFF8FBCBB),
          Color(0xFFD09787),
          Color(0xFFB4A3BE),
          Color(0xFFA3BEB4),
        ],
      );

  factory FolderThemeColors.catppuccin() => const FolderThemeColors(
        palette: [
          Color(0xFFF38BA8),
          Color(0xFFFAB387),
          Color(0xFFF9E2AF),
          Color(0xFFA6E3A1),
          Color(0xFF94E2D5),
          Color(0xFF89DCEB),
          Color(0xFF74C7EC),
          Color(0xFF89B4FA),
          Color(0xFFCBA6F7),
          Color(0xFFF5C2E7),
          Color(0xFFF2CDCD),
          Color(0xFFEBA0AC),
        ],
      );

  factory FolderThemeColors.forest() => const FolderThemeColors(
        palette: [
          Color(0xFF52B788),
          Color(0xFF74C7EC),
          Color(0xFFD8A47F),
          Color(0xFF95D5B2),
          Color(0xFFB7E4C7),
          Color(0xFFD8F3DC),
          Color(0xFF40916C),
          Color(0xFF2D6A4F),
          Color(0xFF1B4332),
          Color(0xFFE56B6F),
          Color(0xFFEAA0A2),
          Color(0xFF84A98C),
        ],
      );

  factory FolderThemeColors.cyberpunk() => const FolderThemeColors(
        palette: [
          Color(0xFFFF2A85),
          Color(0xFF00F0FF),
          Color(0xFFB967FF),
          Color(0xFFFFB800),
          Color(0xFF00FF9D),
          Color(0xFFFF0055),
          Color(0xFF7B2CBF),
          Color(0xFF00B4D8),
          Color(0xFFFF70A6),
          Color(0xFFFF9770),
          Color(0xFFFFD670),
          Color(0xFFE9FF70),
        ],
      );

  factory FolderThemeColors.ocean() => const FolderThemeColors(
        palette: [
          Color(0xFF1E6091),
          Color(0xFF184E77),
          Color(0xFF1E88E5),
          Color(0xFF48CAE4),
          Color(0xFF0096C7),
          Color(0xFF0077B6),
          Color(0xFF023E8A),
          Color(0xFF00B4D8),
          Color(0xFF52B788),
          Color(0xFFF77F00),
          Color(0xFFE63946),
          Color(0xFF457B9D),
        ],
      );

  @override
  FolderThemeColors copyWith({List<Color>? palette}) {
    return FolderThemeColors(palette: palette ?? this.palette);
  }

  @override
  FolderThemeColors lerp(ThemeExtension<FolderThemeColors>? other, double t) {
    if (other is! FolderThemeColors) return this;
    if (palette.length != other.palette.length) return other;

    final lerped = <Color>[];
    for (int i = 0; i < palette.length; i++) {
      lerped.add(Color.lerp(palette[i], other.palette[i], t)!);
    }
    return FolderThemeColors(palette: lerped);
  }
}
