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

    if (option == RightPanelPageOptions.noteEditor) {
      if (PlatformHelper.isWideLayout(context)) {
        ref.read(desktopRightPanelViewProvider.notifier).pushView(option);
      }
      return;
    }

    if (PlatformHelper.isWideLayout(context)) {
      ref.read(desktopRightPanelViewProvider.notifier).pushView(option);
    } else {
      context.push(option.route);
    }
  }

  void pop(BuildContext context) {
    if (PlatformHelper.isWideLayout(context)) {
      ref.read(desktopRightPanelViewProvider.notifier).popView();
    } else {
      if (context.canPop()) {
        context.pop();
      }
    }
  }
}

enum RightPanelPageOptions {
  noteEditor('All Notes', 'View, search, and manage all your saved notes', Icons.grid_view_rounded, AppRoutes.home),
  trash('Trash', 'Recover deleted items or empty the recycle bin', Icons.delete_outline_rounded, AppRoutes.trash),
  themes('Themes', 'Personalize your colors, background, and appearance', Icons.palette_outlined, AppRoutes.themes),
  localSync('Local Sync', 'Connect and synchronize across your local network', Icons.phonelink_outlined, AppRoutes.roleSelector),
  settings('Settings', 'Configure app preferences, accounts, and behavior', Icons.settings_outlined, AppRoutes.settings),
  devTools('Dev Tools', 'Advanced debugging and diagnostic utilities', Icons.bug_report_outlined, AppRoutes.dev),
  clientMode('Client Mode', 'Connect to a host device on your network to sync notes', Icons.devices_outlined, AppRoutes.searchNearBy),
  hostMode('Host Mode', 'Broadcast a local connection for other devices to join and sync', Icons.wifi_tethering_outlined, AppRoutes.broadcastNearBy),
  syncedList('Sync List', 'Displays the list of all previously synced devices', Icons.list_alt, AppRoutes.syncedList),
  noteDetails('Note Details', 'Shows all the metadata about the note', Icons.info_outline, AppRoutes.noteDetails),
  export('Export Notes', 'Download notes to a file', Icons.download_outlined, AppRoutes.export),
  import('Import Notes', 'Upload notes from a file', Icons.upload_outlined, AppRoutes.import),
  qr('Host QR Code', 'Show QR code for device pairing', Icons.qr_code_outlined, AppRoutes.qr),
  scan('Scan QR Code', 'Scan a host QR code to join', Icons.qr_code_scanner_outlined, AppRoutes.scan),
  pin('Pairing PIN', 'Enter PIN to pair with device', Icons.pin_outlined, AppRoutes.pin),
  archivePage('Archive', 'Archive Notes to reduce clutter', Icons.archive_outlined, AppRoutes.archive),
  defaultSettings('Default Layout', 'Configure default views, sort options, and window layout', Icons.tune_outlined, AppRoutes.defaultSettings);

  final String label;
  final String description;
  final IconData icon;
  final String route;

  const RightPanelPageOptions(this.label, this.description, this.icon, this.route);
}
