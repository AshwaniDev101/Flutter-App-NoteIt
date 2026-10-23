import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'shared_drawer_content.dart';

class DrawerMenuButton extends ConsumerStatefulWidget {
  final RightPanelPageOptions? selectedOption;

  const DrawerMenuButton({
    super.key,
    this.selectedOption = RightPanelPageOptions.noteEditor,
  });

  @override
  ConsumerState<DrawerMenuButton> createState() => _DrawerMenuButtonState();
}

class _DrawerMenuButtonState extends ConsumerState<DrawerMenuButton> {
  final MenuController _menuController = MenuController();

  void _closeMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    }
  }

  void _handleOptionSelected(RightPanelPageOptions option) {
    _closeMenu();
    ref.read(drawerNavigationProvider).navigate(context, option);
  }

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
          tooltip: 'Open Menu',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(Icons.menu,color: Theme.of(context).colorScheme.onSurfaceVariant,),
        );
      },
      menuChildren: [
        Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 12,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.all(4.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 280, // Matches the mobile drawer width
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SharedDrawerContent(
              selectedOption: widget.selectedOption,
              onOptionSelected: _handleOptionSelected,
              onClose: _closeMenu,
            ),
          ),
        ),
      ],
    );
  }
}