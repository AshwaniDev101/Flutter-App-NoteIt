import 'package:flutter/material.dart';

import 'package:noteit/core/theme/folder_theme_colors.dart';
import 'package:noteit/database/drift/local_database.dart';

/// Centralized folder icon indicator used across note cards, menus, and badges.
class FolderIcon extends StatelessWidget {
  final Color color;
  final double size;
  final IconData icon;

  static const double defaultSize = 16.0;
  static const IconData defaultIcon = Icons.folder_rounded;

  const FolderIcon({
    super.key,
    required this.color,
    this.size = defaultSize,
    this.icon = defaultIcon,
  });

  /// Factory constructor that resolves color directly from a [Folder] instance.
  factory FolderIcon.forFolder(
    BuildContext context,
    Folder? folder, {
    Key? key,
    double size = defaultSize,
    IconData icon = defaultIcon,
  }) {
    final color = folder != null
        ? FolderThemeColors.of(context, folder.colorIndex)
        : Theme.of(context).colorScheme.outline;

    return FolderIcon(
      key: key,
      color: color,
      size: size,
      icon: icon,
    );
  }

  /// Factory constructor that resolves color from a [colorIndex].
  factory FolderIcon.fromColorIndex(
    BuildContext context,
    int colorIndex, {
    Key? key,
    double size = defaultSize,
    IconData icon = defaultIcon,
  }) {
    return FolderIcon(
      key: key,
      color: FolderThemeColors.of(context, colorIndex),
      size: size,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
