import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/firebase/firebase_database.dart';

/// Abstract base contract for processing database entities over Firebase Cloud sync.
abstract class CloudEntityProcessor {
  final Ref ref;

  CloudEntityProcessor(this.ref);

  /// Human readable entity name (e.g., 'workspace', 'folder', 'note')
  String get entityName;

  /// Firestore collection name (e.g., 'workspaces_manifest', 'folders', 'notes')
  String get collectionName;

  /// Dependency hierarchy rank (0 = Workspaces, 1 = Folders, 2 = Notes)
  int get dependencyLevel;

  /// Pushes pending local changes for [targetWorkspaceId] to Firestore and marks them as cloud synced.
  Future<void> pushPendingChanges(NoteFirestoreDatabase firebaseDb, {String? targetWorkspaceId});

  /// Pulls remote changes from Firestore for [targetWorkspaceId] modified since [lastSyncTime] and merges into local DB.
  Future<void> pullRemoteChanges(NoteFirestoreDatabase firebaseDb, int lastSyncTime, {String? targetWorkspaceId});

  /// Merges a single incoming document snapshot from a realtime stream into the local DB.
  Future<void> processIncomingCloudItem(Map<String, dynamic> data, {String? targetWorkspaceId});
}
