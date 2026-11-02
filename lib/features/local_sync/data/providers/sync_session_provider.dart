import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/util/device_info.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';

final syncSessionProvider = FutureProvider.autoDispose<({String ip, String qrUrl, String deviceName, String pin})>((
    ref,
    ) async {
  final hostData = await ref.watch(serverHostingProvider.future);

  final String generatedPin = Random().nextInt(10000).toString().padLeft(4, '0');

  final serverNotifier = ref.read(syncServerProvider.notifier);

  Future.microtask(() {
    serverNotifier.updatePin(generatedPin);
  });

  ref.onDispose(() {
    AppLogger.d('SyncSessionProvider: QR Screen closed. Erasing PIN to lock down server.');
    serverNotifier.updatePin(null);
  });

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

  return (ip: hostData.ip, qrUrl: qrUrl, deviceName: hostData.deviceName, pin: generatedPin);
});

final serverHostingProvider = FutureProvider<({String ip, int port, String deviceName, String uuid})>((ref) async {
  final String? ip = await ref.watch(localIPProvide.future);

  if (ip == null) {
    throw Exception('Please connect to Wi-Fi to host a sync session.');
  }
  final mdnsNotifier = ref.read(mdnsBroadcastProvider.notifier);
  final String uuid = ref.read(sharedPreferenceProvider).hostUuid;
  final String deviceName = (await ref.watch(deviceInfoProvider.future)).extractName;

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

  await mdnsNotifier.startBroadcasting(port: assignedPort, uuid: uuid, deviceName: deviceName);

  return (ip: ip, port: assignedPort, deviceName: deviceName, uuid: uuid);
});
