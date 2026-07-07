import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/theme/note_theme.dart';
import '../../database/drift/drift_database.dart';
import '../../database/firebase/firebase_database.dart';
import '../../database/sync_manager.dart';
import '../../shared/note_card.dart';
import '../../shared/selectable_card.dart';


final trashNotesProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final driftDb = ref.watch(noteDriftDatabaseProvider);
  return driftDb.watchTrashNotes();
});

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool isSelectMode = false;
  final Set<int> noteIds = {};

  void _toggleSelection(int id) {
    setState(() {
      if (noteIds.contains(id)) {
        noteIds.remove(id);
        if (noteIds.isEmpty) isSelectMode = false;
      } else {
        noteIds.add(id);
      }
    });
  }

  // Handle the Empty Trash action with a confirmation dialog
  Future<void> _handleEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('This will permanently delete all items in the trash. This action cannot be undone.'),
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
      final driftDb = ref.read(noteDriftDatabaseProvider);
      final firebaseDb = ref.read(noteFirebaseDatabaseProvider);

      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emptying trash...')));

        // Delete locally and get the orphaned Firebase IDs
        final cloudIdsToDelete = await driftDb.emptyLocalTrash();

        // If online and logged in, delete from Firebase
        if (firebaseDb != null && cloudIdsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(cloudIdsToDelete);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error emptying trash: $e')));
        }
      }
    }
  }

  // Handle restoring a single note
  Future<void> _restoreNote(int noteId) async {
    final driftDb = ref.read(noteDriftDatabaseProvider);
    await driftDb.restoreNote(noteId);
    ref.read(syncNotifierProvider.notifier).executeFullSync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note restored.')));
    }
  }


// Handle deleting ONLY the selected notes permanently
  Future<void> _handleDeleteSelected(List<Note> allTrashNotes) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('This will permanently delete the ${noteIds.length} selected items. This action cannot be undone.'),
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
      final driftDb = ref.read(noteDriftDatabaseProvider);
      final firebaseDb = ref.read(noteFirebaseDatabaseProvider);

      try {
        // Get the Firebase IDs using your exact property name: firestoreId
        final notesToDelete = allTrashNotes.where((n) => noteIds.contains(n.id)).toList();
        final firestoreIdsToDelete = notesToDelete
            .map((n) => n.firestoreId) // <-- Fixed: cloudId changed to firestoreId
            .whereType<String>()
            .toList();

        // Loop and delete locally using your EXISTING hard-delete function
        for (final id in noteIds) {
          await driftDb.deleteNote(id);
        }

        // Delete from Firebase
        if (firebaseDb != null && firestoreIdsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(firestoreIdsToDelete);
        }

        setState(() {
          isSelectMode = false;
          noteIds.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected notes deleted.')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // App Bar Builder (Handles Default vs Select Mode)
  PreferredSizeWidget _buildAppBar(List<Note> currentNotes) {
    final noteTheme = Theme.of(context).extension<NoteTheme>();

    if (isSelectMode) {
      final isAllSelected = currentNotes.isNotEmpty && noteIds.length == currentNotes.length;

      return AppBar(
        backgroundColor: noteTheme?.selectedAppBar ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            isSelectMode = false;
            noteIds.clear();
          }),
        ),
        title: Text('${noteIds.length} Selected', style: const TextStyle(color: Colors.white)),
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
                    noteIds.clear();
                    isSelectMode = false;
                  } else {
                    noteIds.addAll(currentNotes.map((note) => note.id));
                  }
                });
              },
              child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore Selected',
            onPressed: () async {
              final driftDb = ref.read(noteDriftDatabaseProvider);
              for (final id in noteIds) {
                await driftDb.restoreNote(id);
              }
              ref.read(syncNotifierProvider.notifier).executeFullSync();
              setState(() {
                isSelectMode = false;
                noteIds.clear();
              });
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes restored.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Selected',
            onPressed: () => _handleDeleteSelected(currentNotes),
          ),
        ],
      );
    }

    // Default App Bar
    return AppBar(
      title: const Text('Trash'),
      actions: [
        if (currentNotes.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Empty Trash',
            onPressed: _handleEmptyTrash,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashState = ref.watch(trashNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: _buildAppBar(trashState.value ?? []),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: trashState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (notes) {
            if (notes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Trash is empty', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85)
                  : const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.85),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final isSelected = noteIds.contains(note.id);

                return SelectableCard(
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelectMode) {
                      _toggleSelection(note.id);
                    } else {
                      // Optional: Open a read-only view of the trashed note
                    }
                  },
                  onLongPress: () {
                    if (!isSelectMode) {
                      setState(() => isSelectMode = true);
                      _toggleSelection(note.id);
                    }
                  },
                  child: NoteCard(
                    note: note,
                    isSelected: isSelected,
                    hoverActions: [
                      // Selection Radio Button
                      IconButton(
                        icon: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (!isSelectMode) setState(() => isSelectMode = true);
                          _toggleSelection(note.id);
                        },
                      ),

                      // Restore Button (hidden in bulk-select mode to prevent confusion)
                      if (!isSelectMode)
                        IconButton(
                          icon: const Icon(Icons.restore, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Restore',
                          onPressed: () => _restoreNote(note.id),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}