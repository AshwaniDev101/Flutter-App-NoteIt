import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/folders/providers/folder_providers.dart';
import '../../features/folders/view/folder_button.dart';
import '../../features/home/core/db_sorting_filtering.dart';
import '../../features/home/core/providers.dart';
import '../../features/home/viewmodel/viewmodel.dart';
import '../menus/filter_menu_button.dart';
import '../menus/sort_menu_button.dart';
import '../menus/view_menu_button.dart';
import 'app_search_bar.dart';
import 'floating_bottom_app_bar.dart';

class MobileBottomControlBar extends ConsumerWidget {
  final HomePageState homeState;
  final HomeViewModel viewModel;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const MobileBottomControlBar({
    super.key,
    required this.homeState,
    required this.viewModel,
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSort = ref.watch(homeNoteSortPreferenceProvider);
    final platformFilter = ref.watch(homePlatformFilterProvider);

    return FloatingBottomAppBar(
      child: homeState.isSearchMode
          ? Row(
              key: const ValueKey('searching_control_bar'),
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hintText: 'Search notes...',
                    fillColor: colorScheme.surfaceContainerLow,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        ref.read(searchQueryProvider.notifier).clear();
                      } else {
                        ref.read(searchQueryProvider.notifier).updateQuery(value);
                      }
                    },
                    onClear: () {
                      searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search_off),
                  tooltip: 'Close search',
                  onPressed: () {
                    searchController.clear();
                    ref.read(searchQueryProvider.notifier).clear();
                    viewModel.exitSearchMode();
                  },
                ),
              ],
            )
          : Row(
              key: const ValueKey('standard_control_bar'),
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FolderButton(
                      selectedFolder: ref.watch(activeFolderProvider),
                      showContextMenus: true,
                      isShowTotalNoteCount: true,
                      onFolderSelected: (folder) {
                        if (folder == null) {
                          ref.read(activeFolderProvider.notifier).clear();
                        } else {
                          ref.read(activeFolderProvider.notifier).setFolder(folder);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SortMenuButton(
                  icon: CupertinoIcons.sort_down,
                  currentSortSelection: currentSort,
                  onSelected: (NoteSortPreference sort) {
                    ref.read(homeNoteSortPreferenceProvider.notifier).updateSort(sort);
                  },
                ),
                if (ref.watch(showDeviceFilterProvider))
                  FilterMenuButton(
                    currentFilterSelection: platformFilter,
                    onSelected: (FilterPlatformOptions filter) {
                      ref.read(homePlatformFilterProvider.notifier).setFilter(filter);
                    },
                  ),
                ViewMenuButton(
                  icon: Icons.grid_view,
                  currentView: ref.watch(homeNoteViewTypeProvider),
                  onViewSelected: (NoteViewType selectedView) {
                    ref.read(homeNoteViewTypeProvider.notifier).updateView(selectedView);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search Notes',
                  onPressed: () {
                    viewModel.enterSearchMode();
                    searchFocusNode.requestFocus();
                  },
                  iconSize: 28,
                ),
              ],
            ),
    );
  }
}
