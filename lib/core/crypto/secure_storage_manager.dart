import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:noteit/core/util/logger.dart';

final secureStorageProvider = Provider<SecureStorageManager>((ref) {
  return SecureStorageManager.instance;
});

/// Interface wrapping [FlutterSecureStorage] for platform hardware keystores
/// (Android Keystore, iOS Keychain, and Windows Credential Guard / DPAPI).
class SecureStorageManager {
  SecureStorageManager._internal();

  static final SecureStorageManager instance = SecureStorageManager._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    wOptions: WindowsOptions(),
  );

  static const String _keyMasterSalt = 'sec_kdf_salt';
  static const String _keyLocalValidationMarker = 'sec_local_validation_marker';
  static const String _keyRecoveryValidationMarker = 'sec_recovery_validation_marker';
  static const String _keyMasterKeyHardware = 'sec_master_key_hardware';
  static const String _keyWrappedMasterKey = 'sec_wrapped_master_key';

  /// Saves the 16-byte KDF Salt in hardware-backed secure storage.
  Future<void> saveMasterSalt(List<int> salt) async {
    try {
      await _storage.write(key: _keyMasterSalt, value: base64Encode(salt));
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to save master salt", error: e, stack: st);
    }
  }

  /// Retrieves the 16-byte KDF Salt from hardware-backed secure storage.
  Future<List<int>?> getMasterSalt() async {
    try {
      final str = await _storage.read(key: _keyMasterSalt);
      if (str == null) return null;
      return base64Decode(str);
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to read master salt", error: e, stack: st);
      return null;
    }
  }

  /// Saves the Local Zero-Knowledge Validation Marker JSON map.
  Future<void> saveLocalValidationMarker(Map<String, dynamic> marker) async {
    try {
      await _storage.write(key: _keyLocalValidationMarker, value: jsonEncode(marker));
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to save local validation marker", error: e, stack: st);
    }
  }

  /// Retrieves the Local Zero-Knowledge Validation Marker JSON map.
  Future<Map<String, dynamic>?> getLocalValidationMarker() async {
    try {
      final str = await _storage.read(key: _keyLocalValidationMarker);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to read local validation marker", error: e, stack: st);
      return null;
    }
  }

  /// Saves the 12-word Recovery Validation Marker JSON map.
  Future<void> saveRecoveryValidationMarker(Map<String, dynamic> marker) async {
    try {
      await _storage.write(key: _keyRecoveryValidationMarker, value: jsonEncode(marker));
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to save recovery validation marker", error: e, stack: st);
    }
  }

  /// Retrieves the 12-word Recovery Validation Marker JSON map.
  Future<Map<String, dynamic>?> getRecoveryValidationMarker() async {
    try {
      final str = await _storage.read(key: _keyRecoveryValidationMarker);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to read recovery validation marker", error: e, stack: st);
      return null;
    }
  }

  /// Saves the hardware-backed Master AES Key (used for fast biometric unlock).
  Future<void> saveHardwareMasterKey(List<int> aesKey) async {
    try {
      await _storage.write(key: _keyMasterKeyHardware, value: base64Encode(aesKey));
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to save hardware master key", error: e, stack: st);
    }
  }

  /// Retrieves the hardware-backed Master AES Key.
  Future<List<int>?> getHardwareMasterKey() async {
    try {
      final str = await _storage.read(key: _keyMasterKeyHardware);
      if (str == null) return null;
      return base64Decode(str);
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to read hardware master key", error: e, stack: st);
      return null;
    }
  }

  /// Saves the Master AES Key encrypted with recovery key (for seed phrase password recovery).
  Future<void> saveWrappedMasterKey(String wrappedKeyJson) async {
    try {
      await _storage.write(key: _keyWrappedMasterKey, value: wrappedKeyJson);
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to save wrapped master key", error: e, stack: st);
    }
  }

  /// Retrieves the wrapped Master AES Key JSON string.
  Future<String?> getWrappedMasterKey() async {
    try {
      return await _storage.read(key: _keyWrappedMasterKey);
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to read wrapped master key", error: e, stack: st);
      return null;
    }
  }

  /// Clears all hardware encryption credentials upon master password removal.
  Future<void> clearAllCredentials() async {
    try {
      await _storage.delete(key: _keyMasterSalt);
      await _storage.delete(key: _keyLocalValidationMarker);
      await _storage.delete(key: _keyRecoveryValidationMarker);
      await _storage.delete(key: _keyMasterKeyHardware);
      await _storage.delete(key: _keyWrappedMasterKey);
      AppLogger.d("SecureStorageManager: Cleared hardware encryption credentials.");
    } catch (e, st) {
      AppLogger.e("SecureStorageManager: Failed to clear credentials", error: e, stack: st);
    }
  }
}
