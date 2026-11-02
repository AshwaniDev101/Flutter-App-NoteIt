import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/providers/sync_server_provider.dart';

/// Represents the high-level WebSocket connection lifecycle states.
enum WebSocketActivity {
  disconnected(color: Colors.transparent, tooltip: null),
  hosting(
    color: Colors.greenAccent,
    tooltip: 'Host server running, waiting for client...',
  ),
  reconnecting(
    color: Colors.amberAccent,
    tooltip: 'Connection lost, attempting fast reconnect...',
  ),
  connected(color: Colors.greenAccent, tooltip: 'Sync connected!');

  final Color color;
  final String? tooltip;

  const WebSocketActivity({required this.color, this.tooltip});
}

class WebSocketConnectionIndicator extends ConsumerWidget {
  const WebSocketConnectionIndicator({super.key});

  /// Master Rule Evaluator for Connection Dot Status
  static WebSocketActivity evaluateActivity({
    required bool isHosting,
    required SyncConnectionState syncState,
  }) {
    if (syncState == SyncConnectionState.connected) return WebSocketActivity.connected;
    if (syncState == SyncConnectionState.reconnecting) return WebSocketActivity.reconnecting;
    if (isHosting) return WebSocketActivity.hosting;

    return WebSocketActivity.disconnected;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHosting = ref.watch(syncServerProvider) != null;
    final SyncConnectionState syncState = ref.watch(localSyncServiceProvider);

    final activity = evaluateActivity(
      isHosting: isHosting,
      syncState: syncState,
    );

    if (activity == WebSocketActivity.disconnected) {
      return const SizedBox.shrink();
    }

    final isWide = PlatformHelper.isWideLayout(context);

    Widget dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: activity.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activity.color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (isWide) {
      return Tooltip(
        message: activity.tooltip ?? '',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: dot,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: dot,
    );
  }
}
