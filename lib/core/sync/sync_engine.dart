import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

enum SyncEngine { cloud, local, offline }

final syncEngineProvider = NotifierProvider<SyncEngineNotifier, SyncEngine>(() {
  return SyncEngineNotifier();
});

class SyncEngineNotifier extends Notifier<SyncEngine> {
  @override
  SyncEngine build() {
    // Grab the initial saved value when the app boots
    return ref.watch(sharedPreferenceProvider).currentEngine;
  }

  Future<void> setEngine(SyncEngine newEngine) async {
    // Save to the physical device disk
    await ref.read(sharedPreferenceProvider).setCurrentEngine(newEngine);
    // Update the Riverpod state to instantly trigger Firebase/UI listeners
    state = newEngine;
  }

  /// Attempts to switch sync engine mode with an Auth Guard.
  /// If [SyncEngine.cloud] is requested and the user is unauthenticated,
  /// prompts Google Sign-In via [AuthRepository].
  /// Returns `true` if mode was successfully updated, or `false` if cancelled/failed.
  Future<bool> requestEngineChange(SyncEngine requestedEngine) async {
    if (requestedEngine != SyncEngine.cloud) {
      await setEngine(requestedEngine);
      return true;
    }

    final authRepo = ref.read(authRepositoryProvider);

    if (authRepo.isSignedIn) {
      AppLogger.d("SyncEngineNotifier: User is already signed in. Switching to Cloud Engine.");
      await setEngine(SyncEngine.cloud);
      return true;
    }

    AppLogger.d("SyncEngineNotifier: Cloud Engine requested but user is unauthenticated. Prompting Google Sign-In...");
    final user = await authRepo.signInWithGoogle();

    if (user != null) {
      AppLogger.d("SyncEngineNotifier: Google Sign-In successful. Switching to Cloud Engine.");
      await setEngine(SyncEngine.cloud);
      return true;
    } else {
      AppLogger.w("SyncEngineNotifier: Google Sign-In failed or cancelled. Reverting/keeping current Engine.");
      return false;
    }
  }
}
