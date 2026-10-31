import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:noteit/shared/app_bars/desktop_window_controls.dart';

import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/backup/export_page.dart';
import 'package:noteit/features/backup/import_page.dart';
import 'package:noteit/features/dev_tools/dev_page.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/local_sync/view/mdns/broadcast/host_broadcast.dart';
import 'package:noteit/features/local_sync/view/mdns/searcher/host_searcher.dart';
import 'package:noteit/features/local_sync/view/mdns/searcher/pin_dialog/pin_entry_dialog.dart';
import 'package:noteit/features/local_sync/view/qr/qr_page.dart';
import 'package:noteit/features/local_sync/view/qr/qr_scanner/qr_scanner_page.dart';
import 'package:noteit/features/local_sync/view/role_selector_page.dart';
import 'package:noteit/features/local_sync/view/synced_list.dart';
import 'package:noteit/features/note_editor/screens/view/desktop_edit_page.dart';
import 'package:noteit/features/note_editor/screens/view/details/detail_page.dart';
import 'package:noteit/features/archive/view/archive_page.dart';
import 'package:noteit/features/folders/view/move_to_folder_page.dart';
import 'package:noteit/features/trash/view/trash_page.dart';
import 'package:noteit/features/reminder/reminder_settings_page.dart';
import 'package:noteit/features/themes/view/theme_page.dart';

import '../../../../settings/default_layout/default_settings_page.dart';
import '../../../../settings/keybindings/keybinding_settings_page.dart';
import '../../../../settings/note_editor/note_editor_settings_page.dart';
import '../../../../settings/settings_page.dart';
import '../../../../settings/time_format/time_settings_page.dart';

class DesktopContentPanel extends ConsumerWidget {
  final NoteWithFolder? activeNoteWithFolder;

  const DesktopContentPanel({super.key, required this.activeNoteWithFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewStack = ref.watch(desktopRightPanelViewProvider);
    final currentView = viewStack.isEmpty ? RightPanelPageOptions.noteEditor : viewStack.last;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () {
          ref.read(desktopRightPanelViewProvider.notifier).popView();
        },
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            // Move DragToMoveArea to the background layer
            flexibleSpace: DragToMoveArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            elevation: 0,
            scrolledUnderElevation: PlatformHelper.isWideLayout(context) ? 0.0 : null,
            actions: const [
              IconTray(),
              DesktopWindowControls(),
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
      ),
    );
  }

  Widget _buildRightPanelContent(RightPanelPageOptions view) {
    switch (view) {
      case RightPanelPageOptions.noteEditor:
        return activeNoteWithFolder != null
            ? _PaddingWrapper(
                key: ValueKey('editor_view_${activeNoteWithFolder!.note.uuid}'),
                child: DesktopEditNotePage(key: ValueKey(activeNoteWithFolder!.note.uuid), existingNoteWithFolder: activeNoteWithFolder),
              )
            : const _HomepagePlaceholder(
                key: ValueKey('editor_fallback'),
              );
      case RightPanelPageOptions.trash:
        return const _PaddingWrapper(key: ValueKey('trash_view'), child: TrashPage());
      case RightPanelPageOptions.settings:
        return const _PaddingWrapper(key: ValueKey('settings_view'), child: SettingsPage());
      case RightPanelPageOptions.localSync:
        return const _PaddingWrapper(key: ValueKey('sync_view'), child: RoleSelectorPage());
      case RightPanelPageOptions.themes:
        return const _PaddingWrapper(key: ValueKey('theme_view'), child: ThemesPage());
      case RightPanelPageOptions.devTools:
        return const _PaddingWrapper(key: ValueKey('dev_view'), child: DevPage());
      case RightPanelPageOptions.clientMode:
        return const _PaddingWrapper(key: ValueKey('search_view'), child: HostSearcher());
      case RightPanelPageOptions.hostMode:
        return const _PaddingWrapper(
          key: ValueKey('broadcast_view'),
          child: HostBroadcastPage(),
        );
      case RightPanelPageOptions.syncedList:
        return const _PaddingWrapper(
          key: ValueKey('synced_devices_list_view'),
          child: SyncedDevicesListView(),
        );
      case RightPanelPageOptions.noteDetails:
        return _PaddingWrapper(
          key: const ValueKey('note_details_view'),
          child: NoteDetailsPage(),
        );
      case RightPanelPageOptions.export:
        return const _PaddingWrapper(
          key: ValueKey('export_view'),
          child: ExportNotesPage(),
        );
      case RightPanelPageOptions.import:
        return const _PaddingWrapper(
          key: ValueKey('import_view'),
          child: ImportNotesPage(),
        );
      case RightPanelPageOptions.qr:
        return const _PaddingWrapper(
          key: ValueKey('qr_view'),
          child: QrCodePage(),
        );
      case RightPanelPageOptions.scan:
        return const _PaddingWrapper(
          key: ValueKey('scan_view'),
          child: QrScannerPage(),
        );
      case RightPanelPageOptions.pin:
        return const _PaddingWrapper(
          key: ValueKey('pin_view'),
          child: PinEntryDialog(),
        );
      case RightPanelPageOptions.archivePage:
        return const _PaddingWrapper(
          key: ValueKey('archive_view'),
          child: ArchivePage(),
        );
      case RightPanelPageOptions.defaultSettings:
        return const _PaddingWrapper(
          key: ValueKey('default_settings_view'),
          child: DefaultSettingsPage(),
        );
      case RightPanelPageOptions.reminderSettings:
        return const _PaddingWrapper(
          key: ValueKey('reminder_settings_view'),
          child: ReminderSettingsPage(),
        );
      case RightPanelPageOptions.moveToFolder:
        return const _PaddingWrapper(
          key: ValueKey('move_to_folder_view'),
          child: MoveToFolderPage(),
        );
      case RightPanelPageOptions.timeSettings:
        return const _PaddingWrapper(
          key: ValueKey('time_settings_view'),
          child: TimeSettingsPage(),
        );
      case RightPanelPageOptions.noteEditorSettings:
        return const _PaddingWrapper(
          key: ValueKey('note_editor_settings_view'),
          child: NoteEditorSettingsPage(),
        );
      case RightPanelPageOptions.keybindingSettings:
        return const _PaddingWrapper(
          key: ValueKey('keybinding_settings_view'),
          child: KeybindingSettingsPage(),
        );
    }
  }
}

/// A visual placeholder shown when no note is currently selected.
class _HomepagePlaceholder extends StatelessWidget {
  const _HomepagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SelectableText(
                  'Select a note from the list or press ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                  ' to create a new note.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          ],
        ),
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
      // 12 because of the divider is 4x
      padding: const EdgeInsets.only(left: 12, right: 16, bottom: 16),
      child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(16.0)), child: child),
    );
  }
}
