import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noteit/database/firebase/providers.dart';
import '../../models/note_model.dart';

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

  /// CREATE
  Future<void> addNote({
    required String title,
    required String content,
    int color = 0xFFFFFFFF,
    bool isPinned = false,
    bool isArchived = false,
    bool isDeleted = false,
    int position = 0,
    String? tags,
    DateTime? reminderAt,
  }) async {
    try {
      final now = DateTime.now();

      final note = NoteModel(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        isArchived: isArchived,
        isDeleted: isDeleted,
        position: position,
        tags: tags,
        reminderAt: reminderAt,
        createdAt: now,
      );

      await _notesRef.doc(note.id).set(note.toMap());
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  /// READ
  Stream<List<NoteModel>> watchNotes() {
    return _notesRef
        // .orderBy('isPinned', descending: true)
        // .orderBy('position')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();

        return NoteModel.fromMap(data);
      }).toList(),
    );
  }

  /// UPDATE
  Future<void> updateNote({
    required String documentId,
    String? title,
    String? content,
    int? color,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    int? position,
    String? tags,
    DateTime? reminderAt,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (title != null) data['title'] = title;

      if (content != null) data['content'] = content;

      if (color != null) data['color'] = color;

      if (isPinned != null) data['isPinned'] = isPinned;

      if (isArchived != null) data['isArchived'] = isArchived;

      if (isDeleted != null) data['isDeleted'] = isDeleted;

      if (position != null) data['position'] = position;

      if (tags != null) data['tags'] = tags;

      if (reminderAt != null) {
        data['reminderAt'] = reminderAt.toIso8601String();
      }

      data['updatedAt'] = DateTime.now().toIso8601String();

      await _notesRef.doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  /// DELETE
  Future<void> deleteNote(String documentId) async {
    try {
      await _notesRef.doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  /// BATCH DELETE
  Future<void> deleteNotes(Set<String> documentIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in documentIds) {
        batch.delete(_notesRef.doc(id));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch delete notes: $e');
    }
  }

  /// SOFT DELETE
  Future<void> softDeleteNote(String documentId) async {
    try {
      await _notesRef.doc(documentId).update({
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to soft delete note: $e');
    }
  }
}