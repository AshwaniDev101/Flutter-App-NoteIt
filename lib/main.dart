import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/firebase_options.dart';
import 'package:noteit/shared/widgets/snack_bar_manager.dart';
import 'package:noteit/startup_initializer.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';

// Window Release : flutter build windows
// Built location: build\windows\x64\runner\Release\noteit.exe
// Get Git Diff : git diff HEAD | clip
// Build drift db : dart run build_runner build -d
// Drift database location Windows : appdata\app-name\my_notes_db.sqlite

// TODO:

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Remove the default windows form and add ability to add a custom one
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden, // Hides the default Windows frame
      size: Size(1400, 900),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {

      await windowManager.show();
      await windowManager.focus();
    });

  }



  await SharedPreferenceManager.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: _MyApp()));
}

class _MyApp extends ConsumerWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(startupInitializerProvider);
    //  Watch the active theme state from your provider
    final activeTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Note-It',

      // Resolve the ThemeData dynamically using your unified Themes class
      theme: Themes.getThemeData(activeTheme),
    );
  }
}
