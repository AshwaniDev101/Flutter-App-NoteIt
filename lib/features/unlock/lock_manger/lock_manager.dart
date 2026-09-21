import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../database/sync/sync_orchestrator.dart';

@immutable
class LockState {

  final Set<String> sessionUnlockedNoteIds;
  final bool isAuthenticating;
  final String? error;
  final bool keepUnlockedDuringSession;

  const LockState({
    this.sessionUnlockedNoteIds = const {},
    this.isAuthenticating = false,
    this.error,
    this.keepUnlockedDuringSession = false,
  });

  LockState copyWith({
    Set<String>? sessionUnlockedNoteIds,
    bool? isAuthenticating,
    String? error,
    bool? keepUnlockedDuringSession,
  }) {
    return LockState(
      sessionUnlockedNoteIds: sessionUnlockedNoteIds ?? this.sessionUnlockedNoteIds,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      error: error ?? this.error,
      keepUnlockedDuringSession: keepUnlockedDuringSession ?? this.keepUnlockedDuringSession,
    );
  }
}

class LockNotifier extends Notifier<LockState> {
  @override
  LockState build() {
    // Initialize the state using the saved preference
    final keepUnlocked = ref.read(sharedPreferenceProvider).keepUnlockedDuringSession;
    return LockState(keepUnlockedDuringSession: keepUnlocked);
  }

  bool get hasMasterPassword => ref.read(sharedPreferenceProvider).hasMasterPassword;

  // Update the preference both in memory and storage
  Future<void> setKeepUnlockedPreference(bool keepUnlocked) async {
    state = state.copyWith(keepUnlockedDuringSession: keepUnlocked);
    await ref.read(sharedPreferenceProvider).setKeepUnlockedDuringSession(keepUnlocked);

    // If the user turns the feature OFF, immediately clear all active sessions for security
    if (!keepUnlocked) {
      clearAllSessions();
    }
  }

  bool isNoteSessionUnlocked(String uuid) {
    return state.sessionUnlockedNoteIds.contains(uuid);
  }

  bool verifyPassword(String password) {
    final savedPassword = ref.read(sharedPreferenceProvider).masterPassword;
    return savedPassword != null && savedPassword == password;
  }

  bool verifyAndSessionUnlock(String uuid, String password) {
    if (verifyPassword(password)) {
      final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..add(uuid);
      state = state.copyWith(sessionUnlockedNoteIds: updatedSet, error: null);
      return true;
    } else {
      state = state.copyWith(error: 'Incorrect Password');
      return false;
    }
  }

  Future<bool> setupMasterPassword(String password) async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      final success = await ref.read(sharedPreferenceProvider).setMasterPassword(password);
      state = state.copyWith(isAuthenticating: false);
      return success;
    } catch (e) {
      state = state.copyWith(isAuthenticating: false, error: 'Failed to save password');
      return false;
    }
  }

  void clearAllSessions() {
    state = state.copyWith(sessionUnlockedNoteIds: const {});
  }


  void lockSessionNote(String uuid) {
    final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..remove(uuid);
    state = state.copyWith(sessionUnlockedNoteIds: updatedSet);
  }

  Future<bool> togglePersistentLock(String uuid, String password, {required bool shouldLock, bool ignorePassword = false}) async {
    // Only verify the password if we are UNLOCKING, AND we aren't explicitly ignoring the password check
    if (!shouldLock && !ignorePassword) {
      if (!verifyPassword(password)) {
        state = state.copyWith(error: 'Incorrect Password');
        return false;
      }
    }

    try {
      await ref.read(noteDriftDatabaseProvider).lockNote(uuid, isLocked: shouldLock);

      final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds);
      // Remove it from temporary session memory to keep state clean
      updatedSet.remove(uuid);

      state = state.copyWith(sessionUnlockedNoteIds: updatedSet);

      // Tell the Orchestrator to broadcast the lock state change
      ref.read(syncOrchestratorProvider).triggerSync();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final lockManagerProvider = NotifierProvider<LockNotifier, LockState>(() => LockNotifier());