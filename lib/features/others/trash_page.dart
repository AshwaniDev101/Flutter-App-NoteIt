import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/platform_helper.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/firebase/firebase_database.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/snack_bar_manager.dart';
import '../home/view/shared/desktop_close_button.dart';

final trashNotesProvider = StreamProvider.autoDispose<List<NoteWithFolder>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchTrashNotes();
});

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool isSelectMode = false;
  bool _isSearching = false;

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

  // Handle the Empty Trash action with a confirmation dialog
  Future<void> _handleEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all items in the trash. This action cannot be undone.',
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
      final notesDao = ref.read(notesDaoProvider);
      final firebaseDb = ref.read(noteFirebaseDatabaseProvider);

      try {
        SnackBarManager.show(
          msg: 'Emptying trash...',
          type: SnackBarMessageType.info,
        );

        // Delete locally and get the UUIDs
        final cloudIdsToDelete = await notesDao.emptyLocalTrash();

        // If online and logged in, delete from Firebase using the UUIDs
        if (firebaseDb != null && cloudIdsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(cloudIdsToDelete);
        }

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

  // Handle restoring notes
  Future<void> _restoreNotes(List<String> uuids) async {
    final notesDao = ref.read(notesDaoProvider);
    for (final uuid in uuids) {
      await notesDao.restoreNote(uuid);
    }

    // Trigger the Orchestrator to broadcast the restoration
    ref.read(syncOrchestratorProvider).triggerSync();

    setState(() {
      noteIds.removeAll(uuids);
      if (noteIds.isEmpty) {
        isSelectMode = false;
      }
    });

    if (mounted) {
      SnackBarManager.show(
        msg: uuids.length == 1 ? 'Note restored.' : 'Notes restored.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  // Handle deleting notes permanently
  Future<void> _handleDeleteUuids(List<String> uuidsToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'This will permanently delete ${uuidsToDelete.length == 1 ? 'this item' : 'the ${uuidsToDelete.length} selected items'}. This action cannot be undone.',
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
      final notesDao = ref.read(notesDaoProvider);
      final firebaseDb = ref.read(noteFirebaseDatabaseProvider);

      try {
        // Loop and delete locally
        for (final uuid in uuidsToDelete) {
          await notesDao.deleteNote(uuid);
        }

        // Delete from Firebase directly using the UUIDs
        if (firebaseDb != null && uuidsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(uuidsToDelete);
        }

        setState(() {
          noteIds.removeAll(uuidsToDelete);
          if (noteIds.isEmpty) {
            isSelectMode = false;
          }
        });

        if (mounted) {
          SnackBarManager.show(
            msg: uuidsToDelete.length == 1
                ? 'Note deleted permanently.'
                : 'Selected notes deleted permanently.',
            type: SnackBarMessageType.acknowledgment,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarManager.show(
            msg: 'Error deleting notes',
            description: '$e',
            type: SnackBarMessageType.error,
          );
        }
      }
    }
  }

  // App Bar Builder (Handles Default vs Select Mode)
  PreferredSizeWidget _buildAppBar(List<NoteWithFolder> currentNotes) {

    final colorScheme = Theme.of(context).colorScheme;

    if (isSelectMode) {
      final isAllSelected =
          currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

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
                    noteIds.addAll(currentNotes.map((noteWithFolder) => noteWithFolder.note.uuid));
                  }
                });
              },
              child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore Selected',
            onPressed: () => _restoreNotes(noteIds.toList()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Selected',
            onPressed: () => _handleDeleteUuids(noteIds.toList()),
          ),
        ],
      );
    }

    // Default App Bar
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
              // Small delay to ensure the TextField is built before focusing
              Future.delayed(const Duration(milliseconds: 50), () {
                _searchFocusNode.requestFocus();
              });
            },
          ),

        if (currentNotes.isNotEmpty)
          IconButton(
            onPressed: _handleEmptyTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Empty Trash',
          ),

        const SizedBox(width: 8), DesktopCloseButton(),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashState = ref.watch(trashNotesProvider);
    final searchQuery = _searchController.text.trim();
    final searchQueryLower = searchQuery.toLowerCase();

    return AppScaffold(
      appBar: _buildAppBar(trashState.value ?? []),
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
                              hintText: 'Search trash notes...',
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
            Expanded(
              child: trashState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (List<NoteWithFolder> notes) {
                  final filteredNotesWithFolder = searchQueryLower.isEmpty
                      ? notes
                      : notes.where((noteWithFolder) {
                          return noteWithFolder.note.title.toLowerCase().contains(searchQueryLower) ||
                              noteWithFolder.note.content.toLowerCase().contains(searchQueryLower);
                        }).toList();

                  if (filteredNotesWithFolder.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            notes.isEmpty ? 'Trash is empty' : 'No matching trashed notes found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: PlatformHelper.isMobileScreen
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
                    ),
                    itemCount: filteredNotesWithFolder.length,
                    itemBuilder: (context, index) {
                      final noteWithFolder = filteredNotesWithFolder[index];
                      final isSelected = noteIds.contains(noteWithFolder.note.uuid);

                      return NoteCard(
                        key: ValueKey(noteWithFolder.note.uuid),
                        noteWithFolder: noteWithFolder,
                        searchQuery: searchQuery,
                        isSelected: isSelected,
                        contextMenuOptions: const [
                          NoteContextMenuOption.select,
                          NoteContextMenuOption.restore,
                          NoteContextMenuOption.deleteForever,
                        ],
                        onTap: () {
                          if (isSelectMode) {
                            _toggleSelection(noteWithFolder.note.uuid);
                          } else {
                            // Todo: Open a read-only view of the trashed note
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

                          if (option == NoteContextMenuOption.restore) {
                            final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                            _restoreNotes(targetUuids);
                            return;
                          }

                          if (option == NoteContextMenuOption.deleteForever) {
                            final targetUuids = isSelected ? noteIds.toList() : [noteWithFolder.note.uuid];
                            _handleDeleteUuids(targetUuids);
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
      ),
    );
  }
}
