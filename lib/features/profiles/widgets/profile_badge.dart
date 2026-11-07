import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/features/profiles/widgets/sync_menu_button.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../../../shared/menus/app_bottom_sheet.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import 'create_profile_dialog.dart';
import '../helpers/profile_badge_helper.dart';
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

  void _showMobileBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (bottomSheetContext, setModalState) {
        final activeProfile = ref.watch(activeProfileProvider);
        final profiles = ref.watch(profilesListProvider);
        final authUser = ref.watch(authStateProvider).value;
        final theme = Theme.of(bottomSheetContext);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Profiles',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            ...profiles.map((profile) {
              return _buildProfileTile(
                context: bottomSheetContext,
                profile: profile,
                activeProfile: activeProfile,
                authUser: authUser,
                onSelect: () => Navigator.of(bottomSheetContext).pop(),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(indent: 16, endIndent: 16, height: 1),
            ),
            _buildCreateProfileTile(
              bottomSheetContext,
              onSelect: () => Navigator.of(bottomSheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final authUser = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = !PlatformHelper.isWideLayout(context);

    final syncMode = ref.watch(syncModeProvider);
    final currentEngine = syncMode.isCloud
        ? SyncEngine.cloud
        : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

    final isAuthForActive = authUser != null &&
        activeProfile.linkedEmail != null &&
        authUser.email?.toLowerCase() == activeProfile.linkedEmail?.toLowerCase();

    final activePhotoUrl = isAuthForActive ? authUser.photoURL : null;

    void openProfileMenu() {
      if (isMobile) {
        _showMobileBottomSheet(context);
      } else {
        if (_menuController.isOpen) {
          _menuController.close();
        } else {
          _menuController.open();
        }
      }
    }

    final avatarWidget = _AvatarBadge(
      activeProfileName: activeProfile.name,
      photoUrl: activePhotoUrl,
      onTap: openProfileMenu,
    );

    if (isMobile) {
      return avatarWidget;
    }

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
        return avatarWidget;
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
                  SyncMenuButton(
                    currentEngine: currentEngine,
                    onEngineSelected: (engine) => _handleSyncChange(engine, ref, syncMode),
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),

                  // 1. Dynamic Profile List
                  ...profiles.map((profile) {
                    return _buildProfileTile(
                      context: context,
                      profile: profile,
                      activeProfile: activeProfile,
                      authUser: authUser,
                      onSelect: () {
                        if (_menuController.isOpen) {
                          _menuController.close();
                        }
                      },
                    );
                  }),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),

                  // 2. Actions (Create)
                  _buildCreateProfileTile(
                    context,
                    onSelect: () {
                      if (_menuController.isOpen) {
                        _menuController.close();
                      }
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

  Future<void> _handleSyncChange(SyncEngine selectedEngine, WidgetRef ref, SyncMode currentMode) async {
    SyncMode targetMode;
    switch (selectedEngine) {
      case SyncEngine.cloud:
        targetMode = SyncMode.cloud;
        break;
      case SyncEngine.local:
        targetMode = currentMode.isLocal ? currentMode : SyncMode.localUndefined;
        break;
      case SyncEngine.offline:
        targetMode = SyncMode.offline;
        break;
    }

    final success = await ref.read(syncModeProvider.notifier).requestModeChange(targetMode);
    if (success) {
      ref.read(syncOrchestratorProvider).triggerSync();
    }
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required Profile profile,
    required Profile activeProfile,
    required User? authUser,
    required VoidCallback onSelect,
  }) {
    final isSelected = profile.id == activeProfile.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthForProfile = authUser != null &&
        profile.linkedEmail != null &&
        authUser.email?.toLowerCase() == profile.linkedEmail?.toLowerCase();

    final photoUrl = isAuthForProfile ? authUser.photoURL : null;
    final displayName = isAuthForProfile && (authUser.displayName?.isNotEmpty ?? false)
        ? authUser.displayName!
        : profile.name;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

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
          backgroundColor: ProfileBadgeHelper.getColor(profile.name),
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: !hasPhoto
              ? Text(
                  ProfileBadgeHelper.getInitial(profile.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
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
          onSelect();
          if (!isSelected) {
            await ref.read(activeProfileProvider.notifier).switchProfile(profile);
          }
        },
      ),
    );
  }

  Widget _buildCreateProfileTile(BuildContext context, {required VoidCallback onSelect}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary, size: 20),
      title: Text(
        'Create New Profile',
        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        onSelect();
        showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
      },
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
    if (_menuController.isOpen) {
      _menuController.close();
    }
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
    if (_menuController.isOpen) {
      _menuController.close();
    }
    showDialog(
      context: context,
      builder: (ctx) => CreateProfileDialog(profileToEdit: profile),
    );
  }

  void _confirmAndDeleteProfile(BuildContext context, Profile profile) async {
    if (profile.isDefault) return;
    if (_menuController.isOpen) {
      _menuController.close();
    }

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
}

class _AvatarBadge extends StatefulWidget {
  final String activeProfileName;
  final String? photoUrl;
  final VoidCallback onTap;

  const _AvatarBadge({
    required this.activeProfileName,
    this.photoUrl,
    required this.onTap,
  });

  @override
  State<_AvatarBadge> createState() => _AvatarBadgeState();
}

class _AvatarBadgeState extends State<_AvatarBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return Tooltip(
      message: 'Profiles',
      child: Material(
        color: ProfileBadgeHelper.getColor(widget.activeProfileName),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onHover: (hovered) {
            if (_isHovered != hovered) {
              setState(() => _isHovered = hovered);
            }
          },
          onTap: widget.onTap,
          onSecondaryTap: widget.onTap,
          child: SizedBox(
            height: 24,
            width: 24,
            child: Stack(
              children: [
                if (hasPhoto)
                  Positioned.fill(
                    child: Image.network(
                      widget.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            ProfileBadgeHelper.getInitial(widget.activeProfileName),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Center(
                    child: Text(
                      ProfileBadgeHelper.getInitial(widget.activeProfileName),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHovered
                          ? Colors.transparent
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}