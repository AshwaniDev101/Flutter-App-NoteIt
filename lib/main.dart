import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/firebase_options.dart';
import 'package:noteit/shared/snack_bar_manager.dart';

import 'core/theme/app_theme.dart';

// Build Command: flutter build windows
// Built location: build\windows\x64\runner\Release\noteit.exe
// Get Git Diff : git diff HEAD | clip


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
  Widget build(BuildContext context, ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'NoteIt',
      theme: Themes.lightThemeData,
      darkTheme: Themes.darkThemeData,
      // themeMode: ThemeMode.light,
      themeMode: ThemeMode.dark,
    );
  }
}