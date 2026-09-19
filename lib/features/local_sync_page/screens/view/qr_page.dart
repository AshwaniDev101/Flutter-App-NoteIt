import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/provider/sync_server_provider.dart';

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



class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider
    final deviceInfoAsync = ref.watch(deviceInfoProvider);
    final localIpAsync = ref.watch(localIPProvide);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Local Sync'),
        centerTitle: true,

        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),

      // Use Riverbed's .when() to handle the loading, error, and success states
      body: deviceInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Device Error: $error')),
        data: (info) {
          return localIpAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Network Error: $error')),
            data: (ip) {
              // Failsafe: Ensure device is actually on Wi-Fi
              if (ip == null) {
                return const Center(child: Text('Please connect to Wi-Fi to host a sync session.'));
              }

              // Fire up the WebSocket server in the background using the discovered IP
              ref.read(syncServerProvider.notifier).startHosting(ip);

              final deviceName = extractDeviceName(info);

              // Build the connection string, passing the device name so the client UI can say "Syncing with Varsha's Laptop"
              final qrPayload = 'ws://$ip:8080?name=${Uri.encodeComponent(deviceName)}';

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
                                deviceName,
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
                                child: QrImageView(data: qrPayload),
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
          );
        },
      ),
    );
  }

  String extractDeviceName(BaseDeviceInfo info) {
    if (info is AndroidDeviceInfo) {
      return info.model;
    } else if (info is IosDeviceInfo) {
      return info.name;
    } else if (info is WindowsDeviceInfo) {
      return info.computerName;
    } else if (info is MacOsDeviceInfo) {
      return info.computerName;
    } else if (info is LinuxDeviceInfo) {
      return info.prettyName;
    } else if (info is WebBrowserInfo) {
      return info.browserName.toString();
    }
    return 'Unknown Device';
  }
}
