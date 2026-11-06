import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/overlays/snack_bar_manager.dart';
import 'create_profile_dialog.dart';
import 'manage_profiles_sheet.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_model.dart';
import '../../profiles/profile_providers.dart';
import '../../profiles/profile_repository.dart';

class ProfileBadge extends ConsumerStatefulWidget {
  const ProfileBadge({super.key});

  @override
  ConsumerState<ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends ConsumerState<ProfileBadge> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 8),
      style: const MenuStyle(
        // Transparent so our single Custom Card drives the UI
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: Center(
              child: Text(
                _getAvatarLetter(activeProfile),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(4),
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Dynamic Profile List
                  ...profiles.map((profile) {
                    final isSelected = profile.id == activeProfile.id;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: (details) {
                        _showProfileContextMenu(context, details, profile);
                      },
                      onLongPressStart: (details) {
                        _showProfileContextMenu(
                          context,
                          TapDownDetails(globalPosition: details.globalPosition),
                          profile,
                        );
                      },
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey,
                          child: Text(
                            _getAvatarLetter(profile),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                        subtitle: profile.isDefault
                            ? Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                            : null,
                        onTap: () async {
                          _menuController.close();
                          if (!isSelected) {
                            await ref.read(activeProfileProvider.notifier).switchProfile(profile);
                          }
                        },
                      ),
                    );
                  }),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),

                  // 2. Actions (Create / Manage)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary, size: 20),
                    title: Text(
                      'Create New Profile',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      _menuController.close();
                      showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    title: Text(
                      'Manage Profiles',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      _menuController.close();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const ManageProfilesSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileContextMenu(BuildContext context, TapDownDetails details, Profile profile) async {
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
        PopupMenuItem<String>(
          value: 'set_default',
          enabled: !profile.isDefault,
          child: Row(
            children: [
              Icon(
                profile.isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: profile.isDefault ? Theme.of(context).colorScheme.primary : null,
              ),
              const SizedBox(width: 8),
              Text(profile.isDefault ? 'Default Profile' : 'Set Default'),
            ],
          ),
        ),
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
          enabled: !profile.isDefault,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: profile.isDefault ? null : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: profile.isDefault ? null : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selectedValue == null || !context.mounted) return;

    switch (selectedValue) {
      case 'set_default':
        await _handleSetDefault(profile);
        break;
      case 'edit':
        _showEditProfileDialog(context, profile);
        break;
      case 'delete':
        _confirmAndDeleteProfile(context, profile);
        break;
    }
  }

  Future<void> _handleSetDefault(Profile profile) async {
    if (profile.isDefault) return;
    _menuController.close();
    final success = await ref.read(profilesListProvider.notifier).setDefaultProfile(profile.id);
    if (success) {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile.id == profile.id) {
        ref.read(activeProfileProvider.notifier).updateActiveProfile(profile.copyWith(isDefault: true));
      } else if (activeProfile.isDefault) {
        ref.read(activeProfileProvider.notifier).updateActiveProfile(activeProfile.copyWith(isDefault: false));
      }
      SnackBarManager.show(
        msg: 'Profile "${profile.name}" set as default.',
        type: SnackBarMessageType.acknowledgment,
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, Profile profile) {
    _menuController.close();
    showDialog(
      context: context,
      builder: (ctx) => CreateProfileDialog(profileToEdit: profile),
    );
  }

  void _confirmAndDeleteProfile(BuildContext context, Profile profile) async {
    if (profile.isDefault) return;
    _menuController.close();

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
        final defaultProf = allProfiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => ProfileRepository.defaultProfile,
        );
        await ref.read(activeProfileProvider.notifier).switchProfile(defaultProf);
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

  String _getAvatarLetter(Profile profile) {
    if (profile.name.trim().isNotEmpty) {
      return profile.name.trim()[0].toUpperCase();
    }
    return 'P';
  }
}