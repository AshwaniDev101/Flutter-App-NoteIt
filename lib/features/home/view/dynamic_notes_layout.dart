import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../../../../shared/widgets/note_card.dart';
import '../core/providers.dart';
import '../note_view.dart';

class DynamicNotesLayout extends ConsumerWidget {
  final bool isSelectMode;
  final Set<String> noteIds;
  final String? activeNoteId;
  final Function(String) onToggleSelection;
  final Function() onEnableSelectMode;
  final Future<void> Function(BuildContext, Note) onPromptPassword;
  final void Function(Note) onNoteTap;

  const DynamicNotesLayout({
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
    final notesDao = ref.read(notesDaoProvider);
    await notesDao.softDeleteNotes({uuid}, platform: defaultTargetPlatform.name);
    ref.read(syncOrchestratorProvider).triggerSync();
  }

  Widget _buildNoteItem(BuildContext context, WidgetRef ref, Note currentNote) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = noteIds.contains(currentNote.uuid);
    final isActive = currentNote.uuid == activeNoteId;
    final displayAsLocked = currentNote.isLocked;

    return NoteCard(
      note: currentNote,
      // Tell the card to light up if it's selected OR if it's the active note being edited
      isSelected: isSelected || isActive,
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
      // hoverActions: [
      //   IconButton(
      //     icon: Icon(
      //       isSelected ? Icons.check_circle : Icons.radio_button_unchecked_rounded,
      //       size: 18,
      //       color: colorScheme.primary,
      //     ),
      //     visualDensity: VisualDensity.compact,
      //     onPressed: () {
      //       if (!isSelectMode) onEnableSelectMode();
      //       onToggleSelection(currentNote.uuid);
      //     },
      //   ),
      //   if (!isSelectMode) ...[
      //     IconButton(
      //       icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
      //       visualDensity: VisualDensity.compact,
      //       onPressed: () => _deleteNote(ref, currentNote.uuid),
      //     ),
      //   ],
      // ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);
    final viewType = ref.watch(noteViewTypeProvider); // Listen to the view switcher

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
            onRefresh: () async => ref.read(syncOrchestratorProvider).triggerSync(),
            child: _buildLayout(context, ref, notes, viewType),
          );
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, WidgetRef ref, List<Note> notes, NoteViewType viewType) {
    switch (viewType) {
      case NoteViewType.list:
      case NoteViewType.detailedList:
      // Use ListView for list layouts
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          // padding: const EdgeInsets.only(bottom: 80),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteItem(context, ref, notes[index]),
        );

      case NoteViewType.grid:
      case NoteViewType.largeGrid:
      // Adjust the crossAxisCount based on standard vs large grid
        final isLargeGrid = viewType == NoteViewType.largeGrid;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          gridDelegate: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
              ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLargeGrid ? 1 : 3, // Android dynamic columns
            childAspectRatio: isLargeGrid ? 2.0 : 0.85,
          )
              : SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isLargeGrid ? 400 : 220, // Desktop dynamic size
            childAspectRatio: isLargeGrid ? 1.5 : 0.85,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteItem(context, ref, notes[index]),
        );
    }
  }
}