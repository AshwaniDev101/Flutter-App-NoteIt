import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/provider/provider.dart';
import '../drift/drift_database.dart';

// final noteFirebaseDatabaseProvider = Provider((ref) {
//   final firestore = ref.watch(firestoreProvider);
//
//   return NoteFirestoreDatabase(
//     firestore: firestore,
//   );
// });

final noteFirebaseDatabaseProvider = Provider<NoteFirestoreDatabase?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authUser = ref.watch(authStateProvider).value;

  // If nobody is logged in, no database instance is created
  if (authUser == null) {
    return null;
  }

  return NoteFirestoreDatabase(
    firestore: firestore,
    userId: authUser.uid,
  );
});


class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;
  final String userId;

  NoteFirestoreDatabase({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection('users').doc(userId).collection('notes');

  /// PULL: Fetch all remote notes that ARRIVED on the server since the last sync
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullChanges(int lastSyncTime) async {
    // Convert your local integer timestamp into a Firebase Timestamp
    final syncTimestamp = Timestamp.fromMillisecondsSinceEpoch(lastSyncTime);

    final querySnapshot = await _notesRef
        .where('cloudUpdatedAt', isGreaterThan: syncTimestamp)
        .get();

    return querySnapshot.docs;
  }

  /// STREAM: Listen strictly for new remote changes while the app is actively running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForRemoteChanges(int sessionStartTime) {
    final sessionTimestamp = Timestamp.fromMillisecondsSinceEpoch(sessionStartTime);

    return _notesRef
        .where('cloudUpdatedAt', isGreaterThan: sessionTimestamp)
        .snapshots()
        .map((snapshot) => snapshot.docChanges
        .where((change) => change.type != DocumentChangeType.removed)
        .map((change) => change.doc)
        .toList());
  }

  /// PUSH: Send all pending local changes to Firebase in a single atomic batch
  Future<Map<int, String>> pushBatch(List<Note> pendingNotes) async {
    final batch = _firestore.batch();
    final Map<int, String> assignedIds = {};

    for (final note in pendingNotes) {
      DocumentReference docRef;

      if (note.firestoreId != null && note.firestoreId!.isNotEmpty) {
        docRef = _notesRef.doc(note.firestoreId);
      } else {
        docRef = _notesRef.doc();
      }

      assignedIds[note.id] = docRef.id;

      final data = {
        'title': note.title,
        'content': note.content,
        'color': note.color,
        'isPinned': note.isPinned,
        'isArchived': note.isArchived,
        'isLocked': note.isLocked,
        'position': note.position,
        'tags': note.tags,
        'creationPlatform': note.creationPlatform,
        'creationDevice': note.creationDevice,

        // Preserve the exact local times for the UI
        'deletedAt': note.deletedAt?.toUtc().millisecondsSinceEpoch,
        'reminderAt': note.reminderAt?.toUtc().millisecondsSinceEpoch,
        'createdAt': note.createdAt.toUtc().millisecondsSinceEpoch,
        'updatedAt': note.updatedAt?.toUtc().millisecondsSinceEpoch ?? note.createdAt.toUtc().millisecondsSinceEpoch,

        // Let Firebase dictate the exact sync timeline!
        'cloudUpdatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
    return assignedIds;
  }


  // Hard delete  -----------------------------

  /// EMPTY TRASH (REMOTE): Hard delete a batch of documents from Firestore
  Future<void> deleteBatch(List<String> firestoreIds) async {
    if (firestoreIds.isEmpty) return;

    // Note: Firestore limits a WriteBatch to 500 operations. 
    // If a user has more than 500 notes in the trash, we need to chunk them.
    final chunks = <List<String>>[];
    for (var i = 0; i < firestoreIds.length; i += 500) {
      chunks.add(firestoreIds.sublist(
          i, i + 500 > firestoreIds.length ? firestoreIds.length : i + 500));
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();

      for (final docId in chunk) {
        batch.delete(_notesRef.doc(docId));
      }

      await batch.commit();
      print("Firestore: Hard deleted a batch of ${chunk.length} notes.");
    }
  }

}