import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';

import '../../../../../database/drift/device_pairs/synced_devices_dao.dart';
import '../../../auto_connect/mdns_searcher.dart';
import '../../../provider/sync_client_provider.dart';

class HostSearcher extends ConsumerStatefulWidget {
  const HostSearcher({super.key});

  @override
  ConsumerState<HostSearcher> createState() => _SearchNearByState();
}

class _SearchNearByState extends ConsumerState<HostSearcher> {
  @override
  void initState() {
    super.initState();
    // Start radar scanning immediately upon opening the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mdnsSearcherProvider.notifier).startRadar();
    });
  }

  @override
  void dispose() {
    // Stop scanning if the user hits the back button to leave the page
    // Using Future.microtask prevents state modification errors during widget teardown
    final mdnsNotifier = ref.read(mdnsSearcherProvider.notifier);
    Future.microtask(() => mdnsNotifier.stopScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(mdnsSearcherProvider);
    final devices = searchState.devices;
    final isScanning = searchState.status == ScanStatus.scanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(mdnsSearcherProvider.notifier).startRadar();
              },
            ),
        ],
      ),
      body: searchState.status == ScanStatus.error
          ? const Center(
              child: Text(
                'Failed to start radar.\nCheck your console for the exact error.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            )
          : devices.isEmpty && isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Searching for nearby devices...')],
              ),
            )
          : devices.isEmpty
          ? const Center(child: Text('No devices found nearby.\nMake sure the host is on the same Wi-Fi.'))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (itemContext, index) {
                final service = devices[index];

                final deviceName = service.name ?? 'Unknown Host';

                String hostUuid = '';
                if (service.txt != null && service.txt!.containsKey('uuid')) {
                  final rawUuid = service.txt!['uuid'];
                  if (rawUuid != null) {
                    hostUuid = utf8.decode(rawUuid);
                  }
                }

                final ip = service.host ?? service.addresses?.firstOrNull?.address;
                final port = service.port;

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.devices)),
                  title: Text(deviceName),
                  subtitle: Text(ip != null ? 'Tap to connect' : 'Resolving IP...'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (ip == null || port == null || hostUuid.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Still resolving device info...')));
                      return;
                    }

                    // DB CHECK: Do we already know this UUID?
                    final devicePairsDao = ref.read(syncedDevicesDaoProvider);
                    final isKnown = await devicePairsDao.isDeviceKnown(hostUuid);

                    if (!mounted) return;

                    if (isKnown) {
                      print("UUID is Known");

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Connecting to $deviceName...')));

                      ref
                          .read(syncClientProvider.notifier)
                          .connectToHost(ip: ip, port: port, hostUuid: hostUuid, hostName: deviceName);

                      // Note: We don't need stopScan() here because dispose() will catch it when we pop!
                      context.pop();
                    } else {
                      print("UUID is not Known");

                      // Prompt for PIN!
                      final enteredPin = await context.push<String>(AppRoutes.pin);

                      // Check mounted again after awaiting the PIN dialog
                      if (!mounted) return;

                      if (enteredPin != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Verifying PIN with $deviceName...')));

                        try {
                          ref
                              .read(syncClientProvider.notifier)
                              .connectToHost(
                                ip: ip,
                                port: port,
                                hostUuid: hostUuid,
                                hostName: deviceName,
                                pin: enteredPin,
                              );

                          if (mounted) {
                            context.pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            // e.toString() will contain your custom message: "Exception: Connection rejected..."

                            // Clean up the string to remove the "Exception: " prefix
                            final errorMessage = e.toString().replaceAll('Exception: ', '');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating, // Makes it look a bit nicer
                              ),
                            );
                          }
                        }

                        // // Pop the search page after starting the connection!
                        // context.pop();
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
