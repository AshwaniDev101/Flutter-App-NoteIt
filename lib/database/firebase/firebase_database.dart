import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/provider/provider.dart';
import '../drift/drift_database.dart'; // Needed for the Drift Note model

final noteFirebaseDatabaseProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);

  return NoteFirestoreDatabase(
    firestore: firestore,
  );
});

class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;

  // Note: Once you add authentication, you will likely change this path
  // to something like 'users/${userId}/notes' to keep data private.
  static const String _collectionPath = 'notes';

  NoteFirestoreDatabase({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection(_collectionPath);

  /// PULL: Fetch all remote notes updated since the last sync timestamp
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullChanges(int lastSyncTime) async {
    final querySnapshot = await _notesRef
        .where('updatedAt', isGreaterThan: lastSyncTime)
        .get();

    return querySnapshot.docs;
  }


  /// STREAM: Listen strictly for new remote changes while the app is actively running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForRemoteChanges(int sessionStartTime) {
    return _notesRef
    // Only listen for changes that happen AFTER the app was opened
        .where('updatedAt', isGreaterThan: sessionStartTime)
        .snapshots()
        .map((snapshot) => snapshot.docChanges
    // Only care about Adds and Modifies, not local removals
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

      // If it already has a Firestore ID, target that document.
      // Otherwise, auto-generate a new one.
      if (note.firestoreId != null && note.firestoreId!.isNotEmpty) {
        docRef = _notesRef.doc(note.firestoreId);
      } else {
        docRef = _notesRef.doc();
      }

      assignedIds[note.id] = docRef.id;

      // Map the complete Drift Note model to Firestore
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

        'deletedAt': note.deletedAt?.toUtc().millisecondsSinceEpoch,
        'reminderAt': note.reminderAt?.toUtc().millisecondsSinceEpoch,
        'createdAt': note.createdAt.toUtc().millisecondsSinceEpoch,
        'updatedAt': note.updatedAt?.toUtc().millisecondsSinceEpoch ?? note.createdAt.toUtc().millisecondsSinceEpoch,
      };

      // Use SetOptions(merge: true) to safely upsert without wiping out other potential fields
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
    return assignedIds;
  }
}