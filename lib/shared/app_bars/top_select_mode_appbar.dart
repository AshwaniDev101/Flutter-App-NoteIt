import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/shared/core/note_action.dart';
import '../../core/util/platform_helper.dart';
import '../core/note_action_controller.dart';
import '../../features/lock/lock_manger/lock_manager.dart';
import '../../features/lock/password_prompt_helper.dart';
import '../../features/home/core/providers.dart';

import '../../features/home/viewmodel/viewmodel.dart';

/// App Bar displayed when selection mode is active on Home screens.
///
/// Features:
/// - Displays count of currently selected notes.
/// - Provides "Select All" / "Deselect All" button (defaults to toggling all filtered notes).
/// - Provides "Delete Selected" batch action button.
/// - Optional [onClearSelection] and [onSelectAll] overrides.
class TopSelectModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int? selectedCount;
  final VoidCallback? onClearSelection;
  final VoidCallback? onSelectAll;
  final List<NoteAction> noteActions;
  final void Function(NoteAction)? onActionSelected;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const TopSelectModeAppBar({
    super.key,
    this.selectedCount,
    this.onClearSelection,
    this.onSelectAll,
    this.noteActions = const [],
    this.onActionSelected,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _dispatchAction(BuildContext context, WidgetRef ref, NoteAction action) async {
    if (onActionSelected != null) {
      onActionSelected!(action);
      return;
    }

    final targetUuids = ref.read(homeViewModelProvider).selectedNoteIds.toList();
    if (targetUuids.isEmpty) return;

    final actionsController = ref.read(noteActionsControllerProvider);
    final platform = PlatformHelper.name;

    switch (action) {
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
      case NoteAction.unarchive:
        await actionsController.unarchiveNotes(targetUuids);
        break;
      case NoteAction.lock:
        final lockNotifier = ref.read(lockManagerProvider.notifier);
        if (!lockNotifier.hasMasterPassword) {
          await PasswordPromptHelper.showMasterPasswordManagement(context, ref);
        }
        if (ref.read(lockManagerProvider.notifier).hasMasterPassword) {
          await actionsController.lockNotes(targetUuids);
        }
        break;
      case NoteAction.duplicate:
        await actionsController.duplicateNotes(targetUuids, platform);
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

    onClearSelection?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBgColor = backgroundColor ?? colorScheme.secondaryContainer;
    final effectiveFgColor = foregroundColor ?? colorScheme.onSecondaryContainer;

    final viewModel = ref.read(homeViewModelProvider.notifier);
    final currentNotes = ref.watch(filteredNotesProvider).value ?? [];

    final effectiveSelectedCount =
        selectedCount ?? ref.watch(homeViewModelProvider).selectedNoteIds.length;

    final isAllSelected = currentNotes.isNotEmpty && effectiveSelectedCount == currentNotes.length;

    // Use passed handlers or default to HomeViewModel Riverpod actions
    final handleClearSelection = onClearSelection ?? viewModel.clearSelection;
    final handleSelectAll = onSelectAll ??
            () {
          final allNoteUuids = currentNotes.map((noteWithFolder) => noteWithFolder.note.uuid).toList();
          viewModel.toggleSelectAll(allNoteUuids);
        };

    // Rule: <=3 options -> show all inline; >3 options -> show first 2 inline, rest in more_vert menu
    final List<NoteAction> inlineActions;
    final List<NoteAction> overflowActions;

    if (noteActions.length <= 3) {
      inlineActions = noteActions;
      overflowActions = const [];
    } else {
      inlineActions = noteActions.take(2).toList();
      overflowActions = noteActions.skip(2).toList();
    }

    return AppBar(
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveFgColor,
      iconTheme: IconThemeData(color: effectiveFgColor),
      actionsIconTheme: IconThemeData(color: effectiveFgColor),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: handleClearSelection,
        tooltip: 'Close selection',
        color: effectiveFgColor,
      ),
      title: Text(
        '$effectiveSelectedCount',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: effectiveFgColor,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: effectiveFgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: handleSelectAll,
            child: Text(
              isAllSelected ? 'Deselect All' : 'Select All',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: effectiveFgColor,
              ),
            ),
          ),
        ),
        ...inlineActions.map((action) {
          final color = action.isDestructive ? colorScheme.error : effectiveFgColor;
          return IconButton(
            icon: Icon(action.icon, color: color),
            tooltip: action.label,
            onPressed: () => _dispatchAction(context, ref, action),
          );
        }),
        if (overflowActions.isNotEmpty)
          PopupMenuButton<NoteAction>(
            onSelected: (action) => _dispatchAction(context, ref, action),
            icon: Icon(Icons.more_vert, color: effectiveFgColor),
            itemBuilder: (BuildContext context) {
              return overflowActions.map((action) {
                final color = action.isDestructive ? colorScheme.error : null;
                return PopupMenuItem<NoteAction>(
                  value: action,
                  child: Row(
                    children: [
                      Icon(action.icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        action.label,
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
      ],
    );
  }
}