import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../active_profile_provider.dart';
import '../profile_model.dart';
import '../profile_providers.dart';
import '../profile_repository.dart';
import 'create_profile_dialog.dart';

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
                  const avatarColor = Colors.grey;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Profile',
                          onPressed: () {
                            _showEditProfileDialog(context, profile);
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
    if (profile.name.trim().isNotEmpty) {
      return profile.name.trim()[0].toUpperCase();
    }
    return 'P';
  }

  void _showEditProfileDialog(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (ctx) => CreateProfileDialog(profileToEdit: profile),
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
