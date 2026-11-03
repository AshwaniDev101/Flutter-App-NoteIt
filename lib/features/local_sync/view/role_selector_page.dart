import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/data/network/mdns_searcher.dart';
import 'package:noteit/features/local_sync/data/providers/sync_client_provider.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';
import 'package:noteit/features/local_sync/data/providers/sync_session_provider.dart';
import 'package:noteit/features/local_sync/view/widgets/sync_history_button.dart';
import 'package:noteit/shared/overlays/app_scaffold.dart';

class RoleSelectorPage extends ConsumerStatefulWidget {
  const RoleSelectorPage({super.key});

  @override
  ConsumerState<RoleSelectorPage> createState() => _RoleSelectorPageState();
}

class _RoleSelectorPageState extends ConsumerState<RoleSelectorPage> {
  late bool _isClient;

  @override
  void initState() {
    super.initState();
    final currentRole = ref.read(sharedPreferenceProvider).syncRole;
    if (currentRole == SyncRole.client) {
      _isClient = true;
    } else if (currentRole == SyncRole.host) {
      _isClient = false;
    } else {
      // Default to 'Client' on mobile and 'Host' on desktop if undefined
      _isClient = !PlatformHelper.isNativeDesktop;
    }
  }

  void _updateRole(bool isClient) {
    setState(() {
      _isClient = isClient;
    });
    ref.read(sharedPreferenceProvider).setSyncRole(
          isClient ? SyncRole.client : SyncRole.host,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.localSync,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: _buildSelectionState(context, colorScheme, textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      key: const ValueKey('selection_state'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          'What is this Device?',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 32),

        // Role Selector Row: Text 'Host' -> Switch -> Text 'Client'
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Host Label
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _updateRole(false),
                behavior: HitTestBehavior.opaque,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    fontWeight: !_isClient ? FontWeight.bold : FontWeight.normal,
                    color: !_isClient
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  child: const Text('Host'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Toggle Switch
            Switch(
              value: _isClient,
              onChanged: (value) => _updateRole(value),
            ),
            const SizedBox(width: 16),
            // Client Label
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _updateRole(true),
                behavior: HitTestBehavior.opaque,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    fontWeight: _isClient ? FontWeight.bold : FontWeight.normal,
                    color: _isClient
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  child: const Text('Client'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Brief, professional helper text explaining active role
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
            key: ValueKey<bool>(_isClient),
            height: 48,
            child: Center(
              child: Text(
                _isClient
                    ? 'Client mode enables this device to search the local network and sync with an active host.'
                    : 'Host mode allows this device to broadcast on the local network and share notes with client devices.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Action Button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: FilledButton.icon(
            key: ValueKey<bool>(_isClient),
            onPressed: () async {
              if (_isClient) {
                // CLIENT MODE: Stop any active Host server & mDNS broadcasting
                ref.read(syncServerProvider.notifier).stopHosting();
                ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
                ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.client);

                final option = RightPanelPageOptions.clientMode;
                ref.read(drawerNavigationProvider).navigate(context, option);
              } else {
                // HOST MODE: Stop any active Client dialer & mDNS scanning
                ref.read(syncClientProvider.notifier).disconnect();
                ref.read(mdnsSearcherProvider.notifier).stopScan();

                ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.host);
                await ref.read(syncEngineProvider.notifier).setEngine(SyncEngine.local);

                // Re-evaluate host server and mDNS broadcast cleanly
                ref.invalidate(syncSessionProvider);
                ref.invalidate(serverHostingProvider);

                if (!context.mounted) return;
                ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.hostMode);
              }
            },
            icon: Icon(_isClient ? Icons.search_rounded : Icons.wifi_tethering_rounded),
            label: Text(_isClient ? 'Find Host' : 'Start Hosting'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // History Button
        const SyncHistoryButton(),
      ],
    );
  }
}