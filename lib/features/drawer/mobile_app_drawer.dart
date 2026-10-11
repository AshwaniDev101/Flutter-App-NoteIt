import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/view/desktop/right_panel/core/navigator.dart';
import 'shared_drawer_content.dart';

class AppDrawer extends ConsumerWidget {
  final RightPanelPageOptions? selectedOption;

  const AppDrawer({super.key, this.selectedOption = RightPanelPageOptions.allNotes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: 280,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        // Pass the shared UI right into the Drawer
        child: SharedDrawerContent(
          selectedOption: selectedOption,
          onOptionSelected: (option) {
            if (Scaffold.of(context).isDrawerOpen) {
              Scaffold.of(context).closeDrawer();
            }
            ref.read(drawerNavigationProvider).navigate(context, option);
          },
          onClose: () {
            if (Scaffold.of(context).isDrawerOpen) {
              Scaffold.of(context).closeDrawer();
            }
          },
        ),
      ),
    );
  }
}