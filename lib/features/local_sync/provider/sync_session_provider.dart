import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/local_sync/provider/sync_server_provider.dart';

import '../../../core/config.dart'; // <-- ADDED THIS FOR AppConfig
import '../../../core/device_info.dart';
import '../../../core/util/logger.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../auto_connect/mdns_broadcast.dart';

// Note: .autoDispose: when no shared_widgets are listening to this provider, destroy the cache
// Without it you will get a same url and ip value you have already fetched before
final syncSessionProvider = FutureProvider.autoDispose<({String ip, String qrUrl, String deviceName, String pin})>((
    ref,
    ) async {
  // Wait for the background engine
  final hostData = await ref.watch(serverHostingProvider.future);

  // Generate the UI PIN
  final String generatedPin = Random().nextInt(10000).toString().padLeft(4, '0');

  final serverNotifier = ref.read(syncServerProvider.notifier);

  // Schedule the update for immediately AFTER the provider finishes building
  Future.microtask(() {
    serverNotifier.updatePin(generatedPin);
  });

  // When the user closes the QR screen, erase the PIN from the server.
  ref.onDispose(() {
    AppLogger.d('SyncSessionProvider: QR Screen closed. Erasing PIN to lock down server.');
    serverNotifier.updatePin(null);
  });

  // --- Fetch device info and safely build the QR Code URL ---
  final info = await ref.read(deviceInfoProvider.future);

  final queryParams = {
    'host_uuid': hostData.uuid,
    'host_name': hostData.deviceName,
    'host_platform': info.extractPlatform,
    'v': AppConfig.syncProtocolVersion.toString(),
  };

  final qrUrl = Uri(
    scheme: 'ws',
    host: hostData.ip,
    port: hostData.port,
    queryParameters: queryParams,
  ).toString();
  // --------------------------------------------------------------

  return (ip: hostData.ip, qrUrl: qrUrl, deviceName: hostData.deviceName, pin: generatedPin);
});

/// Master setup provider for the Host screen. It handles 4 steps:
/// 1. Fetches local IP, Device Name, and persistent UUID.
/// 2. Starts the local WebSocket server (getting a dynamic port).
/// 3. Broadcasts the server over mDNS so clients can auto-connect.
/// 4. Returns the final connection URL and IP for the QR code UI.
final serverHostingProvider = FutureProvider<({String ip, int port, String deviceName, String uuid})>((ref) async {
  final String? ip = await ref.watch(localIPProvide.future);

  if (ip == null) {
    throw Exception('Please connect to Wi-Fi to host a sync session.');
  }
  final mdnsNotifier = ref.read(mdnsBroadcastProvider.notifier);
  // ref.watch ties mDNS to this autoDispose provider. When this closes, mDNS dies with it.
  final String uuid = ref.read(sharedPreferenceProvider).hostUuid;
  final String deviceName = (await ref.watch(deviceInfoProvider.future)).extractName;

  // Starts Hosting server and give us Port
  int? assignedPort;

  assignedPort = await ref
      .read(syncServerProvider.notifier)
      .startHosting(
    ip: ip,
    onClientConnected: () {
      AppLogger.d('SyncSessionProvider: Client connected! Shutting down mDNS broadcast.');
      mdnsNotifier.stopBroadcasting();
    },
    onClientDisconnected: () {
      AppLogger.d('SyncSessionProvider: Client disconnected! Restarting mDNS broadcast.');
      if (assignedPort != null) {
        mdnsNotifier.startBroadcasting(port: assignedPort, uuid: uuid, deviceName: deviceName);
      }
    },
  );

  // mDNS (Multicast DNS) acts like a local loudspeaker on the Wi-Fi network.
  // It constantly shouts our server's IP, dynamic port, and unique UUID
  // so client devices can automatically discover us without scanning a QR code every time
  // Start the mDNS Broadcast using the data we just gathered

  await mdnsNotifier.startBroadcasting(port: assignedPort, uuid: uuid, deviceName: deviceName);

  return (ip: ip, port: assignedPort, deviceName: deviceName, uuid: uuid);
});