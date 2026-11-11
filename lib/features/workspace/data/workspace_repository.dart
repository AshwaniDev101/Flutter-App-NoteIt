import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/util/logger.dart';
import '../models/workspace_model.dart';
import 'workspace_secure_storage.dart';

/// Centralized repository for creating, reading, updating, and deleting
/// user workspaces stored in `profiles_manifest.json`.
class WorkspaceRepository {
  static const String _manifestFileName = 'profiles_manifest.json';
  static final WorkspaceRepository instance = WorkspaceRepository._internal();

  WorkspaceRepository._internal();

  File? _manifestFile;
  final List<Workspace> _workspaces = [];

  /// Default initial workspace generated on first app launch (points to existing 'note_it_db').
  static final Workspace defaultWorkspace = Workspace(
    id: 'profile_default',
    name: 'NoteIt',
    dbFileName: 'note_it_db',
    createdAt: DateTime.now().toUtc(),
    lastUsedAt: DateTime.now().toUtc(),
  );

  /// Synchronously initializes the workspace manifest file at app startup.
  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      instance._manifestFile = File('${dir.path}/$_manifestFileName');
      await instance._loadManifest();
    } catch (e, st) {
      AppLogger.e('WorkspaceRepository: Failed to initialize workspace manifest', error: e, stack: st);
    }
  }

  /// Loads workspaces from disk or generates default workspace on first launch.
  Future<void> _loadManifest() async {
    _workspaces.clear();
    final file = _manifestFile;

    if (file != null && await file.exists()) {
      try {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _workspaces.add(Workspace.fromJson(item));
          }
        }
        AppLogger.d('WorkspaceRepository: Loaded ${_workspaces.length} workspaces from manifest.');
      } catch (e, st) {
        AppLogger.e('WorkspaceRepository: Corrupt manifest file. Regenerating default workspace.', error: e, stack: st);
        await _createDefaultManifest();
      }
    } else {
      AppLogger.d('WorkspaceRepository: Manifest file not found. Generating default workspace...');
      await _createDefaultManifest();
    }

    // Ensure default workspace exists if list is somehow empty
    if (_workspaces.isEmpty) {
      _workspaces.add(defaultWorkspace);
      await _saveManifest();
    }
  }

  Future<void> _createDefaultManifest() async {
    _workspaces.clear();
    _workspaces.add(defaultWorkspace);
    await _saveManifest();
  }

  Future<void> _saveManifest() async {
    final file = _manifestFile;
    if (file == null) return;

    try {
      final jsonList = _workspaces.map((p) => p.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString);
      AppLogger.d('WorkspaceRepository: Saved ${_workspaces.length} workspaces to manifest.');
    } catch (e, st) {
      AppLogger.e('WorkspaceRepository: Failed to save manifest', error: e, stack: st);
    }
  }

  // =========================================================================
  // CRUD OPERATIONS
  // =========================================================================

  /// Returns an unmodifiable list of all active (non-deleted) workspaces sorted by [lastUsedAt] descending.
  List<Workspace> getWorkspaces() {
    final list = _workspaces.where((p) => p.deletedAt == null).toList();
    list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return List.unmodifiable(list);
  }

  /// Retrieves a specific workspace by its [id].
  Workspace? getWorkspaceById(String id) {
    try {
      return _workspaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Creates and persists a brand new user workspace with a unique database file.
  Future<Workspace> createWorkspace({
    required String name,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'workspace_$timestamp';
    final dbFileName = 'workspace_$timestamp';

    final newWorkspace = Workspace(
      id: id,
      name: name,
      dbFileName: dbFileName,
      createdAt: DateTime.now().toUtc(),
      lastUsedAt: DateTime.now().toUtc(),
    );

    _workspaces.add(newWorkspace);
    await _saveManifest();

    AppLogger.d('WorkspaceRepository: Created new workspace ${newWorkspace.name} (DB: $dbFileName)');
    return newWorkspace;
  }

  /// Updates or inserts a workspace in the manifest and persists changes to disk.
  Future<bool> upsertWorkspace(Workspace workspace) async {
    final index = _workspaces.indexWhere((p) => p.id == workspace.id);
    if (index != -1) {
      _workspaces[index] = workspace;
    } else {
      _workspaces.add(workspace);
    }
    await _saveManifest();
    AppLogger.d('WorkspaceRepository: Upserted workspace ${workspace.name} (${workspace.id})');
    return true;
  }

  /// Updates an existing workspace's metadata and persists changes to disk.
  Future<bool> updateWorkspace(Workspace updatedWorkspace) async {
    return await upsertWorkspace(updatedWorkspace);
  }

  /// Updates the [lastUsedAt] timestamp for [workspaceId].
  Future<void> touchWorkspaceLastUsed(String workspaceId) async {
    final workspace = getWorkspaceById(workspaceId);
    if (workspace != null) {
      final updated = workspace.copyWith(lastUsedAt: DateTime.now().toUtc());
      await upsertWorkspace(updated);
    }
  }

  /// Soft deletes a workspace (sets deletedAt) and persists changes to disk so tombstones sync across devices.
  Future<bool> deleteWorkspace(String workspaceId) async {
    final workspace = getWorkspaceById(workspaceId);
    if (workspace == null) {
      AppLogger.w('WorkspaceRepository: Cannot delete non-existent workspace $workspaceId');
      return false;
    }

    final now = DateTime.now().toUtc();
    final updated = workspace.copyWith(
      deletedAt: now,
      updateCounter: workspace.updateCounter + 1,
    );

    await upsertWorkspace(updated);
    await WorkspaceSecureStorage.instance.deleteWorkspaceToken(workspaceId);

    // Physically delete SQLite file and auxiliary WAL/SHM files asynchronously
    try {
      final dir = await getApplicationSupportDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        final baseName = workspace.dbFileName;
        for (final entity in entities) {
          if (entity is File) {
            final fileName = entity.path.split(RegExp(r'[/\\]')).last;
            if (fileName == baseName ||
                fileName == '$baseName.sqlite' ||
                fileName.startsWith('$baseName.') ||
                fileName.startsWith('$baseName-')) {
              try {
                await entity.delete();
                AppLogger.d('WorkspaceRepository: Deleted database file ${entity.path}');
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      AppLogger.w('WorkspaceRepository: Failed to delete database files for workspace $workspaceId: $e');
    }

    return true;
  }
}
