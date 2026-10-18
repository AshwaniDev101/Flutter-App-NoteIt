import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/others/archive_page.dart';
import 'package:window_manager/window_manager.dart';
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
import '../../../../note_editor/screens/view/details/detail_page.dart';
import '../../../../settings/view/settings_page.dart';
import '../../../../themes/view/theme_page.dart';
import '../../../../others/trash_page.dart';
import '../../../core/providers.dart';
import 'core/navigator.dart';

class DesktopContentPanel extends ConsumerWidget {
  final Note? activeNote;

  const DesktopContentPanel({super.key, required this.activeNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(desktopRightPanelViewProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          // Move DragToMoveArea to the background layer
          flexibleSpace: DragToMoveArea(
            child: Container(
              // The container must have a color (even transparent) to register mouse hits
              color: Colors.transparent,
            ),
          ),
          // backgroundColor: Colors.red,

          elevation: 0,
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
            ? _PaddingWrapper(
                key: ValueKey('editor_view_${activeNote!.uuid}'),
                child: DesktopEditNotePage(key: ValueKey(activeNote!.uuid), existingNote: activeNote),
              )
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

      RightPanelPageOptions.archivePage => const _PaddingWrapper(
        key: ValueKey('archive_view'),
        child: ArchivePage(),
      ),

    };
  }
}

/// A visual placeholder shown when no note is currently selected.
/// A visual placeholder shown when no note is currently selected.
class _HomepagePlaceholder extends StatelessWidget {
  const _HomepagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          SelectableText(
            'No note selected',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SelectableText(
                'Select a note from the list or press',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              // FAB-like Icon Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),

              SelectableText(
                'to create a new note.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          )
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
      // padding: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.only(left: 16,right: 16,bottom: 16),
      child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(16.0)), child: child),
    );
  }
}
