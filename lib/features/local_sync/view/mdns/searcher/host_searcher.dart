import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/router/router.dart';

import '../../../../../core/config/config.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../../../../shared/overlays/app_scaffold.dart';
import '../../../../../shared/overlays/snack_bar_manager.dart';
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

    final isSyncConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;
    final isClientActive = ref.watch(syncClientProvider) != null;
    final isConnectedToHost = isSyncConnected && isClientActive;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.clientMode,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- CONNECTED BANNER CARD ---
            if (isConnectedToHost)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connected as Client',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local Wi-Fi sync session is active.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(syncClientProvider.notifier).disconnect();
                        SnackBarManager.show(
                          msg: 'Disconnected from host.',
                          type: SnackBarMessageType.info,
                        );
                      },
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect from Host'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // --- RADAR / SEARCH RESULTS SECTION ---
              if (searchState.status == ScanStatus.error)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'Failed to start radar.\nCheck your console for the exact error.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                )
              else ...[
                if (devices.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: devices.length,
                    itemBuilder: (itemContext, index) {
                      final service = devices[index];
                      final deviceName = service.name ?? 'Unknown Host';

                      String? decodeTxt(String key) {
                        if (service.txt == null || !service.txt!.containsKey(key)) return null;
                        final bytes = service.txt![key];
                        if (bytes == null) return null;
                        try {
                          return utf8.decode(List<int>.from(bytes));
                        } catch (_) {
                          return null;
                        }
                      }

                      final hostUuid = decodeTxt('uuid') ?? '';
                      final devicePlatform = decodeTxt('type') ?? 'unknown';
                      final vStr = decodeTxt('v');
                      final protocolVersion = vStr != null ? (int.tryParse(vStr) ?? 0) : 0;

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

                          if (protocolVersion != AppConfig.syncProtocolVersion) {
                            SnackBarManager.show(
                              msg: 'Version mismatch! Please update NoteIt.',
                              type: SnackBarMessageType.suggestion,
                            );
                            return;
                          }

                          if (isConnectedToHost) {
                            SnackBarManager.show(
                              msg: 'Disconnect from current host first before joining another!',
                              type: SnackBarMessageType.info,
                            );
                            return;
                          }

                          SnackBarManager.show(
                            msg: 'Connecting to $deviceName...',
                            type: SnackBarMessageType.info,
                          );

                          ref
                              .read(hostConnectionControllerProvider.notifier)
                              .connect(
                                ip: ip,
                                port: port,
                                hostUuid: hostUuid,
                                hostName: deviceName,
                                devicePlatform: devicePlatform,
                                protocolVersion: protocolVersion,
                                requestPin: () => context.push<String>(
                                  AppRoutes.pin,
                                  extra: {'hostName': deviceName, 'hostIp': ip},
                                ),
                              );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ] else if (!isScanning)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'No devices found nearby.\nMake sure the host is on the same Wi-Fi.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                // Indicator below the list when scanning
                if (isScanning)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          devices.isNotEmpty ? 'Looking for other hosts...' : 'Looking for a host...',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
