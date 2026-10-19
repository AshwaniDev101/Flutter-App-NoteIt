import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/home/view/shared/select_mode_app_bars.dart';
import 'package:noteit/features/home/viewmodel/viewmodel.dart';
import 'package:noteit/shared/note_card/dynamic_notes_layout.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../../../../shared/sort_menu_button.dart';
import '../../../../shared/view_menu_button.dart';
import '../../../drawer/mobile_app_drawer.dart';
import '../../../folders/core/providers.dart';
import '../../../folders/view/folder_selector.dart';
import '../../core/db_sorting_filtering.dart';
import '../../core/note_tap_handler.dart';
import '../../core/providers.dart';
import '../shared/home_search_bar.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });

    // _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNoteTap(NoteWithFolder noteWithFolder) {
    NoteTapHandler.openNote(context, ref, noteWithFolder);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    final currentSort = ref.watch(homeNoteSortPreferenceProvider);
    final currentView = ref.watch(homeNoteViewTypeProvider);
    final platformFilter = ref.watch(homePlatformFilterProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: _buildAppBar(homeState),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.edit),
          elevation: 3,
          child: const Icon(Icons.edit),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: HomeSearchBar(
                      controller: _searchController,
                      hintText: 'Search notes...',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // const SortViewButton(),

                  // SortFilterOptionMenu(),
                  // _buildFilterMenu(
                  //   currentSortOption,
                  //   currentPlatformFilter,
                  //   colorScheme,
                  // ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4), // This is to compensate for the card 4px padding
              child: Row(
                children: [
                  FolderButton(
                    selectedFolder: ref.watch(activeFolderProvider),
                    emptyLabel: 'All Notes',
                    showContextMenus: true,
                    onFolderSelected: (folder) {
                      if (folder == null) {
                        ref.read(activeFolderProvider.notifier).clear();
                      } else {
                        ref.read(activeFolderProvider.notifier).setFolder(folder);
                      }
                    },
                  ),
                  Spacer(),

                  // IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.sort_down)),
                  // IconButton(onPressed: (){}, icon: Icon(Icons.grid_view)),
                  SortMenuButton(
                    icon: Icon(CupertinoIcons.sort_down,color: Theme.of(context).colorScheme.primary),
                    currentSortSelection: _getCurrentSortAction(currentSort),
                    currentPlatformSelection: _getCurrentPlatformAction(platformFilter),
                    onSelected: (HomeMenuAction action) {
                      // Route the UI action to the correct Riverpod provider
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
                    icon: Icon(Icons.grid_view,color: Theme.of(context).colorScheme.primary),
                    currentView: currentView,
                    onViewSelected: (NoteViewType selectedView) {
                      ref.read(homeNoteViewTypeProvider.notifier).updateView(selectedView);
                    },
                  ),

                  // IconButton(onPressed: (){}, icon: HugeIcon(
                  //   icon: HugeIcons.strokeRoundedHome01,
                  // ))
                ],
              ),
            ),
            Expanded(
              child: DynamicNotesLayout(
                isSelectMode: homeState.isSelectMode,
                noteIds: homeState.selectedNoteIds,
                activeNoteId: null,
                onToggleSelection: viewModel.toggleSelection,
                onEnableSelectMode: viewModel.enableSelectMode,
                onNoteTap: _handleNoteTap,
              ),
              // child: NotesGridView(
              //   isSelectMode: homeState.isSelectMode,
              //   noteIds: homeState.selectedNoteIds,
              //   // NotesGridView expects a Set<String>
              //   activeNoteId: null,
              //   onToggleSelection: viewModel.toggleSelection,
              //   onEnableSelectMode: viewModel.enableSelectMode,
              //   onPromptPassword: (ctx, note) => PasswordPromptHelper.promptAndVerify(ctx, ref, note),
              //   onNoteTap: _handleNoteTap,
              // ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomePageState state) {
    if (state.isSelectMode) {
      return SelectModeAppBar(
        noteIds: state.selectedNoteIds,
      );
    }
    return AppBar(
      // leading: DrawerMenuButton(),
      // title: const Text('Notes'),
      elevation: 0,
      // centerTitle: true,
      actions: const [
        IconTray(),
        SizedBox(width: 8),
      ],
    );
  }

  // Helper method to map your internal NoteSortPreference back to the UI Enum (HomeMenuAction)
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
}
