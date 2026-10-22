import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/features/home/core/providers.dart';

// To Navigate to Any page use
// ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteEditor);

final drawerNavigationProvider = Provider((ref) {
  return DrawerNavigationController(ref);
});

class DrawerNavigationController {
  final Ref ref;
  DrawerNavigationController(this.ref);

  void navigate(BuildContext context, RightPanelPageOptions option) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close the drawer
    }

    // The compiler will force you to update this switch if you ever add new enums!
    switch (option) {
      case RightPanelPageOptions.noteEditor:
        if (PlatformHelper.isDesktopScreen) {
          ref.read(desktopRightPanelViewProvider.notifier).pushView(option);
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

      case RightPanelPageOptions.archivePage:
        _handlePlatformRouting(context, option, AppRoutes.archive);
        break;

      case RightPanelPageOptions.clientMode:
        _handlePlatformRouting(context, option, AppRoutes.searchNearBy);
        break;

      case RightPanelPageOptions.hostMode:
        _handlePlatformRouting(context, option, AppRoutes.broadcastNearBy);
        break;

      case RightPanelPageOptions.syncedList:
        _handlePlatformRouting(context, option, AppRoutes.syncedList);
        break;

      case RightPanelPageOptions.noteDetails:
        _handlePlatformRouting(context, option, AppRoutes.noteDetails);
        break;

      case RightPanelPageOptions.export:
        _handlePlatformRouting(context, option, AppRoutes.export);
        break;

      case RightPanelPageOptions.import:
        _handlePlatformRouting(context, option, AppRoutes.import);
        break;

      case RightPanelPageOptions.qr:
        _handlePlatformRouting(context, option, AppRoutes.qr);
        break;

      case RightPanelPageOptions.scan:
        _handlePlatformRouting(context, option, AppRoutes.scan);
        break;

      case RightPanelPageOptions.pin:
        _handlePlatformRouting(context, option, AppRoutes.pin);
        break;

      case RightPanelPageOptions.defaultSettings:
        _handlePlatformRouting(context, option, AppRoutes.defaultSettings);
        break;
    }
  }

  void pop(BuildContext context) {
    if (PlatformHelper.isDesktopScreen) {
      ref.read(desktopRightPanelViewProvider.notifier).popView();
    } else {
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  // A private helper to stop writing the same if/else block
  void _handlePlatformRouting(
    BuildContext context,
    RightPanelPageOptions option,
    String mobileRoute,
  ) {
    if (PlatformHelper.isDesktopScreen) {
      ref.read(desktopRightPanelViewProvider.notifier).pushView(option);
    } else {
      context.push(mobileRoute);
    }
  }
}

enum RightPanelPageOptions {
  noteEditor('All Notes', 'View, search, and manage all your saved notes', Icons.grid_view_rounded),
  trash('Trash', 'Recover deleted items or empty the recycle bin', Icons.delete_outline_rounded),
  themes('Themes', 'Personalize your colors, background, and appearance', Icons.palette_outlined),
  localSync('Local Sync', 'Connect and synchronize across your local network', Icons.phonelink_outlined),
  settings('Settings', 'Configure app preferences, accounts, and behavior', Icons.settings_outlined),
  devTools('Dev Tools', 'Advanced debugging and diagnostic utilities', Icons.bug_report_outlined),
  clientMode('Client Mode', 'Connect to a host device on your network to sync notes', Icons.devices_outlined),
  hostMode('Host Mode', 'Broadcast a local connection for other devices to join and sync', Icons.wifi_tethering_outlined),
  syncedList('Sync List', 'Displays the list of all previously synced devices', Icons.list_alt),
  noteDetails('Note Details', 'Shows all the metadata about the note', Icons.info_outline),
  export('Export Notes', 'Download notes to a file', Icons.download_outlined),
  import('Import Notes', 'Upload notes from a file', Icons.upload_outlined),
  qr('Host QR Code', 'Show QR code for device pairing', Icons.qr_code_outlined),
  scan('Scan QR Code', 'Scan a host QR code to join', Icons.qr_code_scanner_outlined),
  pin('Pairing PIN', 'Enter PIN to pair with device', Icons.pin_outlined),
  archivePage('Archive', 'Archive Notes to reduce clutter', Icons.archive_outlined),
  defaultSettings('Default Layout', 'Configure default views, sort options, and window layout', Icons.tune_outlined);

  final String label;
  final String description;
  final IconData icon;

  const RightPanelPageOptions(this.label, this.description, this.icon);
}
