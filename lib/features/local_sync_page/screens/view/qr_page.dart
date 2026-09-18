import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

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

// .family allow dev to pass a parameter to the FutureProvider,
// first value is normal return type of the future provide while the second value is the input parameter
final syncServerProvider = FutureProvider.family<void, String>((ref, ip) async {
  // Listen for incoming sync payloads from the scanning device
  var handler = webSocketHandler((webSocket, _) {
    print('Client connected to Host!');

    // Listen for incoming sync payloads from the scanning device
    webSocket.stream.listen((message) {
      print('Received from client: $message');

      // TODO: Implement Drift Last-Write-Wins comparison here

      // Send data back to the client
      webSocket.sink.add('Echo from Host: Received your payload');
    });
  });

  // Start the server on port 8080
  final server = await shelf_io.serve(handler, ip, 8080);
  print('Sync server hosting at ws://${server.address.host}:${server.port}');

  // Gracefully shut down the server if the user leaves the QR Code page
  ref.onDispose(() => server.close());
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
              ref.read(syncServerProvider(ip));

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
                        // context.push(AppRoute.qrScan);
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
