import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_engine.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../models/profile_model.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/profile_providers.dart';
import '../helpers/profile_badge_helper.dart';
import 'create_profile_dialog.dart';

class ProfileTile extends ConsumerWidget {
  final Profile profile;
  final Profile activeProfile;
  final User? authUser;
  final ValueChanged<Profile> onSelect;
  final VoidCallback? onMenuDismiss;

  const ProfileTile({
    super.key,
    required this.profile,
    required this.activeProfile,
    required this.authUser,
    required this.onSelect,
    this.onMenuDismiss,
  });

  SyncEngine _getSyncEngineForProfile(Profile profile) {
    if (profile.syncMode == 'cloud') return SyncEngine.cloud;
    if (profile.syncMode == 'localHost' ||
        profile.syncMode == 'localClient' ||
        profile.syncMode == 'localUndefined') {
      return SyncEngine.local;
    }
    return SyncEngine.offline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = profile.id == activeProfile.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncEngine = _getSyncEngineForProfile(profile);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) {
          _showProfileContextMenu(context, ref, details, profile);
        },
        onLongPressStart: (details) {
          _showProfileContextMenu(
            context,
            ref,
            TapDownDetails(globalPosition: details.globalPosition),
            profile,
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
              backgroundColor: ProfileBadgeHelper.getColor(profile.name),
              child: Text(
                ProfileBadgeHelper.getInitial(profile.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              profile.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    syncEngine.icon,
                    size: 12,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    syncEngine.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                : null,
            onTap: () => onSelect(profile),
          ),
        ),
      ),
    );
  }

  void _showProfileContextMenu(
    BuildContext context,
    WidgetRef ref,
    TapDownDetails details,
    Profile profile,
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
        _showEditProfileDialog(context, profile);
        break;
      case 'delete':
        _confirmAndDeleteProfile(context, ref, profile);
        break;
    }
  }

  void _showEditProfileDialog(BuildContext context, Profile profile) {
    onMenuDismiss?.call();
    showDialog(
      context: context,
      builder: (ctx) => CreateProfileDialog(profileToEdit: profile),
    );
  }

  void _confirmAndDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    onMenuDismiss?.call();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Profile "${profile.name}"?'),
        content: const Text(
          'This will permanently delete this profile and its associated SQLite database file on disk. Continue?',
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
            child: const Text('Delete Profile'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile.id == profile.id) {
        final allProfiles = ref.read(profilesListProvider);
        final remaining = allProfiles.where((p) => p.id != profile.id).toList();
        if (remaining.isNotEmpty) {
          await ref.read(activeProfileProvider.notifier).switchProfile(remaining.first);
        } else {
          final newProf = await ref.read(profilesListProvider.notifier).createProfile(name: 'NoteIt');
          await ref.read(activeProfileProvider.notifier).switchProfile(newProf);
        }
      }
      await ref.read(profilesListProvider.notifier).deleteProfile(profile.id);
      if (context.mounted) {
        SnackBarManager.show(
          msg: 'Profile "${profile.name}" deleted.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }
}
