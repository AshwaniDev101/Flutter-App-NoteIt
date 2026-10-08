import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../local_sync/auto_connect/mdns_broadcast.dart';
import '../../../../local_sync/auto_connect/mdns_searcher.dart';


enum MdnsActivity { idle, broadcasting, searching }

class MdnsStatusIndicator extends ConsumerWidget {
  const MdnsStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if mDNS is actively scanning/searching for nearby hosts
    final searchState = ref.watch(mdnsSearcherProvider);
    final bool isSearching = searchState.status == ScanStatus.scanning;

    // Check if mDNS is broadcasting (null means stopped, non-null means active)
    final bool isBroadcasting = ref.watch(mdnsBroadcastProvider) != null;

    // Resolve active activity
    final MdnsActivity activity;
    if (isSearching) {
      activity = MdnsActivity.searching;
    } else if (isBroadcasting) {
      activity = MdnsActivity.broadcasting;
    } else {
      activity = MdnsActivity.idle;
    }

    // Configure visual styling based on the active role
    final IconData iconData;
    final Color iconColor;

    switch (activity) {
      case MdnsActivity.searching:
        iconData = Icons.radar;
        iconColor = Colors.amberAccent;
        break;
      case MdnsActivity.broadcasting:
        iconData = Icons.sensors;
        iconColor = Colors.cyanAccent;
        break;
      case MdnsActivity.idle:
        iconData = Icons.sensors;
        iconColor = Colors.transparent;
        break;
    }

    return AnimatedScale(
      scale: activity != MdnsActivity.idle ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(activity),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (activity != MdnsActivity.idle)
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.4),
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