
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/routing.dart';
import '../../../../../database/drift/drift_database.dart';
import '../../../../../database/sync_manager.dart';
import '../../../../../shared/widgets/note_card.dart';
import '../../core/providers.dart';

class NotesGridView extends ConsumerWidget {
  final bool isSelectMode;
  final Set<int> noteIds;
  final Function(int) onToggleSelection;
  final Function() onEnableSelectMode;
  final Future<void> Function(BuildContext, Note) onPromptPassword;

  const NotesGridView({
    super.key,
    required this.isSelectMode,
    required this.noteIds,
    required this.onToggleSelection,
    required this.onEnableSelectMode,
    required this.onPromptPassword,
  });

  Future<void> _deleteNote(WidgetRef ref, int id) async {
    final driftDatabase = ref.read(noteDriftDatabaseProvider);
    await driftDatabase.softDeleteNotes({id}, platform: defaultTargetPlatform.name);
    ref.read(syncNotifierProvider.notifier).executeFullSync();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: notesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncNotifierProvider.notifier).executeFullSync();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85)
                  : const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.85),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final currentNote = notes[index];
                final isSelected = noteIds.contains(currentNote.id);
                final displayAsLocked = currentNote.isLocked;

                return NoteCard(
                  note: currentNote,
                  isSelected: isSelected,
                  searchQuery: ref.read(searchQueryProvider),
                  onTap: () async {
                    if (isSelectMode) {
                      onToggleSelection(currentNote.id);
                    } else if (displayAsLocked) {
                      await onPromptPassword(context, currentNote);
                    } else {
                      await context.push(AppRoutes.edit, extra: currentNote);
                    }
                  },
                  onLongPress: () {
                    if (!isSelectMode) {
                      onEnableSelectMode();
                      onToggleSelection(currentNote.id);
                    }
                  },
                  hoverActions: [
                    IconButton(
                      icon: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (!isSelectMode) onEnableSelectMode();
                        onToggleSelection(currentNote.id);
                      },
                    ),

                    if (!isSelectMode) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteNote(ref, currentNote.id),
                      ),

                      // Note is completely UNLOCKED -> Option to permanently lock it
                      // if (!currentNote.isLocked)
                      //   IconButton(
                      //     icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
                      //     visualDensity: VisualDensity.compact,
                      //     tooltip: 'Lock Note',
                      //     onPressed: () async {
                      //       final lockManager = ref.read(lockManagerProvider.notifier);
                      //       if (!lockManager.hasMasterPassword) {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //             const SnackBar(content: Text('Tap the note to set a Master Password first!'))
                      //         );
                      //         return;
                      //       }
                      //       final driftDatabase = ref.read(noteDriftDatabaseProvider);
                      //       await driftDatabase.lockNote(currentNote.id, isLocked: true);
                      //       ref.read(syncNotifierProvider.notifier).executeFullSync();
                      //     },
                      //   ),

                      // If Note is LOCKED, but UNLOCKED FOR SESSION -> Option to lock it immediately
                      // if (currentNote.isLocked && isSessionUnlocked)
                      //   IconButton(
                      //     icon: const Icon(Icons.lock_open_rounded, size: 18, color: Colors.green),
                      //     visualDensity: VisualDensity.compact,
                      //     tooltip: 'Lock instantly',
                      //     onPressed: () {
                      //       // Assuming your lock manager has a method to remove from the session list
                      //       ref.read(lockManagerProvider.notifier).lockSessionNote(currentNote.id);
                      //     },
                      //   ),

                      //  Note is LOCKED and LOCKED FOR SESSION -> Option to unlock directly from hover
                      // if (currentNote.isLocked && !isSessionUnlocked)
                      //   IconButton(
                      //     icon: const Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
                      //     visualDensity: VisualDensity.compact,
                      //     tooltip: 'Unlock',
                      //     onPressed: () => onPromptPassword(context, currentNote),
                      //   ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
