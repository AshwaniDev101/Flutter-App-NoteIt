import 'package:flutter/material.dart';

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
          icon: widget.icon //Icon(Icons.view_comfortable_rounded, color: Theme.of(context).colorScheme.primary),
        );
      },
      menuChildren: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 2,
          margin: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: 200,
            // REPLACE ListView with Padding + Column
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // This prevents the size error
                children: NoteViewType.values.map((view) {
                  final isSelected = view == widget.currentView;
                  final colorScheme = Theme.of(context).colorScheme;

                  return ListTile(
                    dense: true,
                    leading: Icon(view.icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
                    title: Text(
                      view.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      widget.onViewSelected(view);
                      _menuController.close();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}