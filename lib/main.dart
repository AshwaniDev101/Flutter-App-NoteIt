import 'dart:io' show Platform; // Added for platform checking
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Added for web checking
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/firebase_options.dart';
import 'package:noteit/shared/snack_bar_manager.dart';

import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferenceManager.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only initialize GoogleSignIn on platforms where it is supported natively
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    await GoogleSignIn.instance.initialize(
      clientId: '707715729232-ulbe4pm7fn9jbn11usgqtrkn3ov11q2h.apps.googleusercontent.com',
    );
  }

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
      // themeMode: ThemeMode.system,
      themeMode: ThemeMode.dark,
    );
  }
}