import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:noteit/features/local_sync/data/providers/sync_session_provider.dart';
import 'package:noteit/features/reminder/reminder_manager.dart';

final startupInitializerProvider = NotifierProvider<StartupInitializer, void>(() {
  return StartupInitializer();
});

class StartupInitializer extends Notifier<void> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isEvaluating = false;

  @override
  void build() {
    // Start listening as soon as the service is created
    _lifecycleListener = AppLifecycleListener(onPause: () => onAppPaused(), onResume: () => onAppResumed());

    ref.onDispose(() {
      _lifecycleListener.dispose();
    });

    Future.microtask(() => _evaluateSyncState());
  }

  void _evaluateSyncState() async {
    if (_isEvaluating) {
      AppLogger.d('StartupInitializer: Sync state evaluation already in progress. Skipping duplicate.');
      return;
    }
    _isEvaluating = true;

    try {
      AppLogger.d('StartupInitializer: Evaluating Sync State & Rearming Reminders...');

      ReminderManager().rearmPendingReminders();

      final mode = ref.read(syncModeProvider);

      if (!mode.isLocal) {
        AppLogger.d('StartupInitializer: SyncMode is $mode (not local). Skipping local sync startup.');
        return;
      }

      switch (mode) {
        case SyncMode.localUndefined:
        case SyncMode.offline:
        case SyncMode.cloud:
          AppLogger.d('StartupInitializer: SyncMode is $mode. No auto local initialization required.');
          break;
        case SyncMode.localHost: // Last time this user was host
          AppLogger.d('StartupInitializer: Sync Role: Host');
          final hasPaired = await ref.read(syncedDevicesDaoProvider).hasPairedDevices();
          if (!hasPaired) {
            AppLogger.d('StartupInitializer: AutoSync [HOST]: No paired devices in DB. Resetting mode to offline.');
            await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
            return;
          }
          AppLogger.d('StartupInitializer: AutoSync [HOST]: Starting background engine...');
          try {
            await ref.read(serverHostingProvider.future);
          } catch (e) {
            AppLogger.d('StartupInitializer: AutoSync [HOST]: Failed to start engine - $e');
          }
          break;
        case SyncMode.localClient:
          AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Initializing connection protocol...');
          await ref.read(syncClientProvider.notifier).autoConnectToPairedHost();
          break;
      }
    } finally {
      _isEvaluating = false;
    }
  }

  void onAppPaused() {
    AppLogger.d('StartupInitializer: App went to the background');

    final mode = ref.read(syncModeProvider);
    if (!mode.isLocal) {
      return;
    }

    if (mode.isHost) {
      // Stop the server and unregister mDNS immediately
      // before the OS suspends us and freezes the network state.
      ref.read(syncServerProvider.notifier).stopHosting();
      ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    } else {
      ref.read(mdnsSearcherProvider.notifier).stopScan();
    }
  }

  void onAppResumed() {
    AppLogger.d('StartupInitializer: App came back to the foreground');

    ReminderManager().rearmPendingReminders();

    final mode = ref.read(syncModeProvider);
    if (!mode.isLocal) {
      return;
    }

    if (mode.isHost) {
      // HOST LOGIC
      // The user might have connected to a different Wi-Fi network while the app was paused.
      // By invalidating the IP provider, Riverpod fetches the fresh IP.
      // This automatically causes `serverHostingProvider` to rebuild and run your
      // safe IP-checking logic inside `startHosting`!
      AppLogger.d('StartupInitializer: AutoSync [HOST]: Re-checking Wi-Fi IP...');

      ref.invalidate(localIPProvide); // Forces the IP to refresh

      // Re-trigger the state evaluation to ensure everything is running smoothly
      _evaluateSyncState();
    } else if (mode.isClient) {
      // CLIENT LOGIC
      // Perform active ping probe to check if OS/radio killed TCP socket in background
      final localSync = ref.read(localSyncServiceProvider.notifier);

      localSync.probeConnection(timeout: const Duration(seconds: 2)).then((isAlive) {
        if (!isAlive) {
          AppLogger.w('StartupInitializer: AutoSync [CLIENT]: Ghost connection or dropped socket detected on resume. Reconnecting...');
          ref.read(syncClientProvider.notifier).disconnect();
          _evaluateSyncState();
        } else {
          AppLogger.d('StartupInitializer: AutoSync [CLIENT]: WebSocket connection verified active via ping probe!');
        }
      });
    }
  }
}