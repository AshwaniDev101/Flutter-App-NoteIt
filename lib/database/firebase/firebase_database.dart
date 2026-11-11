import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/workspace/providers/active_workspace_provider.dart';
import 'auth/firebase_provider.dart';
import '../../core/util/logger.dart';

final noteFirebaseDatabaseProvider = Provider<NoteFirestoreDatabase?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authUser = ref.watch(authStateProvider).value;
  final activeWorkspace = ref.watch(activeWorkspaceProvider);

  // If nobody is logged in, no database instance is created
  if (authUser == null) {
    return null;
  }

  return NoteFirestoreDatabase(
    firestore: firestore,
    userId: authUser.uid,
    profileId: activeWorkspace.id,
  );
});

class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;
  final String userId;
  final String profileId;

  NoteFirestoreDatabase({
    required FirebaseFirestore firestore,
    required this.userId,
    required this.profileId,
  }) : _firestore = firestore;

  /// Returns collection reference for entity collections scoped to a specific workspace ID (defaults to active workspace profileId):
  /// /users/{userId}/workspaces/{targetWorkspaceId}/{collectionName}
  CollectionReference<Map<String, dynamic>> _collectionRef(String collectionName, {String? targetWorkspaceId}) {
    final wsId = targetWorkspaceId ?? profileId;
    final pathName = collectionName.endsWith('s') ? collectionName : '${collectionName}s';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workspaces')
        .doc(wsId)
        .collection(pathName);
  }

  /// Returns collection reference for user's workspace manifest:
  /// /users/{userId}/workspaces_manifest
  CollectionReference<Map<String, dynamic>> manifestRef() {
    return _firestore.collection('users').doc(userId).collection('workspaces_manifest');
  }

  /// PULL: Fetch all remote documents that ARRIVED on the server since the last sync
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullChanges(
    String collectionName,
    int lastSyncTime, {
    String? targetWorkspaceId,
  }) async {
    final syncTimestamp = Timestamp.fromMillisecondsSinceEpoch(lastSyncTime);

    final querySnapshot = await _collectionRef(collectionName, targetWorkspaceId: targetWorkspaceId)
        .where('cloudUpdatedAt', isGreaterThan: syncTimestamp)
        .get();

    return querySnapshot.docs;
  }

  /// STREAM: Listen strictly for new remote changes for active workspace while running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForRemoteChanges(
    String collectionName,
    int sessionStartTime, {
    String? targetWorkspaceId,
  }) {
    final sessionTimestamp = Timestamp.fromMillisecondsSinceEpoch(sessionStartTime);

    return _collectionRef(collectionName, targetWorkspaceId: targetWorkspaceId)
        .where('cloudUpdatedAt', isGreaterThan: sessionTimestamp)
        .snapshots()
        .map(
          (snapshot) => snapshot.docChanges
              .where((change) => change.type != DocumentChangeType.removed)
              .map((change) => change.doc)
              .toList(),
        );
  }

  /// STREAM MANIFEST: Listen strictly for new remote workspace manifest changes while running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForManifestChanges(
    int sessionStartTime,
  ) {
    final sessionTimestamp = Timestamp.fromMillisecondsSinceEpoch(sessionStartTime);

    return manifestRef()
        .where('cloudUpdatedAt', isGreaterThan: sessionTimestamp)
        .snapshots()
        .map(
          (snapshot) => snapshot.docChanges
              .where((change) => change.type != DocumentChangeType.removed)
              .map((change) => change.doc)
              .toList(),
        );
  }

  /// PUSH: Send pending items map for a specific entity collection to Firebase in atomic batches
  Future<void> pushBatch(
    String collectionName,
    List<Map<String, dynamic>> items, {
    String? targetWorkspaceId,
  }) async {
    if (items.isEmpty) return;

    final ref = _collectionRef(collectionName, targetWorkspaceId: targetWorkspaceId);
    final activeWsId = targetWorkspaceId ?? profileId;

    for (var i = 0; i < items.length; i += 500) {
      final chunk = items.sublist(i, i + 500 > items.length ? items.length : i + 500);
      final batch = _firestore.batch();

      for (final item in chunk) {
        final docUuid = item['uuid'] as String;
        final docRef = ref.doc(docUuid);

        final data = Map<String, dynamic>.from(item);
        data['cloudUpdatedAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
      AppLogger.d("NoteFirestoreDatabase: Pushed batch of ${chunk.length} '$collectionName' items for workspace $activeWsId.");
    }
  }

  /// HARD DELETE: Hard delete a batch of documents from Firestore
  Future<void> deleteBatch(String collectionName, List<String> uuids, {String? targetWorkspaceId}) async {
    if (uuids.isEmpty) return;

    final ref = _collectionRef(collectionName, targetWorkspaceId: targetWorkspaceId);
    final activeWsId = targetWorkspaceId ?? profileId;
    for (var i = 0; i < uuids.length; i += 500) {
      final chunk = uuids.sublist(i, i + 500 > uuids.length ? uuids.length : i + 500);
      final batch = _firestore.batch();

      for (final docId in chunk) {
        batch.delete(ref.doc(docId));
      }

      await batch.commit();
      AppLogger.d("NoteFirestoreDatabase: Deleted batch of ${chunk.length} '$collectionName' items for workspace $activeWsId.");
    }
  }

  /// PUSH MANIFEST: Push workspace manifest items to /users/{userId}/workspaces_manifest
  Future<void> pushProfileManifest(List<Map<String, dynamic>> profileItems) async {
    if (profileItems.isEmpty) return;
    final ref = manifestRef();
    final batch = _firestore.batch();

    for (final item in profileItems) {
      final id = item['id'] as String;
      final docRef = ref.doc(id);
      final data = Map<String, dynamic>.from(item);
      data['cloudUpdatedAt'] = FieldValue.serverTimestamp();
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
    AppLogger.d("NoteFirestoreDatabase: Pushed ${profileItems.length} workspace manifest items to cloud.");
  }

  /// PULL MANIFEST: Fetch all workspace manifest items from /users/{userId}/workspaces_manifest
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullProfileManifest() async {
    final querySnapshot = await manifestRef().get();
    return querySnapshot.docs;
  }
}
