import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../models/workspace_model.dart';
import '../../providers/active_workspace_provider.dart';
import '../../providers/workspace_providers.dart';
import '../helpers/workspace_badge_helper.dart';
import 'create_workspace_dialog.dart';

class WorkspaceTile extends ConsumerWidget {
  final Workspace workspace;
  final Workspace activeWorkspace;
  final User? authUser;
  final ValueChanged<Workspace> onSelect;
  final VoidCallback? onMenuDismiss;

  const WorkspaceTile({
    super.key,
    required this.workspace,
    required this.activeWorkspace,
    required this.authUser,
    required this.onSelect,
    this.onMenuDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = workspace.id == activeWorkspace.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) {
          _showWorkspaceContextMenu(context, ref, details, workspace);
        },
        onLongPressStart: (details) {
          _showWorkspaceContextMenu(
            context,
            ref,
            TapDownDetails(globalPosition: details.globalPosition),
            workspace,
          );
        },
        child: Material(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: WorkspaceBadgeHelper.getColor(workspace.name),
              child: Text(
                WorkspaceBadgeHelper.getInitial(workspace.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              workspace.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                : null,
            onTap: () => onSelect(workspace),
          ),
        ),
      ),
    );
  }

  void _showWorkspaceContextMenu(
    BuildContext context,
    WidgetRef ref,
    TapDownDetails details,
    Workspace workspace,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final selectedValue = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selectedValue == null || !context.mounted) return;

    switch (selectedValue) {
      case 'edit':
        _showEditWorkspaceDialog(context, workspace);
        break;
      case 'delete':
        _confirmAndDeleteWorkspace(context, ref, workspace);
        break;
    }
  }

  void _showEditWorkspaceDialog(BuildContext context, Workspace workspace) {
    onMenuDismiss?.call();
    showDialog(
      context: context,
      builder: (ctx) => CreateWorkspaceDialog(workspaceToEdit: workspace),
    );
  }

  void _confirmAndDeleteWorkspace(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
  ) async {
    onMenuDismiss?.call();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Workspace "${workspace.name}"?'),
        content: const Text(
          'This will permanently delete this workspace and its associated SQLite database file on disk. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Workspace'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final activeWorkspace = ref.read(activeWorkspaceProvider);
      if (activeWorkspace.id == workspace.id) {
        final allWorkspaces = ref.read(workspacesListProvider);
        final remaining = allWorkspaces.where((p) => p.id != workspace.id).toList();
        if (remaining.isNotEmpty) {
          await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(remaining.first);
        } else {
          final newProf = await ref.read(workspacesListProvider.notifier).createWorkspace(name: 'NoteIt');
          await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(newProf);
        }
      }
      await ref.read(workspacesListProvider.notifier).deleteWorkspace(workspace.id);
      if (context.mounted) {
        SnackBarManager.show(
          msg: 'Workspace "${workspace.name}" deleted.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }
}
