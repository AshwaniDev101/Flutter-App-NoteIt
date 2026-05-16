
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/features/edit_note_page/screens/view/edit_note_page.dart';
import 'package:noteit/features/home_page/screens/view/home_page.dart';
import 'package:noteit/models/note_model.dart';

import '../../database/drift/drift_database.dart';


class AppRoutes
{
  static const String home = '/';
  static const String edit = '/edit-note';
}


final routerProvider = Provider((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute( path: AppRoutes.home, builder: (context, state) => const HomePage()),
      GoRoute( path: AppRoutes.edit, builder: (context, state) {
        final note =  state.extra as  NoteModel?;

        return EditNotePage(note: note);
  } ),
    ],
  );
});
