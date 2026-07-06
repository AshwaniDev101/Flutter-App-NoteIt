import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust these imports to match your actual project structure
import '../../core/theme/note_theme.dart';
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emptying trash...')));

        // 1. Delete locally and get the orphaned Firebase IDs
        final cloudIdsToDelete = await driftDb.emptyLocalTrash();

        // 2. If online and logged in, delete from Firebase
        if (firebaseDb != null && cloudIdsToDelete.isNotEmpty) {
          await firebaseDb.deleteBatch(cloudIdsToDelete);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied successfully.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error emptying trash: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note restored.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashState = ref.watch(trashNotesProvider);

    final noteTheme = Theme.of(context).extension<NoteTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey,
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
              // EXACT SAME RESPONSIVE GRID DELEGATE FROM HOMEPAGE
              gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85)
                  : const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.85),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];

                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                  ),
                  confirmDismiss: (direction) async {
                    // Prevent accidental swipe deletes for now
                    return false;
                  },
                  child: Card(
                    elevation: 0, // Matches your unselected homepage card
                    color: noteTheme.cardContentBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // TITLE HEADER (Matches Homepage exactly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: noteTheme.cardTitleBackground ?? colorScheme.surfaceContainerHigh,
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      note.title.isEmpty ? "Untitled" : note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: noteTheme.cardTitleForeground ?? colorScheme.onSurface,
                                      ),
                                    ),

                                    Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.restore),
                                      tooltip: 'Restore',
                                      constraints: const BoxConstraints(),
                                      // Removes default massive padding
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _restoreNote(context, ref, note.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // CONTENT AREA
                          Expanded(
                            child: Stack(
                              children: [
                                Padding(
                                  // Added right padding so text doesn't flow under the restore button
                                  padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 32.0, bottom: 12.0),
                                  child: Text(
                                    note.content,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: noteTheme.cardContentForeground ?? colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),

                                // PLATFORM ICON (Bottom Right)
                                if (note.deletedPlatform != null)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Tooltip(
                                      message: 'Deleted on ${note.deletedPlatform}',
                                      child: Icon(
                                        _getPlatformIcon(note.deletedPlatform),
                                        size: 14, // Scaled down to match homepage size
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
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
