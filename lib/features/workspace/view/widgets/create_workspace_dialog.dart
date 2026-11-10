import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../models/workspace_model.dart';
import '../../providers/active_workspace_provider.dart';
import '../../providers/workspace_providers.dart';

/// Modal dialog for creating a new user workspace or editing an existing workspace.
class CreateWorkspaceDialog extends ConsumerStatefulWidget {
  final Workspace? workspaceToEdit;

  const CreateWorkspaceDialog({
    super.key,
    this.workspaceToEdit,
  });

  bool get isEditing => workspaceToEdit != null;

  @override
  ConsumerState<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends ConsumerState<CreateWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspaceToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmAndDeleteWorkspace(BuildContext context, WidgetRef ref, Workspace workspace) async {
    Navigator.of(context).pop();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Workspace "${workspace.name}"?'),
        content: const Text(
          'This will permanently delete this workspace and its associated notes.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
      SnackBarManager.show(
        msg: 'Workspace "${workspace.name}" deleted.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  void _onSave() async {
    var name = _nameController.text.trim();

    if (name.isEmpty) {
      SnackBarManager.show(
        msg: 'Please enter a workspace name',
        type: SnackBarMessageType.acknowledgment,
      );
      return;
    }

    if (widget.isEditing) {
      final updated = widget.workspaceToEdit!.copyWith(
        name: name,
      );
      await ref.read(workspacesListProvider.notifier).updateWorkspace(updated);

      if (ref.read(activeWorkspaceProvider).id == updated.id) {
        ref.read(activeWorkspaceProvider.notifier).updateActiveWorkspace(updated);
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        SnackBarManager.show(
          msg: 'Workspace updated to "$name".',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } else {
      final newWorkspace = await ref.read(workspacesListProvider.notifier).createWorkspace(
            name: name,
          );

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        await ref.read(activeWorkspaceProvider.notifier).switchWorkspace(newWorkspace);
        SnackBarManager.show(
          msg: 'Created and switched to "$name" workspace.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.isEditing;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.add_to_photos_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Workspace' : 'Create New Workspace',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSave(),
                  decoration: InputDecoration(
                    labelText: 'Workspace Name *',
                    hintText: 'e.g. Work, Personal, Side Projects',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.workspace_premium_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a workspace name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEditing && widget.workspaceToEdit != null)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            onPressed: () => _confirmAndDeleteWorkspace(context, ref, widget.workspaceToEdit!),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(isEditing ? 'Save' : 'Create Workspace'),
        ),
      ],
    );
  }
}
