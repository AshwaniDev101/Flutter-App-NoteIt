import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/router/router.dart';
import 'package:noteit/app_bootstrapper.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';
import 'package:noteit/app_lifecycle_manager.dart';
import 'package:toastification/toastification.dart';

import 'core/theme/app_theme.dart';

// Window Release : flutter build windows
// Android Release : flutter run --release
// Built location: build\windows\x64\runner\Release\noteit.exe
// Get Git Diff : git diff HEAD | clip
// Build drift db : dart run build_runner build -d
// Drift database location Windows : appdata\app-name\my_notes_db.sqlite

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final overrides = await AppBootstrapper.init();
  final container = ProviderContainer(overrides: overrides);

  runApp(UncontrolledProviderScope(
    container: container,
    child: const _MyApp(),
  ));
}

class _MyApp extends ConsumerWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen(appLifecycleManagerProvider, (_, _) {});
    //  Watch the active theme state from your provider
    final activeTheme = ref.watch(themeProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: 'Note-It',

        // Resolve the ThemeData dynamically using your unified Themes class
        theme: Themes.getThemeData(activeTheme),
      ),
    );
  }
}