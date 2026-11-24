import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../database/drift/notes/notes_dao.dart';
import 'adaptive_menu_button.dart';

class SortMenuButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final NoteSortPreference currentSortSelection;
  final ValueChanged<NoteSortPreference> onSelected;
  final List<NoteSortPreference>? allowedOptions;

  const SortMenuButton({
    super.key,
    this.icon = CupertinoIcons.sort_down,
    this.tooltip = 'Sort options',
    required this.currentSortSelection,
    required this.onSelected,
    this.allowedOptions,
  });

  String _getLabel(NoteSortPreference sort) {
    switch (sort) {
      case NoteSortPreference.createdAt:
        return 'by created time';
      case NoteSortPreference.name:
        return 'alphabetically';
      case NoteSortPreference.updatedAt:
        return 'by modified time';
      case NoteSortPreference.folder:
        return 'by folder';
      case NoteSortPreference.reminderAt:
        return 'by reminder time';
    }
  }

  IconData _getIcon(NoteSortPreference sort) {
    switch (sort) {
      case NoteSortPreference.createdAt:
        return Icons.calendar_month_outlined;
      case NoteSortPreference.name:
        return Icons.sort_by_alpha;
      case NoteSortPreference.updatedAt:
        return Icons.history;
      case NoteSortPreference.folder:
        return Icons.folder_outlined;
      case NoteSortPreference.reminderAt:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableOptions = allowedOptions ?? NoteSortPreference.values;
    final items = availableOptions.map((sort) {
      return MenuItemSpec<NoteSortPreference>(
        value: sort,
        label: _getLabel(sort),
        icon: _getIcon(sort),
        isSelected: sort == currentSortSelection,
        onTap: () => onSelected(sort),
      );
    }).toList();

    final sections = [
      MenuSectionSpec<NoteSortPreference>(
        items: items,
      ),
    ];

    return AdaptiveMenuButton<NoteSortPreference>(
      icon: icon,
      tooltip: tooltip,
      sheetTitle: 'Sort Options',
      sections: sections,
    );
  }
}
