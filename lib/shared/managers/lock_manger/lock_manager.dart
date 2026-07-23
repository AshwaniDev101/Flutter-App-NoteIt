import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';
import 'package:noteit/database/sync_manager.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';

@immutable
class LockState {
  final Set<int> sessionUnlockedNoteIds;
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
    Set<int>? sessionUnlockedNoteIds,
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

class LockManager extends Notifier<LockState> {
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

  bool isNoteSessionUnlocked(int id) {
    return state.sessionUnlockedNoteIds.contains(id);
  }

  bool verifyPassword(String password) {
    final savedPassword = ref.read(sharedPreferenceProvider).masterPassword;
    return savedPassword != null && savedPassword == password;
  }

  bool verifyAndSessionUnlock(int id, String password) {
    if (verifyPassword(password)) {
      final updatedSet = Set<int>.from(state.sessionUnlockedNoteIds)..add(id);
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

  void lockSessionNote(int id) {
    final updatedSet = Set<int>.from(state.sessionUnlockedNoteIds)..remove(id);
    state = state.copyWith(sessionUnlockedNoteIds: updatedSet);
  }

  Future<bool> togglePersistentLock(int id, String password, {required bool shouldLock, bool ignorePassword = false}) async {

    // Only verify the password if we are UNLOCKING, AND we aren't explicitly ignoring the password check
    if (!shouldLock && !ignorePassword) {
      if (!verifyPassword(password)) {
        state = state.copyWith(error: 'Incorrect Password');
        return false;
      }
    }

    try {
      await ref.read(noteDriftDatabaseProvider).lockNote(id, isLocked: shouldLock);

      final updatedSet = Set<int>.from(state.sessionUnlockedNoteIds);
      // Remove it from temporary session memory to keep state clean
      updatedSet.remove(id);

      state = state.copyWith(sessionUnlockedNoteIds: updatedSet);
      ref.read(syncNotifierProvider.notifier).executeFullSync();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final lockManagerProvider = NotifierProvider<LockManager, LockState>(() => LockManager());