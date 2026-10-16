import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';

import '../../../../../core/config.dart';
import '../../../../home/view/desktop/right_panel/core/navigator.dart';
import '../../../../../shared/app_scaffold.dart';
import '../../../../../shared/snack_bar_manager.dart';
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
        SnackBarManager.show(
          msg: next.errorMessage ?? 'Connection failed',
          type: SnackBarMessageType.error,
        );
      } else if (next.status == ConnectionStatus.success) {
        context.pop(); // Safely close the screen
      }
    });
    // -----------------------------------------

    final searchState = ref.watch(mdnsSearcherProvider);
    final devices = searchState.devices;
    final isScanning = searchState.status == ScanStatus.scanning;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.clientMode,
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

                // --- Safe extraction helper for the UI ---
                String? decodeTxt(String key) {
                  if (service.txt == null || !service.txt!.containsKey(key)) return null;
                  final bytes = service.txt![key];
                  if (bytes == null) return null;
                  try {
                    // Safe List<int>.from cast prevents the Uint8List UI crash!
                    return utf8.decode(List<int>.from(bytes));
                  } catch (_) {
                    return null;
                  }
                }

                // Extract all our strict data safely
                final hostUuid = decodeTxt('uuid') ?? '';
                final devicePlatform = decodeTxt('type') ?? 'unknown';
                final vStr = decodeTxt('v');
                final protocolVersion = vStr != null ? (int.tryParse(vStr) ?? 0) : 0;
                // ----------------------------------------------

                final ip = service.host ?? service.addresses?.firstOrNull?.address;
                final port = service.port;

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.devices)),
                  title: Text(deviceName),
                  subtitle: Text(ip != null ? 'Tap to connect' : 'Resolving IP...'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (ip == null || port == null || hostUuid.isEmpty) {
                      SnackBarManager.show(
                        msg: 'Still resolving device info...',
                        type: SnackBarMessageType.info,
                      );
                      return;
                    }

                    // --- PROTOCOL SAFETY CHECK IN UI ---
                    if (protocolVersion != AppConfig.syncProtocolVersion) {
                      SnackBarManager.show(
                        msg: 'Version mismatch! Please update NoteIt.',
                        type: SnackBarMessageType.suggestion,
                      );
                      return; // Block the connection entirely!
                    }
                    // ----------------------------------------

                    // Prevent double connections
                    if (ref.read(syncClientProvider) != null) {
                      SnackBarManager.show(
                        msg: 'You are already connected to a host!',
                        type: SnackBarMessageType.info,
                      );
                      return;
                    }

                    SnackBarManager.show(
                      msg: 'Connecting to $deviceName...',
                      type: SnackBarMessageType.info,
                    );

                    // Trigger the controller
                    ref
                        .read(hostConnectionControllerProvider.notifier)
                        .connect(
                          ip: ip,
                          port: port,
                          hostUuid: hostUuid,
                          hostName: deviceName,
                          devicePlatform: devicePlatform,
                          // <-- PASS NEW DATA
                          protocolVersion: protocolVersion,
                          // <-- PASS NEW DATA
                          requestPin: () => context.push<String>(AppRoutes.pin), // How to get the PIN
                        );
                  },
                );
              },
            ),
    );
  }
}
