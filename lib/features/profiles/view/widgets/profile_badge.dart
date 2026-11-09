import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_orchestrator.dart';
import '../../../../shared/menus/app_bottom_sheet.dart';
import '../../../../shared/menus/sync_menu_button.dart';
import '../../../../shared/overlays/snack_bar_manager.dart';
import '../../models/profile_model.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/profile_providers.dart';
import '../helpers/profile_badge_helper.dart';
import 'create_profile_dialog.dart';

class ProfileBadge extends ConsumerStatefulWidget {
  const ProfileBadge({super.key});

  @override
  ConsumerState<ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends ConsumerState<ProfileBadge> {
  final MenuController _menuController = MenuController();
  bool _showProfilesList = false;

  void _showMobileBottomSheet(BuildContext context) {
    bool showProfilesList = false;

    AppBottomSheet.show(
      context: context,
      builder: (bottomSheetContext, setModalState) {
        final activeProfile = ref.watch(activeProfileProvider);
        final profiles = ref.watch(profilesListProvider);
        final authUser = ref.watch(authStateProvider).value;
        final syncMode = ref.watch(syncModeProvider);

        final currentEngine = syncMode.isCloud
            ? SyncEngine.cloud
            : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

        if (showProfilesList) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () {
                        setModalState(() {
                          showProfilesList = false;
                        });
                      },
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Switch profile',
                      style: Theme.of(bottomSheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...profiles.map((profile) {
                return _buildProfileTile(
                  context: bottomSheetContext,
                  profile: profile,
                  activeProfile: activeProfile,
                  authUser: authUser,
                  onSelect: (selectedProfile) async {
                    Navigator.of(bottomSheetContext).pop();
                    if (selectedProfile.id != activeProfile.id) {
                      await ref.read(activeProfileProvider.notifier).switchProfile(selectedProfile);
                      SnackBarManager.show(
                        msg: 'Switched to profile "${selectedProfile.name}".',
                        type: SnackBarMessageType.acknowledgment,
                      );
                    }
                  },
                );
              }),
              const Divider(height: 1),
              _buildCreateProfileTile(
                bottomSheetContext,
                onSelect: () {
                  Navigator.of(bottomSheetContext).pop();
                  showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(bottomSheetContext, activeProfile, authUser),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SyncMenuButton(
                currentEngine: currentEngine,
                onEngineSelected: (engine) => _handleSyncChange(engine, ref, syncMode),
              ),
            ),

            _buildActionItem(
              context: bottomSheetContext,
              icon: Icons.switch_account_outlined,
              title: 'Switch account',
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                setModalState(() {
                  showProfilesList = true;
                });
              },
            ),
            _buildActionItem(
              context: bottomSheetContext,
              icon: Icons.add_circle_outline_rounded,
              title: 'Create New Profile',
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
              },
            ),
            const Divider(height: 1),
            _buildActionItem(
              context: bottomSheetContext,
              icon: Icons.logout,
              title: 'Sign out',
              onTap: () => _handleSignOut(bottomSheetContext, isMobile: true),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext menuContext, {required bool isMobile}) async {
    if (isMobile) {
      Navigator.of(menuContext).pop();
    } else {
      if (_menuController.isOpen) _menuController.close();
    }

    final activeProfile = ref.read(activeProfileProvider);

    // 1. Sign out from Firebase & Google
    await ref.read(authRepositoryProvider).signOut();

    // 2. Unlink Google account from active profile if present (resets syncMode to offline)
    if (activeProfile.linkedEmail != null) {
      await ref.read(profilesListProvider.notifier).unlinkGoogleAccount(activeProfile.id);
      final unlinked = ref.read(profileRepositoryProvider).getProfileById(activeProfile.id);
      if (unlinked != null) {
        ref.read(activeProfileProvider.notifier).updateActiveProfile(unlinked);
      }
    }

    SnackBarManager.show(
      msg: 'Signed out and unlinked account successfully.',
      type: SnackBarMessageType.acknowledgment,
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

    final activePhotoUrl = (isAuthForActive ? authUser.photoURL : null) ?? activeProfile.photoUrl;

    void openProfileMenu() {
      if (isMobile) {
        _showMobileBottomSheet(context);
      } else {
        if (_menuController.isOpen) {
          _menuController.close();
        } else {
          setState(() {
            _showProfilesList = false;
          });
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
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _showProfilesList
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _showProfilesList = false;
                                  });
                                },
                                tooltip: 'Back',
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Switch profile',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...profiles.map((profile) {
                          return _buildProfileTile(
                            context: context,
                            profile: profile,
                            activeProfile: activeProfile,
                            authUser: authUser,
                            onSelect: (selectedProfile) async {
                              if (_menuController.isOpen) _menuController.close();
                              if (selectedProfile.id != activeProfile.id) {
                                await ref.read(activeProfileProvider.notifier).switchProfile(selectedProfile);
                                SnackBarManager.show(
                                  msg: 'Switched to profile "${selectedProfile.name}".',
                                  type: SnackBarMessageType.acknowledgment,
                                );
                              }
                            },
                          );
                        }),
                        const Divider(height: 1),
                        _buildCreateProfileTile(
                          context,
                          onSelect: () {
                            if (_menuController.isOpen) _menuController.close();
                            showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
                          },
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, activeProfile, authUser),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SyncMenuButton(
                            currentEngine: currentEngine,
                            onEngineSelected: (engine) => _handleSyncChange(engine, ref, syncMode),
                          ),
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.switch_account_outlined,
                          title: 'Switch account',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            setState(() {
                              _showProfilesList = true;
                            });
                          },
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Create New Profile',
                          onTap: () {
                            if (_menuController.isOpen) _menuController.close();
                            showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
                          },
                        ),
                        const Divider(height: 1),
                        _buildActionItem(
                          context: context,
                          icon: Icons.logout,
                          title: 'Sign out',
                          onTap: () => _handleSignOut(context, isMobile: false),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Profile activeProfile, User? authUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthForProfile = authUser != null &&
        activeProfile.linkedEmail != null &&
        authUser.email?.toLowerCase() == activeProfile.linkedEmail?.toLowerCase();

    final photoUrl = (isAuthForProfile ? authUser.photoURL : null) ?? activeProfile.photoUrl;
    final displayName = (isAuthForProfile && (authUser.displayName?.isNotEmpty ?? false))
        ? authUser.displayName!
        : (activeProfile.displayName?.isNotEmpty ?? false)
            ? activeProfile.displayName!
            : activeProfile.name;
    final email = activeProfile.linkedEmail ?? (isAuthForProfile ? authUser.email : null);
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isGoogleLinked = activeProfile.linkedEmail != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ProfileBadgeHelper.getColor(activeProfile.name),
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: !hasPhoto
                ? Text(
                    ProfileBadgeHelper.getInitial(activeProfile.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isGoogleLinked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activeProfile.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (email != null && email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    if (_menuController.isOpen) _menuController.close();
                    _showEditProfileDialog(context, activeProfile);
                  },
                  child: Text(
                    'Manage your profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) ...[trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required Profile profile,
    required Profile activeProfile,
    required User? authUser,
    required ValueChanged<Profile> onSelect,
  }) {
    final isSelected = profile.id == activeProfile.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthForProfile = authUser != null &&
        profile.linkedEmail != null &&
        authUser.email?.toLowerCase() == profile.linkedEmail?.toLowerCase();

    final photoUrl = (isAuthForProfile ? authUser.photoURL : null) ?? profile.photoUrl;
    final displayName = (isAuthForProfile && (authUser.displayName?.isNotEmpty ?? false))
        ? authUser.displayName!
        : (profile.displayName?.isNotEmpty ?? false)
            ? profile.displayName!
            : profile.name;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isGoogleLinked = profile.linkedEmail != null;

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isGoogleLinked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  profile.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: isGoogleLinked
            ? Text(
                profile.linkedEmail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
            : null,
        onTap: () => onSelect(profile),
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
      onTap: onSelect,
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
        _confirmAndDeleteProfile(context, profile);
        break;
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
        final remaining = allProfiles.where((p) => p.id != profile.id).toList();
        if (remaining.isNotEmpty) {
          await ref.read(activeProfileProvider.notifier).switchProfile(remaining.first);
        } else {
          final newProf = await ref.read(profilesListProvider.notifier).createProfile(name: 'NoteIt');
          await ref.read(activeProfileProvider.notifier).switchProfile(newProf);
        }
        // Brief asynchronous pause to allow Riverpod disposal and SQLite file handle closure
        await Future.delayed(const Duration(milliseconds: 100));
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
