import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db_sorting_filtering.dart';
import '../../core/providers.dart';


// BUTTON WIDGET
class SortViewButton extends StatefulWidget {
  const SortViewButton({super.key});

  @override
  State<SortViewButton> createState() => _SortViewButtonState();
}

class _SortViewButtonState extends State<SortViewButton> {
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
          icon: Icon(Icons.filter_alt,color: Theme.of(context).colorScheme.primary,),
        );
      },
      menuChildren: const [
        SizedBox(width: 250, height: 300, child: FolderSortViewMenu()),
      ],
    );
  }
}


// MAIN MENU MENU
class FolderSortViewMenu extends StatelessWidget {
  const FolderSortViewMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 2,
      margin: const EdgeInsets.all(4.0),
      child: const DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(icon: Icon(Icons.filter_list, size: 20), text: 'Sort'),
                Tab(icon: Icon(Icons.view_comfortable_rounded, size: 20), text: 'View'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SortTab(),
                  ViewTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// TAB 1: SORT & FILTER
enum MenuActionCategory { sort, filter }
enum HomeMenuAction {
  sortCreated('by created time', Icons.calendar_month_outlined, MenuActionCategory.sort),
  sortName('alphabetically', Icons.sort_by_alpha, MenuActionCategory.sort),
  sortUpdated('by modified time', Icons.history, MenuActionCategory.sort),
  filterPhone('Phone', Icons.smartphone_outlined, MenuActionCategory.filter),
  filterWindows('Desktop', Icons.desktop_mac_outlined, MenuActionCategory.filter);

  final String label;
  final IconData? icon;
  final MenuActionCategory category;

  const HomeMenuAction(this.label, this.icon, this.category);
}
class SortTab extends ConsumerWidget {
  const SortTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(noteSortPreferenceProvider);
    // final currentPlatformFilter = ref.watch(platformFilterProvider); // Disabled for now based on original code

    return ListView(

      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        _buildActionTile(context, ref, HomeMenuAction.sortCreated, currentSortOption == NoteSortPreference.createdAt),
        _buildActionTile(context, ref, HomeMenuAction.sortName, currentSortOption == NoteSortPreference.name),
        _buildActionTile(context, ref, HomeMenuAction.sortUpdated, currentSortOption == NoteSortPreference.updatedAt),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, WidgetRef ref, HomeMenuAction action, bool isSelected) {
    return ListTile(
      dense: true,
      leading: action.icon != null ? Icon(action.icon,color: isSelected?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.onSurfaceVariant) : null,
      title: Text(
        action.label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, color: isSelected? Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      onTap: () {
        switch (action) {
          case HomeMenuAction.sortCreated:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
            break;
          case HomeMenuAction.sortName:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
            break;
          case HomeMenuAction.sortUpdated:
            ref.read(noteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
            break;
          case HomeMenuAction.filterPhone:
            ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
            break;
          case HomeMenuAction.filterWindows:
            ref.read(platformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
            break;
        }
      },
    );
  }
}


// TAB 2: VIEWS
enum NoteViewType {
  list('List', Icons.view_headline),
  detailedList('Details', Icons.table_rows),
  grid('Grid', Icons.apps),
  largeGrid('Large grid', Icons.grid_view_rounded);

  final String label;
  final IconData icon;

  const NoteViewType(this.label, this.icon);
}
class ViewTab extends ConsumerWidget {
  const ViewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(noteViewTypeProvider);

    return ListView(

      // padding: const EdgeInsets.symmetric(vertical: 0.0),
      children: NoteViewType.values.map((view) {
        final isSelected = view == currentView;

        return ListTile(
          dense: true,
          leading: Icon(view.icon,color: isSelected?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.onSurfaceVariant),
          title: Text(
            view.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.onSurfaceVariant),
            
          ),
          onTap: () {
            ref.read(noteViewTypeProvider.notifier).updateView(view);
          },
        );
      }).toList(),
    );
  }
}