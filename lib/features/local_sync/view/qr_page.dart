import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../database/drift/device_pairs/device_pairs_dao.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../auto_connect/mdns_broadcast.dart';
import '../provider/sync_server_provider.dart';

/// Create a FutureProvider to fetch cross-platform device info asynchronously
final deviceInfoProvider = FutureProvider<BaseDeviceInfo>((ref) async {
  final deviceInfoPlugin = DeviceInfoPlugin();

  // .deviceInfo automatically detects the platform and returns a BaseDeviceInfo object
  return await deviceInfoPlugin.deviceInfo;
});

/// Fetch the Local Wi-Fi IP Address
final localIPProvide = FutureProvider.autoDispose<String?>((ref) async {
  // 'NetworkInfo' special package used for getting network info
  return await NetworkInfo().getWifiIP();
});

// Note: .autoDispose: when no widgets are listening to this provider, destroy the cache
// Without it you will get a same url and ip value you have already fetched before
/// Master setup provider for the Host screen. It handles 4 steps:
/// 1. Fetches local IP, Device Name, and persistent UUID.
/// 2. Starts the local WebSocket server (getting a dynamic port).
/// 3. Broadcasts the server over mDNS so clients can auto-connect.
/// 4. Returns the final connection URL and IP for the QR code UI.
final syncSessionProvider = FutureProvider.autoDispose<({String ip, String qrUrl, String deviceName})>((ref) async {
  final String? ip = await ref.watch(localIPProvide.future);

  if (ip == null) {
    throw Exception('Please connect to Wi-Fi to host a sync session.');
  }

  final BaseDeviceInfo info = await ref.watch(deviceInfoProvider.future);
  final deviceName = info.extractName;

  // final qrUrl = 'ws://$ip:8080?name=${Uri.encodeComponent(deviceName)}';
  // // START THE SERVER
  // ref.read(syncServerProvider.notifier).startHosting(ip);

  final String uuid = ref.read(sharedPreferenceProvider).hostUuid;

  // The server starts and give us the dynamic base URL (e.g., ws://192.168.1.5:49152)
  final hostData = await ref.read(syncServerProvider.notifier).startHosting(ip);

  // mDNS (Multicast DNS) acts like a local loudspeaker on the Wi-Fi network.
  // It constantly shouts our server's IP, dynamic port, and unique UUID
  // so client devices can automatically discover us without scanning a QR code every time
  // Start the mDNS Broadcast using the data we just gathered
  await ref
      .read(mdnsBroadcastProvider.notifier)
      .startBroadcasting(port: hostData.port, uuid: uuid, deviceName: deviceName);

  // Attach your custom name parameter to the dynamic URL
  final baseUrl = 'ws://${hostData.ip}:${hostData.port}';
  // final qrUrl = '$baseUrl?name=${Uri.encodeComponent(deviceName)}';
  final qrUrl = '$baseUrl?host_name=${Uri.encodeComponent(deviceName)}&host_uuid=$uuid';
  return (ip: ip, qrUrl: qrUrl, deviceName: deviceName);
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

class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider
    final syncSessionAsync = ref.watch(syncSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Local Sync'),
        centerTitle: true,

        // actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),

      // Use Riverbed's .when() to handle the loading, error, and success states
      body: syncSessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Network Error: $error')),
        data: (syncData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            syncData.deviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade800),
                          ),
                          // Text("LanternChat Contact", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
                          SizedBox(height: 8),
                          Container(
                            color: Colors.white,
                            height: 200,
                            width: 200,
                            child: QrImageView(data: syncData.qrUrl),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Scan this QR code using Note-It on another device to sync over Wi-Fi.',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.push(AppRoutes.scan);
                  },
                  child: const Text("Scan QR"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
