import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/device_info.dart';
import '../../core/util/platform_helper.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/snack_bar_manager.dart';
import '../../shared/sort_menu_button.dart';
import '../../shared/view_menu_button.dart';
import '../folders/view/folder_selector.dart';
import '../home/core/note_tap_handler.dart';
import '../home/core/providers.dart';
import '../home/view/shared/desktop_close_button.dart';

final archivedNotesStreamProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

/// Dedicated Sort Preference Provider for Archive Page
final archiveNoteSortPreferenceProvider = NotifierProvider<ArchiveNoteSortPreferenceNotifier, NoteSortPreference>(() {
  return ArchiveNoteSortPreferenceNotifier();
});

class ArchiveNoteSortPreferenceNotifier extends Notifier<NoteSortPreference> {
  @override
  NoteSortPreference build() => NoteSortPreference.createdAt;

  void updateSort(NoteSortPreference option) {
    state = option;
  }
}

/// Dedicated View Type Provider for Archive Page
final archiveNoteViewTypeProvider = NotifierProvider<ArchiveNoteViewTypeNotifier, NoteViewType>(ArchiveNoteViewTypeNotifier.new);

class ArchiveNoteViewTypeNotifier extends Notifier<NoteViewType> {
  @override
  NoteViewType build() => NoteViewType.grid;

  void updateView(NoteViewType view) {
    state = view;
  }
}

/// Dedicated Platform Filter Provider for Archive Page
final archivePlatformFilterProvider = NotifierProvider<PlatformFilterNotifier, FilterPlatformOptions>(
  PlatformFilterNotifier.new,
);

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
  bool isSelectMode = false;
  bool _isSearching = false;
  Folder? _selectedFolder;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final Set<String> noteIds = {};

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

  void _toggleSelection(String uuid) {
    setState(() {
      if (noteIds.contains(uuid)) {
        noteIds.remove(uuid);
        if (noteIds.isEmpty) isSelectMode = false;
      } else {
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
          mainAxisExtent: 110,
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

  PreferredSizeWidget _buildAppBar(List<NoteWithFolder> currentNotesWithFolder) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSelectMode) {
      final isAllSelected =
          currentNotesWithFolder.isNotEmpty && noteIds.length == currentNotesWithFolder.length;

      return AppBar(
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            isSelectMode = false;
            noteIds.clear();
          }),
        ),
        title: Text(
          '${noteIds.length} Selected',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 10.0,
            ),
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
                    noteIds.clear();
                    isSelectMode = false;
                  } else {
                    noteIds.addAll(currentNotesWithFolder.map((noteWithFolder) => noteWithFolder.note.uuid));
                  }
                });
              },
              child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unarchive),
            tooltip: 'Unarchive Selected',
            onPressed: () => _unarchiveNotes(noteIds.toList()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Selected',
            onPressed: () => _deleteNotes(noteIds.toList()),
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Archive'),
      backgroundColor: colorScheme.surfaceContainerLowest,
      centerTitle: true,
      actions: [
        if (!_isSearching)
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
        const SizedBox(width: 8),
        DesktopCloseButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final archivedNotesState = ref.watch(archivedNotesStreamProvider);
    final searchQuery = _searchController.text.trim();

    final currentSort = ref.watch(archiveNoteSortPreferenceProvider);
    final currentView = ref.watch(archiveNoteViewTypeProvider);
    final platformFilter = ref.watch(archivePlatformFilterProvider);

    return AppScaffold(
      appBar: _buildAppBar(archivedNotesState.value ?? []),
      body: Column(
        children: [
          // Search Field Row
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
                            hintText: 'Search archived notes...',
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
                ),
                ViewMenuButton(
                  icon: Icon(Icons.grid_view, color: Theme.of(context).colorScheme.primary),
                  currentView: currentView,
                  onViewSelected: (NoteViewType selectedView) {
                    ref.read(archiveNoteViewTypeProvider.notifier).updateView(selectedView);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: archivedNotesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (notes) {
                // Apply Folder Filter
                var filteredNotes = _selectedFolder == null
                    ? notes
                    : notes.where((nwf) => nwf.note.folderId == _selectedFolder!.uuid).toList();

                // Apply Platform Filter
                if (platformFilter != FilterPlatformOptions.all) {
                  final targetPlatform = platformFilter == FilterPlatformOptions.android ? 'android' : 'windows';
                  filteredNotes = filteredNotes.where((nwf) {
                    return nwf.note.creationPlatform?.toLowerCase() == targetPlatform;
                  }).toList();
                }

                // Apply Text Search
                if (searchQuery.isNotEmpty) {
                  final queryLower = searchQuery.toLowerCase();
                  filteredNotes = filteredNotes.where((noteWithFolder) {
                    return noteWithFolder.note.title.toLowerCase().contains(queryLower) ||
                        noteWithFolder.note.content.toLowerCase().contains(searchQuery);
                  }).toList();
                }

                // Apply Sorting
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

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notes.isEmpty
                              ? 'Your archive is empty.'
                              : 'No matching archived notes found.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: _getGridDelegate(currentView),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final NoteWithFolder noteWithFolder = filteredNotes[index];
                    final isSelected = noteIds.contains(noteWithFolder.note.uuid);

                    return NoteCard(
                      key: ValueKey(noteWithFolder.note.uuid),
                      noteWithFolder: noteWithFolder,
                      viewType: currentView,
                      searchQuery: searchQuery,
                      isSelected: isSelected,
                      contextMenuOptions: const [
                        NoteContextMenuOption.select,
                        NoteContextMenuOption.unarchive,
                        NoteContextMenuOption.delete,
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
                          _toggleSelection(noteWithFolder.note.uuid);
                        }
                      },
                      onContextMenuAction: (option) {
                        if (option == NoteContextMenuOption.select) {
                          if (!isSelectMode) {
                            setState(() => isSelectMode = true);
                          }
                          if (!isSelected) {
                            _toggleSelection(noteWithFolder.note.uuid);
                          }
                          return;
                        }

                        if (option == NoteContextMenuOption.unarchive) {
                          final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                          _unarchiveNotes(targetUuids);
                          return;
                        }

                        if (option == NoteContextMenuOption.delete) {
                          final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                          _deleteNotes(targetUuids);
                          return;
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
