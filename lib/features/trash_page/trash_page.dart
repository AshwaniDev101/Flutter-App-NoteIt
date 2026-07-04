import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust these imports to match your actual project structure
import '../../database/drift/drift_database.dart';
import '../../database/firebase/firebase_database.dart';
import '../../database/sync_manager.dart';

// Create a StreamProvider specifically for the Trash UI
final trashNotesProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final driftDb = ref.watch(noteDriftDatabaseProvider);
  return driftDb.watchTrashNotes();
});

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  // Handle the Empty Trash action with a confirmation dialog
  Future<void> _handleEmptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('This will permanently delete all items in the trash. This action cannot be undone.'),
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

    if (confirmed == true && context.mounted) {
      final driftDb = ref.read(noteDriftDatabaseProvider);
      final firebaseDb = ref.read(noteFirebaseDatabaseProvider);

      try {
        // Show a loading indicator if you have a global one, otherwise let it run
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emptying trash...')),
        );

        // 1. Delete locally and get the orphaned Firebase IDs
        final cloudIdsToDelete = await driftDb.emptyLocalTrash();

        // 2. If online and logged in, delete from Firebase
        if (firebaseDb != null && cloudIdsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(cloudIdsToDelete);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trash emptied successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error emptying trash: $e')),
          );
        }
      }
    }
  }

  // Handle restoring a note
  Future<void> _restoreNote(BuildContext context, WidgetRef ref, int noteId) async {
    final driftDb = ref.read(noteDriftDatabaseProvider);

    // Nullify the deletedAt flag and set syncStatus to 0
    await driftDb.restoreNote(noteId);

    // Trigger the sync manager to push this restored state to Firebase
    ref.read(syncNotifierProvider.notifier).executeFullSync();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note restored.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashState = ref.watch(trashNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          trashState.maybeWhen(
            data: (notes) => notes.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Empty Trash',
              onPressed: () => _handleEmptyTrash(context, ref),
            )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: trashState.when(
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

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              // Wrapping in Dismissible allows users to swipe to permanently delete individual notes
              return Dismissible(
                key: ValueKey(note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // Individual hard delete logic could go here if you want it
                  // For now, we'll just return false to prevent accidental swipes
                  return false;
                },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // CRITICAL: Prevents layout crashes
                        children: [

                          // Show the platform icon if we have the data
                          if (note.deletedPlatform != null)
                            Tooltip(
                              message: 'Deleted on ${note.deletedPlatform}',
                              child: Icon(
                                _getPlatformIcon(note.deletedPlatform),
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),

                          IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: 'Restore',
                            onPressed: () => _restoreNote(context, ref, note.id),
                          ),
                        ],
                      ),
                    ),
                  )
              );
            },
          );
        },
      ),
    );
  }


  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android':
        return Icons.phone_android_outlined;
      case 'ios':
        return Icons.phone_iphone_outlined;
      case 'windows':
        return Icons.desktop_windows_outlined;
      case 'macos':
        return Icons.desktop_mac_outlined;
      case 'web':
        return Icons.language_outlined;
      default:
        return Icons.device_unknown_outlined; // Fallback for null or unknown
    }
  }
}