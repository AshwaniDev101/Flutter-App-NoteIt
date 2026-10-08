import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../database/sync/local_sync_service.dart';
import '../../../../local_sync/provider/sync_server_provider.dart';

class WebSocketConnectionIndicator extends ConsumerWidget {
  const WebSocketConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Is the server running (waiting for a client)?
    final bool isHosting = ref.watch(syncServerProvider) != null;

    // Is there a successful two-way connection? (Works for both Host and Client)
    final bool isConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;

    // Determine visibility: Show if we are hosting OR connected
    final bool shouldShow = isHosting || isConnected;

    //  Determine styling based on the exact state
    final Color iconColor = isConnected ? Colors.greenAccent : Colors.orangeAccent;
    final IconData iconData = isConnected ? Icons.wifi : Icons.wifi_tethering;

    return AnimatedScale(
      scale: shouldShow ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        // The ValueKey tells AnimatedSwitcher to animate the transition when the state changes
        child: Container(
          key: ValueKey(isConnected),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 16,
          ),
        ),
      ),
    );
  }
}