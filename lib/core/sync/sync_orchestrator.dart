import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:noteit/features/local_sync/data/network/local_sync_service.dart';
import 'package:noteit/features/local_sync/data/providers/local_sync_session_manager.dart';
import 'package:noteit/features/profiles/providers/active_profile_provider.dart';

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

    // Listen for Sync Mode Swaps (Cloud vs Local vs Offline)
    ref.listen(syncModeProvider, (previous, next) {
      _evaluateState();
    });

    // Listen for Logins and Logouts
    ref.listen(authStateProvider, (previous, next) {
      _evaluateState();
    });
  }

  void _stopAllLocalSyncServices() {
    AppLogger.d("SyncOrchestrator: Stopping all Local Wi-Fi Sync services...");
    ref.read(localSyncSessionProvider.notifier).endSession();
  }

  // The Master Switchboard: Turns background listeners on or off
  void _evaluateState() {
    final activeProfileNotifier = ref.read(activeProfileProvider.notifier);
    if (activeProfileNotifier.isSwitching) {
      AppLogger.d("SyncOrchestrator: Profile switch in progress. Skipping state evaluation.");
      return;
    }

    final mode = ref.read(syncModeProvider);
    final user = ref.read(authStateProvider).value;
    final activeProfile = ref.read(activeProfileProvider);

    final isMatchingUser = user != null &&
        (activeProfile.linkedEmail == null ||
            user.email?.toLowerCase() == activeProfile.linkedEmail?.toLowerCase());

    final cloudWorker = ref.read(cloudSyncServiceProvider);

    if (mode.isCloud && isMatchingUser) {
      _stopAllLocalSyncServices();
      cloudWorker.start();
    } else if (mode.isLocal) {
      cloudWorker.stop();
    } else {
      // Offline mode, or user logged out, or mismatched user
      cloudWorker.stop();
      _stopAllLocalSyncServices();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ref.read(activeProfileProvider.notifier).isSwitching) return;

    // Only fire Firebase delta syncs on resume if Cloud is actively selected
    if (state == AppLifecycleState.resumed) {
      if (ref.read(syncModeProvider).isCloud) {
        AppLogger.d("SyncOrchestrator: App resumed. Triggering Cloud Delta Sync...");
        ref.read(cloudSyncServiceProvider).executeFullSync();
      }
    }
  }

  // When EditNoteViewModel calls this, it routes the data to the correct engine.
  void triggerSync() {
    final mode = ref.read(syncModeProvider);

    if (mode.isCloud) {
      AppLogger.d("SyncOrchestrator: UI triggered sync. Routing to Cloud Engine.");
      ref.read(cloudSyncServiceProvider).executeFullSync();
    } else if (mode.isLocal) {
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
