import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/local_sync/view/role_selector_page.dart';
import 'package:noteit/features/note_editor/screens/view/details/detail_page.dart';
import 'package:noteit/features/others/archive_page.dart';

import '../../database/drift/notes/notes_dao.dart';
import '../../features/backup/export_page.dart';
import '../../features/backup/import_page.dart';
import '../../features/dev_tools/dev_page.dart';
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
import '../../features/settings/view/settings_page.dart';
import '../../features/themes/view/theme_page.dart';
import '../../features/others/trash_page.dart';
import '../util/platform_helper.dart';

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
}

final routerProvider = Provider((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    // initialLocation: AppRoutes.backup,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          if (PlatformHelper.isDesktopScreen) {
            return DesktopHomePanel();
          } else {
            return MobileHomePage();
          }
        },
      ),
      GoRoute(
        path: AppRoutes.edit,
        builder: (context, state) {
          final noteWithFolder = state.extra as NoteWithFolder?;

          if (PlatformHelper.isDesktopScreen) {
            return DesktopEditNotePage(existingNoteWithFolder: noteWithFolder);
          } else {
            return MobileEditNotePage(existingNoteWithFolder: noteWithFolder);
          }
        },
      ),

      GoRoute(
        path: AppRoutes.themes,
        builder: (context, state) {
          return ThemesPage();
        },
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) {
          return SettingsPage();
        },
      ),

      // GoRoute(
      //   path: AppRoutes.masterPassword,
      //   builder: (context, state) {
      //     return const MasterPasswordPage();
      //   },
      // ),
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



      // Do not forget to update the navigator.dart file in
      // lib/features/home/view/desktop/right_panel/core/navigator.dart
    ],
  );
});
