import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_profile_dialog.dart';
import 'manage_profiles_sheet.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile_model.dart';
import '../../profiles/profile_providers.dart';

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
                    return ListTile(
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

                      subtitle: activeProfile.isDefault?Text("default"):null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                          : null,
                      onTap: () async {
                        _menuController.close();
                        if (!isSelected) {
                          await ref.read(activeProfileProvider.notifier).switchProfile(profile);
                        }
                      },
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

  String _getAvatarLetter(Profile profile) {
    if (profile.name.trim().isNotEmpty) {
      return profile.name.trim()[0].toUpperCase();
    }
    return 'P';
  }
}