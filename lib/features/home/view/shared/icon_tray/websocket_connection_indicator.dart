import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/util/platform_helper.dart';
import '../../../../../database/sync/local_sync_service.dart';
import '../../../../local_sync/provider/sync_server_provider.dart';

/// Represents the high-level WebSocket connection lifecycle states.
enum WebSocketActivity {
  disconnected( color: Colors.transparent, tooltip: null),
  hosting(
    color: Colors.blueAccent,
    tooltip: 'Host server running, waiting for client...',
  ),


  connected(color: Colors.greenAccent, tooltip: 'Devices connected over Wi-Fi');

  final Color color;
  final String? tooltip;

  const WebSocketActivity({required this.color, this.tooltip});


  // Evaluate the icon dynamically at runtime using a getter
  IconData get icon {
    switch (this) {
      case WebSocketActivity.disconnected:
        return Icons.circle;
      case WebSocketActivity.hosting:
        return Icons.circle_outlined;
      case WebSocketActivity.connected:
        return PlatformHelper.isDesktopScreen ? Icons.phone_iphone_sharp : Icons.monitor;
    }
  }

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
