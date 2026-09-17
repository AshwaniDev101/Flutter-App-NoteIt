import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Create a FutureProvider to fetch cross-platform device info asynchronously
final deviceInfoProvider = FutureProvider<BaseDeviceInfo>((ref) async {
  final deviceInfoPlugin = DeviceInfoPlugin();

  // .deviceInfo automatically detects the platform and returns a BaseDeviceInfo object
  return await deviceInfoPlugin.deviceInfo;
});

class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Watch the FutureProvider
    final deviceInfoAsync = ref.watch(deviceInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR code'),
        leading: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),

      // Use Riverbed's .when() to handle the loading, error, and success states
      body: deviceInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error loading info: $error')),
        data: (info) {

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Safely print the map data (or extract specific keys you want)
                              Text(
                                  extractDeviceName(info),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade800)
                              ),
                              // Text("LanternChat Contact", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
                              SizedBox(height: 8,),
                              Container(
                                color: Colors.white,
                                height: 200,
                                width: 200,
                                child: QrImageView(data: "919.9191.029"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Scan the QR code using Note-It app to sync over the wifi',
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