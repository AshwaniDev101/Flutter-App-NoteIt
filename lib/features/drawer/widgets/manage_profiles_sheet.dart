import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_model.dart';
import '../../profiles/profile_providers.dart';
import '../../profiles/profile_repository.dart';

/// Modal bottom sheet for managing, editing, and deleting workspace profiles.
class ManageProfilesSheet extends ConsumerWidget {
  const ManageProfilesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesListProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title
            Row(
              children: [
                Icon(Icons.settings_outlined, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Manage Workspace Profiles',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: profiles.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 64,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (ctx, index) {
                  final profile = profiles[index];
                  final isActive = profile.id == activeProfile.id;
                  final avatarLetter = _getAvatarLetter(profile);
                  final avatarColor = Color(profile.colorValue);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: profile.customAlias != null && profile.customAlias!.isNotEmpty
                        ? Text(
                            profile.customAlias!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Profile',
                          onPressed: () {
                            _showEditProfileDialog(context, ref, profile);
                          },
                        ),
                        // Delete button (disabled for default profile)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: profile.isDefault ? colorScheme.outline.withValues(alpha: 0.3) : colorScheme.error,
                          ),
                          tooltip: profile.isDefault ? 'Cannot delete default profile' : 'Delete Profile',
                          onPressed: profile.isDefault
                              ? null
                              : () {
                                  _confirmAndDeleteProfile(context, ref, profile, isActive);
                                },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAvatarLetter(Profile profile) {
    if (profile.customAlias != null && profile.customAlias!.trim().isNotEmpty) {
      return profile.customAlias!.trim()[0].toUpperCase();
    }
    if (profile.name.trim().isNotEmpty) {
      return profile.name.trim()[0].toUpperCase();
    }
    return 'P';
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, Profile profile) {
    final nameController = TextEditingController(text: profile.name);
    final aliasController = TextEditingController(text: profile.customAlias ?? '');
    int selectedColorHex = profile.colorValue;

    const presetColors = [
      0xFF2196F3, // Ocean Blue
      0xFF4CAF50, // Emerald Green
      0xFFFF9800, // Amber / Orange
      0xFF9C27B0, // Royal Purple
      0xFFE91E63, // Crimson Rose
      0xFF009688, // Teal
      0xFF3F51B5, // Indigo
      0xFF00BCD4, // Cyan
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          final theme = Theme.of(dialogCtx);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            title: Text('Edit Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Profile Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aliasController,
                    decoration: const InputDecoration(labelText: 'Subtitle / Custom Alias'),
                  ),
                  const SizedBox(height: 16),
                  Text('Accent Color', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetColors.map((colorHex) {
                      final isSelected = selectedColorHex == colorHex;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColorHex = colorHex),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? colorScheme.onSurface : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;

                  final updated = profile.copyWith(
                    name: newName,
                    customAlias: aliasController.text.trim().isNotEmpty ? aliasController.text.trim() : null,
                    colorValue: selectedColorHex,
                  );

                  await ref.read(profilesListProvider.notifier).updateProfile(updated);
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

                  // If active profile was updated, refresh active profile
                  if (ref.read(activeProfileProvider).id == profile.id) {
                    ref.read(activeProfileProvider.notifier).updateActiveProfile(updated);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmAndDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    bool isActive,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Profile "${profile.name}"?'),
        content: const Text(
          'This will permanently delete this profile and its associated SQLite database file on disk. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Profile'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      if (isActive) {
        // Switch back to default profile before deleting
        await ref.read(activeProfileProvider.notifier).switchProfile(ProfileRepository.defaultProfile);
      }
      await ref.read(profilesListProvider.notifier).deleteProfile(profile.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close sheet
        SnackBarManager.show(
          msg: 'Profile "${profile.name}" deleted.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }
}
