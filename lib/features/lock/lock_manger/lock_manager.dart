import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:noteit/core/crypto/crypto_engine.dart';
import 'package:noteit/core/crypto/secure_storage_manager.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';

@immutable
class LockState {
  final Set<String> sessionUnlockedNoteIds;
  final bool isAuthenticating;
  final String? error;
  final bool keepUnlockedDuringSession;
  final bool hasMasterPassword;
  final List<int>? masterKeyBytes;
  final String? activeRecoveryPhrase;

  const LockState({
    this.sessionUnlockedNoteIds = const {},
    this.isAuthenticating = false,
    this.error,
    this.keepUnlockedDuringSession = false,
    this.hasMasterPassword = false,
    this.masterKeyBytes,
    this.activeRecoveryPhrase,
  });

  LockState copyWith({
    Set<String>? sessionUnlockedNoteIds,
    bool? isAuthenticating,
    String? error,
    bool? keepUnlockedDuringSession,
    bool? hasMasterPassword,
    List<int>? masterKeyBytes,
    bool clearMasterKey = false,
    String? activeRecoveryPhrase,
    bool clearActiveRecoveryPhrase = false,
  }) {
    return LockState(
      sessionUnlockedNoteIds: sessionUnlockedNoteIds ?? this.sessionUnlockedNoteIds,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      error: error,
      keepUnlockedDuringSession: keepUnlockedDuringSession ?? this.keepUnlockedDuringSession,
      hasMasterPassword: hasMasterPassword ?? this.hasMasterPassword,
      masterKeyBytes: clearMasterKey ? null : (masterKeyBytes ?? this.masterKeyBytes),
      activeRecoveryPhrase: clearActiveRecoveryPhrase ? null : (activeRecoveryPhrase ?? this.activeRecoveryPhrase),
    );
  }
}

final lockManagerProvider = NotifierProvider<LockNotifier, LockState>(() => LockNotifier());

class LockNotifier extends Notifier<LockState> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  LockState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _zeroOutMasterKeyMemory();
    });

    final keepUnlocked = ref.read(sharedPreferenceProvider).keepUnlockedDuringSession;
    final hasPass = ref.read(sharedPreferenceProvider).hasMasterPassword;
    return LockState(
      keepUnlockedDuringSession: keepUnlocked,
      hasMasterPassword: hasPass,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Zero out memory and clear unlocked sessions when app moves to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AppLogger.d('LockNotifier: App paused/hidden. Zeroing master key memory.');
      _zeroOutMasterKeyMemory();
    }
  }

  void _zeroOutMasterKeyMemory() {
    if (state.masterKeyBytes != null) {
      try {
        for (int i = 0; i < state.masterKeyBytes!.length; i++) {
          state.masterKeyBytes![i] = 0;
        }
      } catch (_) {}
    }
    state = state.copyWith(
      clearMasterKey: true,
      clearActiveRecoveryPhrase: true,
      sessionUnlockedNoteIds: const {},
    );
  }

  /// Clears active seed recovery phrase from state memory once displayed to user.
  void clearActiveRecoveryPhrase() {
    state = state.copyWith(clearActiveRecoveryPhrase: true);
  }

  bool get hasMasterPassword => ref.read(sharedPreferenceProvider).hasMasterPassword;

  Future<void> setKeepUnlockedPreference(bool keepUnlocked) async {
    state = state.copyWith(keepUnlockedDuringSession: keepUnlocked);
    await ref.read(sharedPreferenceProvider).setKeepUnlockedDuringSession(keepUnlocked);

    if (!keepUnlocked) {
      clearAllSessions();
    }
  }

  /// Zero-knowledge verification of [password] against the local validation marker
  Future<bool> verifyPassword(String password) async {
    final salt = await SecureStorageManager.instance.getMasterSalt();
    final marker = await SecureStorageManager.instance.getLocalValidationMarker();

    if (salt == null || marker == null) {
      return false;
    }

    final derivedKeyData = await CryptoEngine.deriveMasterKey(password, salt: salt);
    final keyBytes = Uint8List.fromList(derivedKeyData.bytes);
    final isValid = await CryptoEngine.verifyValidationMarker(marker, keyBytes);

    if (isValid) {
      state = state.copyWith(masterKeyBytes: keyBytes, error: null);
    }
    return isValid;
  }

  Future<bool> verifyAndSessionUnlock(String uuid, String password) async {
    final isValid = await verifyPassword(password);

    if (isValid) {
      if (state.keepUnlockedDuringSession) {
        final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..add(uuid);
        state = state.copyWith(sessionUnlockedNoteIds: updatedSet, error: null);
      } else {
        state = state.copyWith(error: null);
      }
      return true;
    } else {
      state = state.copyWith(error: 'Incorrect Password');
      return false;
    }
  }

  /// Direct session unlock for active key in memory (e.g. immediately after setup or biometric verification).
  bool sessionUnlockWithActiveKey(String uuid) {
    if (state.masterKeyBytes == null) return false;
    if (state.keepUnlockedDuringSession) {
      final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds)..add(uuid);
      state = state.copyWith(sessionUnlockedNoteIds: updatedSet, error: null);
    } else {
      state = state.copyWith(error: null);
    }
    return true;
  }

  /// Unlocks active session using biometrics (fingerprint/Windows Hello)
  Future<bool> unlockWithBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
        state = state.copyWith(error: 'Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your password-protected notes',
      );

      if (authenticated) {
        final storedKey = await SecureStorageManager.instance.getHardwareMasterKey();
        if (storedKey != null) {
          state = state.copyWith(masterKeyBytes: Uint8List.fromList(storedKey), error: null);
          return true;
        }
      }
      return false;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Biometric authentication failed', error: e, stack: st);
      return false;
    }
  }

  /// Sets up a new Master Password with KDF, validation markers, and 12-word recovery phrase
  Future<bool> setupMasterPassword(
    String password, {
    Uint8List? existingMasterKeyBytes,
  }) async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      final oldMasterKey = existingMasterKeyBytes ??
          (state.masterKeyBytes != null ? Uint8List.fromList(state.masterKeyBytes!) : null);

      final salt = CryptoEngine.generateRandomBytes(16);
      final derivedKeyData = await CryptoEngine.deriveMasterKey(password, salt: salt);
      final masterKeyBytes = Uint8List.fromList(derivedKeyData.bytes);

      if (oldMasterKey != null) {
        await ref.read(notesDaoProvider).reencryptAllLockedNotes(
              oldMasterKey: oldMasterKey,
              newMasterKey: masterKeyBytes,
            );
      }

      final localMarker = await CryptoEngine.createValidationMarker(masterKeyBytes, salt: salt);
      final phrase = CryptoEngine.generateRecoveryPhrase();
      final recoveryKeyData = await CryptoEngine.deriveRecoveryKey(phrase.split(' '), salt: salt);
      final recoveryMarker = await CryptoEngine.createValidationMarker(recoveryKeyData.bytes, salt: salt);
      final wrappedMasterKey = await CryptoEngine.wrapKey(
        keyToWrap: masterKeyBytes,
        wrappingKey: recoveryKeyData.bytes,
      );

      await SecureStorageManager.instance.saveMasterSalt(salt);
      await SecureStorageManager.instance.saveLocalValidationMarker(localMarker);
      await SecureStorageManager.instance.saveRecoveryValidationMarker(recoveryMarker);
      await SecureStorageManager.instance.saveHardwareMasterKey(masterKeyBytes);
      await SecureStorageManager.instance.saveWrappedMasterKey(wrappedMasterKey);

      await ref.read(sharedPreferenceProvider).setHasMasterPassword(true);

      try {
        final firebaseDb = ref.read(noteFirebaseDatabaseProvider);
        if (firebaseDb != null) {
          await firebaseDb.pushValidationMarker(localMarker);
        }
      } catch (e) {
        AppLogger.w('LockNotifier: Failed to push validation marker to cloud: $e');
      }


      // Todo: activeRecoveryPhrase: Temporarily holds the 12-word seed phrase right after setup so the UI can display it to the user to write down.
      AppLogger.d('LockNotifier: Master password & zero-knowledge validation markers created');
      state = state.copyWith(
        isAuthenticating: false,
        hasMasterPassword: true,
        masterKeyBytes: masterKeyBytes,
        activeRecoveryPhrase: phrase,
      );
      return true;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to setup master password', error: e, stack: st);
      state = state.copyWith(isAuthenticating: false, error: 'Failed to save password');
      return false;
    }
  }

  // Todo: We don't see or show these recoverWithPhrase strings
  /// Restores access using 12-word recovery seed phrase and sets new password
  Future<bool> recoverWithPhrase(List<String> words, String newPassword) async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      final salt = await SecureStorageManager.instance.getMasterSalt();
      final recoveryMarker = await SecureStorageManager.instance.getRecoveryValidationMarker();
      final wrappedKeyJson = await SecureStorageManager.instance.getWrappedMasterKey();

      if (salt == null || recoveryMarker == null) {
        state = state.copyWith(isAuthenticating: false, error: 'No recovery key found');
        return false;
      }

      final recoveryKeyData = await CryptoEngine.deriveRecoveryKey(words, salt: salt);
      final isValid = await CryptoEngine.verifyValidationMarker(recoveryMarker, recoveryKeyData.bytes);

      if (!isValid) {
        state = state.copyWith(isAuthenticating: false, error: 'Invalid recovery phrase');
        return false;
      }

      Uint8List? recoveredMasterKey;
      if (wrappedKeyJson != null) {
        try {
          recoveredMasterKey = await CryptoEngine.unwrapKey(
            wrappedKeyJson: wrappedKeyJson,
            wrappingKey: recoveryKeyData.bytes,
          );
        } catch (e) {
          AppLogger.w('LockNotifier: Failed to unwrap master key during recovery: $e');
        }
      }

      if (recoveredMasterKey == null) {
        state = state.copyWith(isAuthenticating: false, error: 'Failed to unwrap recovery key');
        return false;
      }

      // Password recovered successfully; setup new master password while keeping existing master key
      return await setupMasterPassword(newPassword, existingMasterKeyBytes: recoveredMasterKey);
    } catch (e, st) {
      AppLogger.e('LockNotifier: Password recovery failed', error: e, stack: st);
      state = state.copyWith(isAuthenticating: false, error: 'Recovery failed');
      return false;
    }
  }

  Future<bool> removeMasterPassword() async {
    state = state.copyWith(isAuthenticating: true, error: null);
    try {
      await ref.read(notesDaoProvider).unlockAllNotes(masterKeyBytes: state.masterKeyBytes);
      await SecureStorageManager.instance.clearAllCredentials();
      await ref.read(sharedPreferenceProvider).removeMasterPassword();
      _zeroOutMasterKeyMemory();

      AppLogger.d('LockNotifier: Master password removed and all notes unlocked');

      state = state.copyWith(
        isAuthenticating: false,
        hasMasterPassword: false,
      );

      ref.read(syncOrchestratorProvider).triggerSync();
      return true;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to remove master password', error: e, stack: st);
      state = state.copyWith(isAuthenticating: false, error: 'Failed to remove password');
      return false;
    }
  }

  void clearAllSessions() {
    _zeroOutMasterKeyMemory();
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
    if ((shouldLock || !ignorePassword) && state.masterKeyBytes == null) {
      if (password.isNotEmpty) {
        final valid = await verifyPassword(password);
        if (!valid) {
          AppLogger.w('LockNotifier: Incorrect password during note lock toggle for $uuid');
          state = state.copyWith(error: 'Incorrect Password');
          return false;
        }
      } else {
        state = state.copyWith(error: 'Password required');
        return false;
      }
    } else if (!shouldLock && !ignorePassword) {
      final valid = await verifyPassword(password);
      if (!valid) {
        AppLogger.w('LockNotifier: Incorrect password during note lock toggle for $uuid');
        state = state.copyWith(error: 'Incorrect Password');
        return false;
      }
    }

    if (state.masterKeyBytes == null) {
      state = state.copyWith(error: 'Session locked');
      return false;
    }

    try {
      final success = await ref.read(notesDaoProvider).lockNote(
            uuid,
            isLocked: shouldLock,
            masterKeyBytes: state.masterKeyBytes,
          );

      if (!success) {
        state = state.copyWith(error: 'Failed to update note lock state');
        return false;
      }

      final updatedSet = Set<String>.from(state.sessionUnlockedNoteIds);
      updatedSet.remove(uuid);
      state = state.copyWith(sessionUnlockedNoteIds: updatedSet);

      AppLogger.d('LockNotifier: Toggled persistent lock for note $uuid (isLocked: $shouldLock)');
      ref.read(syncOrchestratorProvider).triggerSync();
      return true;
    } catch (e, st) {
      AppLogger.e('LockNotifier: Failed to toggle note lock', error: e, stack: st);
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
