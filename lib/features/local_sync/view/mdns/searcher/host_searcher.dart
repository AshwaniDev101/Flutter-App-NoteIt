import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';

import '../../../../../core/util/logger.dart';
import '../../../../../database/drift/synced_devices/synced_devices_dao.dart';
import '../../../../home/view/shared/desktop_close_button.dart';
import '../../../auto_connect/mdns_searcher.dart';
import '../../../provider/sync_client_provider.dart';
import 'pin_dialog/host_connection_controller.dart';

class HostSearcher extends ConsumerStatefulWidget {
  const HostSearcher({super.key});

  @override
  ConsumerState<HostSearcher> createState() => _SearchNearByState();
}

class _SearchNearByState extends ConsumerState<HostSearcher> {
  late final MdnsSearcherNotifier _mdnsNotifier;

  @override
  void initState() {
    super.initState();

    _mdnsNotifier = ref.read(mdnsSearcherProvider.notifier);

    // Start radar scanning immediately upon opening the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mdnsSearcherProvider.notifier).startRadar();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      _mdnsNotifier.stopScan();
      ref.read(hostConnectionControllerProvider.notifier).reset();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {



    ref.listen(hostConnectionControllerProvider, (previous, next) {
      if (next.status == ConnectionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Connection failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.status == ConnectionStatus.success) {
        context.pop(); // Safely close the screen
      }
    });
    // -----------------------------------------


    final searchState = ref.watch(mdnsSearcherProvider);
    final devices = searchState.devices;
    final isScanning = searchState.status == ScanStatus.scanning;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Nearby Devices'),

        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLowest,
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

          DesktopCloseButton(),
        ],
      ),
      body: searchState.status == ScanStatus.error
          ? Center(
              child: Text(
                'Failed to start radar.\nCheck your console for the exact error.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
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
                  onTap: () {
                    if (ip == null || port == null || hostUuid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Still resolving device info...'))
                      );
                      return;
                    }

                    // Prevent double connections
                    if (ref.read(syncClientProvider) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You are already connected to a host!'))
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connecting to $deviceName...'))
                    );

                    // Trigger the controller
                    ref.read(hostConnectionControllerProvider.notifier).connect(
                      ip: ip,
                      port: port,
                      hostUuid: hostUuid,
                      hostName: deviceName,
                      requestPin: () => context.push<String>(AppRoutes.pin), // How to get the PIN
                    );
                  },
                );
              },
            ),
    );
  }
}
