import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/core/theme/network_signal_colors.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';

/// Represents the high-level WebSocket connection lifecycle states.
enum WebSocketActivity {
  disconnected(icon: Icons.signal_wifi_connected_no_internet_4, tooltip: "Disconnected"),
  hosting(
    icon: Icons.wifi_tethering_rounded,
    tooltip: 'Host server running, waiting for client...',
  ),
  reconnecting(
    icon: Icons.change_circle_outlined,
    tooltip: 'Connection lost, attempting fast reconnect...',
  ),
  connected(icon: Icons.check_circle, tooltip: 'Sync connected!');

  final IconData icon;
  final String tooltip;

  const WebSocketActivity({required this.icon, required this.tooltip});

  Color getColor(BuildContext context) {
    final netColors = Theme.of(context).extension<NetworkSignalColors>();
    if (netColors != null) {
      switch (this) {
        case WebSocketActivity.connected:
          return netColors.connected;
        case WebSocketActivity.reconnecting:
          return netColors.connecting;
        case WebSocketActivity.hosting:
          return Theme.of(context).colorScheme.onSurface;
        case WebSocketActivity.disconnected:
          return netColors.failed;
      }
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class WebSocketConnectionIndicator extends ConsumerWidget {
  const WebSocketConnectionIndicator({super.key});

  /// Master Rule Evaluator for Connection Dot Status
  static WebSocketActivity evaluateActivity({required bool isHosting, required SyncConnectionState syncState}) {
    if (syncState == SyncConnectionState.connected) return WebSocketActivity.connected;
    if (syncState == SyncConnectionState.reconnecting) return WebSocketActivity.reconnecting;
    if (isHosting) return WebSocketActivity.hosting;

    return WebSocketActivity.disconnected;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHosting = ref.watch(syncServerProvider) != null;
    final SyncConnectionState syncState = ref.watch(localSyncServiceProvider);

    final activity = evaluateActivity(isHosting: isHosting, syncState: syncState);

    if (activity == WebSocketActivity.disconnected) {
      return const SizedBox.shrink();
    }

    final isWide = PlatformHelper.isWideLayout(context);
    final color = activity.getColor(context);

    Widget dot = Icon(activity.icon, color: color);

    if (isWide) {
      return Tooltip(
        message: activity.tooltip,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: dot),
      );
    }

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: dot);
  }
}
