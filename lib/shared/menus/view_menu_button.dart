import 'package:flutter/material.dart';

import 'adaptive_menu_button.dart';

// ==========================================
// ENUMS
// ==========================================
enum NoteViewType {
  list('List', Icons.view_headline),
  detailedList('Details', Icons.table_rows),
  grid('Grid', Icons.apps),
  largeGrid('Large grid', Icons.grid_view_rounded);

  final String label;
  final IconData icon;

  const NoteViewType(this.label, this.icon);
}

class ViewMenuButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final NoteViewType currentView;
  final ValueChanged<NoteViewType> onViewSelected;

  const ViewMenuButton({
    super.key,
    this.icon = Icons.grid_view,
    this.tooltip = 'View options',
    required this.currentView,
    required this.onViewSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sections = [
      MenuSectionSpec<NoteViewType>(
        title: 'LAYOUT',
        items: NoteViewType.values.map((view) {
          return MenuItemSpec<NoteViewType>(
            value: view,
            label: view.label,
            icon: view.icon,
            isSelected: view == currentView,
            onTap: () => onViewSelected(view),
          );
        }).toList(),
      ),
    ];

    return AdaptiveMenuButton<NoteViewType>(
      icon: icon,
      tooltip: tooltip,
      sheetTitle: 'View Layout',
      sections: sections,
    );
  }
}
