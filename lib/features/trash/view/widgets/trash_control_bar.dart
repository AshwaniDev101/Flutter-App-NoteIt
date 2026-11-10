import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../shared/app_bars/app_search_bar.dart';
import '../../../../shared/menus/sort_menu_button.dart';
import '../../../../shared/menus/view_menu_button.dart';
import '../../../folders/view/folder_option_menu.dart';
import '../../../home/core/providers.dart';
import '../../providers/trash_providers.dart';

class TrashControlBar extends ConsumerStatefulWidget {
  const TrashControlBar({super.key});

  @override
  ConsumerState<TrashControlBar> createState() => _TrashControlBarState();
}

class _TrashControlBarState extends ConsumerState<TrashControlBar> {
  bool _isSearching = false;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  HomeMenuAction _getCurrentSortAction(NoteSortPreference currentSort) {
    if (currentSort == NoteSortPreference.folder) return HomeMenuAction.sortFolder;
    if (currentSort == NoteSortPreference.reminderAt) return HomeMenuAction.sortReminder;
    if (currentSort == NoteSortPreference.name) return HomeMenuAction.sortName;
    if (currentSort == NoteSortPreference.updatedAt) return HomeMenuAction.sortUpdated;
    return HomeMenuAction.sortCreated;
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
  Widget build(BuildContext context) {
    final currentSort = ref.watch(trashNoteSortPreferenceProvider);
    final currentView = ref.watch(trashNoteViewTypeProvider);
    final platformFilter = ref.watch(trashPlatformFilterProvider);
    final selectedFolder = ref.watch(trashSelectedFolderProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 220),
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeOutCubic,
      sizeCurve: Curves.easeOutCubic,
      crossFadeState: _isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Row(
        key: const ValueKey('standard_control_bar'),
        children: [
          FolderOptionMenu(
            selectedFolder: selectedFolder,
            emptyLabel: 'All Folders',
            onFolderSelected: (folder) {
              ref.read(trashSelectedFolderProvider.notifier).selectFolder(folder);
            },
          ),
          const Spacer(),
          SortMenuButton(
            icon: CupertinoIcons.sort_down,
            currentSortSelection: _getCurrentSortAction(currentSort),
            currentPlatformSelection: _getCurrentPlatformAction(platformFilter),
            onSelected: (HomeMenuAction action) {
              if (action == HomeMenuAction.sortCreated) {
                ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
              } else if (action == HomeMenuAction.sortName) {
                ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
              } else if (action == HomeMenuAction.sortUpdated) {
                ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
              } else if (action == HomeMenuAction.sortFolder) {
                ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.folder);
              } else if (action == HomeMenuAction.sortReminder) {
                ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.reminderAt);
              } else if (action == HomeMenuAction.filterAll) {
                ref.read(trashPlatformFilterProvider.notifier).setFilter(FilterPlatformOptions.all);
              } else if (action == HomeMenuAction.filterPhone) {
                ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
              } else if (action == HomeMenuAction.filterWindows) {
                ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
              }
            },
          ),
          ViewMenuButton(
            icon: Icons.grid_view,
            currentView: currentView,
            onViewSelected: (NoteViewType selectedView) {
              ref.read(trashNoteViewTypeProvider.notifier).updateView(selectedView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Trash',
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
              Future.delayed(const Duration(milliseconds: 50), () {
                _searchFocusNode.requestFocus();
              });
            },
          ),
        ],
      ),
      secondChild: Row(
        key: const ValueKey('searching_control_bar'),
        children: [
          if (PlatformHelper.isWideLayout(context)) ...[
            FolderOptionMenu(
              selectedFolder: selectedFolder,
              emptyLabel: 'All Folders',
              onFolderSelected: (folder) {
                ref.read(trashSelectedFolderProvider.notifier).selectFolder(folder);
              },
            ),
            const Spacer(),
            SortMenuButton(
              icon: CupertinoIcons.sort_down,
              currentSortSelection: _getCurrentSortAction(currentSort),
              currentPlatformSelection: _getCurrentPlatformAction(platformFilter),
              onSelected: (HomeMenuAction action) {
                if (action == HomeMenuAction.sortCreated) {
                  ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
                } else if (action == HomeMenuAction.sortName) {
                  ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
                } else if (action == HomeMenuAction.sortUpdated) {
                  ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
                } else if (action == HomeMenuAction.sortFolder) {
                  ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.folder);
                } else if (action == HomeMenuAction.sortReminder) {
                  ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.reminderAt);
                } else if (action == HomeMenuAction.filterAll) {
                  ref.read(trashPlatformFilterProvider.notifier).setFilter(FilterPlatformOptions.all);
                } else if (action == HomeMenuAction.filterPhone) {
                  ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
                } else if (action == HomeMenuAction.filterWindows) {
                  ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
                }
              },
            ),
            ViewMenuButton(
              icon: Icons.grid_view,
              currentView: currentView,
              onViewSelected: (NoteViewType selectedView) {
                ref.read(trashNoteViewTypeProvider.notifier).updateView(selectedView);
              },
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: !PlatformHelper.isWideLayout(context) ? double.infinity : 320,
              ),
              child: AppSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search trash...',
                fillColor: colorScheme.surfaceContainerLow,
                onChanged: (text) {
                  ref.read(trashSearchQueryProvider.notifier).updateQuery(text);
                },
                onClear: () {
                  ref.read(trashSearchQueryProvider.notifier).clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search_off),
            tooltip: 'Close search',
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
              ref.read(trashSearchQueryProvider.notifier).clear();
            },
          ),
        ],
      ),
    );
  }
}
