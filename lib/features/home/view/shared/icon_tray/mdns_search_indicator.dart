import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../local_sync/auto_connect/mdns_searcher.dart';

class MdnsSearchIndicator extends ConsumerWidget {
  const MdnsSearchIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //  Watch strictly for the scanning status
    final isSearching = ref.watch(mdnsSearcherProvider).status == ScanStatus.scanning;

    Widget content = Container(
      width: 32,
      alignment: Alignment.center,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [// Inner tight glow
              BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 3, spreadRadius: 0),
              // Outer soft glow
              BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1),],
          ),
          child: const Icon(Icons.search, color: Colors.amber, size: 16),
        ),
      ),
    );

    // AnimatedSwitcher handles smooth scaling and fading when the widget appears/disappears
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Combines scale and size transitions so it shrinks both visually and in layout footprint
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      // Return the UI if searching, else return a zero-size widget
      child: isSearching
          ? Tooltip(message: 'Searching for nearby devices...', child: content)
          : const SizedBox.shrink(), // Takes up exactly 0 pixels when inactive
    );
  }
}
