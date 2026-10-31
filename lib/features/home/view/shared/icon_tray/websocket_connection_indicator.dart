import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/helpers/platform_helper.dart';
import '../../../../../database/sync/local_sync_service.dart';
import '../../../../local_sync/provider/sync_server_provider.dart';

/// Represents the high-level WebSocket connection lifecycle states.
enum WebSocketActivity {
  disconnected(color: Colors.transparent, tooltip: null),
  hosting(
    color: Colors.greenAccent,
    tooltip: 'Host server running, waiting for client...',
  ),
  reconnecting(
    color: Colors.amberAccent,
    tooltip: 'Reconnecting / Probing sync connection...',
  ),
  connected(color: Colors.greenAccent, tooltip: 'Devices connected over Wi-Fi');

  final Color color;
  final String? tooltip;

  const WebSocketActivity({required this.color, this.tooltip});

  IconData get icon {
    switch (this) {
      case WebSocketActivity.disconnected:
        return Icons.circle;
      case WebSocketActivity.hosting:
        return Icons.circle_outlined;
      case WebSocketActivity.reconnecting:
        return Icons.sync_problem;
      case WebSocketActivity.connected:
        return PlatformHelper.isDesktopScreen ? Icons.phone_iphone_sharp : Icons.monitor;
    }
  }

  bool get isVisible => this != WebSocketActivity.disconnected;

  static WebSocketActivity resolve({
    required bool isHosting,
    required SyncConnectionState syncState,
  }) {
    if (syncState == SyncConnectionState.connected) return WebSocketActivity.connected;
    if (syncState == SyncConnectionState.reconnecting || syncState == SyncConnectionState.ghostDetected) {
      return WebSocketActivity.reconnecting;
    }
    if (isHosting) return WebSocketActivity.hosting;
    return WebSocketActivity.disconnected;
  }
}

class WebSocketConnectionIndicator extends ConsumerWidget {
  const WebSocketConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHosting = ref.watch(syncServerProvider) != null;
    final SyncConnectionState syncState = ref.watch(localSyncServiceProvider);

    final activity = WebSocketActivity.resolve(isHosting: isHosting, syncState: syncState);

    Widget content = Container(
      width: 32,
      alignment: Alignment.center,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (activity.isVisible) ...[
                // Inner tight glow (creates intensity)
                BoxShadow(
                    color: activity.color.withValues(alpha: 0.5),
                    blurRadius: 3,
                    spreadRadius: 0),

                // Outer soft glow (creates the ambient light effect)
                BoxShadow(
                  color: activity.color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ],
          ),
          child: Icon(activity.icon, color: activity.color, size: 16),
        ),
      ),
    );

    if (activity.tooltip != null) {
      content = Tooltip(message: activity.tooltip!, child: content);
    }

    // Use AnimatedSwitcher with SizeTransition so it fully collapses when disconnected
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // This ensures the widget shrinks visually AND loses its layout footprint
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: activity.isVisible
          ? KeyedSubtree(key: ValueKey(activity), child: content)
          : const SizedBox.shrink(), // Takes up 0 pixels in the Row when disconnected
    );
  }
}
