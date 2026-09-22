import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/features/local_sync/view/search_nearby/host_broadcast.dart';
import 'package:noteit/features/local_sync/view/search_nearby/search_nearby.dart';

import '../../features/dev_tools/dev_page.dart';
import '../../features/home/view/home_page.dart';
import '../../features/local_sync/view/qr/qr_page.dart';
import '../../features/local_sync/view/qr/qr_scanner/qr_scanner_page.dart';
import '../../features/note_editor/screens/view/edit_note_page.dart';
import '../../features/settings/view/options/master_password_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/themes/view/theme_page.dart';
import '../../features/trash/trash_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String edit = '/edit-note';
  static const String search = '/search';
  static const String themes = '/themes';
  static const String settings = '/settings';
  static const String masterPassword = '/master-password';
  static const String trash = '/trash';
  static const String dev = '/dev';
  static const String searchNearBy = '/search-nearby';
  static const String broadcastNearBy = '/broadcast-nearby';
  static const String qr = '/qr';
  static const String scan = '/qr-scan';
}

final routerProvider = Provider((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    // initialLocation: AppRoutes.search,
    routes: <RouteBase>[
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
      GoRoute(
        path: AppRoutes.edit,
        builder: (context, state) {
          final note = state.extra as Note?;
          return EditNotePage(existingNote: note);
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

      GoRoute(
        path: AppRoutes.masterPassword,
        builder: (context, state) {
          return const MasterPasswordPage();
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
        path: AppRoutes.searchNearBy,
        builder: (context, state) {
          return const SearchNearBy();
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
    ],
  );
});
