import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/util/logger.dart';
import '../models/profile_model.dart';
import 'profile_secure_storage.dart';

/// Centralized repository for creating, reading, updating, and deleting
/// user workspace profiles stored in `profiles_manifest.json`.
class ProfileRepository {
  static const String _manifestFileName = 'profiles_manifest.json';
  static final ProfileRepository instance = ProfileRepository._internal();

  ProfileRepository._internal();

  File? _manifestFile;
  final List<Profile> _profiles = [];

  /// Default initial profile generated on first app launch (points to existing 'note_it_db').
  static final Profile defaultProfile = Profile(
    id: 'profile_default',
    name: 'NoteIt',
    dbFileName: 'note_it_db',
    createdAt: DateTime.now().toUtc(),
    lastUsedAt: DateTime.now().toUtc(),
  );

  /// Synchronously initializes the profile manifest file at app startup.
  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      instance._manifestFile = File('${dir.path}/$_manifestFileName');
      await instance._loadManifest();
    } catch (e, st) {
      AppLogger.e('ProfileRepository: Failed to initialize profiles manifest', error: e, stack: st);
    }
  }

  /// Loads profiles from disk or generates default profile on first launch.
  Future<void> _loadManifest() async {
    _profiles.clear();
    final file = _manifestFile;

    if (file != null && await file.exists()) {
      try {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _profiles.add(Profile.fromJson(item));
          }
        }
        AppLogger.d('ProfileRepository: Loaded ${_profiles.length} profiles from manifest.');
      } catch (e, st) {
        AppLogger.e('ProfileRepository: Corrupt manifest file. Regenerating default profile.', error: e, stack: st);
        await _createDefaultManifest();
      }
    } else {
      AppLogger.d('ProfileRepository: Manifest file not found. Generating default profile...');
      await _createDefaultManifest();
    }

    // Ensure default profile exists if list is somehow empty
    if (_profiles.isEmpty) {
      _profiles.add(defaultProfile);
      await _saveManifest();
    }
  }

  Future<void> _createDefaultManifest() async {
    _profiles.clear();
    _profiles.add(defaultProfile);
    await _saveManifest();
  }

  Future<void> _saveManifest() async {
    final file = _manifestFile;
    if (file == null) return;

    try {
      final jsonList = _profiles.map((p) => p.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString);
      AppLogger.d('ProfileRepository: Saved ${_profiles.length} profiles to manifest.');
    } catch (e, st) {
      AppLogger.e('ProfileRepository: Failed to save manifest', error: e, stack: st);
    }
  }

  // =========================================================================
  // CRUD OPERATIONS
  // =========================================================================

  /// Returns an unmodifiable list of all active (non-deleted) profiles sorted by [lastUsedAt] descending.
  List<Profile> getProfiles() {
    final list = _profiles.where((p) => p.deletedAt == null).toList();
    list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return List.unmodifiable(list);
  }

  /// Retrieves a specific profile by its [id].
  Profile? getProfileById(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Creates and persists a brand new user profile with a unique database file.
  Future<Profile> createProfile({
    required String name,
    String syncMode = 'offline',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'profile_$timestamp';
    final dbFileName = 'profile_$timestamp';

    final newProfile = Profile(
      id: id,
      name: name,
      dbFileName: dbFileName,
      syncMode: syncMode,
      createdAt: DateTime.now().toUtc(),
      lastUsedAt: DateTime.now().toUtc(),
    );

    _profiles.add(newProfile);
    await _saveManifest();

    AppLogger.d('ProfileRepository: Created new profile ${newProfile.name} (DB: $dbFileName)');
    return newProfile;
  }

  /// Updates an existing profile's metadata and persists changes to disk.
  Future<bool> updateProfile(Profile updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index == -1) return false;

    _profiles[index] = updatedProfile;
    await _saveManifest();
    AppLogger.d('ProfileRepository: Updated profile metadata for ${updatedProfile.name}');
    return true;
  }

  /// Updates the [lastUsedAt] timestamp for [profileId].
  Future<void> touchProfileLastUsed(String profileId) async {
    final profile = getProfileById(profileId);
    if (profile != null) {
      final updated = profile.copyWith(lastUsedAt: DateTime.now().toUtc());
      await updateProfile(updated);
    }
  }

  /// Soft deletes a profile or physically deletes its database file.
  Future<bool> deleteProfile(String profileId) async {
    final profile = getProfileById(profileId);
    if (profile == null) {
      AppLogger.w('ProfileRepository: Cannot delete non-existent profile $profileId');
      return false;
    }

    _profiles.removeWhere((p) => p.id == profileId);
    await _saveManifest();

    await ProfileSecureStorage.instance.deleteProfileToken(profileId);

    // Physically delete SQLite file and auxiliary WAL/SHM files asynchronously
    try {
      final dir = await getApplicationSupportDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        final baseName = profile.dbFileName;
        for (final entity in entities) {
          if (entity is File) {
            final fileName = entity.path.split(RegExp(r'[/\\]')).last;
            if (fileName == baseName ||
                fileName == '$baseName.sqlite' ||
                fileName.startsWith('$baseName.') ||
                fileName.startsWith('$baseName-')) {
              try {
                await entity.delete();
                AppLogger.d('ProfileRepository: Deleted database file ${entity.path}');
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      AppLogger.w('ProfileRepository: Failed to delete database files for profile $profileId: $e');
    }

    return true;
  }
}
