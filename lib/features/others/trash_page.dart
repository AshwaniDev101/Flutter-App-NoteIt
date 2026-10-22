import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/platform_helper.dart';
import '../../database/drift/folders/folders_dao.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/app_search_bar.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/note_card/folder_trash_card.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/snack_bar_manager.dart';
import '../../shared/sort_menu_button.dart';
import '../../shared/view_menu_button.dart';
import '../home/core/providers.dart';
import '../home/view/shared/desktop_close_button.dart';
import '../note_editor/widgets/folder_option_menu.dart';

// ==========================================
// PROVIDERS & NOTIFIERS
// ==========================================

final trashNotesProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchTrashNotes();
});

final trashFoldersProvider = StreamProvider.autoDispose<List<Folder>>((ref) {
  final foldersDao = ref.watch(foldersDaoProvider);
  return foldersDao.watchTrashFolders();
});

/// Dedicated Sort Preference Provider for Trash Page
final trashNoteSortPreferenceProvider = NotifierProvider<TrashNoteSortPreferenceNotifier, NoteSortPreference>(() {
  return TrashNoteSortPreferenceNotifier();
});

class TrashNoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() {
    return SharedPreferenceManager.instance.getPageSortOption('trash');
  }

  void updateSort(NoteSortPreference option) {
    state = option;
    SharedPreferenceManager.instance.setPageSortOption('trash', option);
  }
}

/// Dedicated View Type Provider for Trash Page
final trashNoteViewTypeProvider = NotifierProvider<TrashNoteViewTypeNotifier, NoteViewType>(
  TrashNoteViewTypeNotifier.new,
);

class TrashNoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() {
    return SharedPreferenceManager.instance.getPageViewType('trash');
  }

  void updateView(NoteViewType view) {
    state = view;
    SharedPreferenceManager.instance.setPageViewType('trash', view);
  }
}

/// Dedicated Platform Filter Provider for Trash Page
final trashPlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);

// ==========================================
// TRASH PAGE WIDGET
// ==========================================

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> with WidgetsBindingObserver {
  bool isSelectMode = false;
  bool _isSearching = false;
  bool _wasKeyboardOpen = false;
  Folder? _selectedFolder;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final Set<String> selectedNoteIds = {};
  final Set<String> selectedFolderIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
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
  // SELECTION HELPERS
  // ------------------------------------------

  void _clearSelection() {
    setState(() {
      isSelectMode = false;
      selectedNoteIds.clear();
      selectedFolderIds.clear();
    });
  }

  void _toggleNoteSelection(String uuid) {
    setState(() {
      if (selectedNoteIds.contains(uuid)) {
        selectedNoteIds.remove(uuid);
      } else {
        selectedNoteIds.add(uuid);
      }
      isSelectMode = selectedNoteIds.isNotEmpty || selectedFolderIds.isNotEmpty;
    });
  }

  void _toggleFolderSelection(String uuid) {
    setState(() {
      if (selectedFolderIds.contains(uuid)) {
        selectedFolderIds.remove(uuid);
      } else {
        selectedFolderIds.add(uuid);
      }
      isSelectMode = selectedNoteIds.isNotEmpty || selectedFolderIds.isNotEmpty;
    });
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
  // ASYNC DIALOG ACTIONS
  // ------------------------------------------

  Future<void> _handleEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all notes and folders in the trash. Action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        SnackBarManager.show(msg: 'Emptying trash...', type: SnackBarMessageType.info);

        await ref.read(noteActionsControllerProvider).emptyLocalAndCloudTrash();

        if (mounted) {
          SnackBarManager.show(msg: 'Trash emptied successfully.', type: SnackBarMessageType.acknowledgment);
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(msg: 'Error emptying trash', description: '$e', type: SnackBarMessageType.error);
        }
      }
    }
  }

  Future<void> _restoreItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    final notesDao = ref.read(notesDaoProvider);
    final foldersDao = ref.read(foldersDaoProvider);

    if (noteUuids != null) {
      for (final uuid in noteUuids) {
        await notesDao.restoreNote(uuid);
      }
    }

    if (folderUuids != null) {
      for (final uuid in folderUuids) {
        await foldersDao.restoreFolder(uuid);
      }
    }

    ref.read(syncOrchestratorProvider).triggerSync();

    setState(() {
      if (noteUuids != null) selectedNoteIds.removeAll(noteUuids);
      if (folderUuids != null) selectedFolderIds.removeAll(folderUuids);
      isSelectMode = selectedNoteIds.isNotEmpty || selectedFolderIds.isNotEmpty;
    });

    if (mounted) {
      final totalCount = (noteUuids?.length ?? 0) + (folderUuids?.length ?? 0);
      SnackBarManager.show(
        msg: totalCount == 1 ? 'Item restored.' : '$totalCount items restored.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  Future<void> _handleDeleteItems({List<String>? noteUuids, List<String>? folderUuids}) async {
    final totalCount = (noteUuids?.length ?? 0) + (folderUuids?.length ?? 0);
    if (totalCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'This will permanently delete ${totalCount == 1 ? 'this item' : 'the $totalCount selected items'}. Action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(noteActionsControllerProvider)
            .hardDeleteSelection(noteUuids: noteUuids, folderUuids: folderUuids);

        setState(() {
          if (noteUuids != null) selectedNoteIds.removeAll(noteUuids);
          if (folderUuids != null) selectedFolderIds.removeAll(folderUuids);
          isSelectMode = selectedNoteIds.isNotEmpty || selectedFolderIds.isNotEmpty;
        });

        if (mounted) {
          SnackBarManager.show(
            msg: totalCount == 1 ? 'Item deleted permanently.' : 'Selected items deleted permanently.',
            type: SnackBarMessageType.acknowledgment,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(msg: 'Error deleting items', description: '$e', type: SnackBarMessageType.error);
        }
      }
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

  List<Folder> _getFilteredFolders({
    required List<Folder> folders,
    required String searchQueryLower,
    required NoteSortPreference currentSort,
  }) {
    var filtered = _selectedFolder == null
        ? folders
        : folders.where((f) => f.uuid == _selectedFolder!.uuid).toList();

    if (searchQueryLower.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.name.toLowerCase().contains(searchQueryLower);
      }).toList();
    }

    filtered.sort((a, b) {
      switch (currentSort) {
        case NoteSortPreference.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case NoteSortPreference.createdAt:
          return b.createdAt.compareTo(a.createdAt);
        case NoteSortPreference.updatedAt:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return filtered;
  }

  // ------------------------------------------
  // APP BAR BUILDERS WITH ANIMATION
  // ------------------------------------------

  PreferredSizeWidget _buildAppBar(List<NoteWithFolder> currentNotes, List<Folder> currentFolders) {
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
              ? _buildSelectionAppBar(currentNotes, currentFolders)
              : _buildStandardAppBar(currentNotes.length + currentFolders.length),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(List<NoteWithFolder> currentNotes, List<Folder> currentFolders) {
    final totalSelected = selectedNoteIds.length + selectedFolderIds.length;
    final totalItems = currentNotes.length + currentFolders.length;
    final isAllSelected = totalItems > 0 && totalSelected == totalItems;

    return AppBar(
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(
        '$totalSelected Selected',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _clearSelection();
                } else {
                  selectedNoteIds.addAll(currentNotes.map((n) => n.note.uuid));
                  selectedFolderIds.addAll(currentFolders.map((f) => f.uuid));
                }
              });
            },
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.restore),
          tooltip: 'Restore Selected',
          onPressed: () =>
              _restoreItems(noteUuids: selectedNoteIds.toList(), folderUuids: selectedFolderIds.toList()),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Delete Selected',
          onPressed: () =>
              _handleDeleteItems(noteUuids: selectedNoteIds.toList(), folderUuids: selectedFolderIds.toList()),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildStandardAppBar(int totalItems) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Trash Bin'),
      backgroundColor: colorScheme.surfaceContainerLowest,
      centerTitle: true,
      actions: [
        if (totalItems > 0)
          IconButton(
            onPressed: _handleEmptyTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty Trash',
          ),
        const SizedBox(width: 8),
        const DesktopCloseButton(),
      ],
    );
  }

  // ------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final trashNotesState = ref.watch(trashNotesProvider);
    final trashFoldersState = ref.watch(trashFoldersProvider);

    final searchQuery = _searchController.text.trim();
    final searchQueryLower = searchQuery.toLowerCase();

    final currentNotes = trashNotesState.value ?? [];
    final currentFolders = trashFoldersState.value ?? [];

    final currentSort = ref.watch(trashNoteSortPreferenceProvider);
    final currentView = ref.watch(trashNoteViewTypeProvider);
    final platformFilter = ref.watch(trashPlatformFilterProvider);

    return AppScaffold(
      appBar: _buildAppBar(currentNotes, currentFolders),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Column(
          children: [
            // Top control bar for Desktop
            if (PlatformHelper.isDesktopScreen) _buildControlBarContent(),

            // Content Area
            Expanded(
              child: trashNotesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (notes) {
                  return trashFoldersState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                    data: (folders) {
                      final filteredNotes = _getFilteredNotes(
                        notes: notes,
                        platformFilter: platformFilter,
                        searchQueryLower: searchQueryLower,
                        currentSort: currentSort,
                      );

                      final filteredFolders = _getFilteredFolders(
                        folders: folders,
                        searchQueryLower: searchQueryLower,
                        currentSort: currentSort,
                      );

                      final hasAnyTrashItems = notes.isNotEmpty || folders.isNotEmpty;

                      return _buildContentArea(
                        filteredNotes: filteredNotes,
                        filteredFolders: filteredFolders,
                        hasAnyTrashItems: hasAnyTrashItems,
                        currentView: currentView,
                        searchQuery: searchQuery,
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom control bar for Mobile
            if (PlatformHelper.isMobileScreen)
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
    required List<Folder> filteredFolders,
    required bool hasAnyTrashItems,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    final isEmpty = filteredNotes.isEmpty && filteredFolders.isEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isEmpty
          ? KeyedSubtree(
              key: const ValueKey('empty_trash_view'),
              child: _buildEmptyState(hasAnyTrashItems: hasAnyTrashItems),
            )
          : KeyedSubtree(
              key: const ValueKey('trash_scroll_view'),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ..._buildFoldersSlivers(filteredFolders),
                  ..._buildNotesSlivers(
                    notes: filteredNotes,
                    currentView: currentView,
                    searchQuery: searchQuery,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState({required bool hasAnyTrashItems}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            !hasAnyTrashItems ? 'Trash is empty' : 'No matching trashed items found',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFoldersSlivers(List<Folder> folders) {
    if (folders.isEmpty) return const [];

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Folders (${folders.length})',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: folders.map((folder) => _buildFolderCard(folder)).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _buildFolderCard(Folder folder) {
    final isSelected = selectedFolderIds.contains(folder.uuid);

    return AnimatedScale(
      scale: isSelected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: FolderTrashCard(
        folder: folder,
        isSelected: isSelected,
        onTap: () {
          if (isSelectMode) {
            _toggleFolderSelection(folder.uuid);
          }
        },
        onLongPress: () {
          if (!isSelectMode) {
            setState(() => isSelectMode = true);
          }
          _toggleFolderSelection(folder.uuid);
        },
        onContextMenuAction: (option) {
          switch (option) {
            case NoteContextMenuOption.select:
              if (!isSelectMode) setState(() => isSelectMode = true);
              if (!isSelected) _toggleFolderSelection(folder.uuid);
              break;

            case NoteContextMenuOption.restore:
              final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
              _restoreItems(folderUuids: targetUuids);
              break;

            case NoteContextMenuOption.deleteForever:
              final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
              _handleDeleteItems(folderUuids: targetUuids);
              break;

            default:
              break;
          }
        },
      ),
    );
  }

  List<Widget> _buildNotesSlivers({
    required List<NoteWithFolder> notes,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    if (notes.isEmpty) return const [];

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
          child: Text(
            'Notes (${notes.length})',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        sliver: SliverGrid(
          gridDelegate: _getGridDelegate(currentView),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final noteWithFolder = notes[index];
              return _buildNoteCard(
                noteWithFolder: noteWithFolder,
                currentView: currentView,
                searchQuery: searchQuery,
              );
            },
            childCount: notes.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildNoteCard({
    required NoteWithFolder noteWithFolder,
    required NoteViewType currentView,
    required String searchQuery,
  }) {
    final uuid = noteWithFolder.note.uuid;
    final isSelected = selectedNoteIds.contains(uuid);

    return AnimatedScale(
      scale: isSelected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: NoteCard(
        key: ValueKey(uuid),
        noteWithFolder: noteWithFolder,
        viewType: currentView,
        searchQuery: searchQuery,
        isSelected: isSelected,
        contextMenuOptions: const [
          NoteContextMenuOption.select,
          NoteContextMenuOption.restore,
          NoteContextMenuOption.deleteForever,
        ],
        onTap: () {
          if (isSelectMode) {
            _toggleNoteSelection(uuid);
          }
        },
        onLongPress: () {
          if (!isSelectMode) {
            setState(() => isSelectMode = true);
          }
          _toggleNoteSelection(uuid);
        },
        onContextMenuAction: (option) {
          switch (option) {
            case NoteContextMenuOption.select:
              if (!isSelectMode) setState(() => isSelectMode = true);
              if (!isSelected) _toggleNoteSelection(uuid);
              break;

            case NoteContextMenuOption.restore:
              final targetUuids = isSelected ? selectedNoteIds.toList() : [uuid];
              _restoreItems(noteUuids: targetUuids);
              break;

            case NoteContextMenuOption.deleteForever:
              final targetUuids = isSelected ? selectedNoteIds.toList() : [uuid];
              _handleDeleteItems(noteUuids: targetUuids);
              break;

            default:
              break;
          }
        },
      ),
    );
  }

  // ------------------------------------------
  // CONTROL BAR & MENU CONTROLS
  // ------------------------------------------

  Widget _buildControlBarContent() {
    final currentSort = ref.watch(trashNoteSortPreferenceProvider);
    final currentView = ref.watch(trashNoteViewTypeProvider);
    final platformFilter = ref.watch(trashPlatformFilterProvider);
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
                hintText: 'Search trash...',
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
            ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.createdAt);
            break;
          case HomeMenuAction.sortName:
            ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.name);
            break;
          case HomeMenuAction.sortUpdated:
            ref.read(trashNoteSortPreferenceProvider.notifier).updateSort(NoteSortPreference.updatedAt);
            break;
          case HomeMenuAction.filterAll:
            ref.read(trashPlatformFilterProvider.notifier).setFilter(FilterPlatformOptions.all);
            break;
          case HomeMenuAction.filterPhone:
            ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.android);
            break;
          case HomeMenuAction.filterWindows:
            ref.read(trashPlatformFilterProvider.notifier).toggleFilter(FilterPlatformOptions.windows);
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
        ref.read(trashNoteViewTypeProvider.notifier).updateView(selectedView);
      },
    );
  }
}
