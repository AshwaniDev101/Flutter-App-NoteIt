import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import '../../../core/util/platform_helper.dart';
import '../../../../../database/sync/sync_orchestrator.dart';
import '../../features/folders/core/providers.dart';
import '../menus/view_menu_button.dart';
import 'core/note_action.dart';
import 'core/note_action_controller.dart';
import 'note_card.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/home/viewmodel/viewmodel.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
import '../../../features/lock/password_prompt_helper.dart';

class DynamicNotesLayout extends ConsumerWidget {
  final bool isSelectMode;
  final Set<String> noteIds;
  final String? activeNoteId;
  final Function(String) onToggleSelection;
  final Function() onEnableSelectMode;
  final void Function(NoteWithFolder) onNoteTap;

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
    final viewType = ref.watch(homeNoteViewTypeProvider);

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

  Widget _buildAdaptiveLayout(List<NoteWithFolder> notesWithFolder, NoteViewType viewType, WidgetRef ref) {
    final pinnedNotes = notesWithFolder.where((n) => n.note.pinnedAt != null).toList();
    final otherNotes = notesWithFolder.where((n) => n.note.pinnedAt == null).toList();

    const physics = AlwaysScrollableScrollPhysics();
    const padding = EdgeInsets.only(bottom: 0);

    // If no pinned notes, render standard unsectioned list/grid
    if (pinnedNotes.isEmpty) {
      if (viewType == NoteViewType.list || viewType == NoteViewType.detailedList) {
        return ListView.builder(
          physics: physics,
          padding: padding,
          itemCount: notesWithFolder.length,
          itemBuilder: (context, index) => _buildNoteCard(context, ref, notesWithFolder[index], viewType),
        );
      }

      return GridView.builder(
        physics: physics,
        padding: padding,
        itemCount: notesWithFolder.length,
        gridDelegate: _getGridDelegate(viewType),
        itemBuilder: (context, index) => _buildNoteCard(context, ref, notesWithFolder[index], viewType),
      );
    }

    // Sectioned CustomScrollView when pinned notes exist
    final isListView = viewType == NoteViewType.list || viewType == NoteViewType.detailedList;

    return CustomScrollView(
      physics: physics,
      slivers: [
        // PINNED SECTION HEADER
        SliverToBoxAdapter(
          child: _buildSectionHeader(ref.context, 'Pinned'),
        ),

        // PINNED NOTES
        if (isListView)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNoteCard(context, ref, pinnedNotes[index], viewType),
              childCount: pinnedNotes.length,
            ),
          )
        else
          SliverGrid(
            gridDelegate: _getGridDelegate(viewType),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNoteCard(context, ref, pinnedNotes[index], viewType),
              childCount: pinnedNotes.length,
            ),
          ),

        // ALL NOTES SECTION HEADER & ITEMS
        if (otherNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(ref.context, 'Others'),
          ),

          if (isListView)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNoteCard(context, ref, otherNotes[index], viewType),
                childCount: otherNotes.length,
              ),
            )
          else
            SliverGrid(
              gridDelegate: _getGridDelegate(viewType),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNoteCard(context, ref, otherNotes[index], viewType),
                childCount: otherNotes.length,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 6.0, right: 4.0),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, NoteWithFolder currentNoteWithFolder, NoteViewType viewType) {
    final isCurrentlySelected = noteIds.contains(currentNoteWithFolder.note.uuid);
    return NoteCard(
      noteWithFolder: currentNoteWithFolder,
      viewType: viewType,
      key: ValueKey(currentNoteWithFolder.note.uuid),
      isSelected: isCurrentlySelected || currentNoteWithFolder.note.uuid == activeNoteId,
      searchQuery: ref.read(searchQueryProvider),

      onTap: () {
        // Native Desktop UX: Check if Ctrl (Windows) or Cmd (Mac) is held down
        final isModifierPressed = HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed;

        if (isSelectMode || isModifierPressed) {
          if (!isSelectMode) onEnableSelectMode();
          onToggleSelection(currentNoteWithFolder.note.uuid);
        } else {
          onNoteTap(currentNoteWithFolder);
        }
      },
      onLongPress: () {
        if (!isSelectMode) {
          onEnableSelectMode();
          onToggleSelection(currentNoteWithFolder.note.uuid);
        }
      },

      onContextMenuAction: (option) {
        if (option == NoteAction.select) {
          if (!isSelectMode) onEnableSelectMode();
          if (!isCurrentlySelected) {
            onToggleSelection(currentNoteWithFolder.note.uuid);
          }
          return;
        }

        if (isCurrentlySelected) {
          _handleBatchAction(context, ref, option, noteIds.toList());
        } else {
          _handleBatchAction(context, ref, option, [currentNoteWithFolder.note.uuid]);
        }
      },
    );
  }

  void _handleBatchAction(BuildContext context, WidgetRef ref, NoteAction option, List<String> targetUuids) async {
    ref.read(homeViewModelProvider.notifier).clearSelection();
    final actionsController = ref.read(noteActionsControllerProvider);
    final deviceInfo = await ref.read(deviceInfoProvider.future);
    final String platform = deviceInfo.extractPlatform;

    switch (option) {
      case NoteAction.select:
        throw AssertionError('Select action should be intercepted before reaching here.');
      case NoteAction.delete:
        await actionsController.deleteNotes(targetUuids, platform);
        break;
      case NoteAction.pin:
        await actionsController.pinNotes(targetUuids);
        break;
      case NoteAction.unpin:
        await actionsController.unpinNotes(targetUuids);
        break;
      case NoteAction.archive:
        await actionsController.archiveNotes(targetUuids);
        break;
      case NoteAction.lock:
        final lockNotifier = ref.read(lockManagerProvider.notifier);

        if (!lockNotifier.hasMasterPassword) {
          if (!context.mounted) return;
          await PasswordPromptHelper.showMasterPasswordManagement(context, ref);
        }
        if (ref.read(lockManagerProvider.notifier).hasMasterPassword) {
          await actionsController.lockNotes(targetUuids);
        }
        break;
      case NoteAction.duplicate:
        await actionsController.duplicateNotes(targetUuids, platform);
        break;
      case NoteAction.moveTo:
        break;
      case NoteAction.reminder:
        break;
      case NoteAction.openNewWindow:
        break;
      case NoteAction.unarchive:
        await actionsController.unarchiveNotes(targetUuids);
        break;
      case NoteAction.restore:
        await actionsController.restoreNotes(targetUuids);
        break;
      case NoteAction.deleteForever:
        await actionsController.deleteForever(targetUuids);
        break;
      default:
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