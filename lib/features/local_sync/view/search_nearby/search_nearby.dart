import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/drift/device_pairs/device_pairs_dao.dart';
import '../../auto_connect/mdns_searcher.dart';
import '../../provider/sync_client_provider.dart';

class SearchNearBy extends ConsumerStatefulWidget {
  const SearchNearBy({super.key});

  @override
  ConsumerState<SearchNearBy> createState() => _SearchNearByState();
}

class _SearchNearByState extends ConsumerState<SearchNearBy> {
  @override
  void initState() {
    super.initState();
    // Start radar scanning immediately upon opening the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mdnsSearcherProvider.notifier).startRadar();
    });
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
              itemBuilder: (context, index) {
                final service = devices[index];

                // 1. Parse Name
                final deviceName = service.name ?? 'Unknown Host';

                // 2. Parse UUID from TXT record
                String hostUuid = '';
                if (service.txt != null && service.txt!.containsKey('uuid')) {
                  final rawUuid = service.txt!['uuid'];
                  if (rawUuid != null) {
                    hostUuid = utf8.decode(rawUuid);
                  }
                }

                // 3. Parse IP and Port
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

                    // Stop scanning when the user decides to connect
                    ref.read(mdnsSearcherProvider.notifier).stopScan();

                    // DB CHECK: Do we already know this UUID?
                    final devicePairsDao = ref.read(devicePairsDaoProvider);
                    final isKnown = await devicePairsDao.isDeviceKnown(hostUuid);

                    if (isKnown) {
                      // MAGIC PATH: Connect instantly without asking for a PIN
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Connecting to $deviceName...')));

                      ref
                          .read(syncClientProvider.notifier)
                          .connectToHost(ip: ip, port: port, hostUuid: hostUuid, hostName: deviceName);

                      if (context.mounted) Navigator.pop(context);
                    } else {
                      // STRANGER PATH: Prompt for PIN!
                      _showPinDialog(context, ip, port, hostUuid, deviceName);
                    }
                  },
                );
              },
            ),
    );
  }

  void _showPinDialog(BuildContext context, String ip, int port, String hostUuid, String hostName) {
    // TODO: Build the PIN entry popup UI here!
    print("Prompting user for PIN to connect to $hostName...");
  }
}
