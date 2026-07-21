import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/firebase_options.dart';
import 'package:noteit/shared/widgets/snack_bar_manager.dart';

import 'core/theme/app_theme.dart';

// Build Command: flutter build windows
// Built location: build\windows\x64\runner\Release\noteit.exe
// Get Git Diff : git diff HEAD | clip
// Build drift db : dart run build_runner build -d
// Drift database location Windows : C:\Users\Ashwin\Documents\my_notes_db.sqlite


// TODO:
// 1. when lock is open during a session we still see the lock icon, there should be a tiny unlock icon on the lock when it lockable note but unlock during the session,
// 2. when lock is open in editor, the message 'Unlock note' should be replaced with 'Remove Lock' and click that should not as for a master password as ur in the editor page because u already have the password,

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferenceManager.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: _MyApp(),
    ),
  );
}

class _MyApp extends ConsumerWidget {
  const _MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    //  Watch the active theme state from your provider
    final activeTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'NoteIt',

      // Resolve the ThemeData dynamically using your unified Themes class
      theme: Themes.getThemeData(activeTheme),

    );
  }
}