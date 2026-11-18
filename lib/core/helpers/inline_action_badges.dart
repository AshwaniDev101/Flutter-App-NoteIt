import 'package:flutter/material.dart';

import 'package:noteit/core/theme/folder_theme_colors.dart';
import 'package:noteit/database/drift/local_database.dart';

/// Single entry-point for reusable inline visual badges (e.g. mini FABs or folder chips inside hint text).
abstract class InlineBadge {
  /// Mini action button badge (e.g. FAB replica inside hint text)
  static Widget action({
    Key? key,
    required IconData icon,
  }) {
    return _InlineActionBadge(
      key: key,
      icon: icon,
    );
  }

  /// Folder badge indicator inside hint text
  static Widget folder({
    Key? key,
    required Folder folder,
    required BuildContext context,
  }) {
    return _InlineFolderBadge(
      key: key,
      folderName: folder.name,
      folderColor: FolderThemeColors.of(context, folder.colorIndex),
    );
  }

  /// Folder badge indicator with explicit name and color
  static Widget folderRaw({
    Key? key,
    required String folderName,
    required Color folderColor,
  }) {
    return _InlineFolderBadge(
      key: key,
      folderName: folderName,
      folderColor: folderColor,
    );
  }
}

class _InlineActionBadge extends StatelessWidget {
  final IconData icon;

  const _InlineActionBadge({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 14,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _InlineFolderBadge extends StatelessWidget {
  final String folderName;
  final Color folderColor;

  const _InlineFolderBadge({
    super.key,
    required this.folderName,
    required this.folderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: folderColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              folderName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
