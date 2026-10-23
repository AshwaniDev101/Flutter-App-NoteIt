import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/device_info.dart';
import '../../core/util/platform_helper.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/app_bars/top_select_mode_appbar.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/app_search_bar.dart';
import '../../shared/core/note_action_controller.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/core/note_action.dart';
import '../../shared/snack_bar_manager.dart';
import '../../shared/sort_menu_button.dart';
import '../../shared/view_menu_button.dart';
import '../home/core/note_tap_handler.dart';
import '../home/core/providers.dart';
import '../home/view/shared/desktop_close_button.dart';
import '../../shared/app_bars/bottom_select_mode_appbar.dart';
import '../note_editor/widgets/folder_option_menu.dart';

// ==========================================
// PROVIDERS & NOTIFIERS
// ==========================================

final archivedNotesStreamProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

/// Dedicated Sort Preference Provider for Archive Page
final archiveNoteSortPreferenceProvider = NotifierProvider<ArchiveNoteSortPreferenceNotifier, NoteSortPreference>(() {
  return ArchiveNoteSortPreferenceNotifier();
});

class ArchiveNoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() {
    return SharedPreferenceManager.instance.getPageSortOption('archive');
  }

  void updateSort(NoteSortPreference option) {
    state = option;
    SharedPreferenceManager.instance.setPageSortOption('archive', option);
  }
}

/// Dedicated View Type Provider for Archive Page
final archiveNoteViewTypeProvider = NotifierProvider<ArchiveNoteViewTypeNotifier, NoteViewType>(
  ArchiveNoteViewTypeNotifier.new,
);

class ArchiveNoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() {
    return SharedPreferenceManager.instance.getPageViewType('archive');
  }

  void updateView(NoteViewType view) {
    state = view;
    SharedPreferenceManager.instance.setPageViewType('archive', view);
  }
}

/// Dedicated Platform Filter Provider for Archive Page
final archivePlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);

// ==========================================
// ARCHIVE PAGE WIDGET
// ==========================================

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> with WidgetsBindingObserver {
  bool isSelectMode = false;
  bool _isSearching = false;
  bool _wasKeyboardOpen = false;
  Folder? _selectedFolder;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final Set<String> noteIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    if (isSelectMode) {
      ref.read(rightPanelSelectionProvider.notifier).exitSelection();
    }
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
      if (_isSearching && PlatformHelper.isMobileScreen && mounted) {
        setState(() {
          _isSearching = false;
          _searchController.clear();
        });
      }
    }
    _wasKeyboardOpen = isKeyboardOpen;
  }

  // ------------------------------------------
  // SELECTION & ACTIONS HELPERS
  // ------------------------------------------

  void _clearSelection() {
    ref.read(rightPanelSelectionProvider.notifier).exitSelection();
    setState(() {
      isSelectMode = false;
      noteIds.clear();
    });
  }

  void _toggleSelection(String uuid) {
    setState(() {
      if (noteIds.contains(uuid)) {
        noteIds.remove(uuid);
        if (noteIds.isEmpty) {
          isSelectMode = false;
          ref.read(rightPanelSelectionProvider.notifier).exitSelection();
        }
      } else {
        if (!isSelectMode || !ref.read(rightPanelSelectionProvider).isSelecting) {
          isSelectMode = true;
          ref.read(rightPanelSelectionProvider.notifier).enterSelection(onClear: _clearSelection);
        }
        noteIds.add(uuid);
      }
    });
  }

  Future<void> _unarchiveNotes(List<String> uuids) async {
    final actionsController = ref.read(noteActionsControllerProvider);
    await actionsController.unarchiveNotes(uuids);
    ref.read(syncOrchestratorProvider).triggerSync();

    setState(() {
      noteIds.removeAll(uuids);
      if (noteIds.isEmpty) {
        isSelectMode = false;
      }
    });

    if (mounted) {
      SnackBarManager.show(
        msg: uuids.length == 1 ? 'Note unarchived.' : 'Notes unarchived.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  Future<void> _deleteNotes(List<String> uuids) async {
    final deviceInfo = await ref.read(deviceInfoProvider.future);
    final actionsController = ref.read(noteActionsControllerProvider);
    await actionsController.deleteNotes(uuids, deviceInfo.extractPlatform);
    ref.read(syncOrchestratorProvider).triggerSync();

    setState(() {
      noteIds.removeAll(uuids);
      if (noteIds.isEmpty) {
        isSelectMode = false;
      }
    });

    if (mounted) {
      SnackBarManager.show(
        msg: uuids.length == 1 ? 'Note moved to trash.' : 'Notes moved to trash.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

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

  SliverGridDelegate _getGridDelegate(NoteViewType viewType) {
    final isMobile = PlatformHelper.isMobileScreen;
    switch (viewType) {
      case NoteViewType.list:
        return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisExtent: 44,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        );
      case NoteViewType.detailedList:
        return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisExtent: 125,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        );
      case NoteViewType.largeGrid:
        return isMobile
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              )
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 1.0,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              );
      case NoteViewType.grid:
        return isMobile
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              )
            : const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.85,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              );
    }
  }

  // ------------------------------------------
  // FILTERING & SORTING PROCESSORS
  // ------------------------------------------

  List<NoteWithFolder> _getFilteredNotes({
    required List<NoteWithFolder> notes,
    required FilterPlatformOptions platformFilter,
    required String searchQueryLower,
    required NoteSortPreference currentSort,
  }) {
    var filtered = _selectedFolder == null
        ? notes
        : notes.where((nwf) => nwf.note.folderId == _selectedFolder!.uuid).toList();

    if (platformFilter != FilterPlatformOptions.all) {
      final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
      filtered = filtered.where((nwf) {
        return nwf.note.creationPlatform?.toLowerCase() == targetPlatform;
      }).toList();
    }

    if (searchQueryLower.isNotEmpty) {
      filtered = filtered.where((nwf) {
        return nwf.note.title.toLowerCase().contains(searchQueryLower) ||
            nwf.note.content.toLowerCase().contains(searchQueryLower);
      }).toList();
    }

    filtered.sort((a, b) {
      switch (currentSort) {
        case NoteSortPreference.name:
          return a.note.title.toLowerCase().compareTo(b.note.title.toLowerCase());
        case NoteSortPreference.createdAt:
          return b.note.createdAt.compareTo(a.note.createdAt);
        case NoteSortPreference.updatedAt:
          return b.note.updatedAt.compareTo(a.note.updatedAt);
      }
    });

    return filtered;
  }

  // ------------------------------------------
  // APP BAR BUILDERS WITH ANIMATION
  // ------------------------------------------

  PreferredSizeWidget _buildAppBar(List<NoteWithFolder> currentNotesWithFolder) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(isSelectMode),
          child: isSelectMode
              ? _buildSelectionAppBar(currentNotesWithFolder)
              : _buildStandardAppBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(List<NoteWithFolder> currentNotesWithFolder) {
    return TopSelectModeAppBar(
      selectedCount: noteIds.length,
      onClearSelection: _clearSelection,
      onSelectAll: () {
        setState(() {
          final isAllSelected =
              currentNotesWithFolder.isNotEmpty && noteIds.length == currentNotesWithFolder.length;
          if (isAllSelected) {
            _clearSelection();
          } else {
            noteIds.addAll(currentNotesWithFolder.map((nwf) => nwf.note.uuid));
          }
        });
      },
      noteActions: const [
        NoteAction.unarchive,
        NoteAction.delete,
      ],
      onActionSelected: (action) {
        final targetUuids = noteIds.toList();
        if (action == NoteAction.unarchive) {
          _unarchiveNotes(targetUuids);
        } else if (action == NoteAction.delete) {
          _deleteNotes(targetUuids);
        }
      },
    );
  }

  PreferredSizeWidget _buildStandardAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Archive'),
      backgroundColor: colorScheme.surfaceContainerLowest,
      centerTitle: true,
      actions: const [
        DesktopCloseButton(),
      ],
    );
  }

  // ------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final archivedNotesState = ref.watch(archivedNotesStreamProvider);
    final searchQuery = _searchController.text.trim();
    final searchQueryLower = searchQuery.toLowerCase();

    final currentNotes = archivedNotesState.value ?? [];

    final currentSort = ref.watch(archiveNoteSortPreferenceProvider);
    final currentView = ref.watch(archiveNoteViewTypeProvider);
    final platformFilter = ref.watch(archivePlatformFilterProvider);

    return AppScaffold(
      appBar: _buildAppBar(currentNotes),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Column(
          children: [
            // Top control bar for Desktop
            if (PlatformHelper.isDesktopScreen) _buildControlBarContent(),

            // Content Area
            Expanded(
              child: archivedNotesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (notes) {
                  final filteredNotes = _getFilteredNotes(
                    notes: notes,
                    platformFilter: platformFilter,
                    searchQueryLower: searchQueryLower,
                    currentSort: currentSort,
                  );

                  return _buildContentArea(
                    filteredNotes: filteredNotes,
                    isArchiveEmpty: notes.isEmpty,
                    currentView: currentView,
                    searchQuery: searchQuery,
                  );
                },
              ),
            ),

            // Bottom control bar for Mobile
            if (PlatformHelper.isMobileScreen && !isSelectMode)
              BottomAppBar(
                elevation: 8.0,
                child: _buildControlBarContent(),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------
  // SUB-VIEW BUILDERS
  // ------------------------------------------

  Widget _buildContentArea({
    required List<NoteWithFolder> filteredNotes,
    required bool isArchiveEmpty,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: filteredNotes.isEmpty
          ? KeyedSubtree(
              key: const ValueKey('empty_archive_view'),
              child: _buildEmptyState(isArchiveEmpty: isArchiveEmpty),
            )
          : KeyedSubtree(
              key: const ValueKey('archive_grid_view'),
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                physics: const BouncingScrollPhysics(),
                gridDelegate: _getGridDelegate(currentView),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final noteWithFolder = filteredNotes[index];
                  final isSelected = noteIds.contains(noteWithFolder.note.uuid);

                  return AnimatedScale(
                    scale: isSelected ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    child: NoteCard(
                      key: ValueKey(noteWithFolder.note.uuid),
                      noteWithFolder: noteWithFolder,
                      viewType: currentView,
                      searchQuery: searchQuery,
                      isSelected: isSelected,
                      contextMenuOptions: const [
                        NoteAction.select,
                        NoteAction.unarchive,
                        NoteAction.delete,
                      ],
                      onTap: () {
                        if (isSelectMode) {
                          _toggleSelection(noteWithFolder.note.uuid);
                        } else {
                          NoteTapHandler.openNote(context, ref, noteWithFolder);
                        }
                      },
                      onLongPress: () {
                        if (!isSelectMode) {
                          setState(() => isSelectMode = true);
                        }
                        _toggleSelection(noteWithFolder.note.uuid);
                      },
                      onContextMenuAction: (option) {
                        switch (option) {
                          case NoteAction.select:
                            if (!isSelectMode) setState(() => isSelectMode = true);
                            if (!isSelected) _toggleSelection(noteWithFolder.note.uuid);
                            break;

                          case NoteAction.unarchive:
                            final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                            _unarchiveNotes(targetUuids);
                            break;

                          case NoteAction.delete:
                            final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                            _deleteNotes(targetUuids);
                            break;

                          default:
                            break;
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState({required bool isArchiveEmpty}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isArchiveEmpty ? 'Your archive is empty.' : 'No matching archived notes found.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // CONTROL BAR & MENU CONTROLS
  // ------------------------------------------

  Widget _buildControlBarContent() {
    final currentSort = ref.watch(archiveNoteSortPreferenceProvider);
    final currentView = ref.watch(archiveNoteViewTypeProvider);
    final platformFilter = ref.watch(archivePlatformFilterProvider);
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
          _folderOptionMenu(),
          const Spacer(),
          _sortMenuButton(currentSort, platformFilter),
          _viewMenuButton(currentView),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Archive',
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
          if (PlatformHelper.isDesktopScreen) ...[
            _folderOptionMenu(),
            const Spacer(),
            _sortMenuButton(currentSort, platformFilter),
            _viewMenuButton(currentView),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: PlatformHelper.isMobileScreen ? double.infinity : 320,
              ),
              child: AppSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search archive...',
                fillColor: colorScheme.surfaceContainerLow,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
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
            },
          ),
        ],
      ),
    );
  }

  Widget _folderOptionMenu() {
    return FolderOptionMenu(
      selectedFolder: _selectedFolder,
      emptyLabel: 'All Folders',
      onFolderSelected: (folder) {
        setState(() {
          _selectedFolder = folder;
        });
      },
    );
  }

  Widget _sortMenuButton(NoteSortPreference currentSort, FilterPlatformOptions platformFilter) {
    return SortMenuButton(
      icon: Icon(CupertinoIcons.sort_down, color: Theme.of(context).colorScheme.primary),
      currentSortSelection: _getCurrentSortAction(currentSort),
      currentPlatformSelection: _getCurrentPlatformAction(platformFilter),
      onSelected: (HomeMenuAction action) {
        switch (action) {
          case HomeMenuAction.sortCreated:
            ref.read(archiveNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
            break;
          case HomeMenuAction.sortName:
            ref.read(archiveNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
            break;
          case HomeMenuAction.sortUpdated:
            ref.read(archiveNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
            break;
          case HomeMenuAction.filterAll:
            ref.read(archivePlatformFilterProvider.notifier).setFilter(FilterPlatformOptions.all);
            break;
          case HomeMenuAction.filterPhone:
            ref.read(archivePlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
            break;
          case HomeMenuAction.filterWindows:
            ref.read(archivePlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
            break;
        }
      },
    );
  }

  Widget _viewMenuButton(NoteViewType currentView) {
    return ViewMenuButton(
      icon: Icon(Icons.grid_view, color: Theme.of(context).colorScheme.primary),
      currentView: currentView,
      onViewSelected: (NoteViewType selectedView) {
        ref.read(archiveNoteViewTypeProvider.notifier).updateView(selectedView);
      },
    );
  }
}
