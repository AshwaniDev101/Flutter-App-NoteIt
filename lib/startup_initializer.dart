import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/provider/sync_session_provider.dart';
import 'package:noteit/shared/snack_bar_manager.dart';

import 'core/config/config.dart';
import 'core/util/device_info.dart';
import 'core/util/logger.dart';
import 'database/drift/local_database.dart';
import 'features/local_sync/auto_connect/mdns_broadcast.dart';
import 'features/local_sync/auto_connect/mdns_searcher.dart';
import 'features/local_sync/provider/sync_client_provider.dart';
import 'features/local_sync/provider/sync_server_provider.dart';

final startupInitializerProvider = NotifierProvider<StartupInitializer, void>(() {
  return StartupInitializer();
});

class StartupInitializer extends Notifier<void> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void build() {
    // Start listening as soon as the service is created
    _lifecycleListener = AppLifecycleListener(onPause: () => onAppPaused(), onResume: () => onAppResumed());

    ref.onDispose(() {
      _lifecycleListener.dispose();
    });

    _evaluateSyncState();
  }

  void _evaluateSyncState() async {
    AppLogger.d('StartupInitializer: Evaluating Sync State...');

    final spp = ref.read(sharedPreferenceProvider);
    final syncRole = spp.syncRole;

    switch (syncRole) {
      case SyncRole.undefine:
        AppLogger.d('StartupInitializer: SyncRole is undefine');
        // Do nothing this is the first time user opened this app, or yet to user local sync function
        break;
      case SyncRole.host: // Last time this user was host
        AppLogger.d('StartupInitializer: Sync Role: Host');
        AppLogger.d('StartupInitializer: AutoSync [HOST]: Starting background engine...');
        try {
          await ref.read(serverHostingProvider.future);
        } catch (e) {
          AppLogger.d('StartupInitializer: AutoSync [HOST]: Failed to start engine - $e');
        }
        break;
      case SyncRole.client:
        AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Initializing connection protocol...');

        final SyncedDevice? host = await ref.read(syncedDevicesDaoProvider).getMostRecentHost();

        if (host == null) {
          AppLogger.d('StartupInitializer: AutoSync [CLIENT]: No host found in DB.');
          return;
        }

        final clientNotifier = ref.read(syncClientProvider.notifier);
        bool connected = false;

// Fast Reconnect (Try DB IP first)
        if (host.lastKnownIp != null && host.lastKnownPort != null) {
          AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Attempting Fast Reconnect to ${host.lastKnownIp}:${host.lastKnownPort}...');
          try {
            await clientNotifier.connectToHost(
              ip: host.lastKnownIp!,
              port: host.lastKnownPort!,
              hostUuid: host.deviceUuid,
              hostName: host.deviceName,
              pin: null,
              devicePlatform: host.deviceType ?? 'unknown',
              protocolVersion: host.protocolVersion ?? 0,
            );
            connected = true;
          } catch (e) {
            AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Fast Reconnect failed. Moving to mDNS fallback...');
          }
        }

        // mDNS Radar Fallback
        if (!connected) {
          AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Starting mDNS radar...');
          final mdnsResult = await ref.read(mdnsSearcherProvider.notifier).findServer(host.deviceUuid);

          if (mdnsResult != null) {
            AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Host found via mDNS at ${mdnsResult.ip}:${mdnsResult.port}.');

            // --- PROTOCOL SAFETY CHECK (Removed the != null check) ---
            if (mdnsResult.protocolVersion != AppConfig.syncProtocolVersion) {
              AppLogger.d('StartupInitializer: AutoSync [CLIENT]: BLOCKING CONNECTION - Version mismatch! Host is v${mdnsResult.protocolVersion}, we are v${AppConfig.syncProtocolVersion}.');
              SnackBarManager.show(msg: "Please update NoteIt on your Device");
              return;
            }
            // -----------------------------------

            try {
              await clientNotifier.connectToHost(
                ip: mdnsResult.ip,
                port: mdnsResult.port,
                hostUuid: host.deviceUuid,
                hostName: host.deviceName,
                pin: null,
                devicePlatform: mdnsResult.deviceType,
                protocolVersion: mdnsResult.protocolVersion,
              );
              // Connection successful!
            } catch (e) {
              AppLogger.d('StartupInitializer: AutoSync [CLIENT]: Failed to connect after mDNS discovery: $e');
            }
          } else {
            AppLogger.d('StartupInitializer: AutoSync [CLIENT]: mDNS Radar timed out. Host unreachable.');
          }
        }
        break;
    }
  }

  void onAppPaused() {
    AppLogger.d('StartupInitializer: App went to the background');

    final syncRole = ref.read(sharedPreferenceProvider).syncRole;

    if (syncRole == SyncRole.host) {
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

    final syncRole = ref.read(sharedPreferenceProvider).syncRole;

    if (syncRole == SyncRole.host) {
      // HOST LOGIC
      // The user might have connected to a different Wi-Fi network while the app was paused.
      // By invalidating the IP provider, Riverpod fetches the fresh IP.
      // This automatically causes `serverHostingProvider` to rebuild and run your
      // safe IP-checking logic inside `startHosting`!
      AppLogger.d('StartupInitializer: AutoSync [HOST]: Re-checking Wi-Fi IP...');

      ref.invalidate(localIPProvide); // Forces the IP to refresh

      // Re-trigger the state evaluation to ensure everything is running smoothly
      _evaluateSyncState();
    } else if (syncRole == SyncRole.client) {
      // CLIENT LOGIC
      // Check if the OS killed our WebSocket connection while we were asleep
      final currentConnection = ref.read(syncClientProvider);

      if (currentConnection == null) {
        AppLogger.d('StartupInitializer: AutoSync [CLIENT]: WebSocket was killed in background. Reconnecting...');
        // Run the Fast Reconnect / mDNS Radar logic again
        _evaluateSyncState();
      } else {
        AppLogger.d('StartupInitializer: AutoSync [CLIENT]: WebSocket survived the background pause!');
      }
    }
  }
}