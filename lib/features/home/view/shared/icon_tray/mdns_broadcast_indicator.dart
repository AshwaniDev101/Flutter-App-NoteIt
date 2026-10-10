import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../local_sync/auto_connect/mdns_broadcast.dart';

class MdnsBroadcastIndicator extends ConsumerWidget {
  const MdnsBroadcastIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch strictly for active mDNS registrations
    final isBroadcasting = ref.watch(mdnsBroadcastProvider) != null;

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
              // Inner tight glow
              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 3, spreadRadius: 0),
              // Outer soft glow
              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: const Icon(
            Icons.wifi, // Or Icons.sensors
            color: Colors.cyanAccent,
            size: 16,
          ),
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: isBroadcasting
          ? Tooltip(message: 'Broadcasting sync availability', child: content)
          : const SizedBox.shrink(),
    );
  }
}
