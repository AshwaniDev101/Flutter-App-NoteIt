import 'package:flutter/material.dart';

import 'app_bottom_sheet.dart';

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

class ViewMenuButton extends StatefulWidget {
  final Icon icon;
  final NoteViewType currentView;
  final ValueChanged<NoteViewType> onViewSelected;

  const ViewMenuButton({
    super.key,
    required this.icon,
    required this.currentView,
    required this.onViewSelected,
  });

  @override
  State<ViewMenuButton> createState() => _ViewMenuButtonState();
}

class _ViewMenuButtonState extends State<ViewMenuButton> {
  final MenuController _menuController = MenuController();

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'View Layout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            ...NoteViewType.values.map(
              (view) => _buildViewTile(context, view, onTap: setModalState),
            ),
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
        iconSize: widget.icon.size,
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
          iconSize: widget.icon.size,
        );
      },
      menuChildren: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 2,
          margin: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: NoteViewType.values.map((view) {
                  return _buildViewTile(context, view);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTile(BuildContext context, NoteViewType view, {StateSetter? onTap}) {
    final isSelected = view == widget.currentView;

    return AppMenuTile(
      label: view.label,
      icon: view.icon,
      isSelected: isSelected,
      onTap: () {
        widget.onViewSelected(view);
        if (onTap != null) {
          onTap(() {});
        }
      },
    );
  }
}
