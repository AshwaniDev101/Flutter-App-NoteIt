import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

/// Available sync engines with associated label, description, and icon.
enum SyncEngine {
  cloud(
    label: 'Cloud',
    description: 'Sync notes across devices using cloud storage',
    icon: Icons.cloud_outlined,
  ),
  local(
    label: 'Local Network',
    description: 'Sync notes directly with devices on your local network',
    icon: Icons.wifi,
  ),
  offline(
    label: 'Offline',
    description: 'Keep all notes stored only on this device',
    icon: Icons.signal_wifi_off,
  );

  final String label;
  final String description;
  final IconData icon;

  const SyncEngine({
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Unified synchronization mode of the application.
enum SyncMode {
  /// Local-only mode; background syncing is disabled.
  offline,

  /// Cloud backend sync (e.g. Firebase / Google Drive).
  cloud,

  /// Local P2P sync acting as a Host (WebSocket Server / mDNS Broadcaster).
  localHost,

  /// Local P2P sync acting as a Client (WebSocket Client / mDNS Searcher).
  localClient,

  /// Local P2P sync enabled, but role (Host vs Client) is pending selection.
  localUndefined;

  /// Whether local P2P sync is active (Host, Client, or Undefined).
  bool get isLocal => this == SyncMode.localHost || this == SyncMode.localClient || this == SyncMode.localUndefined;

  /// Whether the device operates as a local P2P Host.
  bool get isHost => this == SyncMode.localHost;

  /// Whether the device operates as a local P2P Client.
  bool get isClient => this == SyncMode.localClient;

  /// Whether cloud sync is active.
  bool get isCloud => this == SyncMode.cloud;

  /// Whether offline mode is active.
  bool get isOffline => this == SyncMode.offline;

  /// Whether any remote or P2P sync is enabled.
  bool get isSyncing => this != SyncMode.offline;
}

/// Unified Provider for accessing and modifying the active app-wide [SyncMode].
final syncModeProvider = NotifierProvider<SyncModeNotifier, SyncMode>(() {
  return SyncModeNotifier();
});

/// Legacy provider for backwards compatibility.
final syncEngineProvider = NotifierProvider<SyncEngineNotifier, SyncEngine>(() {
  return SyncEngineNotifier();
});

class SyncModeNotifier extends Notifier<SyncMode> {
  @override
  SyncMode build() {
    final initialMode = SharedPreferenceManager.instance.syncMode;

    // Reactively bind SyncMode to Google Auth state
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      if (!next.hasValue) return;

      final user = next.value;
      final currentMode = state;

      if (user == null && currentMode == SyncMode.cloud) {
        AppLogger.d("SyncModeNotifier: User unauthenticated. Falling back from Cloud to Offline mode.");
        Future.microtask(() => setMode(SyncMode.offline));
      } else if (user != null && currentMode == SyncMode.offline) {
        AppLogger.d("SyncModeNotifier: User authenticated. Automatically switching from Offline to Cloud mode.");
        Future.microtask(() => setMode(SyncMode.cloud));
      }
    }, fireImmediately: true);

    return initialMode;
  }

  Future<void> setMode(SyncMode newMode) async {
    await SharedPreferenceManager.instance.setSyncMode(newMode);
    state = newMode;
  }

  /// Attempts to switch sync mode with an Auth Guard.
  /// If [SyncMode.cloud] is requested and the user is unauthenticated,
  /// prompts Google Sign-In via [AuthRepository].
  /// Returns `true` if mode was successfully updated, or `false` if cancelled/failed.
  Future<bool> requestModeChange(SyncMode requestedMode) async {
    if (requestedMode != SyncMode.cloud) {
      await setMode(requestedMode);
      return true;
    }

    final authRepo = ref.read(authRepositoryProvider);

    if (authRepo.isSignedIn && authRepo.currentUser?.email != null) {
      await setMode(SyncMode.cloud);
      return true;
    }

    AppLogger.d("SyncModeNotifier: Cloud Mode requested but user is unauthenticated. Prompting Google Sign-In...");
    final result = await authRepo.signInWithGoogleDetails();
    final user = result.user;

    if (user != null && user.email != null) {
      await setMode(SyncMode.cloud);
      AppLogger.d("SyncModeNotifier: Google Sign-In successful. Switching to Cloud Mode.");
      return true;
    } else {
      AppLogger.w("SyncModeNotifier: Google Sign-In failed or cancelled. Reverting/keeping current Mode.");
      return false;
    }
  }
}

class SyncEngineNotifier extends Notifier<SyncEngine> {
  @override
  SyncEngine build() {
    final mode = ref.watch(syncModeProvider);
    if (mode.isCloud) return SyncEngine.cloud;
    if (mode.isLocal) return SyncEngine.local;
    return SyncEngine.offline;
  }

  Future<void> setEngine(SyncEngine newEngine) async {
    switch (newEngine) {
      case SyncEngine.cloud:
        await ref.read(syncModeProvider.notifier).setMode(SyncMode.cloud);
        break;
      case SyncEngine.offline:
        await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
        break;
      case SyncEngine.local:
        final current = ref.read(syncModeProvider);
        if (!current.isLocal) {
          await ref.read(syncModeProvider.notifier).setMode(SyncMode.localUndefined);
        }
        break;
    }
  }

  Future<bool> requestEngineChange(SyncEngine requestedEngine) async {
    switch (requestedEngine) {
      case SyncEngine.cloud:
        return await ref.read(syncModeProvider.notifier).requestModeChange(SyncMode.cloud);
      case SyncEngine.offline:
        await ref.read(syncModeProvider.notifier).setMode(SyncMode.offline);
        return true;
      case SyncEngine.local:
        final current = ref.read(syncModeProvider);
        if (!current.isLocal) {
          await ref.read(syncModeProvider.notifier).setMode(SyncMode.localUndefined);
        }
        return true;
    }
  }
}
