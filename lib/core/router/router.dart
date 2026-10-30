import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/local_sync/view/role_selector_page.dart';
import 'package:noteit/features/note_editor/screens/view/details/detail_page.dart';
import 'package:noteit/features/archive/view/archive_page.dart';

import '../../database/drift/notes/notes_dao.dart';
import '../../features/backup/export_page.dart';
import '../../features/backup/import_page.dart';
import '../../features/dev_tools/dev_page.dart';
import '../../features/folders/view/move_to_folder_page.dart';
import '../../features/home/view/desktop/home_page.dart';
import '../../features/home/view/mobile/mobile_home_page.dart';
import '../../features/local_sync/view/mdns/broadcast/host_broadcast.dart';
import '../../features/local_sync/view/mdns/searcher/host_searcher.dart';
import '../../features/local_sync/view/mdns/searcher/pin_dialog/pin_entry_dialog.dart';
import '../../features/local_sync/view/qr/qr_page.dart';
import '../../features/local_sync/view/qr/qr_scanner/qr_scanner_page.dart';
import '../../features/local_sync/view/synced_list.dart';
import '../../features/note_editor/screens/view/desktop_edit_page.dart';
import '../../features/note_editor/screens/view/mobile_edit_page.dart';
import '../../features/reminder/reminder_settings_page.dart';
import '../../features/settings/view/default_settings_page.dart';
import '../../features/settings/view/keybinding_settings.dart';
import '../../features/settings/view/note_editor_settings.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/settings/view/time_settings_page.dart';
import '../../features/themes/view/theme_page.dart';
import '../../features/trash/view/trash_page.dart';
import '../helpers/platform_helper.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const String home = '/';
  static const String edit = '/edit-note';
  static const String search = '/search';
  static const String themes = '/themes';
  static const String settings = '/settings';
  static const String trash = '/trash';
  static const String dev = '/dev';
  static const String roleSelector = '/role-selector';
  static const String searchNearBy = '/search-nearby';
  static const String broadcastNearBy = '/broadcast-nearby';
  static const String qr = '/qr';
  static const String scan = '/qr-scan';
  static const String pin = '/pin-entry';
  static const String export = '/export';
  static const String import = '/import';
  static const String syncedList = '/synced-list';
  static const String noteDetails = '/note-details';
  static const String archive = '/archive';
  static const String defaultSettings = '/default-settings';
  static const String reminderSettings = '/reminder-settings';
  static const String moveToFolder = '/move-to-folder';
  static const String timeSettings = '/time-settings';
  static const String noteEditorSettings = '/note-editor-settings';
  static const String keybindingSettings = '/keybinding-settings';
}

GoRoute _adaptiveRoute({
  required String path,
  required Widget Function(GoRouterState state) mobile,
  required Widget Function(GoRouterState state) desktop,
}) {
  return GoRoute(
    path: path,
    builder: (context, state) => PlatformHelper.isWideLayout(context)
        ? desktop(state)
        : mobile(state),
  );
}

final routerProvider = Provider((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      _adaptiveRoute(
        path: AppRoutes.home,
        mobile: (_) => MobileHomePage(),
        desktop: (_) => DesktopHomePanel(),
      ),
      _adaptiveRoute(
        path: AppRoutes.edit,
        mobile: (state) => MobileEditNotePage(existingNoteWithFolder: state.extra as NoteWithFolder?),
        desktop: (state) => DesktopEditNotePage(existingNoteWithFolder: state.extra as NoteWithFolder?),
      ),

      GoRoute(
        path: AppRoutes.themes,
        builder: (context, state) => ThemesPage(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) {
          return SettingsPage();
        },
      ),

      GoRoute(
        path: AppRoutes.trash,
        builder: (context, state) {
          return const TrashPage();
        },
      ),

      GoRoute(
        path: AppRoutes.dev,
        builder: (context, state) {
          return const DevPage();
        },
      ),

      GoRoute(
        path: AppRoutes.roleSelector,
        builder: (context, state) {
          return const RoleSelectorPage();
        },
      ),

      GoRoute(
        path: AppRoutes.searchNearBy,
        builder: (context, state) {
          return const HostSearcher();
        },
      ),

      GoRoute(
        path: AppRoutes.broadcastNearBy,
        builder: (context, state) {
          return const HostBroadcastPage();
        },
      ),

      GoRoute(
        path: AppRoutes.qr,
        builder: (context, state) {
          return const QrCodePage();
        },
      ),

      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) {
          return const QrScannerPage();
        },
      ),
      GoRoute(path: AppRoutes.pin, builder: (context, state) => const PinEntryDialog()),

      GoRoute(path: AppRoutes.export, builder: (context, state) => const ExportNotesPage()),
      GoRoute(path: AppRoutes.import, builder: (context, state) => const ImportNotesPage()),
      GoRoute(path: AppRoutes.syncedList, builder: (context, state) => const SyncedDevicesListView()),
      GoRoute(path: AppRoutes.noteDetails, builder: (context, state) => const NoteDetailsPage()),

      GoRoute(path: AppRoutes.archive, builder: (context, state) => const ArchivePage()),
      GoRoute(path: AppRoutes.defaultSettings, builder: (context, state) => const DefaultSettingsPage()),
      GoRoute(path: AppRoutes.reminderSettings, builder: (context, state) => const ReminderSettingsPage()),
      GoRoute(path: AppRoutes.moveToFolder, builder: (context, state) => const MoveToFolderPage()),
      GoRoute(path: AppRoutes.timeSettings, builder: (context, state) => const DemoTimeSettingsPage()),
      GoRoute(path: AppRoutes.noteEditorSettings, builder: (context, state) => const NoteEditorSettingsPage()),
      GoRoute(path: AppRoutes.keybindingSettings, builder: (context, state) => const KeybindingSettingsPage()),
    ],
  );
});
