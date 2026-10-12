
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';

import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../database/sync/sync_orchestrator.dart';

@immutable
class LockState {
  final Set<String> sessionUnlockedNoteIds;
  final bool isAuthenticating;
  final String? error;
  final bool keepUnlockedDuringSession;
  final bool hasMasterPassword;

  const LockState({
    this.sessionUnlockedNoteIds = const {},
    this.isAuthenticating = false,
    this.error,
    this.keepUnlockedDuringSession = false,
    this.hasMasterPassword = false,
  });

  LockState copyWith({
    Set<String>? sessionUnlockedNoteIds,
    bool? isAuthenticating,
    String? error,
    bool? keepUnlockedDuringSession,
    bool? hasMasterPassword,
  }) {
    return LockState(
      sessionUnlockedNoteIds: sessionUnlockedNoteIds ?? this.sessionUnlockedNoteIds,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      error: error ?? this.error,
      keepUnlockedDuringSession: keepUnlockedDuringSession ?? this.keepUnlockedDuringSession,
      hasMasterPassword: hasMasterPassword ?? this.hasMasterPassword,
    );
  }
}

final lockManagerProvider = NotifierProvider<LockNotifier, LockState>(() => LockNotifier());

class LockNotifier extends Notifier<LockState> {
  @override
  LockState build() {
    // Initialize the state using saved preferences
    final keepUnlocked = ref.read(sharedPreferenceProvider).keepUnlockedDuringSession;
    final hasPass = ref.read(sharedPreferenceProvider).hasMasterPassword;
    return LockState(
      keepUnlockedDuringSession: keepUnlocked,
      hasMasterPassword: hasPass,
    );
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

  bool verifyPassword(String password) {
    final savedPassword = ref.read(sharedPreferenceProvider).masterPassword;
    return savedPassword != null && savedPassword == password;
  }

  bool verifyAndSessionUnlock(String uuid, String password) {
    if (verifyPassword(password)) {
      //  Only cache the UUID if the user has the setting enabled
      if (state.keepUnlockedDuringSession) {
        final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..add(uuid);
        state = state.copyWith(sessionUnlockedNoteIds: updatedSet, error: null);
      } else {
        //  If the setting is off, clear errors but do NOT cache the session
        state = state.copyWith(error: null);
      }
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
      AppLogger.d('LockNotifier: Master password created successfully');
      state = state.copyWith(
        isAuthenticating: false,
        hasMasterPassword: true,
      );
      return success;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to setup master password', error: e, stack: st);
      state = state.copyWith(isAuthenticating: false, error: 'Failed to save password');
      return false;
    }
  }

  Future<bool> removeMasterPassword() async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      // 1. Unlock all locked notes in the local database
      await ref.read(notesDaoProvider).unlockAllNotes();

      // 2. Remove master password from preferences
      final success = await ref.read(sharedPreferenceProvider).removeMasterPassword();

      // 3. Clear session memory
      clearAllSessions();

      AppLogger.d('LockNotifier: Master password removed and all notes unlocked');

      // 4. Update state
      state = state.copyWith(
        isAuthenticating: false,
        hasMasterPassword: false,
      );

      // 5. Trigger sync so changes propagate to sync targets
      ref.read(syncOrchestratorProvider).triggerSync();

      return success;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to remove master password', error: e, stack: st);
      state = state.copyWith(isAuthenticating: false, error: 'Failed to remove password');
      return false;
    }
  }

  void clearAllSessions() {
    AppLogger.d('LockNotifier: Cleared all session unlocked note IDs');
    state = state.copyWith(sessionUnlockedNoteIds: const {});
  }

  void lockSessionNote(String uuid) {
    final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..remove(uuid);
    state = state.copyWith(sessionUnlockedNoteIds: updatedSet);
  }

  Future<bool> togglePersistentLock(
    String uuid,
    String password, {
    required bool shouldLock,
    bool ignorePassword = false,
  }) async {
    // Only verify the password if we are UNLOCKING, AND we aren't explicitly ignoring the password check
    if (!shouldLock && !ignorePassword) {
      if (!verifyPassword(password)) {
        AppLogger.w('LockNotifier: Incorrect password during note lock toggle for $uuid');
        state = state.copyWith(error: 'Incorrect Password');
        return false;
      }
    }

    try {
      await ref.read(notesDaoProvider).lockNote(uuid, isLocked: shouldLock);

      final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds);
      // Remove it from temporary session memory to keep state clean
      updatedSet.remove(uuid);

      state = state.copyWith(sessionUnlockedNoteIds: updatedSet);

      AppLogger.d('LockNotifier: Toggled persistent lock for note $uuid (isLocked: $shouldLock)');

      // Tell the Orchestrator to broadcast the lock state change
      ref.read(syncOrchestratorProvider).triggerSync();
      return true;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to toggle note lock', error: e, stack: st);
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
