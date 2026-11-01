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
  final ScrollController _scrollController = ScrollController(); // Explicit controller for scrollbar

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
    _scrollController.dispose(); // Prevent memory leak
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollController, // Attach same controller
            child: SingleChildScrollView(
              controller: _scrollController, // Attach same controller
              // Padding moved to child to push scrollbar to the very edge
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // --- HERO HEADER ---
                          if (!isConnectedToHost) ...[
                            Icon(
                              searchState.status == ScanStatus.error
                                  ? Icons.wifi_off_rounded
                                  : (devices.isEmpty && !isScanning ? Icons.wifi_find_rounded : Icons.radar_rounded),
                              size: 48,
                              color: searchState.status == ScanStatus.error
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Connect to Server',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isScanning ? 'Searching local network...' : 'Ready to connect',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],

                          // --- STATE: CONNECTED ---
                          if (isConnectedToHost) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 48,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Connected as Client',
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Local Wi-Fi sync session is active.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.green.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      ref.read(syncClientProvider.notifier).disconnect();
                                      SnackBarManager.show(
                                        msg: 'Disconnected from host.',
                                        type: SnackBarMessageType.info,
                                      );
                                    },
                                    icon: const Icon(Icons.link_off_rounded, size: 20),
                                    label: const Text('Disconnect'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                                      foregroundColor: Colors.green.shade900,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ]

                          // --- STATE: ERROR ---
                          else if (searchState.status == ScanStatus.error) ...[
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 40, color: colorScheme.error),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Scan Failed',
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check your network connection and try again.',
                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.tonalIcon(
                                    onPressed: _triggerRetryScan,
                                    icon: const Icon(Icons.refresh_rounded, size: 20),
                                    label: const Text('Retry Scan'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ]

                          // --- STATE: SEARCHING & RESULTS ---
                          else ...[
                              // Found Devices List
                              if (devices.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'DISCOVERED HOSTS',
                                        style: textTheme.labelSmall?.copyWith(
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isScanning)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        onPressed: _triggerRetryScan,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Rescan',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: devices.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.laptop_rounded,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          deviceName,
                                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          ip != null ? '$ip • $devicePlatform' : 'Resolving IP...',
                                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: colorScheme.onPrimaryContainer,
                                            size: 20,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                const SizedBox(height: 40),
                              ]

                              // Empty State
                              else if (!isScanning) ...[
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.devices_outlined,
                                        size: 40,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Hosts Found',
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ensure the host has server mode active and both devices are on the same Wi-Fi.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      FilledButton.tonalIcon(
                                        onPressed: _triggerRetryScan,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        label: const Text('Search Again'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ]
                              // Loading Indicator (only if empty and scanning)
                              else ...[
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ]
                            ],

                          // --- INSTRUCTIONS ---
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'How to connect',
                                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInstructionStep(context, '1', 'Open Drawer → Local Sync → Host Server on host device.'),
                                const SizedBox(height: 12),
                                _buildInstructionStep(context, '2', 'Connect both devices to the same Wi-Fi.'),
                                const SizedBox(height: 12),
                                _buildInstructionStep(context, '3', 'Select the host device above and enter the PIN.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // --- ACTIONS ---
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              // History Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref.read(drawerNavigationProvider).navigate(
                                    context,
                                    RightPanelPageOptions.syncedList,
                                  );
                                },
                                icon: const Icon(Icons.history_rounded, size: 18),
                                label: const Text('History'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _changeRole,
                                icon: const Icon(Icons.stop, size: 20),
                                label: const Text('Stop'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer,
                                  foregroundColor: colorScheme.onErrorContainer,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}