import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../models/profile_model.dart';
import '../providers/active_profile_provider.dart';
import '../providers/profile_providers.dart';
import 'helpers/profile_badge_helper.dart';
import 'widgets/create_profile_dialog.dart';
import 'widgets/profile_tile.dart';

enum _ProfileSubView { main, profiles, sync }

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
  _ProfileSubView _activeSubView = _ProfileSubView.main;

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final authUser = ref.watch(authStateProvider).value;
    final syncMode = ref.watch(syncModeProvider);

    final currentEngine = syncMode.isCloud
        ? SyncEngine.cloud
        : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

    if (_activeSubView == _ProfileSubView.profiles) {
      return _buildProfilesPanel(
        context: context,
        profiles: profiles,
        activeProfile: activeProfile,
        authUser: authUser,
      );
    }

    if (_activeSubView == _ProfileSubView.sync) {
      return _buildSyncOptionsPanel(
        context: context,
        currentEngine: currentEngine,
        syncMode: syncMode,
      );
    }

    return _buildMainPanel(
      context: context,
      activeProfile: activeProfile,
      authUser: authUser,
      currentEngine: currentEngine,
      syncMode: syncMode,
    );
  }

  Widget _buildMainPanel({
    required BuildContext context,
    required Profile activeProfile,
    required User? authUser,
    required SyncEngine currentEngine,
    required SyncMode syncMode,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, activeProfile, authUser, syncMode),
        const Divider(height: 1),
        _buildExpandableTile(
          context: context,
          icon: currentEngine.icon,
          title: 'Sync Method',
          statusText: currentEngine.label,
          onTap: () {
            setState(() {
              _activeSubView = _ProfileSubView.sync;
            });
          },
        ),
        _buildExpandableTile(
          context: context,
          icon: Icons.switch_account_outlined,
          title: 'Switch account',
          onTap: () {
            setState(() {
              _activeSubView = _ProfileSubView.profiles;
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
        if (syncMode.isCloud) ...[
          const Divider(height: 1),
          _buildActionItem(
            context: context,
            icon: Icons.logout,
            title: 'Sign out',
            onTap: () => _handleSignOut(context),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProfilesPanel({
    required BuildContext context,
    required List<Profile> profiles,
    required Profile activeProfile,
    required User? authUser,
  }) {
    final theme = Theme.of(context);

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
                    _activeSubView = _ProfileSubView.main;
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

  Widget _buildSyncOptionsPanel({
    required BuildContext context,
    required SyncEngine currentEngine,
    required SyncMode syncMode,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const options = [
      SyncEngine.cloud,
      SyncEngine.local,
      SyncEngine.offline,
    ];

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
                    _activeSubView = _ProfileSubView.main;
                  });
                },
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Text(
                'Sync Method',
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...options.map((engine) {
          final isSelected = currentEngine == engine;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              engine.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            title: Text(
              engine.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              engine.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                : null,
            onTap: () async {
              await _handleSyncChange(engine, ref, syncMode);
              setState(() {
                _activeSubView = _ProfileSubView.main;
              });
            },
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpandableTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? statusText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (statusText != null) ...[
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Profile activeProfile, User? authUser, SyncMode syncMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCloud = syncMode.isCloud;

    final photoUrl = ProfileBadgeHelper.getEffectivePhotoUrl(activeProfile, authUser, isCloud: isCloud);
    final displayName = ProfileBadgeHelper.getEffectiveDisplayName(activeProfile, authUser, isCloud: isCloud);
    final email = ProfileBadgeHelper.getEffectiveEmail(activeProfile, authUser, isCloud: isCloud);
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isGoogleAuthView = ProfileBadgeHelper.isAuthForProfile(activeProfile, authUser, isCloud: isCloud);

    final linkedEmail = activeProfile.linkedEmail ?? (authUser?.email);
    final hasLinkedAccount = linkedEmail != null && linkedEmail.isNotEmpty;
    final googlePhotoUrl = authUser?.photoURL ?? activeProfile.photoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    if (isGoogleAuthView) ...[
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
                if (isGoogleAuthView && email != null && email.isNotEmpty)
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
          if (!isCloud && hasLinkedAccount) ...[
            const SizedBox(width: 12),
            Tooltip(
              message: 'Linked Account: $linkedEmail',
              child: CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: googlePhotoUrl != null && googlePhotoUrl.isNotEmpty
                    ? NetworkImage(googlePhotoUrl)
                    : null,
                child: (googlePhotoUrl == null || googlePhotoUrl.isEmpty)
                    ? Icon(Icons.person, size: 14, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ],
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
    final syncNotifier = ref.read(syncModeProvider.notifier);
    final orchestrator = ref.read(syncOrchestratorProvider);

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

    final success = await syncNotifier.requestModeChange(targetMode);
    if (success) {
      orchestrator.triggerSync();
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
