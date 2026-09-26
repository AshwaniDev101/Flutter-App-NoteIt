import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/device_pairs/synced_devices_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/provider/sync_session_provider.dart';

import 'database/drift/local_database.dart';
import 'features/local_sync/auto_connect/mdns_searcher.dart';
import 'features/local_sync/provider/sync_client_provider.dart';

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
    print('Evaluating Sync State...');

    final spp = ref.read(sharedPreferenceProvider);
    final syncRole = spp.syncRole;

    switch (syncRole) {
      case SyncRole.undefine:
        // Do nothing this is the first time user opened this app, or yet to user local sync function
        break;
      case SyncRole.host: // Last time this user was host
        print('AutoSync [HOST]: Starting background engine...');
        try {
          await ref.read(serverHostingProvider.future);
        } catch (e) {
          print('AutoSync [HOST]: Failed to start engine - $e');
        }
        break;
      case SyncRole.client:
        print('AutoSync [CLIENT]: Initializing connection protocol...');

        final SyncedDevice? host = await ref.read(syncedDevicesDaoProvider).getMostRecentHost();

        if (host == null) {
          print('AutoSync [CLIENT]: No host found in DB.');
          return;
        }

        final clientNotifier = ref.read(syncClientProvider.notifier);
        bool connected = false;

        // Fast Reconnect (Try DB IP first)
        if (host.lastKnownIp != null && host.lastKnownPort != null) {
          print('AutoSync [CLIENT]: Attempting Fast Reconnect to ${host.lastKnownIp}:${host.lastKnownPort}...');
          try {
            await clientNotifier.connectToHost(
              ip: host.lastKnownIp!,
              port: host.lastKnownPort!,
              hostUuid: host.deviceUuid,
              hostName: host.deviceName,
              pin: null, // Silent background connection
            );
            connected = true;
          } catch (e) {
            print('AutoSync [CLIENT]: Fast Reconnect failed. Moving to mDNS fallback...');
          }
        }

        // mDNS Radar Fallback
        if (!connected) {
          print('AutoSync [CLIENT]: Starting mDNS radar...');
          final mdnsResult = await ref.read(mdnsSearcherProvider.notifier).findServer(host.deviceUuid);

          if (mdnsResult != null) {
            print('AutoSync [CLIENT]: Host found via mDNS at ${mdnsResult.ip}:${mdnsResult.port}.');
            try {
              await clientNotifier.connectToHost(
                ip: mdnsResult.ip,
                port: mdnsResult.port,
                hostUuid: host.deviceUuid,
                hostName: host.deviceName,
                pin: null,
              );
              // Connection successful! (Make sure your connectToHost method saves the new IP/Port to DB)
            } catch (e) {
              print('AutoSync [CLIENT]: Failed to connect after mDNS discovery: $e');
            }
          } else {
            print('AutoSync [CLIENT]: mDNS Radar timed out. Host unreachable.');
          }
        }
        break;
    }
  }

  void onAppPaused() {
    print('App went to the background');
    ref.read(mdnsSearcherProvider.notifier).stopScan();
  }

  void onAppResumed() {
    print('App came back to the foreground');

    final syncRole = ref.read(sharedPreferenceProvider).syncRole;

    if (syncRole == SyncRole.host) {
      // HOST LOGIC
      // The user might have connected to a different Wi-Fi network while the app was paused.
      // By invalidating the IP provider, Riverpod fetches the fresh IP.
      // This automatically causes `serverHostingProvider` to rebuild and run your
      // safe IP-checking logic inside `startHosting`!
      print('AutoSync [HOST]: Re-checking Wi-Fi IP...');

      ref.invalidate(localIPProvide); // Forces the IP to refresh

      // Re-trigger the state evaluation to ensure everything is running smoothly
      _evaluateSyncState();
    } else if (syncRole == SyncRole.client) {
      // CLIENT LOGIC
      // Check if the OS killed our WebSocket connection while we were asleep
      final currentConnection = ref.read(syncClientProvider);

      if (currentConnection == null) {
        print('AutoSync [CLIENT]: WebSocket was killed in background. Reconnecting...');
        // Run the Fast Reconnect / mDNS Radar logic again
        _evaluateSyncState();
      } else {
        print('AutoSync [CLIENT]: WebSocket survived the background pause!');
      }
    }
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../database/drift/device_pairs/synced_devices_dao.dart';
// import '../../../database/shared_preference/shared_preference_manager.dart';
// import 'features/local_sync/auto_connect/mdns_searcher.dart';
// import 'features/local_sync/provider/sync_client_provider.dart';
// import 'features/local_sync/provider/sync_server_provider.dart';
// import 'features/local_sync/provider/sync_session_provider.dart';

// final autoSyncManagerProvider = NotifierProvider<AutoSyncManager, void>(() {
//   return AutoSyncManager();
// });

// class AutoSyncManager extends Notifier<void> with WidgetsBindingObserver {
//   // Cache for Fast Reconnects (Client Mode)
//   String? _lastIp;
//   int? _lastPort;
//   String? _lastUuid;
//   String? _lastName;
//
//   // Subscription to keep the Host server alive dynamically
//   ProviderSubscription? _hostSubscription;
//
//   @override
//   void build() {
//     WidgetsBinding.instance.addObserver(this);
//
//     ref.onDispose(() {
//       WidgetsBinding.instance.removeObserver(this);
//       _hostSubscription?.close(); // Clean up if manager dies
//     });
//
//     // Listen to the mDNS Radar (Only used in Client Mode)
//     ref.listen(mdnsSearcherProvider, _onRadarUpdated);
//
//     // Run startup logic
//     _onAppResumed();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _onAppResumed();
//     } else if (state == AppLifecycleState.paused) {
//       _onAppPaused();
//     }
//   }
//
//   void _onAppPaused() {
//     // 1. Stop scanning to save battery
//     ref.read(mdnsSearcherProvider.notifier).stopScan();
//
//     // 2. We DO NOT disconnect the WebSockets.
//     // Let the OS decide if it wants to kill them while the user is away.
//     print('AutoSync: App paused. WebSockets left alive.');
//   }
//
//   Future<void> _onAppResumed() async {
//     // Determine the role from SharedPreferences
//     // ⚠️ Make sure `isSyncHost` exists in your shared preferences manager!
//     final isHost = ref.read(sharedPreferenceProvider).isSyncHost ?? false;
//
//     if (isHost) {
//       _startHostMode();
//     } else {
//       _startClientMode();
//     }
//   }
//
//   // ==========================================
//   // HOST MODE LOGIC
//   // ==========================================
//   void _startHostMode() {
//     print('AutoSync [HOST]: Ensuring server is running...');
//
//     // Disconnect client if we were previously in client mode
//     ref.read(syncClientProvider.notifier).disconnect();
//
//     // Use listenManual to dynamically keep the autoDispose syncSessionProvider alive.
//     // Because it references your existing code, this will automatically:
//     // 1. Fetch IP 2. Generate PIN 3. Start Server 4. Start mDNS Broadcast
//     _hostSubscription ??= ref.listenManual(syncSessionProvider, (previous, next) {
//       if (next.hasError) {
//         print('AutoSync [HOST]: Failed to start silently - ${next.error}');
//       } else if (next.hasValue) {
//         print('AutoSync [HOST]: Server is silently running in the background!');
//       }
//     });
//   }
//
//   // ==========================================
//   // CLIENT MODE LOGIC
//   // ==========================================
//   Future<void> _startClientMode() async {
//     // 1. Shut down host server if we were previously in host mode
//     if (_hostSubscription != null) {
//       _hostSubscription?.close();
//       _hostSubscription = null;
//
//       // We MUST explicitly stop the server because your syncServerProvider is not autoDispose
//       ref.read(syncServerProvider.notifier).stopHosting();
//       print('AutoSync [CLIENT]: Shut down host server.');
//     }
//
//     // 2. If the socket survived the pause, we don't need to do anything!
//     if (ref.read(syncClientProvider) != null) {
//       print('AutoSync [CLIENT]: Socket survived the pause!');
//       return;
//     }
//
//     // 3. FAST DIRECT RECONNECT: Try the last known IP first before starting the radar
//     if (_lastIp != null && _lastPort != null && _lastUuid != null) {
//       print('AutoSync [CLIENT]: Attempting fast reconnect to $_lastName...');
//       try {
//         await ref.read(syncClientProvider.notifier).connectToHost(
//           ip: _lastIp!, port: _lastPort!, hostUuid: _lastUuid!, hostName: _lastName ?? 'Host',
//         );
//         return; // Success! No need to scan.
//       } catch (e) {
//         print('AutoSync [CLIENT]: Fast reconnect failed. Starting Radar...');
//       }
//     }
//
//     // 4. SLOW RECONNECT: Start the radar
//     ref.read(mdnsSearcherProvider.notifier).startRadar();
//   }
//
//   // ==========================================
//   // INVISIBLE RADAR (Auto-Connect)
//   // ==========================================
//   Future<void> _onRadarUpdated(MdnsState? previous, MdnsState next) async {
//     // If we are already connected OR we are currently the Host, ignore radar updates
//     final isHost = ref.read(sharedPreferenceProvider).isSyncHost ?? false;
//     if (isHost || ref.read(syncClientProvider) != null) return;
//
//     for (var service in next.devices) {
//       if (service.txt != null && service.txt!.containsKey('uuid')) {
//         final hostUuid = utf8.decode(service.txt!['uuid']!);
//
//         // Use your existing drift DAO
//         final isKnown = await ref.read(devicePairsDaoProvider).isDeviceKnown(hostUuid);
//
//         if (isKnown) {
//           final ip = service.host ?? service.addresses?.firstOrNull?.address;
//           final port = service.port;
//           final hostName = service.name ?? 'Known Device';
//
//           if (ip != null && port != null) {
//             print('AutoSync [CLIENT]: Found known device ($hostName) via Radar! Connecting...');
//
//             // Stop scanning so we don't drain the battery
//             ref.read(mdnsSearcherProvider.notifier).stopScan();
//
//             try {
//               // Use your existing client provider
//               await ref.read(syncClientProvider.notifier).connectToHost(
//                 ip: ip, port: port, hostUuid: hostUuid, hostName: hostName,
//               );
//
//               // Cache details for fast reconnect next time
//               _lastIp = ip;
//               _lastPort = port;
//               _lastUuid = hostUuid;
//               _lastName = hostName;
//
//             } catch (e) {
//               print('AutoSync [CLIENT]: Auto-connect failed: $e');
//             }
//             break;
//           }
//         }
//       }
//     }
//   }
// }
