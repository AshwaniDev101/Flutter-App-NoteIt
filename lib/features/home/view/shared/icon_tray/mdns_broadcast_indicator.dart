import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/local_sync/data/network/mdns_broadcast.dart';

class MdnsBroadcastIndicator extends ConsumerWidget {
  const MdnsBroadcastIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch strictly for active mDNS registrations
    final isBroadcasting = ref.watch(mdnsBroadcastProvider) != null;
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;

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
              BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 3, spreadRadius: 0),
              BoxShadow(color: iconColor.withValues(alpha: 0.15), blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: Icon(
            Icons.wifi,
            color: iconColor,
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
