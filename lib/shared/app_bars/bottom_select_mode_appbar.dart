import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/shared/core/note_action.dart';
import '../../core/util/platform_helper.dart';
import '../app_search_bar.dart';
import '../core/note_action_controller.dart';
import '../../features/lock/lock_manger/lock_manager.dart';
import '../../features/lock/password_prompt_helper.dart';
import '../../features/home/core/providers.dart';

import '../../features/home/viewmodel/viewmodel.dart';

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


