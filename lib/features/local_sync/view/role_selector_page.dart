import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
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
    // Default to 'Client' on mobile and 'Host' on desktop
    _isClient = !PlatformHelper.isNativeDesktop;

    // Immediately save initial device role preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedPreferenceProvider).setSyncRole(
            _isClient ? SyncRole.client : SyncRole.host,
          );
    });
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
          'This Device is a ?',
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
            onPressed: () {
              ref.read(sharedPreferenceProvider).setSyncRole(
                    _isClient ? SyncRole.client : SyncRole.host,
                  );

              final option = _isClient
                  ? RightPanelPageOptions.clientMode
                  : RightPanelPageOptions.hostMode;
              ref.read(drawerNavigationProvider).navigate(context, option);
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}