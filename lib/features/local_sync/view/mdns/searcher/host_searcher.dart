import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/config/config.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/router/router.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:noteit/features/local_sync/view/mdns/searcher/pin_dialog/host_connection_controller.dart';
import 'package:noteit/features/local_sync/view/widgets/alternative_sync_cards.dart';
import 'package:noteit/features/local_sync/view/widgets/sync_history_button.dart';
import 'package:noteit/shared/overlays/app_scaffold.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';

import '../../../../home/view/shared/sync_state_widget.dart';

class HostSearcher extends ConsumerStatefulWidget {
  const HostSearcher({super.key});

  @override
  ConsumerState<HostSearcher> createState() => _SearchNearByState();
}

class _SearchNearByState extends ConsumerState<HostSearcher> {
  late final MdnsSearcherNotifier _mdnsNotifier;
  late final HostConnectionController _hostConnectionController;
  final ScrollController _scrollController = ScrollController(); // Explicit controller for scrollbar

  @override
  void initState() {
    super.initState();
    _mdnsNotifier = ref.read(mdnsSearcherProvider.notifier);
    _hostConnectionController = ref.read(hostConnectionControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mdnsNotifier.startRadar(duration: const Duration(seconds: 3));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mdnsNotifier.stopScan();
    _hostConnectionController.reset();
    super.dispose();
  }

  void _triggerRetryScan() {
    _mdnsNotifier.startRadar(duration: const Duration(seconds: 3));
  }

  void _showConnectByIpDialog(BuildContext context) {
    final ipController = TextEditingController(text: '192.168.1.');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Connect via Host IP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the IP address displayed on your Host device screen:'),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Host IP Address',
                  hintText: 'e.g. 192.168.1.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final enteredIp = ipController.text.trim();
                Navigator.of(dialogContext).pop();
                if (enteredIp.isEmpty) return;

                SnackBarManager.show(
                  msg: 'Connecting to $enteredIp...',
                  type: SnackBarMessageType.info,
                );

                ref.read(hostConnectionControllerProvider.notifier).connect(
                  ip: enteredIp,
                  port: AppConfig.defaultSyncPort,
                  hostUuid: 'manual-$enteredIp',
                  hostName: 'Host ($enteredIp)',
                  devicePlatform: 'unknown',
                  protocolVersion: AppConfig.syncProtocolVersion,
                  requestPin: () => context.push<String>(
                    AppRoutes.pin,
                    extra: {'hostName': 'Host ($enteredIp)', 'hostIp': enteredIp},
                  ),
                );
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDisconnectAndExit() async {
    _mdnsNotifier.stopScan();
    await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
    ref.read(syncClientProvider.notifier).disconnect();

    SnackBarManager.show(
      msg: 'Disconnected from host.',
      type: SnackBarMessageType.info,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (PlatformHelper.isWideLayout(context)) {
        ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.localSync);
      } else {
        context.pushReplacement(RightPanelPageOptions.localSync.route);
      }
    });
  }

  void _disconnectAndExit(BuildContext context) {
    final activeSession = ref.read(localSyncSessionProvider);
    if (activeSession.isSyncing) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sync in Progress'),
          content: const Text('Data transfer is currently active. Are you sure you want to disconnect?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performDisconnectAndExit();
              },
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    } else {
      _performDisconnectAndExit();
    }
  }

  void _confirmAndSwitchToCloudMode() {
    final activeSession = ref.read(localSyncSessionProvider);
    if (activeSession.isSyncing) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sync in Progress'),
          content: const Text('Data transfer is currently active. Are you sure you want to switch to Cloud mode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _switchToCloudMode();
              },
              child: const Text('Switch Mode'),
            ),
          ],
        ),
      );
    } else {
      _switchToCloudMode();
    }
  }

  void _confirmAndSwitchToOfflineMode() {
    final activeSession = ref.read(localSyncSessionProvider);
    if (activeSession.isSyncing) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sync in Progress'),
          content: const Text('Data transfer is currently active. Are you sure you want to turn off sync?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _switchToOfflineMode();
              },
              child: const Text('Turn Off Sync'),
            ),
          ],
        ),
      );
    } else {
      _switchToOfflineMode();
    }
  }

  Future<void> _switchToCloudMode() async {
    _mdnsNotifier.stopScan();
    ref.read(syncClientProvider.notifier).disconnect();

    final success = await ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
    if (success && mounted) {
      SnackBarManager.show(
        msg: 'Switched to Cloud Sync Mode',
        type: SnackBarMessageType.info,
      );
      _exitToDefaultView();
    }
  }

  Future<void> _switchToOfflineMode() async {
    _mdnsNotifier.stopScan();
    ref.read(syncClientProvider.notifier).disconnect();

    await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
    if (mounted) {
      SnackBarManager.show(
        msg: 'Sync turned off (Offline Mode)',
        type: SnackBarMessageType.info,
      );
      _exitToDefaultView();
    }
  }

  void _exitToDefaultView() {
    if (PlatformHelper.isWideLayout(context)) {
      ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.noteEditor);
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.pushReplacement(RightPanelPageOptions.noteEditor.route);
      }
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (PlatformHelper.isWideLayout(context)) {
            ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.localSync);
          } else if (GoRouter.of(context).canPop()) {
            context.pop();
          }
        });
      }
    });

    final searchState = ref.watch(mdnsSearcherProvider);
    final devices = searchState.devices;
    final isScanning = searchState.status == ScanStatus.scanning;

    final activeSession = ref.watch(localSyncSessionProvider);
    final isConnectedToHost = activeSession.isConnected;
    final hostTitle = activeSession.peerName != null
        ? 'Connected to ${activeSession.peerName}'
        : 'Connected as Client';
    final subTitle = 'Local Wi-Fi sync session is active.';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.clientMode,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                              size: 36,
                              color: searchState.status == ScanStatus.error
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Searching for Host',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isScanning ? 'Searching local network...' : '',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // --- STATE: CONNECTED ---
                          if (isConnectedToHost) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ACTIVE SESSION',
                                          style: textTheme.labelSmall?.copyWith(
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 32,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    hostTitle,
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subTitle,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ]
                          // --- STATE: ERROR ---
                          else if (searchState.status == ScanStatus.error) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 36, color: colorScheme.error),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Scan Failed',
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check your network connection and try again.',
                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.tonalIcon(
                                    onPressed: _triggerRetryScan,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Retry Scan'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ]
                          // --- STATE: SEARCHING & RESULTS ---
                          else ...[
                              if (devices.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'DISCOVERED HOSTS (${devices.length})',
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
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        onPressed: _triggerRetryScan,
                                        icon: const Icon(Icons.refresh_rounded, size: 18),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Rescan',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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

                                    return Material(
                                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.laptop_rounded,
                                            color: colorScheme.primary,
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          deviceName,
                                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          ip != null ? '$ip\n$devicePlatform' : 'Resolving IP...',
                                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                            // borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.question_mark,
                                            color: colorScheme.onPrimaryContainer,
                                            size: 18,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                                          ref.read(hostConnectionControllerProvider.notifier).connect(
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
                                const SizedBox(height: 24),
                              ] else if (!isScanning) ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.devices_outlined,
                                        size: 36,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Hosts Found',
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ensure both devices are on the same Wi-Fi network (no internet required).',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          FilledButton.tonalIcon(
                                            onPressed: _triggerRetryScan,
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            label: const Text('Search Again'),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _showConnectByIpDialog(context),
                                            icon: const Icon(Icons.lan_rounded, size: 18),
                                            label: const Text('Connect by IP'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ] else ...[
                                // Container(
                                //   padding: const EdgeInsets.all(20),
                                //   decoration: BoxDecoration(
                                //     color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                //     borderRadius: BorderRadius.circular(16),
                                //   ),
                                //   child: Center(
                                //     child: Row(
                                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //       // crossAxisAlignment: CrossAxisAlignment.stretch,
                                //       children: [
                                //
                                //         Column(
                                //           children: [
                                //             Text("Host not found.", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),),
                                //             Text("Make sure other Device is hosting!", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),),
                                //           ],
                                //         ),
                                //
                                //         SizedBox(width: 16,),
                                //         SizedBox(
                                //           height: 14,
                                //           width: 14,
                                //           child: CircularProgressIndicator(
                                //             strokeWidth: 2,
                                //             color: colorScheme.primary,
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // 1. Expanded prevents text overflow on smaller screens
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start, // 2. Left-aligns the text
                                          children: [
                                            Text(
                                              "Scanning for hosts...",
                                              style: textTheme.titleSmall?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Make sure the other device is actively hosting.",
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // 3. Slightly bumped up the size for better visibility
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ]
                            ],
                          const SizedBox(height: 24),

                          // --- INSTRUCTIONS ---
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.onSurfaceVariant),
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
                                const SizedBox(height: 12),
                                _buildInstructionStep(context, '1', 'Install this app on your other device.'),
                                const SizedBox(height: 8),
                                _buildRichInstructionStep(context, '2', <InlineSpan>[
                                  const TextSpan(text: 'Go to Main Menu '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(Icons.menu, size: 16, color: colorScheme.primary),
                                    ),
                                  ),
                                  const TextSpan(text: '\n → Local Sync → Select \'Host\' → \'Start hosting\''),
                                ]),
                                const SizedBox(height: 8),
                                _buildRichInstructionStep(context, '3', const <InlineSpan>[
                                  TextSpan(text: 'Once the host is active, note the '),
                                  TextSpan(text: 'Host Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' and '),
                                  TextSpan(text: 'PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ', then refresh this page.'),
                                ]),
                                const SizedBox(height: 8),
                                _buildRichInstructionStep(context, '4', const <InlineSpan>[
                                  TextSpan(text: 'Select the '),
                                  TextSpan(text: 'host name', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' from the list and enter the '),
                                  TextSpan(text: 'PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' to connect.'),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- ACTIONS ---
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              const SyncHistoryButton(),
                              FilledButton.tonalIcon(
                                onPressed: () => _disconnectAndExit(context),
                                icon: Icon(
                                  isConnectedToHost ? Icons.link_off_rounded : Icons.tune_rounded,
                                  size: 18,
                                ),
                                label: Text(isConnectedToHost ? 'Disconnect' : 'Change Role'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isConnectedToHost
                                      ? colorScheme.errorContainer
                                      : null,
                                  foregroundColor: isConnectedToHost
                                      ? colorScheme.onErrorContainer
                                      : null,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // --- ALTERNATIVE SYNC OPTIONS ---
                          AlternativeSyncCards(
                            onSelectCloud: _confirmAndSwitchToCloudMode,
                            onSelectOffline: _confirmAndSwitchToOfflineMode,
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
      actions: [
        if(!PlatformHelper.isWideLayout(context))...[
          SyncStateWidget(),
          SizedBox(width: 8,),
          // IconTray(),
        ]
      ],
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichInstructionStep(BuildContext context, String number, List<InlineSpan> spans) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
          child: Text(number, style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(children: spans),
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.3),
          ),
        ),
      ],
    );
  }
}