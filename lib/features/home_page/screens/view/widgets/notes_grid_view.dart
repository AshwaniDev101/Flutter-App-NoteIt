import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/drift/drift_database.dart';
import '../../../../../database/sync_manager.dart';
import '../../../../../shared/widgets/note_card.dart';
import '../../core/providers.dart';

class NotesGridView extends ConsumerWidget {
  final bool isSelectMode;
  final Set<int> noteIds;
  final int? activeNoteId; // Added to identify the active note
  final Function(int) onToggleSelection;
  final Function() onEnableSelectMode;
  final Future<void> Function(BuildContext, Note) onPromptPassword;
  final void Function(Note) onNoteTap;

  const NotesGridView({
    super.key,
    required this.isSelectMode,
    required this.noteIds,
    this.activeNoteId,
    required this.onToggleSelection,
    required this.onEnableSelectMode,
    required this.onPromptPassword,
    required this.onNoteTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, childAspectRatio: 0.85)
                  : const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.85),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final currentNote = notes[index];
                final isSelected = noteIds.contains(currentNote.id);
                final isActive = currentNote.id == activeNoteId;
                final displayAsLocked = currentNote.isLocked;

                final noteCard = NoteCard(
                  note: currentNote,
                  isSelected: isSelected,
                  searchQuery: ref.read(searchQueryProvider),
                  onTap: () async {
                    if (isSelectMode) {
                      onToggleSelection(currentNote.id);
                    } else if (displayAsLocked) {
                      await onPromptPassword(context, currentNote);
                    } else {
                      onNoteTap(currentNote);
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
                    ],
                  ],
                );

                // If this note is currently open in the right-side editor, wrap it in a highlight border
                if (isActive && !isSelectMode) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2.5,
                      ),
                    ),
                    child: noteCard,
                  );
                }

                return noteCard;
              },
            ),
          );
        },
      ),
    );
  }
}