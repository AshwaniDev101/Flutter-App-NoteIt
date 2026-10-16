import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/core/note_tap_handler.dart';
import 'package:noteit/shared/app_scaffold.dart';

import '../../core/device_info.dart';
import '../../core/util/platform_helper.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/sync/sync_orchestrator.dart';
import '../../shared/note_card/core/note_action_controller.dart';
import '../../shared/note_card/note_card.dart';
import '../../shared/snack_bar_manager.dart';
import '../home/view/shared/desktop_close_button.dart';

final archivedNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
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

  PreferredSizeWidget _buildAppBar(List<Note> currentNotes) {
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
                    noteIds.addAll(currentNotes.map((note) => note.uuid));
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

    return AppScaffold(
      appBar: _buildAppBar(archivedNotesState.value ?? []),
      body: Column(
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

          Expanded(
            child: archivedNotesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (notes) {
                final filteredNotes = searchQuery.isEmpty
                    ? notes
                    : notes.where((note) {
                        final queryLower = searchQuery.toLowerCase();
                        return note.title.toLowerCase().contains(queryLower) ||
                            note.content.toLowerCase().contains(queryLower);
                      }).toList();

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
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    final isSelected = noteIds.contains(note.uuid);

                    return NoteCard(
                      key: ValueKey(note.uuid),
                      note: note,
                      searchQuery: searchQuery,
                      isSelected: isSelected,
                      contextMenuOptions: const [
                        NoteContextMenuOption.select,
                        NoteContextMenuOption.unarchive,
                        NoteContextMenuOption.delete,
                      ],
                      onTap: () {
                        if (isSelectMode) {
                          _toggleSelection(note.uuid);
                        } else {
                          NoteTapHandler.openNote(context, ref, note);
                        }
                      },
                      onLongPress: () {
                        if (!isSelectMode) {
                          setState(() => isSelectMode = true);
                          _toggleSelection(note.uuid);
                        }
                      },
                      onContextMenuAction: (option) {
                        if (option == NoteContextMenuOption.select) {
                          if (!isSelectMode) {
                            setState(() => isSelectMode = true);
                          }
                          if (!isSelected) {
                            _toggleSelection(note.uuid);
                          }
                          return;
                        }

                        if (option == NoteContextMenuOption.unarchive) {
                          final targetUuids = isSelected ? noteIds.toList() : [note.uuid];
                          _unarchiveNotes(targetUuids);
                          return;
                        }

                        if (option == NoteContextMenuOption.delete) {
                          final targetUuids = isSelected ? noteIds.toList() : [note.uuid];
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
