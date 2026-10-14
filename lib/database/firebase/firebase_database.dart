import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/provider/provider.dart';
import '../../core/util/logger.dart';
import '../drift/local_database.dart';

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

  return NoteFirestoreDatabase(firestore: firestore, userId: authUser.uid);
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
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pullChanges(
    int lastSyncTime,
  ) async {
    // Convert your local integer timestamp into a Firebase Timestamp
    final syncTimestamp = Timestamp.fromMillisecondsSinceEpoch(lastSyncTime);

    final querySnapshot = await _notesRef
        .where('cloudUpdatedAt', isGreaterThan: syncTimestamp)
        .get();

    return querySnapshot.docs;
  }

  /// STREAM: Listen strictly for new remote changes while the app is actively running
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> watchForRemoteChanges(
    int sessionStartTime,
  ) {
    final sessionTimestamp = Timestamp.fromMillisecondsSinceEpoch(
      sessionStartTime,
    );

    return _notesRef
        .where('cloudUpdatedAt', isGreaterThan: sessionTimestamp)
        .snapshots()
        .map(
          (snapshot) => snapshot.docChanges
              .where((change) => change.type != DocumentChangeType.removed)
              .map((change) => change.doc)
              .toList(),
        );
  }

  /// PUSH: Send all pending local changes to Firebase in a single atomic batch
  Future<void> pushBatch(List<Note> pendingNotes) async {
    final batch = _firestore.batch();

    for (final note in pendingNotes) {
      // Force Firebase to use your exact local Drift UUID!
      final docRef = _notesRef.doc(note.uuid);

      final data = {
        // CORE
        'uuid': note.uuid,
        'title': note.title,
        'content': note.content,
        'color': note.color,

        // VERSIONING & CONFLICT RESOLUTION
        'schemaVersion': note.schemaVersion,
        'contentVersion': note.contentVersion,
        'updateCounter': note.updateCounter, // Crucial for LWW logic in the cloud

        // UX TIMESTAMPS (Upgraded from booleans)
        'pinnedAt': note.pinnedAt?.toUtc().millisecondsSinceEpoch,
        'archivedAt': note.archivedAt?.toUtc().millisecondsSinceEpoch,
        'lockedAt': note.lockedAt?.toUtc().millisecondsSinceEpoch,

        // ATTACHMENTS
        'localAttachmentPath': note.localAttachmentPath,
        'cloudAttachmentUrl': note.cloudAttachmentUrl,

        // NAVIGATION & SECURITY
        'folderId': note.folderId,
        'tags': note.tags,
        'ownerUid': note.ownerUid,

        // METADATA
        'creationPlatform': note.creationPlatform,
        'creationDevice': note.creationDevice,
        'lastEditedPlatform': note.lastEditedPlatform,
        'lastEditedDevice': note.lastEditedDevice,
        'deletedPlatform': note.deletedPlatform,
        'deletedDevice': note.deletedDevice,

        // SYNC TIMESTAMPS
        'reminderAt': note.reminderAt?.toUtc().millisecondsSinceEpoch,
        'deletedAt': note.deletedAt?.toUtc().millisecondsSinceEpoch,
        'createdAt': note.createdAt.toUtc().millisecondsSinceEpoch,
        'updatedAt': note.updatedAt.toUtc().millisecondsSinceEpoch,

        // Let Firebase dictate the exact cloud sync timeline
        'cloudUpdatedAt': FieldValue.serverTimestamp(),
      };

      // SetOptions(merge: true) ensures we don't wipe out future columns
      // created by newer app versions if this is pushed from an older app.
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Hard delete  -----------------------------

  /// EMPTY TRASH (REMOTE): Hard delete a batch of documents from Firestore
  Future<void> deleteBatch(List<String> uuids) async {
    if (uuids.isEmpty) return;

    // Note: Firestore limits a WriteBatch to 500 operations.
    // If a user has more than 500 notes in the trash, we need to chunk them.
    final chunks = <List<String>>[];
    for (var i = 0; i < uuids.length; i += 500) {
      chunks.add(
        uuids.sublist(i, i + 500 > uuids.length ? uuids.length : i + 500),
      );
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();

      for (final docId in chunk) {
        batch.delete(_notesRef.doc(docId));
      }

      await batch.commit();
      AppLogger.d("NoteFirestoreDatabase: Hard deleted a batch of ${chunk.length} notes.");
    }
  }
}
