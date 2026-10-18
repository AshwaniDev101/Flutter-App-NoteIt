import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/device_info.dart';

import '../../../core/util/platform_helper.dart';
import '../../../../database/drift/local_database.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../features/folders/core/providers.dart';
import '../view_menu_button.dart';
import 'core/note_action_controller.dart';
import 'note_card.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/home/viewmodel/viewmodel.dart';

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

    // WATCH THE ACTIVE FOLDER
    final activeFolder = ref.watch(activeFolderProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return notesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (notes) {
        if (notes.isEmpty) {
          return _emptyNotePlaceholder(colorScheme, textTheme, activeFolder: activeFolder);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.read(syncOrchestratorProvider).triggerSync(),
          child: _buildAdaptiveLayout(notes, viewType, ref),
        );
      },
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
        onLongPress: () {
          if (!isSelectMode) {
            onEnableSelectMode();
            onToggleSelection(currentNote.uuid);
          }
        },

        onContextMenuAction: (option) {
          if (option == NoteContextMenuOption.select) {
            if (!isSelectMode) onEnableSelectMode();
            if (!isCurrentlySelected) {
              onToggleSelection(currentNote.uuid);
            }
            return;
          }

          if (isCurrentlySelected) {
            _handleBatchAction(ref, option, noteIds.toList());
          }
          else {
            _handleBatchAction(ref, option, [currentNote.uuid]);
          }
        },
      );
    }

    const physics = AlwaysScrollableScrollPhysics();
    const padding = EdgeInsets.only(bottom: 0);

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

  void _handleBatchAction(WidgetRef ref, NoteContextMenuOption option, List<String> targetUuids) async {
    ref.read(homeViewModelProvider.notifier).clearSelection();
    final actionsController = ref.read(noteActionsControllerProvider);
    final deviceInfo = await ref.read(deviceInfoProvider.future);
    final String platform = deviceInfo.extractPlatform;

    switch (option) {
      case NoteContextMenuOption.select:
        throw AssertionError('Select action should be intercepted before reaching here.');
      case NoteContextMenuOption.delete:
        await actionsController.deleteNotes(targetUuids, platform);
        break;
      case NoteContextMenuOption.pin:
        await actionsController.pinNotes(targetUuids);
        break;
      case NoteContextMenuOption.unpin:
        await actionsController.unpinNotes(targetUuids);
        break;
      case NoteContextMenuOption.archive:
        await actionsController.archiveNotes(targetUuids);
        break;
      case NoteContextMenuOption.lock:
        await actionsController.lockNotes(targetUuids);
        break;
      case NoteContextMenuOption.duplicate:
        await actionsController.duplicateNotes(targetUuids, platform);
        break;
      case NoteContextMenuOption.moveTo:
        break;
      case NoteContextMenuOption.reminder:
        break;
      case NoteContextMenuOption.openNewWindow:
        break;
      case NoteContextMenuOption.unarchive:
        await actionsController.unarchiveNotes(targetUuids);
        break;
      case NoteContextMenuOption.restore:
        await actionsController.restoreNotes(targetUuids);
        break;
      case NoteContextMenuOption.deleteForever:
        await actionsController.deleteForever(targetUuids);
        break;
    }
  }

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

  // Empty note placeholder
  Widget _emptyNotePlaceholder(ColorScheme colorScheme, TextTheme textTheme, {Folder? activeFolder}) {
    final isFolderSelected = activeFolder != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFolderSelected ? Icons.folder_open_outlined : Icons.note_alt_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),

            if (isFolderSelected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "No notes in ",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // The "Folder selector like" Container for the folder
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.primaries[activeFolder.colorIndex % Colors.primaries.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              activeFolder.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                "No notes found",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              isFolderSelected
                  ? "Press + to add a note to this folder."
                  : "Create your first note to get started.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}