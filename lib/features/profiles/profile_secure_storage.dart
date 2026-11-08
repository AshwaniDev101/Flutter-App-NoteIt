import 'dart:convert';
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
  static String _oauthKey(String profileId) => 'oauth_tokens_$profileId';

  /// Saves OAuth idToken & accessToken securely for [profileId].
  Future<bool> saveProfileOAuthTokens({
    required String profileId,
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final payload = jsonEncode({
        'idToken': idToken,
        'accessToken': accessToken,
      });
      await _storage.write(key: _oauthKey(profileId), value: payload);
      AppLogger.d('ProfileSecureStorage: Successfully saved OAuth tokens for profile $profileId');
      return true;
    } catch (e, st) {
      AppLogger.e('ProfileSecureStorage: Failed to save OAuth tokens for $profileId', error: e, stack: st);
      return false;
    }
  }

  /// Retrieves the securely stored OAuth idToken & accessToken map for [profileId].
  Future<Map<String, String>?> getProfileOAuthTokens(String profileId) async {
    try {
      final raw = await _storage.read(key: _oauthKey(profileId));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final idToken = map['idToken'] as String?;
      if (idToken == null || idToken.isEmpty) return null;
      return {
        'idToken': idToken,
        if (map['accessToken'] != null) 'accessToken': map['accessToken'] as String,
      };
    } catch (e, st) {
      AppLogger.w('ProfileSecureStorage: Failed or corrupt OAuth token read for $profileId', e, st);
      return null;
    }
  }

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

  /// Deletes the securely stored OAuth tokens for [profileId].
  Future<bool> deleteProfileToken(String profileId) async {
    try {
      await _storage.delete(key: _tokenKey(profileId));
      await _storage.delete(key: _oauthKey(profileId));
      AppLogger.d('ProfileSecureStorage: Deleted secure tokens for $profileId');
      return true;
    } catch (e, st) {
      AppLogger.w('ProfileSecureStorage: Failed to delete tokens for $profileId', e, st);
      return false;
    }
  }
}
