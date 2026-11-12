import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../database/firebase/auth/firebase_provider.dart';
import '../../features/archive/providers/archive_providers.dart';
import '../../features/folders/view/folder_selector.dart';
import '../../features/keybinding/shortcut_config.dart';
import '../../features/trash/providers/trash_providers.dart';
import 'logger.dart';

final appWarmupServiceProvider = NotifierProvider<AppWarmupService, bool>(() {
  return AppWarmupService();
});

/// Service that performs background pre-warming of data streams and UI assets
/// after the main screen notes list has finished initial rendering.
class AppWarmupService extends Notifier<bool> {
  bool _hasWarmedUp = false;
  final List<ProviderSubscription> _subscriptions = [];

  @override
  bool build() {
    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.close();
      }
      _subscriptions.clear();
    });
    return _hasWarmedUp;
  }

  /// Schedules background warm-up after a deferred delay.
  /// Idempotent: Executes at most once per app session.
  void scheduleWarmup(BuildContext context, {Duration delay = const Duration(milliseconds: 500)}) {
    if (_hasWarmedUp) {
      return;
    }

    AppLogger.d('AppWarmupService: Warmup scheduled in ${delay.inMilliseconds}ms...');

    Future.delayed(delay, () {
      if (_hasWarmedUp) return;
      if (context.mounted) {
        _executeWarmup(context);
      }
    });
  }

  void _executeWarmup(BuildContext context) {
    if (_hasWarmedUp) return;
    _hasWarmedUp = true;
    state = true;

    AppLogger.d('AppWarmupService: Executing background warm-up...');

    // 1. Data Warm-up: Keep active subscriptions to secondary stream providers
    _warmupDataStreams();

    // 2. Asset Warm-up: Pre-cache drawer and UI assets
    if (context.mounted) {
      _warmupAssets(context);
    }

    AppLogger.d('AppWarmupService: Background warm-up completed successfully.');
  }

  void _warmupDataStreams() {
    try {
      // Subscribe to active folders stream
      final folderSub = ref.listen(activeFoldersStreamProvider, (previous, next) {
        AppLogger.d('AppWarmupService: activeFoldersStreamProvider primed (${next.value?.length ?? 0} folders)');
      }, fireImmediately: true);
      _subscriptions.add(folderSub);

      // Subscribe to total notes count stream
      final totalCountSub = ref.listen(totalNotesCountStreamProvider, (previous, next) {
        AppLogger.d('AppWarmupService: totalNotesCountStreamProvider primed (${next.value ?? 0} total notes)');
      }, fireImmediately: true);
      _subscriptions.add(totalCountSub);

      // Subscribe to trash notes stream
      final trashSub = ref.listen(trashNotesProvider, (previous, next) {
        AppLogger.d('AppWarmupService: trashNotesProvider primed (${next.value?.length ?? 0} trash items)');
      }, fireImmediately: true);
      _subscriptions.add(trashSub);

      // Subscribe to trash folders stream
      final trashFolderSub = ref.listen(trashFoldersProvider, (previous, next) {
        AppLogger.d('AppWarmupService: trashFoldersProvider primed (${next.value?.length ?? 0} trash folders)');
      }, fireImmediately: true);
      _subscriptions.add(trashFolderSub);

      // Subscribe to archived notes stream
      final archiveSub = ref.listen(archivedNotesStreamProvider, (previous, next) {
        AppLogger.d('AppWarmupService: archivedNotesStreamProvider primed (${next.value?.length ?? 0} archive items)');
      }, fireImmediately: true);
      _subscriptions.add(archiveSub);

      // Subscribe to Firebase Auth state
      final authSub = ref.listen(authStateProvider, (previous, next) {
        AppLogger.d('AppWarmupService: authStateProvider primed (${next.value?.email ?? "Guest"})');
      }, fireImmediately: true);
      _subscriptions.add(authSub);

      // Subscribe to keybindings stream
      final keybindingSub = ref.listen(keybindingsProvider, (previous, next) {
        AppLogger.d('AppWarmupService: keybindingsProvider primed');
      }, fireImmediately: true);
      _subscriptions.add(keybindingSub);

      // Subscribe to synced devices stream
      final deviceSub = ref.listen(syncedDevicesStreamProvider, (previous, next) {
        AppLogger.d('AppWarmupService: syncedDevicesStreamProvider primed');
      }, fireImmediately: true);
      _subscriptions.add(deviceSub);
    } catch (e, st) {
      AppLogger.e('AppWarmupService: Error warming data streams: $e', error: e, stack: st);
    }
  }

  void _warmupAssets(BuildContext context) {
    try {
      if (!context.mounted) return;
      precacheImage(const AssetImage('assets/icons/note_icon.png'), context);
    } catch (e) {
      AppLogger.w('AppWarmupService: Error pre-caching assets: $e');
    }
  }
}
