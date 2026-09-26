import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:noteit/features/local_sync/provider/sync_server_provider.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';
import '../auto_connect/mdns_broadcast.dart';

// Note: .autoDispose: when no widgets are listening to this provider, destroy the cache
// Without it you will get a same url and ip value you have already fetched before
final syncSessionProvider = FutureProvider.autoDispose<({String ip, String qrUrl, String deviceName, String pin})>((
  ref,
) async {
  // Wait for the background engine
  final hostData = await ref.watch(serverHostingProvider.future);

  // Generate the UI PIN
  final String generatedPin = Random().nextInt(10000).toString().padLeft(4, '0');

  // Schedule the update for immediately AFTER the provider finishes building
  Future.microtask(() {
    ref.read(syncServerProvider.notifier).updatePin(generatedPin);
  });

  // When the user closes the QR screen, erase the PIN from the server.
  ref.onDispose(() {
    print('QR Screen closed. Erasing PIN to lock down server.');
    ref.read(syncServerProvider.notifier).updatePin(null);
  });

  // 5. Build the QR Code URL
  final baseUrl = 'ws://${hostData.ip}:${hostData.port}';
  final qrUrl = '$baseUrl?host_name=${Uri.encodeComponent(hostData.deviceName)}&host_uuid=${hostData.uuid}';

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
          print('Engine: Client connected! Shutting down mDNS broadcast.');
          mdnsNotifier.stopBroadcasting();
        },
        onClientDisconnected: () {
          print('Engine: Client disconnected! Restarting mDNS broadcast.');
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

/// Create a FutureProvider to fetch cross-platform device info asynchronously
final deviceInfoProvider = FutureProvider<BaseDeviceInfo>((ref) async {
  final deviceInfoPlugin = DeviceInfoPlugin();

  // .deviceInfo automatically detects the platform and returns a BaseDeviceInfo object
  return await deviceInfoPlugin.deviceInfo;
});

/// Fetch the Local Wi-Fi IP Address
final localIPProvide = FutureProvider<String?>((ref) async {
  // 'NetworkInfo' special package used for getting network info
  return await NetworkInfo().getWifiIP();
});

extension DeviceInfoExtension on BaseDeviceInfo {
  String get extractName {
    if (this is AndroidDeviceInfo) return (this as AndroidDeviceInfo).model;
    if (this is IosDeviceInfo) return (this as IosDeviceInfo).name;
    if (this is WindowsDeviceInfo) {
      return (this as WindowsDeviceInfo).computerName;
    }
    if (this is MacOsDeviceInfo) return (this as MacOsDeviceInfo).computerName;
    if (this is LinuxDeviceInfo) return (this as LinuxDeviceInfo).prettyName;
    if (this is WebBrowserInfo) {
      return (this as WebBrowserInfo).browserName.toString();
    }

    return 'Unknown Device';
  }
}
