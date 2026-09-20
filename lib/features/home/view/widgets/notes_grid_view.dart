import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/drift/drift_database.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../../../../shared/widgets/note_card.dart';
import '../../core/providers.dart';

class NotesGridView extends ConsumerWidget {
  final bool isSelectMode;
  final Set<String> noteIds;
  final String? activeNoteId;
  final Function(String) onToggleSelection;
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

  Future<void> _deleteNote(WidgetRef ref, String uuid) async {
    final driftDatabase = ref.read(noteDriftDatabaseProvider);
    await driftDatabase.softDeleteNotes({uuid}, platform: defaultTargetPlatform.name);

    ref.read(syncOrchestratorProvider).triggerSync();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: notesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(syncOrchestratorProvider).triggerSync();
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

                final isSelected = noteIds.contains(currentNote.uuid);
                final isActive = currentNote.uuid == activeNoteId;
                final displayAsLocked = currentNote.isLocked;

                final noteCard = NoteCard(
                  note: currentNote,
                  isSelected: isSelected,
                  searchQuery: ref.read(searchQueryProvider),
                  onTap: () async {
                    if (isSelectMode) {
                      onToggleSelection(currentNote.uuid);
                    } else if (displayAsLocked) {
                      await onPromptPassword(context, currentNote);
                    } else {
                      onNoteTap(currentNote);
                    }
                  },
                  onLongPress: () {
                    if (!isSelectMode) {
                      onEnableSelectMode();
                      onToggleSelection(currentNote.uuid);
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
                        onToggleSelection(currentNote.uuid);
                      },
                    ),
                    if (!isSelectMode) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteNote(ref, currentNote.uuid),
                      ),
                    ],
                  ],
                );

                if (isActive && !isSelectMode) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary, width: 2.5),
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
