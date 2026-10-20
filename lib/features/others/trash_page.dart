import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/platform_helper.dart';
import '../../database/drift/folders/folders_dao.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/note_card/folder_trash_card.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/snack_bar_manager.dart';
import '../../shared/sort_menu_button.dart';
import '../../shared/view_menu_button.dart';
import '../folders/view/folder_selector.dart';
import 'package:noteit/features/home/core/providers.dart';
import '../home/view/shared/desktop_close_button.dart';

import '../../database/shared_preference/shared_preference_manager.dart';

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
final trashNoteViewTypeProvider = NotifierProvider<TrashNoteViewTypeNotifier, NoteViewType>(TrashNoteViewTypeNotifier.new);

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

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool isSelectMode = false;
  bool _isSearching = false;
  Folder? _selectedFolder;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final Set<String> selectedNoteIds = {};
  final Set<String> selectedFolderIds = {};

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

  Future<void> _handleEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all notes and folders in the trash. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
        SnackBarManager.show(
          msg: 'Emptying trash...',
          type: SnackBarMessageType.info,
        );

        await ref.read(noteActionsControllerProvider).emptyLocalAndCloudTrash();

        if (mounted) {
          SnackBarManager.show(
            msg: 'Trash emptied successfully.',
            type: SnackBarMessageType.acknowledgment,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(
            msg: 'Error emptying trash',
            description: '$e',
            type: SnackBarMessageType.error,
          );
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
          'This will permanently delete ${totalCount == 1 ? 'this item' : 'the $totalCount selected items'}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
        await ref.read(noteActionsControllerProvider).hardDeleteSelection(
          noteUuids: noteUuids,
          folderUuids: folderUuids,
        );

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
          SnackBarManager.show(
            msg: 'Error deleting items',
            description: '$e',
            type: SnackBarMessageType.error,
          );
        }
      }
    }
  }

  PreferredSizeWidget _buildAppBar(List<NoteWithFolder> currentNotes, List<Folder> currentFolders) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSelected = selectedNoteIds.length + selectedFolderIds.length;
    final totalItems = currentNotes.length + currentFolders.length;

    if (isSelectMode) {
      final isAllSelected = totalItems > 0 && totalSelected == totalItems;

      return AppBar(
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            isSelectMode = false;
            selectedNoteIds.clear();
            selectedFolderIds.clear();
          }),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                setState(() {
                  if (isAllSelected) {
                    selectedNoteIds.clear();
                    selectedFolderIds.clear();
                    isSelectMode = false;
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
            onPressed: () => _restoreItems(
              noteUuids: selectedNoteIds.toList(),
              folderUuids: selectedFolderIds.toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Selected',
            onPressed: () => _handleDeleteItems(
              noteUuids: selectedNoteIds.toList(),
              folderUuids: selectedFolderIds.toList(),
            ),
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Trash Bin'),
      backgroundColor: colorScheme.surfaceContainerLowest,
      centerTitle: true,
      actions: [
        if (!_isSearching)
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
        if (totalItems > 0)
          IconButton(
            onPressed: _handleEmptyTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty Trash',
          ),
        const SizedBox(width: 8),
        DesktopCloseButton(),
      ],
    );
  }

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
            if (_isSearching)
              Align(
                alignment: Alignment.topRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search trash notes & folders...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Close Search',
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Control Bar Row: FolderButton + SortMenuButton + ViewMenuButton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Row(
                children: [
                  FolderButton(
                    selectedFolder: _selectedFolder,
                    emptyLabel: 'All Folders',
                    showContextMenus: true,
                    onFolderSelected: (folder) {
                      setState(() {
                        _selectedFolder = folder;
                      });
                    },
                  ),
                  const Spacer(),
                  SortMenuButton(
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
                  ),
                  ViewMenuButton(
                    icon: Icon(Icons.grid_view, color: Theme.of(context).colorScheme.primary),
                    currentView: currentView,
                    onViewSelected: (NoteViewType selectedView) {
                      ref.read(trashNoteViewTypeProvider.notifier).updateView(selectedView);
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: trashNotesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (notes) {
                  return trashFoldersState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                    data: (folders) {
                      // 1. Folder Filter
                      var filteredNotes = _selectedFolder == null
                          ? notes
                          : notes.where((nwf) => nwf.note.folderId == _selectedFolder!.uuid).toList();

                      var filteredFolders = _selectedFolder == null
                          ? folders
                          : folders.where((f) => f.uuid == _selectedFolder!.uuid).toList();

                      // 2. Platform Filter
                      if (platformFilter != FilterPlatformOptions.all) {
                        final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
                        filteredNotes = filteredNotes.where((nwf) {
                          return nwf.note.creationPlatform?.toLowerCase() == targetPlatform;
                        }).toList();
                      }

                      // 3. Text Search Filter
                      if (searchQueryLower.isNotEmpty) {
                        filteredNotes = filteredNotes.where((nwf) {
                          return nwf.note.title.toLowerCase().contains(searchQueryLower) ||
                              nwf.note.content.toLowerCase().contains(searchQueryLower);
                        }).toList();

                        filteredFolders = filteredFolders.where((f) {
                          return f.name.toLowerCase().contains(searchQueryLower);
                        }).toList();
                      }

                      // 4. Sorting
                      filteredNotes.sort((a, b) {
                        switch (currentSort) {
                          case NoteSortPreference.name:
                            return a.note.title.toLowerCase().compareTo(b.note.title.toLowerCase());
                          case NoteSortPreference.createdAt:
                            return b.note.createdAt.compareTo(a.note.createdAt);
                          case NoteSortPreference.updatedAt:
                            return b.note.updatedAt.compareTo(a.note.updatedAt);
                        }
                      });

                      filteredFolders.sort((a, b) {
                        switch (currentSort) {
                          case NoteSortPreference.name:
                            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                          case NoteSortPreference.createdAt:
                            return b.createdAt.compareTo(a.createdAt);
                          case NoteSortPreference.updatedAt:
                            return b.updatedAt.compareTo(a.updatedAt);
                        }
                      });

                      if (filteredNotes.isEmpty && filteredFolders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                notes.isEmpty && folders.isEmpty ? 'Trash is empty' : 'No matching trashed items found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return CustomScrollView(
                        slivers: [
                          // 1. TRASHED FOLDERS SECTION (Dynamic Wrapped Chips)
                          if (filteredFolders.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                                child: Text(
                                  'Folders (${filteredFolders.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
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
                                  children: filteredFolders.map((folder) {
                                    final isSelected = selectedFolderIds.contains(folder.uuid);

                                    return FolderTrashCard(
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
                                        if (option == NoteContextMenuOption.select) {
                                          if (!isSelectMode) setState(() => isSelectMode = true);
                                          if (!isSelected) _toggleFolderSelection(folder.uuid);
                                          return;
                                        }

                                        if (option == NoteContextMenuOption.restore) {
                                          final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
                                          _restoreItems(folderUuids: targetUuids);
                                          return;
                                        }

                                        if (option == NoteContextMenuOption.deleteForever) {
                                          final targetUuids = isSelected ? selectedFolderIds.toList() : [folder.uuid];
                                          _handleDeleteItems(folderUuids: targetUuids);
                                          return;
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],

                          // 2. TRASHED NOTES SECTION
                          if (filteredNotes.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                                child: Text(
                                  'Notes (${filteredNotes.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
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
                                    final noteWithFolder = filteredNotes[index];
                                    final isSelected = selectedNoteIds.contains(noteWithFolder.note.uuid);

                                    return NoteCard(
                                      key: ValueKey(noteWithFolder.note.uuid),
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
                                          _toggleNoteSelection(noteWithFolder.note.uuid);
                                        }
                                      },
                                      onLongPress: () {
                                        if (!isSelectMode) {
                                          setState(() => isSelectMode = true);
                                        }
                                        _toggleNoteSelection(noteWithFolder.note.uuid);
                                      },
                                      onContextMenuAction: (option) {
                                        if (option == NoteContextMenuOption.select) {
                                          if (!isSelectMode) setState(() => isSelectMode = true);
                                          if (!isSelected) _toggleNoteSelection(noteWithFolder.note.uuid);
                                          return;
                                        }

                                        if (option == NoteContextMenuOption.restore) {
                                          final targetUuids = isSelected ? selectedNoteIds.toList() : [noteWithFolder.note.uuid];
                                          _restoreItems(noteUuids: targetUuids);
                                          return;
                                        }

                                        if (option == NoteContextMenuOption.deleteForever) {
                                          final targetUuids = isSelected ? selectedNoteIds.toList() : [noteWithFolder.note.uuid];
                                          _handleDeleteItems(noteUuids: targetUuids);
                                          return;
                                        }
                                      },
                                    );
                                  },
                                  childCount: filteredNotes.length,
                                ),
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 32),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
