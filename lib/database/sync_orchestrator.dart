import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:noteit/database/sync_engine.dart';
import '../core/provider/provider.dart';
import 'cloud_sync_service.dart';
import 'local_sync_service.dart';

final isSyncingProvider = StateProvider<bool>((ref) => false);

final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final orchestrator = SyncOrchestrator(ref);
  orchestrator.init();

  // Clean up the lifecycle observer if the app closes
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

class SyncOrchestrator with WidgetsBindingObserver {
  final Ref ref;

  SyncOrchestrator(this.ref);

  void init() {
    WidgetsBinding.instance.addObserver(this);

    // Listen for Engine Mode Swaps (Cloud vs Local vs Offline)
    ref.listen(syncEngineProvider, (previous, next) {
      _evaluateState();
    });

    // Listen for Logins and Logouts
    ref.listen(authStateProvider, (previous, next) {
      _evaluateState();
    });
  }

  // The Master Switchboard: Turns background listeners on or off
  void _evaluateState() {
    final engine = ref.read(syncEngineProvider);
    final user = ref.read(authStateProvider).value;

    final cloudWorker = ref.read(cloudSyncServiceProvider);
    final localWorker = ref.read(localSyncServiceProvider);

    if (engine == SyncEngine.cloud && user != null) {
      localWorker.stop();
      cloudWorker.start();
    } else if (engine == SyncEngine.local) {
      cloudWorker.stop();
      localWorker.start();
    } else {
      // Offline mode, or user logged out
      cloudWorker.stop();
      localWorker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only fire Firebase delta syncs on resume if Cloud is actively selected
    if (state == AppLifecycleState.resumed) {
      if (ref.read(syncEngineProvider) == SyncEngine.cloud) {
        print("Orchestrator: App resumed. Triggering Cloud Delta Sync...");
        ref.read(cloudSyncServiceProvider).executeFullSync();
      }
    }
  }


  // When EditNoteViewModel calls this, it routes the data to the correct engine.
  void triggerSync() {
    final engine = ref.read(syncEngineProvider);

    if (engine == SyncEngine.cloud) {
      print("Orchestrator: UI triggered sync. Routing to Cloud Engine.");
      ref.read(cloudSyncServiceProvider).executeFullSync();
    } else if (engine == SyncEngine.local) {
      print("Orchestrator: UI triggered sync. Routing to Local Wi-Fi Engine.");
      ref.read(localSyncServiceProvider).broadcastLocalChanges();
    } else {
      print("Orchestrator: UI triggered sync, but app is Offline. Ignored.");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}