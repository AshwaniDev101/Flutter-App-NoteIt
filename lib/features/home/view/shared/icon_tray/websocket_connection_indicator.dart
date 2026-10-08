import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../database/sync/local_sync_service.dart';
import '../../../../local_sync/provider/sync_server_provider.dart';

/// Represents the high-level WebSocket connection lifecycle states.
enum WebSocketActivity {
  disconnected(icon: Icons.circle, color: Colors.transparent, tooltip: null),
  hosting(
    icon: Icons.circle_outlined,
    color: Colors.orangeAccent,
    tooltip: 'Host server running, waiting for client...',
  ),
  connected(
    icon: Icons.check_circle_outline,
    color: Colors.greenAccent,
    tooltip: 'Devices connected over Wi-Fi',
  );

  final IconData icon;
  final Color color;
  final String? tooltip;

  const WebSocketActivity({required this.icon, required this.color, this.tooltip});

  bool get isVisible => this != WebSocketActivity.disconnected;

  static WebSocketActivity resolve({required bool isHosting, required bool isConnected}) {
    if (isConnected) return WebSocketActivity.connected;
    if (isHosting) return WebSocketActivity.hosting;
    return WebSocketActivity.disconnected;
  }
}

class WebSocketConnectionIndicator extends ConsumerWidget {
  const WebSocketConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHosting = ref.watch(syncServerProvider) != null;
    final bool isConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;

    final activity = WebSocketActivity.resolve(isHosting: isHosting, isConnected: isConnected);

    Widget content = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (activity.isVisible)
            BoxShadow(color: activity.color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Icon(activity.icon, color: activity.color, size: 16),
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
          ? Padding(
        // Padding added here so it also collapses when the widget disappears
        padding: const EdgeInsets.only(right: 8.0),
        child: KeyedSubtree(
          key: ValueKey(activity),
          child: content,
        ),
      )
          : const SizedBox.shrink(), // Takes up 0 pixels in the Row when disconnected
    );
  }
}