import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/sync/local_sync_service.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../database/sync/sync_orchestrator.dart';
import '../shared/spinning_sync_icon.dart';
import '../shared/websocket_connection_indicator.dart';
import '../../../note_editor/screens/view/desktop_edit_page.dart';

class DesktopRightPanel extends ConsumerWidget {
  final Note? activeNote;

  const DesktopRightPanel({super.key, required this.activeNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(localSyncServiceProvider) == SyncConnectionState.connected;
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(
            elevation: 0,
            actions: [
              WebSocketConnectionIndicator(isConnected: isConnected),
              IconButton(
                tooltip: "Sync Notes",
                icon: SpinningSyncIcon(isSyncing: isSyncing, color: Colors.white),
                onPressed: () {
                  ref.read(syncOrchestratorProvider).triggerSync();
                },
              ),
              const SizedBox(width: 8),
              // Re-add standard window controls manually for desktop frame logic
              IconButton(icon: const Icon(Icons.minimize, size: 16), onPressed: () => windowManager.minimize()),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 16),
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => windowManager.close()),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),

      // Inject the Editor widget if a note is selected, otherwise show a placeholder graphic.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOutCubic,
        // Decelerates smoothly into place
        switchOutCurve: Curves.easeIn,

        transitionBuilder: (Widget child, Animation<double> animation) {
          // Scale from 96% to 100% while fading in
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },

        // The ValueKey is important here. It tells the AnimatedSwitcher when to trigger!
        child: activeNote == null
            ? const _HomepagePlaceholder()
            : DesktopEditNotePage(key: ValueKey(activeNote!.uuid), existingNote: activeNote),
      ),
    );
  }
}

/// A visual placeholder shown when no note is currently selected.
class _HomepagePlaceholder extends StatelessWidget {
  const _HomepagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 64),
          const SizedBox(height: 16),
          Text('No note selected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Select a note from the list or click + to start editing.'),
        ],
      ),
    );
  }
}
