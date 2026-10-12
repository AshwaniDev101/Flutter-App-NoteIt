import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../../core/app_env.dart';
import '../../../../../core/util/platform_helper.dart';
import '../../../../backup/export_page.dart';
import '../../../../backup/import_page.dart';
import '../../../../dev_tools/dev_page.dart';
import '../../../../local_sync/view/mdns/broadcast/host_broadcast.dart';
import '../../../../local_sync/view/mdns/searcher/host_searcher.dart';
import '../../../../local_sync/view/mdns/searcher/pin_dialog/pin_entry_dialog.dart';
import '../../../../local_sync/view/qr/qr_page.dart';
import '../../../../local_sync/view/qr/qr_scanner/qr_scanner_page.dart';
import '../../../../local_sync/view/role_selector_page.dart';
import '../../../../local_sync/view/synced_list.dart';
import '../../../../note_editor/screens/view/desktop_edit_page.dart';
import '../../../../note_editor/screens/view/note_detail_page.dart';
import '../../../../settings/view/settings_page.dart';
import '../../../../themes/view/theme_page.dart';
import '../../../../trash/trash_page.dart';
import '../../../core/providers.dart';
import 'core/navigator.dart';

class DesktopRightPanel extends ConsumerWidget {
  final Note? activeNote;

  const DesktopRightPanel({super.key, required this.activeNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(desktopRightPanelViewProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final versionString = "v${AppEnv.version}-${AppEnv.buildNumber}";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(versionString, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            leadingWidth: 200,
            scrolledUnderElevation: PlatformHelper.isDesktopScreen ? 0.0 : null,
            actions: [
              IconTray(),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.minimize, size: 16), onPressed: () => windowManager.minimize()),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 16),
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => windowManager.close()),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        child: _buildRightPanelContent(currentView),
      ),
    );
  }

  Widget _buildRightPanelContent(RightPanelPageOptions view) {
    return switch (view) {
      RightPanelPageOptions.allNotes =>
        activeNote != null
            ? DesktopEditNotePage(key: ValueKey(activeNote!.uuid), existingNote: activeNote)
            : const _HomepagePlaceholder(
                key: ValueKey('editor_fallback'),
              ),
      RightPanelPageOptions.trash => const _PaddingWrapper(key: ValueKey('trash_view'), child: TrashPage()),
      RightPanelPageOptions.settings => const _PaddingWrapper(key: ValueKey('settings_view'), child: SettingsPage()),
      RightPanelPageOptions.localSync => const _PaddingWrapper(key: ValueKey('sync_view'), child: RoleSelectorPage()),
      RightPanelPageOptions.themes => const _PaddingWrapper(key: ValueKey('theme_view'), child: ThemesPage()),
      RightPanelPageOptions.devTools => const _PaddingWrapper(key: ValueKey('dev_view'), child: DevPage()),
      RightPanelPageOptions.clientMode => const _PaddingWrapper(key: ValueKey('search_view'), child: HostSearcher()),
      RightPanelPageOptions.hostMode => const _PaddingWrapper(
        key: ValueKey('broadcast_view'),
        child: HostBroadcastPage(),
      ),
      RightPanelPageOptions.syncedList => const _PaddingWrapper(
        key: ValueKey('synced_devices_list_view'),
        child: SyncedDevicesListView(),
      ),
      RightPanelPageOptions.noteDetails => _PaddingWrapper(
        key: const ValueKey('note_details_view'),
        child: NoteDetailsPage(),
      ),
      RightPanelPageOptions.export => const _PaddingWrapper(
        key: ValueKey('export_view'),
        child: ExportNotesPage(),
      ),
      RightPanelPageOptions.import => const _PaddingWrapper(
        key: ValueKey('import_view'),
        child: ImportNotesPage(),
      ),
      RightPanelPageOptions.qr => const _PaddingWrapper(
        key: ValueKey('qr_view'),
        child: QrCodePage(),
      ),
      RightPanelPageOptions.scan => const _PaddingWrapper(
        key: ValueKey('scan_view'),
        child: QrScannerPage(),
      ),
      RightPanelPageOptions.pin => const _PaddingWrapper(
        key: ValueKey('pin_view'),
        child: PinEntryDialog(),
      ),
    };
  }
}

/// A visual placeholder shown when no note is currently selected.
class _HomepagePlaceholder extends StatelessWidget {
  const _HomepagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 64),
          const SizedBox(height: 16),
          Text('No note selected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Select a note from the list or click + to start editing.'),
        ],
      ),
    );
  }
}

/// A visual padding wrapper for selected drawer option pages
class _PaddingWrapper extends StatelessWidget {
  final Widget child;

  const _PaddingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(16.0)), child: child),
    );
  }
}
