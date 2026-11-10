import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/util/logger.dart';

/// Hardware-backed secure storage wrapper for storing per-workspace OAuth credentials.
///
/// Uses EncryptedSharedPreferences on Android and Keychain Services on iOS.
class WorkspaceSecureStorage {
  static final WorkspaceSecureStorage instance = WorkspaceSecureStorage._internal();

  WorkspaceSecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static String _tokenKey(String workspaceId) => 'auth_token_$workspaceId';
  static String _oauthKey(String workspaceId) => 'oauth_tokens_$workspaceId';

  /// Saves OAuth idToken & accessToken securely for [workspaceId].
  Future<bool> saveWorkspaceOAuthTokens({
    required String workspaceId,
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final payload = jsonEncode({
        'idToken': idToken,
        'accessToken': accessToken,
      });
      await _storage.write(key: _oauthKey(workspaceId), value: payload);
      AppLogger.d('WorkspaceSecureStorage: Successfully saved OAuth tokens for workspace $workspaceId');
      return true;
    } catch (e, st) {
      AppLogger.e('WorkspaceSecureStorage: Failed to save OAuth tokens for $workspaceId', error: e, stack: st);
      return false;
    }
  }

  /// Retrieves the securely stored OAuth idToken & accessToken map for [workspaceId].
  Future<Map<String, String>?> getWorkspaceOAuthTokens(String workspaceId) async {
    try {
      final raw = await _storage.read(key: _oauthKey(workspaceId));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final idToken = map['idToken'] as String?;
      if (idToken == null || idToken.isEmpty) return null;
      return {
        'idToken': idToken,
        if (map['accessToken'] != null) 'accessToken': map['accessToken'] as String,
      };
    } catch (e, st) {
      AppLogger.w('WorkspaceSecureStorage: Failed or corrupt OAuth token read for $workspaceId', e, st);
      return null;
    }
  }

  /// Saves an OAuth refresh token or credential string securely for [workspaceId].
  Future<bool> saveWorkspaceToken({
    required String workspaceId,
    required String token,
  }) async {
    try {
      await _storage.write(key: _tokenKey(workspaceId), value: token);
      AppLogger.d('WorkspaceSecureStorage: Successfully saved token for workspace $workspaceId');
      return true;
    } catch (e, st) {
      AppLogger.e('WorkspaceSecureStorage: Failed to save token for $workspaceId', error: e, stack: st);
      return false;
    }
  }

  /// Retrieves the securely stored OAuth refresh token or credential string for [workspaceId].
  ///
  /// Automatically catches Keystore / Keychain corruption exceptions and returns null.
  Future<String?> getWorkspaceToken(String workspaceId) async {
    try {
      return await _storage.read(key: _tokenKey(workspaceId));
    } catch (e, st) {
      AppLogger.w('WorkspaceSecureStorage: Corrupt keystore or failed read for $workspaceId. Clearing key.', e, st);
      await deleteWorkspaceToken(workspaceId);
      return null;
    }
  }

  /// Deletes the securely stored OAuth tokens for [workspaceId].
  Future<bool> deleteWorkspaceToken(String workspaceId) async {
    try {
      await _storage.delete(key: _tokenKey(workspaceId));
      await _storage.delete(key: _oauthKey(workspaceId));
      AppLogger.d('WorkspaceSecureStorage: Deleted secure tokens for $workspaceId');
      return true;
    } catch (e, st) {
      AppLogger.w('WorkspaceSecureStorage: Failed to delete tokens for $workspaceId', e, st);
      return false;
    }
  }
}
