import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';

import '../../../../core/helpers/platform_helper.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../shared/menus/app_bottom_sheet.dart';
import '../../providers/active_profile_provider.dart';
import '../helpers/profile_badge_helper.dart';
import '../profile_menu_content.dart';
import 'profile_avatar_badge.dart';

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
        return ProfileMenuContent(
          onCloseMenu: () => Navigator.of(bottomSheetContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final authUser = ref.watch(authStateProvider).value;
    final syncMode = ref.watch(syncModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = !PlatformHelper.isWideLayout(context);

    final activePhotoUrl = syncMode.isCloud
        ? ProfileBadgeHelper.getEffectivePhotoUrl(
            activeProfile,
            authUser,
          )
        : null;

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

    final avatarWidget = ProfileAvatarBadge(
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
              child: ProfileMenuContent(
                onCloseMenu: () {
                  if (_menuController.isOpen) _menuController.close();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
