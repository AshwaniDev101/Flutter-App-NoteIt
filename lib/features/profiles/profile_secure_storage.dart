import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/util/logger.dart';

/// Hardware-backed secure storage wrapper for storing per-profile OAuth credentials.
///
/// Uses EncryptedSharedPreferences on Android and Keychain Services on iOS.
class ProfileSecureStorage {
  static final ProfileSecureStorage instance = ProfileSecureStorage._internal();

  ProfileSecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static String _tokenKey(String profileId) => 'auth_token_$profileId';

  /// Saves an OAuth refresh token or credential string securely for [profileId].
  Future<bool> saveProfileToken({
    required String profileId,
    required String token,
  }) async {
    try {
      await _storage.write(key: _tokenKey(profileId), value: token);
      AppLogger.d('ProfileSecureStorage: Successfully saved token for profile $profileId');
      return true;
    } catch (e, st) {
      AppLogger.e('ProfileSecureStorage: Failed to save token for $profileId', error: e, stack: st);
      return false;
    }
  }

  /// Retrieves the securely stored OAuth refresh token or credential string for [profileId].
  ///
  /// Automatically catches Keystore / Keychain corruption exceptions and returns null.
  Future<String?> getProfileToken(String profileId) async {
    try {
      return await _storage.read(key: _tokenKey(profileId));
    } catch (e, st) {
      AppLogger.w('ProfileSecureStorage: Corrupt keystore or failed read for $profileId. Clearing key.', e, st);
      await deleteProfileToken(profileId);
      return null;
    }
  }

  /// Deletes the securely stored OAuth token for [profileId].
  Future<bool> deleteProfileToken(String profileId) async {
    try {
      await _storage.delete(key: _tokenKey(profileId));
      AppLogger.d('ProfileSecureStorage: Deleted secure token for $profileId');
      return true;
    } catch (e, st) {
      AppLogger.w('ProfileSecureStorage: Failed to delete token for $profileId', e, st);
      return false;
    }
  }
}
