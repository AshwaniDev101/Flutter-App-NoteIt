import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/provider/provider.dart';
import '../drift/drift_database.dart';

final noteFirebaseDatabaseProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);

  return NoteFirestoreDatabase(
    firestore: firestore,
  );
});

class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;

  static const String _collectionPath = 'notes';

  NoteFirestoreDatabase({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection(_collectionPath);

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
}