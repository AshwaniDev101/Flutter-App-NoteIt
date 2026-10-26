import 'dart:convert';

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

import 'core/util/platform_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/reminder/note_showcase_page.dart';
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

  // Fast synchronous check for sub-window isolate (0ms startup delay)
  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final Map<String, dynamic> argumentData =
        args.length > 2 && args[2].isNotEmpty
            ? jsonDecode(args[2]) as Map<String, dynamic>
            : <String, dynamic>{};

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: NoteShowcaseMultiWindow(
          windowId: windowId,
          title: argumentData['title'] as String? ?? 'Untitled Note',
          content: argumentData['content'] as String? ?? '',
          folderName: argumentData['folderName'] as String?,
          colorIndex: argumentData['colorIndex'] as int?,
          reminderAtStr: argumentData['reminderAt'] as String?,
        ),
      ),
    );
    return;
  }

  await SharedPreferenceManager.init();
  await ReminderManager().init();

  if (PlatformHelper.isNativeDesktop) {
    // Remove default Windows frame and initialize window/tray manager
    await windowManager.ensureInitialized();
    await DesktopTrayHandler.instance.init();

    final savedWidth = SharedPreferenceManager.instance.windowWidth;
    final savedHeight = SharedPreferenceManager.instance.windowHeight;

    const minWindowSize = Size(360, 500);

    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      size: Size(savedWidth, savedHeight),
      minimumSize: minWindowSize,
      center: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(minWindowSize);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Allow us to print app version in UI
  final packageInfo = await PackageInfo.fromPlatform();
  AppEnv.init(packageInfo);

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
