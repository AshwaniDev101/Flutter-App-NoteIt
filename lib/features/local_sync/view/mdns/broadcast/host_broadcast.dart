import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:noteit/database/sync/sync_engine.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import '../../../../../shared/overlays/app_scaffold.dart';
import '../../../provider/sync_session_provider.dart';

class HostBroadcastPage extends ConsumerStatefulWidget {
  const HostBroadcastPage({super.key});

  @override
  ConsumerState<HostBroadcastPage> createState() => _HostBroadcastPageState();
}

class _HostBroadcastPageState extends ConsumerState<HostBroadcastPage> {
  bool _showPinOverride = false;
  final ScrollController _scrollController = ScrollController(); // Added controller

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(syncSessionProvider);
    final syncState = ref.watch(localSyncServiceProvider);
    final isConnected = syncState == SyncConnectionState.connected;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.hostMode,
      body: sessionAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Starting server and broadcasting...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text('Failed to host', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(syncSessionProvider),
                  child: const Text('Retry'),
                ),
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
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        minWidth: constraints.maxWidth,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- HEADER ---
                                Icon(
                                  isConnected ? Icons.check_circle_rounded : Icons.wifi_tethering_rounded,
                                  size: 48,
                                  color: isConnected ? Colors.green : colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isConnected ? 'Device Connected' : 'Ready to Sync',
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  "${hostData.deviceName} • ${hostData.ip}",
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // --- PIN CARD ---
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: isConnected
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : colorScheme.primaryContainer.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(24),
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
                                        const SizedBox(height: 16),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            hostData.pin,
                                            style: textTheme.displayMedium?.copyWith(
                                              letterSpacing: 12,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isConnected && !shouldShowPin)
                                        Text(
                                          'Syncing in progress...',
                                          style: textTheme.titleMedium?.copyWith(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (isConnected) ...[
                                        const SizedBox(height: 16),
                                        TextButton.icon(
                                          onPressed: () => setState(() => _showPinOverride = !_showPinOverride),
                                          icon: Icon(
                                            _showPinOverride ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            size: 18,
                                          ),
                                          label: Text(_showPinOverride ? 'Hide PIN' : 'Reveal PIN'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

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
                                      _buildInstructionStep(context, '1', 'Install this app on your other device.'),
                                      const SizedBox(height: 12),
                                      _buildInstructionStep(context, '2', 'Go to Drawer → Local Sync → Connect as Client.'),
                                      const SizedBox(height: 12),
                                      _buildInstructionStep(context, '3', 'Select this host name and enter the PIN.'),
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
                                      onPressed: () async {
                                        ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.undefine);
                                        await ref.read(sharedPreferenceProvider).setCurrentEngine(SyncEngine.offline);
                                        await ref.read(syncEngineProvider.notifier).setEngine(SyncEngine.offline);
                                        ref.read(localSyncServiceProvider.notifier).stop();
                                        if (context.mounted) {
                                          ref.read(drawerNavigationProvider).pop(context);
                                        }
                                      },
                                      icon: const Icon(Icons.stop_rounded, size: 20),
                                      label: const Text('Stop Server'),
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
              }
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