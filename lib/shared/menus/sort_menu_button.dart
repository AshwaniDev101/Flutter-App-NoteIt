import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'adaptive_menu_button.dart';

enum HomeMenuAction {
  sortCreated('by created time', Icons.calendar_month_outlined),
  sortName('alphabetically', Icons.sort_by_alpha),
  sortUpdated('by modified time', Icons.history),
  sortFolder('by folder', Icons.folder_outlined),
  sortReminder('by reminder time', Icons.notifications_none_outlined),
  filterAll('All Devices', Icons.devices_other),
  filterPhone('Phone', Icons.smartphone_outlined),
  filterWindows('Desktop', Icons.desktop_mac_outlined);

  final String label;
  final IconData? icon;

  const HomeMenuAction(this.label, this.icon);
}

class SortMenuButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final HomeMenuAction currentSortSelection;
  final HomeMenuAction currentPlatformSelection;
  final ValueChanged<HomeMenuAction> onSelected;
  final bool showPlatformFilter;

  const SortMenuButton({
    super.key,
    this.icon = CupertinoIcons.sort_down,
    this.tooltip = 'Sort options',
    required this.currentSortSelection,
    this.currentPlatformSelection = HomeMenuAction.filterAll,
    required this.onSelected,
    this.showPlatformFilter = false,
  });

  MenuItemSpec<HomeMenuAction> _buildItem(HomeMenuAction action) {
    return MenuItemSpec<HomeMenuAction>(
      value: action,
      label: action.label,
      icon: action.icon,
      isSelected: (action == currentSortSelection) || (action == currentPlatformSelection),
      onTap: () => onSelected(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      MenuSectionSpec<HomeMenuAction>(
        title: 'SORT BY',
        items: [
          _buildItem(HomeMenuAction.sortCreated),
          _buildItem(HomeMenuAction.sortName),
          _buildItem(HomeMenuAction.sortUpdated),
          _buildItem(HomeMenuAction.sortFolder),
          _buildItem(HomeMenuAction.sortReminder),
        ],
      ),
      if (showPlatformFilter)
        MenuSectionSpec<HomeMenuAction>(
          title: 'FILTER BY DEVICE',
          items: [
            _buildItem(HomeMenuAction.filterAll),
            _buildItem(HomeMenuAction.filterPhone),
            _buildItem(HomeMenuAction.filterWindows),
          ],
        ),
    ];

    return AdaptiveMenuButton<HomeMenuAction>(
      icon: icon,
      tooltip: tooltip,
      sheetTitle: 'Sort & Filter',
      sections: sections,
    );
  }
}
