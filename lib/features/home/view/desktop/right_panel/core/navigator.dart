import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../../../../core/routing/routing.dart';
import '../../../../../../core/util/platform_helper.dart';
import '../../../../core/providers.dart';


final drawerNavigationProvider = Provider((ref) {
  return DrawerNavigationController(ref);
});

class DrawerNavigationController {
  final Ref ref;
  DrawerNavigationController(this.ref);

  void navigate(BuildContext context, RightPanelPageOptions option) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();// Close the drawer
    }

    // The compiler will force you to update this switch if you ever add new enums!
    switch (option) {
      case RightPanelPageOptions.allNotes:
        if (PlatformHelper.isDesktopScreen) {
          ref.read(desktopRightPanelViewProvider.notifier).setView(option);
        }
        break;

      case RightPanelPageOptions.trash:
        _handlePlatformRouting(context, option, AppRoutes.trash);
        break;

      case RightPanelPageOptions.themes:
        _handlePlatformRouting(context, option, AppRoutes.themes);
        break;

      case RightPanelPageOptions.localSync:
        _handlePlatformRouting(context, option, AppRoutes.roleSelector);
        break;

      case RightPanelPageOptions.settings:
        _handlePlatformRouting(context, option, AppRoutes.settings);
        break;

      case RightPanelPageOptions.devTools:
        _handlePlatformRouting(context, option, AppRoutes.dev);
        break;

      case RightPanelPageOptions.clientMode:
        _handlePlatformRouting(context, option, AppRoutes.searchNearBy);
        break;
      case RightPanelPageOptions.hostMode:
        _handlePlatformRouting(context, option, AppRoutes.broadcastNearBy);
      // Explicitly ignored here, but included so the switch is exhaustive
        break;
    }
  }

  // A private helper to stop writing the same if/else block 5 times!
  void _handlePlatformRouting(
      BuildContext context,
      RightPanelPageOptions option,
      String mobileRoute,
      ) {
    if (PlatformHelper.isDesktopScreen) {
      ref.read(desktopRightPanelViewProvider.notifier).setView(option);
    } else {
      context.push(mobileRoute);
    }
  }
}

enum RightPanelPageOptions {
  allNotes('All Notes', 'View, search, and manage all your saved notes', Icons.grid_view_rounded),
  trash('Trash', 'Recover deleted items or empty the recycle bin', Icons.delete_outline_rounded),
  themes('Themes', 'Personalize your colors, background, and appearance', Icons.palette_outlined),
  localSync('Local Sync', 'Connect and synchronize across your local network', Icons.phonelink_outlined),
  settings('Settings', 'Configure app preferences, accounts, and behavior', Icons.settings_outlined),
  devTools('Dev Tools', 'Advanced debugging and diagnostic utilities', Icons.bug_report_outlined),
  clientMode('Client Mode', 'Connect to a host device on your network to sync notes', Icons.devices_outlined),
  hostMode(
    'Host Mode',
    'Broadcast a local connection for other devices to join and sync',
    Icons.wifi_tethering_outlined,
  );

  final String label;
  final String description;
  final IconData icon;

  const RightPanelPageOptions(this.label, this.description, this.icon);

}