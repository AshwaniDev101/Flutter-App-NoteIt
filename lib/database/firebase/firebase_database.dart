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

  /// Returns collection reference for entity collections scoped to active profile:
  /// /users/{userId}/profiles/{profileId}/{collectionName}
  CollectionReference<Map<String, dynamic>> _collectionRef(String collectionName) {
    final pathName = collectionName.endsWith('s') ? collectionName : '${collectionName}s';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .collection(pathName);
  }

  /// Returns collection reference for user's profile manifest:
  /// /users/{userId}/profiles_manifest
  CollectionReference<Map<String, dynamic>> manifestRef() {
    return _firestore.collection('users').doc(userId).collection('profiles_manifest');
  }

  /// PULL: Fetch all remote documents that ARRIVED on the server since the last sync
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullChanges(
    String collectionName,
    int lastSyncTime,
  ) async {
    final syncTimestamp = Timestamp.fromMillisecondsSinceEpoch(lastSyncTime);

    final querySnapshot = await _collectionRef(collectionName)
        .where('cloudUpdatedAt', isGreaterThan: syncTimestamp)
        .get();

    return querySnapshot.docs;
  }

  /// STREAM: Listen strictly for new remote changes for active profile while running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForRemoteChanges(
    String collectionName,
    int sessionStartTime,
  ) {
    final sessionTimestamp = Timestamp.fromMillisecondsSinceEpoch(sessionStartTime);

    return _collectionRef(collectionName)
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
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return;

    final ref = _collectionRef(collectionName);

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
      AppLogger.d("NoteFirestoreDatabase: Pushed batch of ${chunk.length} '$collectionName' items for profile $profileId.");
    }
  }

  /// HARD DELETE: Hard delete a batch of documents from Firestore
  Future<void> deleteBatch(String collectionName, List<String> uuids) async {
    if (uuids.isEmpty) return;

    final ref = _collectionRef(collectionName);
    for (var i = 0; i < uuids.length; i += 500) {
      final chunk = uuids.sublist(i, i + 500 > uuids.length ? uuids.length : i + 500);
      final batch = _firestore.batch();

      for (final docId in chunk) {
        batch.delete(ref.doc(docId));
      }

      await batch.commit();
      AppLogger.d("NoteFirestoreDatabase: Deleted batch of ${chunk.length} '$collectionName' items for profile $profileId.");
    }
  }

  /// PUSH MANIFEST: Push profile manifest items to /users/{userId}/profiles_manifest
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
    AppLogger.d("NoteFirestoreDatabase: Pushed ${profileItems.length} profile manifest items to cloud.");
  }

  /// PULL MANIFEST: Fetch all profile manifest items from /users/{userId}/profiles_manifest
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullProfileManifest() async {
    final querySnapshot = await manifestRef().get();
    return querySnapshot.docs;
  }
}
