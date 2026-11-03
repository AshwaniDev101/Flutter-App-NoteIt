import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/database/drift/synced_devices/synced_devices_dao.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/home/view/shared/icon_tray/icon_tray.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:noteit/features/local_sync/data/providers/sync_session_provider.dart';
import 'package:noteit/features/local_sync/view/widgets/sync_history_button.dart';
import 'package:noteit/shared/overlays/app_scaffold.dart';

import '../../../../home/view/shared/sync_state_widget.dart';

class HostBroadcastPage extends ConsumerStatefulWidget {
  const HostBroadcastPage({super.key});

  @override
  ConsumerState<HostBroadcastPage> createState() => _HostBroadcastPageState();
}

class _HostBroadcastPageState extends ConsumerState<HostBroadcastPage> {
  bool _showPinOverride = false;
  bool _isConnected = false;
  final ScrollController _scrollController = ScrollController();

  late final SyncedDevicesDao _syncedDevicesDao;
  late final SyncServerNotifier _syncServerNotifier;
  late final MdnsBroadcastNotifier _mdnsBroadcastNotifier;
  late final SharedPreferenceManager _sharedPreferenceManager;
  late final LocalSyncNotifier _localSyncNotifier;

  @override
  void initState() {
    super.initState();
    _syncedDevicesDao = ref.read(syncedDevicesDaoProvider);
    _syncServerNotifier = ref.read(syncServerProvider.notifier);
    _mdnsBroadcastNotifier = ref.read(mdnsBroadcastProvider.notifier);
    _sharedPreferenceManager = ref.read(sharedPreferenceProvider);
    _localSyncNotifier = ref.read(localSyncServiceProvider.notifier);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose to prevent memory leaks
    _checkAndAutoStopUnpairedHost();
    super.dispose();
  }

  void _checkAndAutoStopUnpairedHost() async {
    if (_isConnected) return; // Keep server running if actively connected

    final hasPaired = await _syncedDevicesDao.hasPairedDevices();
    if (!hasPaired) {
      // Unpaired exploration session: stop server and reset role
      _syncServerNotifier.stopHosting();
      _mdnsBroadcastNotifier.stopBroadcasting();
      await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
      _localSyncNotifier.stop();
    }
  }

  void _confirmAndStopHosting(BuildContext context) {
    final activeSession = ref.read(localSyncSessionProvider);
    if (activeSession.isSyncing) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sync in Progress'),
          content: const Text('Data transfer is currently active. Are you sure you want to stop hosting?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _stopHosting();
              },
              child: const Text('Stop Hosting'),
            ),
          ],
        ),
      );
    } else {
      _stopHosting();
    }
  }

  Future<void> _stopHosting() async {
    ref.read(syncServerProvider.notifier).stopHosting();
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
    ref.read(localSyncServiceProvider.notifier).stop();
    if (!mounted) return;
    if (PlatformHelper.isWideLayout(context)) {
      ref.read(desktopRightPanelViewProvider.notifier).setView(RightPanelPageOptions.localSync);
    } else {
      context.pushReplacement(RightPanelPageOptions.localSync.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(syncSessionProvider);
    final activeSession = ref.watch(localSyncSessionProvider);
    final isConnected = activeSession.isConnected;
    _isConnected = isConnected;
    final peerTitle = activeSession.peerName != null ? 'Connected to ${activeSession.peerName}' : '1 Device Connected';

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.hostMode,
      body: sessionAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Starting server and broadcasting...')],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.error, size: 36),
                const SizedBox(height: 12),
                Text('Failed to host', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton.tonal(onPressed: () => ref.invalidate(syncSessionProvider), child: const Text('Retry')),
              ],
            ),
          ),
        ),
        data: (hostData) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          final shouldShowPin = !isConnected || _showPinOverride;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _scrollController, // Attach controller to Scrollbar
                child: SingleChildScrollView(
                  controller: _scrollController, // Attach SAME controller to ScrollView
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight, minWidth: constraints.maxWidth),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- HEADER ---
                              const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 36,
                                // color: colorScheme.primary,
                              ),

                              const SizedBox(height: 4),
                              SelectableText(
                                "Host: ${hostData.deviceName}",
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                "IP: ${hostData.ip}",
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),

                              const SizedBox(height: 12),

                              if (isConnected) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        peerTitle,
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.greenAccent,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Ready to Sync',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // --- PIN CARD ---
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    if (shouldShowPin) ...[
                                      Text(
                                        'PAIRING PIN',
                                        style: textTheme.labelSmall?.copyWith(
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          hostData.pin,
                                          style: textTheme.headlineLarge?.copyWith(
                                            letterSpacing: 8,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                    // if (isConnected && !shouldShowPin)
                                    //   Text(
                                    //     'Syncing in progress...',
                                    //     style: textTheme.titleMedium?.copyWith(
                                    //       color: Colors.green.shade700,
                                    //       fontWeight: FontWeight.w500,
                                    //     ),
                                    //     textAlign: TextAlign.center,
                                    //   ),
                                    if (isConnected) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () => setState(() => _showPinOverride = !_showPinOverride),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: Icon(
                                          _showPinOverride ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          size: 16,
                                        ),
                                        label: Text(_showPinOverride ? 'Hide PIN' : 'Reveal PIN'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
                                        alignment: PlaceholderAlignment.middle, // Aligns icon with the text vertically
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Icon(Icons.menu, size: 16, color: colorScheme.primary),
                                        ),
                                      ),
                                      const TextSpan(text: '\n → Local Sync → Select \'Client\' → \'Find Host\''),
                                    ]),

                                    const SizedBox(height: 8),

                                    // Step 3
                                    _buildRichInstructionStep(context, '3', <InlineSpan>[
                                      const TextSpan(text: 'Search & Find host name: '),
                                      TextSpan(
                                        text: hostData.deviceName,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                      ),
                                      const TextSpan(text: ' and enter PIN: '),
                                      TextSpan(
                                        text: hostData.pin,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                      ),
                                      const TextSpan(text: '.'),
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
                                    onPressed: () => _confirmAndStopHosting(context),
                                    icon: const Icon(Icons.stop_rounded, size: 18),
                                    label: const Text('Stop Hosting'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.errorContainer,
                                      foregroundColor: colorScheme.onErrorContainer,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          );
        },
      ),
      actions: [
        if(!PlatformHelper.isWideLayout(context))
          // IconTray(),
          SyncStateWidget(),
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
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
          child: Text(number, style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.3)),
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