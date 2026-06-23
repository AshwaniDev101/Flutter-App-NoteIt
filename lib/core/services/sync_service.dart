import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../../core/provider/provider.dart'; // Where firestoreProvider lives
import '../../database/drift/drift_database.dart';

final syncServiceProvider = Provider((ref) {
  final driftDb = ref.watch(noteDriftDatabaseProvider);
  final firestore = ref.watch(firestoreProvider);
  return SyncService(driftDb, firestore);
});

class SyncService {
  final NoteDriftDatabase _driftDb;
  final FirebaseFirestore _firestore;

  SyncService(this._driftDb, this._firestore);

  /// Must Call this when the app starts, or when network connection is restored
  Future<void> pushLocalChangesToCloud() async {
    print("### SyncService: Checking for pending notes...");

    // Find all notes that haven't been synced yet (syncStatus == 0)
    final pendingNotes = await (_driftDb.select(_driftDb.notes)
      ..where((t) => t.syncStatus.equals(0)))
        .get();

    if (pendingNotes.isEmpty) {
      print("### SyncService: All caught up! No pending notes.");
      return;
    }

    for (final note in pendingNotes) {
      try {
        // Prepare the payload for Firestore
        final noteData = {
          'title': note.title,
          'content': note.content,
          'createdAt': note.createdAt.toIso8601String(),
          // 'userId': auth.currentUser?.uid, // I'll add this later for Google Auth
        };

        DocumentReference docRef;

        // If it has a firestoreId, update it. If not, create a new document.
        if (note.firestoreId != null && note.firestoreId!.isNotEmpty) {
          docRef = _firestore.collection('notes').doc(note.firestoreId);
          await docRef.update(noteData);
        } else {
          docRef = await _firestore.collection('notes').add(noteData);
        }

        // 4. Mark as synced (status = 1) and save the new Firestore ID locally
        await (_driftDb.update(_driftDb.notes)
          ..where((t) => t.id.equals(note.id)))
            .write(
          NotesCompanion(
            syncStatus: const Value(1),
            firestoreId: Value(docRef.id),
          ),
        );

        print("### SyncService: Successfully synced note ${note.id}");
      } catch (e) {
        print("### SyncService: Failed to sync note ${note.id}: $e");
        // We leave syncStatus as 0 so it tries again next time
      }
    }
  }
}