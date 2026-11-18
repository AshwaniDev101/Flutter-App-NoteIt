import 'package:flutter/material.dart';

import '../../features/home/core/providers.dart';
import 'adaptive_menu_button.dart';

class FilterMenuButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final FilterPlatformOptions currentFilterSelection;
  final ValueChanged<FilterPlatformOptions> onSelected;

  const FilterMenuButton({
    super.key,
    this.icon = Icons.devices_outlined,
    this.tooltip = 'Filter by device',
    required this.currentFilterSelection,
    required this.onSelected,
  });

  String _getLabel(FilterPlatformOptions filter) {
    switch (filter) {
      case FilterPlatformOptions.all:
        return 'All Devices';
      case FilterPlatformOptions.android:
        return 'Phone';
      case FilterPlatformOptions.windows:
        return 'Desktop';
    }
  }

  IconData _getIcon(FilterPlatformOptions filter) {
    switch (filter) {
      case FilterPlatformOptions.all:
        return Icons.devices_other;
      case FilterPlatformOptions.android:
        return Icons.smartphone_outlined;
      case FilterPlatformOptions.windows:
        return Icons.desktop_mac_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = FilterPlatformOptions.values.map((filter) {
      return MenuItemSpec<FilterPlatformOptions>(
        value: filter,
        label: _getLabel(filter),
        icon: _getIcon(filter),
        isSelected: filter == currentFilterSelection,
        onTap: () => onSelected(filter),
      );
    }).toList();

    final sections = [
      MenuSectionSpec<FilterPlatformOptions>(
        items: items,
      ),
    ];

    return AdaptiveMenuButton<FilterPlatformOptions>(
      icon: icon,
      tooltip: tooltip,
      sheetTitle: 'Filter Devices',
      sections: sections,
    );
  }
}
