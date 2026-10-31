import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/router/router.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/database/sync/sync_engine.dart';
import 'package:noteit/features/home/core/providers.dart';

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

    // Start radar scanning immediately upon opening (3 seconds initial scan)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mdnsSearcherProvider.notifier).startRadar(duration: const Duration(seconds: 3));
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

  void _triggerRetryScan() {
    ref.read(mdnsSearcherProvider.notifier).startRadar(duration: const Duration(seconds: 3));
  }

  Future<void> _changeRole() async {
    _mdnsNotifier.stopScan();

    ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.undefine);
    await ref.read(sharedPreferenceProvider).setCurrentEngine(SyncEngine.offline);
    await ref.read(syncEngineProvider.notifier).setEngine(SyncEngine.offline);
    ref.read(syncClientProvider.notifier).disconnect();

    if (!mounted) return;
    if (PlatformHelper.isWideLayout(context)) {
      ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.localSync);
    } else {
      context.pushReplacement(RightPanelPageOptions.localSync.route);
    }
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- TOP STATUS / HEADER ROW ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search),
                        const SizedBox(width: 8),
                        Text(
                          'Connect to Server',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [


                        OutlinedButton.icon(
                          onPressed: _changeRole,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Change Role'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        // TextButton.icon(
                        //   onPressed: _changeRole,
                        //   icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        //   label: const Text('Change Role'),
                        //   style: TextButton.styleFrom(
                        //     foregroundColor: colorScheme.primary,
                        //     visualDensity: VisualDensity.compact,
                        //   ),
                        // ),
                        // if (!isConnectedToHost)
                        //   IconButton(
                        //     tooltip: isScanning ? 'Scanning...' : 'Rescan (10s)',
                        //     onPressed: isScanning ? null : _triggerRetryScan,
                        //     icon: Icon(
                        //       Icons.refresh_rounded,
                        //       size: 20,
                        //       color: isScanning ? colorScheme.onSurface.withValues(alpha: 0.3) : colorScheme.primary,
                        //     ),
                        //   ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- CONNECTED BANNER CARD ---
                if (isConnectedToHost) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 36,
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
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('Disconnect from Host'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(
                              color: colorScheme.error.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // --- SCANNING / ERROR / DISCOVERED / NO HOST STATES ---
                  if (searchState.status == ScanStatus.error)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 40,),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to scan network',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check network connection or restart scan.',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _triggerRetryScan,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry Scan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Scanning Banner Indicator when actively scanning
                    if (isScanning)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              devices.isNotEmpty ? 'Searching for more hosts...' : 'Searching local network for host...',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Found Devices List
                    if (devices.isNotEmpty) ...[
                      Text(
                        'DISCOVERED HOSTS',
                        style: textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.5,
                          // color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: devices.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
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

                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.laptop_rounded,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                deviceName,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                ip != null ? '$ip • $devicePlatform' : 'Resolving IP...',
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.primary,
                              ),
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
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ] else if (!isScanning) ...[
                      // --- NO HOST FOUND EMPTY STATE ---
                      Card(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          // decoration: BoxDecoration(
                          //   color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          //   borderRadius: BorderRadius.circular(16),
                          //   border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          // ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Host Found',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ensure the host device has server mode active and both devices are connected to the same Wi-Fi.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _triggerRetryScan,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry Scan'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(
                                    color: colorScheme.primary.withValues(alpha: 0.5),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ],

                // --- INSTRUCTION HELP BOX ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'How to Sync:',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Open Drawer → Local Sync → Host Server on host device.\n'
                      '2. Connect both devices to the same Wi-Fi.\n'
                      '3. Select the host device from the list above and enter PIN.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
