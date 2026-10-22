import 'package:flutter/material.dart';
import 'app_bottom_sheet.dart';

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

  void _showMobileBottomSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Sort & Filter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            _buildSectionHeader(context, 'SORT BY'),
            _buildActionTile(context, HomeMenuAction.sortCreated, onTap: setModalState),
            _buildActionTile(context, HomeMenuAction.sortName, onTap: setModalState),
            _buildActionTile(context, HomeMenuAction.sortUpdated, onTap: setModalState),
            const SizedBox(height: 8),
            _buildSectionHeader(context, 'FILTER BY DEVICE'),
            _buildActionTile(context, HomeMenuAction.filterAll, onTap: setModalState),
            _buildActionTile(context, HomeMenuAction.filterPhone, onTap: setModalState),
            _buildActionTile(context, HomeMenuAction.filterWindows, onTap: setModalState),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (isMobile) {
      return IconButton(
        icon: widget.icon,
        onPressed: () => _showMobileBottomSheet(context),
      );
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'SORT BY'),
                  _buildActionTile(context, HomeMenuAction.sortCreated),
                  _buildActionTile(context, HomeMenuAction.sortName),
                  _buildActionTile(context, HomeMenuAction.sortUpdated),
                  const Divider(indent: 12, endIndent: 12),
                  _buildSectionHeader(context, 'FILTER BY DEVICE'),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, HomeMenuAction action, {StateSetter? onTap}) {
    final isSelected = (action == widget.currentSortSelection) ||
        (action == widget.currentPlatformSelection);

    return AppMenuTile(
      label: action.label,
      icon: action.icon,
      isSelected: isSelected,
      onTap: () {
        widget.onSelected(action);
        if (onTap != null) {
          onTap(() {});
        }
      },
    );
  }
}
