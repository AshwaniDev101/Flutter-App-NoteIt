import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/drift/local_database.dart';
import '../../../../features/lock/lock_manger/lock_manager.dart';

class LockOverlayWidget extends ConsumerWidget {
  final Note note;

  const LockOverlayWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If completely unlocked, render nothing (no overlay)
    if (!note.isLocked) return const SizedBox.shrink();

    // Check session state
    final isSessionUnlocked = ref.watch(lockManagerProvider).sessionUnlockedNoteIds.contains(note.uuid);

    // If session unlocked -> Transparent background, small icon top-right
    if (isSessionUnlocked) {
      return const Positioned(
        top: 0,
        right: 0,
        child: Icon(
          Icons.lock_open_rounded,
          size: 18,
          color: Colors.grey,
        ),
      );
    }

    // If fully locked -> Opaque grey background, big icon in center
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}