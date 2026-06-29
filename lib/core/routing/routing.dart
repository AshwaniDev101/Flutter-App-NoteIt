import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/edit_note_page/screens/view/edit_note_page.dart';
import 'package:noteit/features/home_page/screens/view/home_page.dart';
import 'package:noteit/features/home_page/screens/view/theme_page.dart';
import 'package:noteit/features/settings_page/screens/view/settings_page.dart';

import 'package:noteit/database/drift/drift_database.dart';
import '../../features/settings_page/screens/view/options/master_password_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String edit = '/edit-note';
  static const String search = '/search';
  static const String themes = '/themes';
  static const String settings = '/settings';
  static const String masterPassword = '/master-password';
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
    ],
  );
});
