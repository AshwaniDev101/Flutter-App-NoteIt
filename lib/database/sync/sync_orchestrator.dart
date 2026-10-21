import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/database/sync/sync_engine.dart';
import 'package:noteit/features/local_sync/auto_connect/mdns_broadcast.dart';
import 'package:noteit/features/local_sync/auto_connect/mdns_searcher.dart';
import 'package:noteit/features/local_sync/provider/sync_client_provider.dart';
import 'package:noteit/features/local_sync/provider/sync_server_provider.dart';
import '../firebase/auth/firebase_provider.dart';
import '../../core/util/logger.dart';
import 'cloud_sync_service.dart';
import 'local_sync_service.dart';

final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(() {
  return IsSyncingNotifier();
});

class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false; // initial state

  void setSyncing(bool value) => state = value;
}

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

    // Initial state evaluation scheduled safely after provider build completes
    Future.microtask(() {
      _evaluateState();
    });

    // Listen for Engine Mode Swaps (Cloud vs Local vs Offline)
    ref.listen(syncEngineProvider, (previous, next) {
      _evaluateState();
    });

    // Listen for Logins and Logouts
    ref.listen(authStateProvider, (previous, next) {
      _evaluateState();
    });
  }

  void _stopAllLocalSyncServices() {
    AppLogger.d("SyncOrchestrator: Stopping all Local Wi-Fi Sync services...");
    ref.read(localSyncServiceProvider.notifier).stop();
    ref.read(syncServerProvider.notifier).stopHosting();
    ref.read(mdnsBroadcastProvider.notifier).stopBroadcasting();
    ref.read(mdnsSearcherProvider.notifier).stopScan();
    ref.read(syncClientProvider.notifier).disconnect();
    ref.read(sharedPreferenceProvider).setSyncRole(SyncRole.undefine);
  }

  // The Master Switchboard: Turns background listeners on or off
  void _evaluateState() {
    final engine = ref.read(syncEngineProvider);
    final user = ref.read(authStateProvider).value;

    final cloudWorker = ref.read(cloudSyncServiceProvider);

    if (engine == SyncEngine.cloud && user != null) {
      _stopAllLocalSyncServices();
      cloudWorker.start();
    } else if (engine == SyncEngine.local) {
      cloudWorker.stop();
    } else {
      // Offline mode, or user logged out
      cloudWorker.stop();
      _stopAllLocalSyncServices();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only fire Firebase delta syncs on resume if Cloud is actively selected
    if (state == AppLifecycleState.resumed) {
      if (ref.read(syncEngineProvider) == SyncEngine.cloud) {
        AppLogger.d("SyncOrchestrator: App resumed. Triggering Cloud Delta Sync...");
        ref.read(cloudSyncServiceProvider).executeFullSync();
      }
    }
  }

  // When EditNoteViewModel calls this, it routes the data to the correct engine.
  void triggerSync() {
    final engine = ref.read(syncEngineProvider);

    if (engine == SyncEngine.cloud) {
      AppLogger.d("SyncOrchestrator: UI triggered sync. Routing to Cloud Engine.");
      ref.read(cloudSyncServiceProvider).executeFullSync();
    } else if (engine == SyncEngine.local) {
      AppLogger.d("SyncOrchestrator: UI triggered sync. Routing to Local Wi-Fi Engine.");
      ref.read(localSyncServiceProvider.notifier).broadcastLocalChanges();
    } else {
      AppLogger.d("SyncOrchestrator: UI triggered sync, but app is Offline. Ignored.");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
