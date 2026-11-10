import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../../core/sync/sync_engine.dart';
import '../../models/profile_model.dart';
import '../../providers/active_profile_provider.dart';
import '../helpers/profile_badge_helper.dart';

/// A sleek, non-disruptive loading overlay displayed over notes/content panels
/// during workspace profile switching.
class ProfileSwitchOverlay extends ConsumerWidget {
  final Widget child;

  const ProfileSwitchOverlay({
    super.key,
    required this.child,
  });

  SyncEngine _getSyncEngine(Profile? profile) {
    if (profile == null) return SyncEngine.offline;
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
    final switchingState = ref.watch(profileSwitchingProvider);
    final authUser = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSwitching = switchingState.isSwitching;
    final targetProfile = switchingState.targetProfile;
    final profileName = targetProfile?.name ?? 'Workspace';

    final photoUrl = targetProfile != null
        ? ProfileBadgeHelper.getEffectivePhotoUrl(targetProfile, authUser)
        : null;
    final displayName = targetProfile != null
        ? ProfileBadgeHelper.getEffectiveDisplayName(targetProfile, authUser)
        : profileName;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isGoogleAuthView = targetProfile != null &&
        ProfileBadgeHelper.isAuthForProfile(targetProfile, authUser);

    final syncEngine = _getSyncEngine(targetProfile);
    final linkedEmail = targetProfile?.linkedEmail;
    final displayEmail = (targetProfile?.syncMode == 'cloud' &&
            linkedEmail != null &&
            linkedEmail.isNotEmpty)
        ? linkedEmail
        : null;

    return Stack(
      children: [
        child,

        // Centered animated overlay layer
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            reverseDuration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isSwitching
                ? SizedBox.expand(
                    key: ValueKey('profile_switch_overlay_active_${targetProfile?.id}'),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.70),
                          child: Center(
                            child: Card(
                              elevation: 8,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              child: SizedBox(
                                width: 320,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: ProfileBadgeHelper.getColor(profileName),
                                            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                                            child: !hasPhoto
                                                ? Text(
                                                    ProfileBadgeHelper.getInitial(profileName),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Switching workspace...',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        displayName,
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: colorScheme.onSurface,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isGoogleAuthView) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.primaryContainer
                                                              .withValues(alpha: 0.7),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          targetProfile.name,
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
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      syncEngine.icon,
                                                      size: 12,
                                                      color: colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      syncEngine.label,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontSize: 11,
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (displayEmail != null) ...[
                                                      Text(
                                                        ' • ',
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          fontSize: 11,
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          displayEmail,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            fontSize: 11,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const LinearProgressIndicator(minHeight: 3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('profile_switch_overlay_inactive')),
          ),
        ),
      ],
    );
  }
}
