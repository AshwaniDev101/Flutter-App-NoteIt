# Dev Note: NoteIt Security Engine & Zero-Knowledge Architecture (2026-11-14)

## Overview
NoteIt uses a **Zero-Knowledge End-to-End Encryption (E2EE)** system to ensure that user notes remain completely private. Sensitive notes are encrypted locally before being saved to SQLite storage or transmitted over Cloud (Firestore) or P2P Wi-Fi (WebSocket) sync channels.

Raw master passwords are **never** stored on disk. Password correctness is validated using encrypted canary payloads (validation markers), and all key material is protected by platform hardware keystores.

---

## Key Security Components

### 1. Cryptographic Engine (`CryptoEngine`)
- **Key Derivation (KDF)**: Uses **PBKDF2** with SHA-256, a random 16-byte salt, and **600,000 iterations** to derive 256-bit AES master keys resistant to GPU dictionary attacks.
- **Authenticated Encryption**: Uses **AES-256-GCM** with 12-byte initialization vectors (IVs) and 16-byte MAC authentication tags.
- **Zero-Knowledge Validation Markers**: Creates and verifies encrypted "canary" payloads (`createValidationMarker` / `verifyValidationMarker`) to authenticate passwords without persisting password hashes or plaintext strings.
- **BIP39 Seed Recovery & Key Wrapping**: Generates 12-word mnemonic phrases and uses `wrapKey` / `unwrapKey` to encrypt the master key with a recovery key derived from the seed phrase.

### 2. Hardware Secure Storage (`SecureStorageManager`)
Wraps platform hardware keystores via `FlutterSecureStorage` (Android Keystore, iOS Keychain, Windows DPAPI / Credential Guard) to persist:
- `sec_kdf_salt`: 16-byte KDF salt.
- `sec_local_validation_marker`: Local zero-knowledge password validation payload.
- `sec_recovery_validation_marker`: 12-word seed phrase validation payload.
- `sec_master_key_hardware`: Biometric unlock master key.
- `sec_wrapped_master_key`: Master key wrapped with BIP39 recovery key.

### 3. State Management & Memory Hygiene (`LockNotifier`)
- **Background Auto-Purging**: Observes app lifecycle (`WidgetsBindingObserver`). When paused or hidden, `_zeroOutMasterKeyMemory()` zero-fills `masterKeyBytes` in RAM byte-by-byte and resets session keys.
- **Seed Phrase Hygiene**: `clearActiveRecoveryPhrase()` purges the 12-word phrase from RAM as soon as the user closes the seed phrase setup dialog.
- **Biometric Unlock**: Integrates `local_auth` backed by hardware keystore keys (`unlockWithBiometrics`).

### 4. Background Isolate Re-encryption (`ReencryptionIsolateWorker`)
- Offloads 100% of CPU-bound AES-256-GCM decryption and re-encryption tasks to a background Dart Isolate via `compute()` during password updates and 12-word recovery.
- Prevents main thread UI freezes during bulk note processing while Drift SQLite executes batch database writes on the main thread.

### 5. Database Layer & Data Loss Guards (`NotesDao`)
- **Locking**: Encrypts note contents into a JSON payload (`ciphertext` + `authTag`), clears the plaintext `content` column in SQLite, and sets `lockedAt`.
- **Unlocking**: Decrypts the JSON payload using `masterKeyBytes` and restores the plaintext `content`.
- **Fail-Safe Guards**: Throws `StateError` if locking or unlocking is attempted without active key bytes or if decryption fails. Prevents accidental clearing of encrypted data.

### 6. P2P & Cloud Sync Security
- **P2P Wi-Fi Sync (`LocalSyncService`)**: Enforces mutual `validation_handshake` exchanges upon WebSocket connection setup. Incoming note payloads are dropped (`_isPeerVerified`) until peer validation succeeds. Mismatched or unauthenticated connections disconnect immediately with code `4001`.
- **Cloud Remote Marker Check (`CloudSyncService` & `CloudNoteProcessor`)**: Device B validates local `masterKeyBytes` against remote Firestore validation markers (`validateRemotePasswordMarker`). Clears local session keys if password was updated on another device.

---

## Data Flow Summary

### Locking a Note
1. User toggles lock $\rightarrow$ `LockNotifier.togglePersistentLock` verifies active key.
2. `NotesDao.lockNote` passes plaintext content to `CryptoEngine.encryptPayload`.
3. SQLite updates row: sets `content = ''`, stores `encryptedPayload = JSON({"ciphertext": ..., "authTag": ...})`, `encryptionIv`, and `lockedAt = now`.

### Unlocking a Note
1. User enters password $\rightarrow$ `LockNotifier.verifyPassword` derives key via PBKDF2.
2. Key tested against local validation marker $\rightarrow$ if valid, cached in `LockState.masterKeyBytes`.
3. `NotesDao.lockNote(isLocked: false)` decrypts JSON payload and restores plaintext `content`.

### Password Recovery & Re-encryption
1. User enters 12-word seed phrase + new password $\rightarrow$ `CryptoEngine` derives recovery key.
2. `CryptoEngine.unwrapKey` retrieves original master key.
3. `ReencryptionIsolateWorker.batchReencrypt` decrypts all locked notes using old key and re-encrypts using new key inside a background Isolate.
4. Drift SQLite executes atomic batch update in database.
