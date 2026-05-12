
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/providers.dart';

final noteFirebaseDatabaseProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  return NoteFirestoreDatabase(firestore: firestore);
});


class NoteFirestoreDatabase {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'notes';


  NoteFirestoreDatabase({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> addNote({required String title,required String content})  async {
    try {
      await _firestore.collection(_collectionPath).add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add note to Firebase: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotes() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  Future<void> updateNote(String id, String title, String content) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'title': title,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}

