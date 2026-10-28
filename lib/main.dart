import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/app_env.dart';
import 'package:noteit/core/router/router.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/firebase_options.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';
import 'package:noteit/startup_initializer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';

import 'core/helpers/platform_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/reminder/reminder_manager.dart';
import 'features/tray/window_tray.dart';

// Window Release : flutter build windows
// Android Release : flutter run --release
// Built location: build\windows\x64\runner\Release\noteit.exe
// Get Git Diff : git diff HEAD | clip
// Build drift db : dart run build_runner build -d
// Drift database location Windows : appdata\app-name\my_notes_db.sqlite

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  await SharedPreferenceManager.init();
  await ReminderManager().init(container);

  if (PlatformHelper.isNativeDesktop) {
    // Remove default Windows frame and initialize window/tray manager
    await windowManager.ensureInitialized();
    await DesktopTrayHandler.instance.init();

    const minWindowSize = Size(360, 500);

    final savedWidth = math.max(SharedPreferenceManager.instance.windowWidth, minWindowSize.width);
    final savedHeight = math.max(SharedPreferenceManager.instance.windowHeight, minWindowSize.height);

    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      size: Size(savedWidth, savedHeight),
      minimumSize: minWindowSize,
      center: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Allow us to print app version in UI and initialize Firebase concurrently
  final results = await Future.wait([
    PackageInfo.fromPlatform(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  final packageInfo = results[0] as PackageInfo;
  AppEnv.init(packageInfo);

  runApp(UncontrolledProviderScope(container: container, child: const _MyApp()));
}

class _MyApp extends ConsumerWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen(startupInitializerProvider, (_, _) {});
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