import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_model.dart';
import '../../profiles/profile_providers.dart';
import 'create_profile_dialog.dart';
import 'manage_profiles_sheet.dart';

/// Full-width profile switcher header card rendered at the top of the app drawer.
///
/// Displays the active profile's letter avatar, color badge, name, custom alias,
/// and a popup menu for 1-tap profile switching, profile creation, and profile management.
class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avatarLetter = _getAvatarLetter(activeProfile);
    final profileColor = Color(activeProfile.colorValue);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Switch or manage profiles',
        offset: const Offset(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
        onSelected: (value) async {
          if (value == 'create_profile') {
            showDialog(
              context: context,
              builder: (ctx) => const CreateProfileDialog(),
            );
          } else if (value == 'manage_profiles') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const ManageProfilesSheet(),
            );
          } else {
            final selected = ref.read(profilesListProvider).firstWhere((p) => p.id == value);
            await ref.read(activeProfileProvider.notifier).switchProfile(selected);
          }
        },
        itemBuilder: (ctx) {
          final items = <PopupMenuEntry<String>>[];

          // 1. List of profiles
          for (final profile in profiles) {
            final isSelected = profile.id == activeProfile.id;
            final itemLetter = _getAvatarLetter(profile);
            final itemColor = Color(profile.colorValue);

            items.add(
              PopupMenuItem<String>(
                value: profile.id,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        itemLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (profile.customAlias != null && profile.customAlias!.isNotEmpty)
                            Text(
                              profile.customAlias!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                  ],
                ),
              ),
            );
          }

          items.add(const PopupMenuDivider());

          // 2. Actions
          items.add(
            PopupMenuItem<String>(
              value: 'create_profile',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Create New Profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );

          items.add(
            PopupMenuItem<String>(
              value: 'manage_profiles',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Manage Profiles',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );

          return items;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Avatar circle with letter
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: profileColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile Name & Custom Alias
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeProfile.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activeProfile.customAlias != null && activeProfile.customAlias!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          activeProfile.customAlias!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant, size: 24),
            ],
          ),
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
}
