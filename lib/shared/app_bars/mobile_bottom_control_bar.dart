import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/folders/core/providers.dart';
import '../../features/folders/view/folder_selector.dart';
import '../../features/home/core/db_sorting_filtering.dart';
import '../../features/home/core/providers.dart';
import '../../features/home/viewmodel/viewmodel.dart';
import 'app_search_bar.dart';
import '../menus/sort_menu_button.dart';
import '../menus/view_menu_button.dart';

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

  HomeMenuAction _getCurrentSortAction(NoteSortPreference currentSort) {
    switch (currentSort) {
      case NoteSortPreference.createdAt:
        return HomeMenuAction.sortCreated;
      case NoteSortPreference.name:
        return HomeMenuAction.sortName;
      case NoteSortPreference.updatedAt:
        return HomeMenuAction.sortUpdated;
    }
  }

  HomeMenuAction _getCurrentPlatformAction(FilterPlatformOptions platformFilter) {
    switch (platformFilter) {
      case FilterPlatformOptions.all:
        return HomeMenuAction.filterAll;
      case FilterPlatformOptions.android:
        return HomeMenuAction.filterPhone;
      case FilterPlatformOptions.windows:
        return HomeMenuAction.filterWindows;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BottomAppBar(
        elevation: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                  FolderButton(
                    selectedFolder: ref.watch(activeFolderProvider),
                    emptyLabel: 'All Notes',
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
                  const Spacer(),
                  SortMenuButton(
                    icon: CupertinoIcons.sort_down,
                    currentSortSelection: _getCurrentSortAction(ref.watch(homeNoteSortPreferenceProvider)),
                    currentPlatformSelection: _getCurrentPlatformAction(ref.watch(homePlatformFilterProvider)),
                    onSelected: (HomeMenuAction action) {
                      switch (action) {
                        case HomeMenuAction.sortCreated:
                          ref.read(homeNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
                          break;
                        case HomeMenuAction.sortName:
                          ref.read(homeNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
                          break;
                        case HomeMenuAction.sortUpdated:
                          ref.read(homeNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
                          break;
                        case HomeMenuAction.filterAll:
                          ref.read(homePlatformFilterProvider.notifier).setFilter(FilterPlatformOptions.all);
                          break;
                        case HomeMenuAction.filterPhone:
                          ref.read(homePlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
                          break;
                        case HomeMenuAction.filterWindows:
                          ref.read(homePlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
                          break;
                      }
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
                    icon: const Icon(Icons.search,),
                    tooltip: 'Search Notes',
                    onPressed: () {
                      viewModel.enterSearchMode();
                      searchFocusNode.requestFocus();
                    },
                    iconSize: 28,
                  ),
                ],
              ),
      ),
    );
  }
}
