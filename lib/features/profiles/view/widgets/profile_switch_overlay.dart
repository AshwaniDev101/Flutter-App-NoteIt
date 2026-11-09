import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switchingState = ref.watch(profileSwitchingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSwitching = switchingState.isSwitching;
    final targetProfile = switchingState.targetProfile;
    final profileName = targetProfile?.name ?? 'Workspace';

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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                  vertical: 24.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ProfileBadgeHelper.getColor(profileName),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        ProfileBadgeHelper.getInitial(profileName),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Switching workspace...',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profileName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: 140,
                                      child: LinearProgressIndicator(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
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
