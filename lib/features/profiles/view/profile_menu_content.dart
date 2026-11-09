import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../../../shared/menus/sync_menu_button.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../models/profile_model.dart';
import '../providers/active_profile_provider.dart';
import '../providers/profile_providers.dart';
import 'helpers/profile_badge_helper.dart';
import 'widgets/create_profile_dialog.dart';
import 'widgets/profile_tile.dart';

class ProfileMenuContent extends ConsumerStatefulWidget {
  final VoidCallback onCloseMenu;

  const ProfileMenuContent({
    super.key,
    required this.onCloseMenu,
  });

  @override
  ConsumerState<ProfileMenuContent> createState() => _ProfileMenuContentState();
}

class _ProfileMenuContentState extends ConsumerState<ProfileMenuContent> {
  bool _showProfilesList = false;

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final authUser = ref.watch(authStateProvider).value;
    final syncMode = ref.watch(syncModeProvider);

    final currentEngine = syncMode.isCloud
        ? SyncEngine.cloud
        : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

    if (_showProfilesList) {
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
                    setState(() {
                      _showProfilesList = false;
                    });
                  },
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Text(
                  'Switch profile',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...profiles.map((profile) {
            return ProfileTile(
              profile: profile,
              activeProfile: activeProfile,
              authUser: authUser,
              onMenuDismiss: widget.onCloseMenu,
              onSelect: (selectedProfile) async {
                widget.onCloseMenu();
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
              widget.onCloseMenu();
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
            widget.onCloseMenu();
            showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
          },
        ),
        const Divider(height: 1),
        _buildActionItem(
          context: context,
          icon: Icons.logout,
          title: 'Sign out',
          onTap: () => _handleSignOut(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Profile activeProfile, User? authUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final photoUrl = ProfileBadgeHelper.getEffectivePhotoUrl(activeProfile, authUser);
    final displayName = ProfileBadgeHelper.getEffectiveDisplayName(activeProfile, authUser);
    final email = ProfileBadgeHelper.getEffectiveEmail(activeProfile, authUser);
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
                    widget.onCloseMenu();
                    showDialog(
                      context: context,
                      builder: (ctx) => CreateProfileDialog(profileToEdit: activeProfile),
                    );
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

  Future<void> _handleSignOut(BuildContext context) async {
    widget.onCloseMenu();

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
}
