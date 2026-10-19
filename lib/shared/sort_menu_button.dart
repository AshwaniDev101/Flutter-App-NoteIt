import 'package:flutter/material.dart';

enum HomeMenuAction {
  sortCreated('by created time', Icons.calendar_month_outlined),
  sortName('alphabetically', Icons.sort_by_alpha),
  sortUpdated('by modified time', Icons.history),
  filterAll('All Devices', Icons.devices_other),
  filterPhone('Phone', Icons.smartphone_outlined),
  filterWindows('Desktop', Icons.desktop_mac_outlined);

  final String label;
  final IconData? icon;

  const HomeMenuAction(this.label, this.icon);
}

class SortMenuButton extends StatefulWidget {
  final Icon icon;
  final HomeMenuAction currentSortSelection;
  final HomeMenuAction currentPlatformSelection;
  final ValueChanged<HomeMenuAction> onSelected;

  const SortMenuButton({
    super.key,
    required this.icon,
    required this.currentSortSelection,
    this.currentPlatformSelection = HomeMenuAction.filterAll,
    required this.onSelected,
  });

  @override
  State<SortMenuButton> createState() => _SortMenuButtonState();
}

class _SortMenuButtonState extends State<SortMenuButton> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: widget.icon,
        );
      },
      menuChildren: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 2,
          margin: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionTile(context, HomeMenuAction.sortCreated),
                  _buildActionTile(context, HomeMenuAction.sortName),
                  _buildActionTile(context, HomeMenuAction.sortUpdated),
                  const Divider(),
                  _buildActionTile(context, HomeMenuAction.filterAll),
                  _buildActionTile(context, HomeMenuAction.filterPhone),
                  _buildActionTile(context, HomeMenuAction.filterWindows),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, HomeMenuAction action) {
    final isSelected = (action == widget.currentSortSelection) ||
        (action == widget.currentPlatformSelection);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: action.icon != null
          ? Icon(action.icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
          : null,
      title: Text(
        action.label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, size: 18, color: colorScheme.primary) : null,
      onTap: () {
        widget.onSelected(action);
        _menuController.close();
      },
    );
  }
}
