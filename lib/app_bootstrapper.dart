import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:noteit/core/config/app_env.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/folders/folders_dao.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/folders/providers/folder_providers.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/reminder/reminder_manager.dart';
import 'package:noteit/features/tray/window_tray.dart';
import 'package:noteit/features/workspace/data/workspace_repository.dart';
import 'package:noteit/firebase_options.dart';

class AppBootstrapper {
  static Future<List<Override>> init() async {
    // Core Services
    await SharedPreferenceManager.init();
    await WorkspaceRepository.init();
    
    // Create a temporary container just for reading DBs during initialization
    final tempContainer = ProviderContainer();
    await ReminderManager().init(tempContainer);

    // Desktop Window Config
    if (PlatformHelper.isNativeDesktop) {
      await _initDesktopWindow();
    }

    // Third-party Async configs (Firebase, PackageInfo)
    await _initThirdPartyServices();

    // Pre-load the UI State from the DB
    final folderOverride = await _preloadActiveFolder(tempContainer);
    final noteOverride = await _preloadActiveNote(tempContainer);
    
    // Dispose the temporary container as we're about to spin up the real one
    tempContainer.dispose();

    return [
      if (folderOverride != null) folderOverride,
      if (noteOverride != null) noteOverride,
    ];
  }

  static Future<void> _initDesktopWindow() async {
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

  static Future<void> _initThirdPartyServices() async {
    final results = await Future.wait([
      PackageInfo.fromPlatform(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);

    final packageInfo = results[0] as PackageInfo;
    AppEnv.init(packageInfo);
  }

  static Future<Override?> _preloadActiveFolder(ProviderContainer container) async {
    final lastFolderId = SharedPreferenceManager.instance.lastActiveFolderId;
    if (lastFolderId != null) {
      final db = container.read(foldersDaoProvider);
      final folder = await db.getFolderById(lastFolderId);
      if (folder != null && folder.deletedAt == null) {
        return activeFolderProvider.overrideWith(() => ActiveFolderNotifier(initialState: folder));
      } else {
        SharedPreferenceManager.instance.setLastActiveFolderId(null);
      }
    }
    return null;
  }

  static Future<Override?> _preloadActiveNote(ProviderContainer container) async {
    if (!PlatformHelper.isNativeDesktop) return null;

    final lastNoteId = SharedPreferenceManager.instance.lastActiveNoteId;
    if (lastNoteId != null) {
      final db = container.read(notesDaoProvider);
      final noteWithFolder = await db.getNoteById(lastNoteId);

      if (noteWithFolder.note.deletedAt == null && noteWithFolder.note.archivedAt == null) {
        return activeNoteProvider.overrideWith(() => ActiveNoteNotifier(initialState: noteWithFolder));
      } else {
        SharedPreferenceManager.instance.setLastActiveNoteId(null);
      }
    }
    return null;
  }
}
