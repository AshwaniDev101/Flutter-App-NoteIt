import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/shared/tag_sort_view_menu.dart';
import '../../../../../database/drift/local_database.dart';
import '../../../../../../database/sync/sync_orchestrator.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../../shared/widgets/note_card/note_card.dart';
import '../../core/providers.dart';

class DynamicNotesLayout extends ConsumerWidget {
  final bool isSelectMode;
  final Set<String> noteIds;
  final String? activeNoteId;
  final Function(String) onToggleSelection;
  final Function() onEnableSelectMode;
  final void Function(Note) onNoteTap;

  const DynamicNotesLayout({
    super.key,
    required this.isSelectMode,
    required this.noteIds,
    this.activeNoteId,
    required this.onToggleSelection,
    required this.onEnableSelectMode,
    required this.onNoteTap,
  });

  Widget _buildNoteItem(BuildContext context, WidgetRef ref, Note currentNote) {
    final isSelected = noteIds.contains(currentNote.uuid);
    final isActive = currentNote.uuid == activeNoteId;

    return NoteCard(
      note: currentNote,
      key: ValueKey(currentNote.uuid),
      // Tell the card to light up if it's selected OR if it's the active note being edited
      isSelected: isSelected || isActive,
      searchQuery: ref.read(searchQueryProvider),
      onTap: () async {
        if (isSelectMode) {
          onToggleSelection(currentNote.uuid);
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
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteItem(context, ref, notes[index]),
        );

      case NoteViewType.grid:
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, left: 4, right: 4),

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
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteItem(context, ref, notes[index]),
        );

      case NoteViewType.largeGrid:
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80, left: 4, right: 4),
          gridDelegate: PlatformHelper.isMobileScreen
              ? const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, // Full width on mobile
            mainAxisExtent: 160,
            mainAxisSpacing: 0,
          )
              : const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 200,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteItem(context, ref, notes[index]),
        );
    }
  }
}
