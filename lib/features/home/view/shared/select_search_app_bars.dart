import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/shared/core/note_action.dart';
import '../../../../core/util/platform_helper.dart';
import '../../../../shared/app_search_bar.dart';
import '../../../../shared/core/note_action_controller.dart';
import '../../../lock/lock_manger/lock_manager.dart';
import '../../../lock/password_prompt_helper.dart';
import '../../core/providers.dart';

import '../../viewmodel/viewmodel.dart';

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
      // backgroundColor: colorScheme.surfaceContainerLow,
      // foregroundColor: colorScheme.onSurface,

      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: handleClearSelection,
        tooltip: 'Close selection',
      ),
      title: Text(
        '$effectiveSelectedCount',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: handleSelectAll,
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
        ),
        ...inlineActions.map((action) {
          final color = action.isDestructive ? colorScheme.error : null;
          return IconButton(
            icon: Icon(action.icon, color: color),
            tooltip: action.label,
            onPressed: () => _dispatchAction(context, ref, action),
          );
        }),
        if (overflowActions.isNotEmpty)
          PopupMenuButton<NoteAction>(
            onSelected: (action) => _dispatchAction(context, ref, action),
            icon: const Icon(Icons.more_vert),
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

class BottomSelectModeAppBar extends ConsumerWidget {
  final List<NoteAction> noteActions;
  final bool isMultiSelect;
  final Function(NoteAction)? onActionSelected;

  static const List<NoteAction> defaultActions = [
    NoteAction.pin,
    NoteAction.archive,
    NoteAction.delete,
    NoteAction.lock,
    NoteAction.moveTo,
    NoteAction.reminder,
    NoteAction.duplicate,
  ];

  const BottomSelectModeAppBar({
    super.key,
    this.noteActions = defaultActions,
    this.isMultiSelect = false,
    this.onActionSelected,
  });

  void _handleAction(BuildContext context, WidgetRef ref, NoteAction action) async {
    if (onActionSelected != null) {
      onActionSelected!(action);
      return;
    }

    final selectedNoteIds = ref.read(homeViewModelProvider).selectedNoteIds.toList();
    if (selectedNoteIds.isEmpty) return;

    final actionsController = ref.read(noteActionsControllerProvider);
    final platform = PlatformHelper.name;

    switch (action) {
      case NoteAction.delete:
        await actionsController.deleteNotes(selectedNoteIds, platform);
        break;
      case NoteAction.pin:
        await actionsController.pinNotes(selectedNoteIds);
        break;
      case NoteAction.unpin:
        await actionsController.unpinNotes(selectedNoteIds);
        break;
      case NoteAction.archive:
        await actionsController.archiveNotes(selectedNoteIds);
        break;
      case NoteAction.unarchive:
        await actionsController.unarchiveNotes(selectedNoteIds);
        break;
      case NoteAction.lock:
        final lockNotifier = ref.read(lockManagerProvider.notifier);
        if (!lockNotifier.hasMasterPassword) {
          await PasswordPromptHelper.showMasterPasswordManagement(context, ref);
        }
        if (ref.read(lockManagerProvider.notifier).hasMasterPassword) {
          await actionsController.lockNotes(selectedNoteIds);
        }
        break;
      case NoteAction.duplicate:
        await actionsController.duplicateNotes(selectedNoteIds, platform);
        break;
      case NoteAction.restore:
        await actionsController.restoreNotes(selectedNoteIds);
        break;
      case NoteAction.deleteForever:
        await actionsController.deleteForever(selectedNoteIds);
        break;
      default:
        break;
    }

    ref.read(homeViewModelProvider.notifier).clearSelection();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    final firstFour = noteActions.take(4).toList();
    final remainingActions = noteActions.skip(4).toList();

    return BottomAppBar(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...firstFour.map((action) {
            final color = action.isDestructive ? errorColor : null;
            return _buildActionItem(
              icon: action.icon,
              label: action.label,
              color: color,
              onPressed: () => _handleAction(context, ref, action),
            );
          }),
          if (remainingActions.isNotEmpty)
            PopupMenuButton<NoteAction>(
              onSelected: (action) => _handleAction(context, ref, action),
              itemBuilder: (BuildContext context) {
                return remainingActions.map((action) {
                  final color = action.isDestructive ? errorColor : null;
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
              child: _buildActionItem(
                icon: Icons.more_vert,
                label: 'More',
                onPressed: null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28.0,
              color: color,
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// App Bar displayed when search mode is active.
class SearchModeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onExitSearchMode;

  const SearchModeAppBar({super.key, required this.searchController, required this.onExitSearchMode});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onExitSearchMode),
      title: AppSearchBar.appBar(
        controller: searchController,
        hintText: 'Search notes...',
        autofocus: true,
        onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
        onClear: () => ref.read(searchQueryProvider.notifier).clear(),
      ),
    );
  }
}
