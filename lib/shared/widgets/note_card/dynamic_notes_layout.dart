import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/platform_helper.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import 'core/note_action_controller.dart';
import 'note_card.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/home/viewmodel/viewmodel.dart';
import '../../../features/home/view/shared/tag_sort_view_menu.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(filteredNotesProvider);
    final viewType = ref.watch(noteViewTypeProvider);

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
            child: _buildAdaptiveLayout(notes, viewType, ref),
          );
        },
      ),
    );
  }

  Widget _buildAdaptiveLayout(List<Note> notes, NoteViewType viewType, WidgetRef ref) {
    Widget itemBuilder(BuildContext context, int index) {
      final currentNote = notes[index];
      final isCurrentlySelected = noteIds.contains(currentNote.uuid);
      return NoteCard(
        note: currentNote,
        key: ValueKey(currentNote.uuid),
        isSelected: noteIds.contains(currentNote.uuid) || currentNote.uuid == activeNoteId,
        searchQuery: ref.read(searchQueryProvider),

        onTap: () {
          // Native Desktop UX: Check if Ctrl (Windows) or Cmd (Mac) is held down
          final isModifierPressed = HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          if (isSelectMode || isModifierPressed) {
            if (!isSelectMode) onEnableSelectMode();
            onToggleSelection(currentNote.uuid);
          } else {
            onNoteTap(currentNote);
          }
        },
        // onTap: () {
        //   if (isSelectMode) {
        //     onToggleSelection(currentNote.uuid);
        //   } else {
        //     onNoteTap(currentNote);
        //   }
        // },
        onLongPress: () {
          if (!isSelectMode) {
            onEnableSelectMode();
            onToggleSelection(currentNote.uuid);
          }
        },

        onContextMenuAction: (option) {
          //  INTERCEPT THE 'SELECT' UI ACTION
          if (option == NoteContextMenuOption.select) {
            if (!isSelectMode) onEnableSelectMode();

            // Only toggle it if it isn't already selected
            if (!isCurrentlySelected) {
              onToggleSelection(currentNote.uuid);
            }
            return; // Stop here, don't send to DB controller
          }

          // ROUTE TO DATABASE CONTROLLER
          // SCENARIO B: Already selected, apply to whole batch
          if (isCurrentlySelected) {
            _handleBatchAction(ref, option, noteIds.toList());
          }
          // SCENARIO A: Not selected, apply to this note only
          else {
            _handleBatchAction(ref, option, [currentNote.uuid]);
          }
        },
      );
    }


    // Shared Settings
    const physics = AlwaysScrollableScrollPhysics();
    const padding = EdgeInsets.only(bottom: 100); // Unified bottom clearance

    // Adaptive Return
    if (viewType == NoteViewType.list || viewType == NoteViewType.detailedList) {
      return ListView.builder(
        physics: physics,
        padding: padding,
        itemCount: notes.length,
        itemBuilder: itemBuilder,
      );
    }

    return GridView.builder(
      physics: physics,
      padding: padding,
      itemCount: notes.length,
      gridDelegate: _getGridDelegate(viewType),
      itemBuilder: itemBuilder,
    );
  }


  void _handleBatchAction(WidgetRef ref, NoteContextMenuOption option, List<String> targetUuids) {
    // Read our new action controller
    final actionsController = ref.read(noteActionsControllerProvider);

    switch (option) {

      case NoteContextMenuOption.select:
      // Unreachable: Handled upstream
      throw AssertionError();
      case NoteContextMenuOption.delete:
        actionsController.deleteNotes(targetUuids);
        break;
      case NoteContextMenuOption.pin:
        actionsController.togglePinNotes(targetUuids);
        break;
      case NoteContextMenuOption.archive:
        actionsController.archiveNotes(targetUuids);
        break;
      case NoteContextMenuOption.lock:
        actionsController.lockNotes(targetUuids);
        break;
      case NoteContextMenuOption.duplicate:
        actionsController.duplicateNotes(targetUuids);
        break;
      case NoteContextMenuOption.moveTo:
      // E.g. Open a dialog to select a folder, then call actionsController.moveNotes(targetUuids, newFolderId)
        break;
      case NoteContextMenuOption.reminder:
      // E.g. Open a date/time picker
        break;
      case NoteContextMenuOption.openNewWindow:
      // E.g. Send to window_manager API
        break;

    }
  }

  // Clean Delegate Extraction
  SliverGridDelegate _getGridDelegate(NoteViewType viewType) {
    final isMobile = PlatformHelper.isMobileScreen;

    if (viewType == NoteViewType.grid) {
      return isMobile
          ? const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
      )
          : const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.85,
      );
    }

    // largeGrid fallback
    return isMobile
        ? const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 1,
      mainAxisExtent: 160,
    )
        : const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 400,
      mainAxisExtent: 200,
    );
  }
}