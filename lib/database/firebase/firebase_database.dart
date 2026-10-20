import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/firebase_provider.dart';
import '../../core/util/logger.dart';

final noteFirebaseDatabaseProvider = Provider<NoteFirestoreDatabase?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authUser = ref.watch(authStateProvider).value;

  // If nobody is logged in, no database instance is created
  if (authUser == null) {
    return null;
  }

  return NoteFirestoreDatabase(firestore: firestore, userId: authUser.uid);
});

class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;
  final String userId;

  NoteFirestoreDatabase({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _collectionRef(String collectionName) {
    // Standard plural collection names (e.g. 'folders', 'notes')
    final pathName = collectionName.endsWith('s') ? collectionName : '${collectionName}s';
    return _firestore.collection('users').doc(userId).collection(pathName);
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

  /// STREAM: Listen strictly for new remote changes while the app is actively running
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
      AppLogger.d("NoteFirestoreDatabase: Pushed batch of ${chunk.length} '$collectionName' items.");
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
      AppLogger.d("NoteFirestoreDatabase: Deleted batch of ${chunk.length} '$collectionName' items.");
    }
  }
}
