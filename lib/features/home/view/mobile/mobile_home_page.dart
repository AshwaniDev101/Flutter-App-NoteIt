import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/home/view/shared/select_search_app_bars.dart';

import '../../../../core/routing/routing.dart';
import '../../../../database/drift/notes/notes_dao.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../../../shared/app_search_bar.dart';
import '../../../../shared/note_card/dynamic_notes_layout.dart';
import '../../../../shared/sort_menu_button.dart';
import '../../../../shared/view_menu_button.dart';
import '../../../drawer/mobile_app_drawer.dart';
import '../../../folders/core/providers.dart';
import '../../../folders/view/folder_selector.dart';
import '../../core/db_sorting_filtering.dart';
import '../../core/note_tap_handler.dart';
import '../../core/providers.dart';
import '../../viewmodel/viewmodel.dart';

// ==========================================
// MOBILE HOME PAGE
// ==========================================

class MobileHomePage extends ConsumerStatefulWidget {
  const MobileHomePage({super.key});

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).triggerSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    if (_wasKeyboardOpen && !isKeyboardOpen) {
      final homeState = ref.read(homeViewModelProvider);
      if (homeState.isSearchMode && mounted) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).clear();
        ref.read(homeViewModelProvider.notifier).exitSearchMode();
      }
    }
    _wasKeyboardOpen = isKeyboardOpen;
  }

  void _handleNoteTap(NoteWithFolder noteWithFolder) {
    NoteTapHandler.openNote(context, ref, noteWithFolder);
  }

  // ------------------------------------------
  // APP BAR BUILDERS
  // ------------------------------------------

  PreferredSizeWidget _buildAppBar(HomePageState state) {
    if (state.isSelectMode) {
      return TopSelectModeAppBar(
        noteIds: state.selectedNoteIds,
      );
    }

    return AppBar(
      elevation: 0,
      actions: const [
        IconTray(),
        SizedBox(width: 8),
      ],
    );
  }


  Widget _buildBottomAppBar(HomePageState homeState, HomeViewModel homeViewModel) {
    if (homeState.isSelectMode) {
      return BottomSelectModeAppBar();
    }

    return _MobileBottomControlBar(
      homeState: homeState,
      viewModel: homeViewModel,
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
    );
  }





  // ------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Watched solely to keep the sync manager alive in the widget tree.
    ref.watch(syncOrchestratorProvider);

    return PopScope(
      canPop: !homeState.isSelectMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && homeState.isSelectMode) viewModel.clearSelection();
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: _buildAppBar(homeState),
        floatingActionButton: _MobileFAB(
          onPressed: () => context.push(AppRoutes.edit),
        ),
        bottomNavigationBar: _buildBottomAppBar(homeState, viewModel),
        // bottomNavigationBar: _MobileBottomControlBar(
        //   homeState: homeState,
        //   viewModel: viewModel,
        //   searchController: _searchController,
        //   searchFocusNode: _searchFocusNode,
        // ),
        body: DynamicNotesLayout(
          isSelectMode: homeState.isSelectMode,
          noteIds: homeState.selectedNoteIds,
          activeNoteId: null,
          onToggleSelection: viewModel.toggleSelection,
          onEnableSelectMode: viewModel.enableSelectMode,
          onNoteTap: _handleNoteTap,
        ),
      ),
    );
  }
}

// ==========================================
// ISOLATED SUB-WIDGETS (HIGH PERFORMANCE)
// ==========================================

class _MobileFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _MobileFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 3,
      child: const Icon(Icons.edit),
    );
  }
}

class _MobileBottomControlBar extends ConsumerWidget {
  final HomePageState homeState;
  final HomeViewModel viewModel;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const _MobileBottomControlBar({
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
                    icon: Icon(CupertinoIcons.sort_down, color: colorScheme.primary),
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
                    icon: Icon(Icons.grid_view, color: colorScheme.primary),
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
                  ),
                ],
              ),
      ),
    );
  }
}
