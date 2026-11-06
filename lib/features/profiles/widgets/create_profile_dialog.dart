import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../active_profile_provider.dart';
import '../profile_model.dart';
import '../profile_providers.dart';

/// Modal dialog for creating a new user profile workspace or editing an existing profile.
class CreateProfileDialog extends ConsumerStatefulWidget {
  final Profile? profileToEdit;

  const CreateProfileDialog({
    super.key,
    this.profileToEdit,
  });

  bool get isEditing => profileToEdit != null;

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();

    if (widget.isEditing) {
      final updated = widget.profileToEdit!.copyWith(name: name);
      await ref.read(profilesListProvider.notifier).updateProfile(updated);

      if (ref.read(activeProfileProvider).id == updated.id) {
        ref.read(activeProfileProvider.notifier).updateActiveProfile(updated);
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        SnackBarManager.show(
          msg: 'Profile renamed to "$name".',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } else {
      final newProfile = await ref.read(profilesListProvider.notifier).createProfile(
            name: name,
          );

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        await ref.read(activeProfileProvider.notifier).switchProfile(newProfile);
        SnackBarManager.show(
          msg: 'Created and switched to "$name" profile.',
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
            isEditing ? 'Edit Profile' : 'Create New Profile',
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
                  decoration: InputDecoration(
                    labelText: 'Profile Name *',
                    hintText: 'e.g. Work, Personal, Side Projects',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.workspace_premium_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a profile name';
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(isEditing ? 'Save Changes' : 'Create Profile'),
        ),
      ],
    );
  }
}