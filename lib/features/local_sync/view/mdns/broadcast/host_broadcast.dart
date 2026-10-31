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

  @override
  Widget build(BuildContext context) {
    // Watching this provider automatically starts the server and mDNS broadcast.
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
              SizedBox(height: 16),
              Text('Starting server and broadcasting...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Failed to host: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
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

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- NON-CHANGEABLE SERVER LABEL & STOP BUTTON ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'This Device is a Server',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.undefine);
                            await ref.read(sharedPreferenceProvider).setCurrentEngine(SyncEngine.offline);
                            ref.read(localSyncServiceProvider.notifier).stop();
                            if (context.mounted) {
                              ref.read(drawerNavigationProvider).pop(context);
                            }
                          },
                          icon: const Icon(Icons.stop_circle_outlined, size: 18),
                          label: const Text('Stop Server'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- FLAT HOST DETAILS CARD ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            icon: Icons.laptop_rounded,
                            label: 'Host Name',
                            value: hostData.deviceName,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            context,
                            icon: Icons.wifi_rounded,
                            label: 'Host IP',
                            value: hostData.ip,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- CONNECTION STATUS & PAIRING PIN CARD ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          // Connected status message
                          if (isConnected) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'At least 1 device is connected',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Pairing PIN (Shown if not connected OR if user taps Show PIN)
                          if (shouldShowPin) ...[
                            Text(
                              'PAIRING PIN',
                              style: textTheme.labelMedium?.copyWith(
                                letterSpacing: 2,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hostData.pin,
                              style: textTheme.displayMedium?.copyWith(
                                fontSize: 40,
                                letterSpacing: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],

                          // Show PIN toggle button when device is connected
                          if (isConnected) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showPinOverride = !_showPinOverride;
                                });
                              },
                              icon: Icon(
                                _showPinOverride
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                              ),
                              label: Text(_showPinOverride ? 'Hide PIN' : 'Show PIN'),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- INSTRUCTION HELP BOX (OUTSIDE PIN BOX) ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'To Sync:',
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Install this app on your other device.\n'
                            '2. Go to: Drawer → Local Sync → Connect as Client.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        SelectableText(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
