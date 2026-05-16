// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'drift/drift_database.dart';
// import 'firebase/firebase_database.dart';
//
// final noteRepositoryProvider = Provider((ref) {
//   final firebaseDatabase = ref.watch(noteFirebaseDatabaseProvider);
//   final driftNoteDatabase = ref.watch(noteDriftDatabaseProvider);
//   return NoteRepository(noteFirestoreDatabase: firebaseDatabase, noteDriftDatabase: driftNoteDatabase);
// });
//
// class NoteRepository {
//   NoteFirestoreDatabase _noteFirestoreDatabase;
//   NoteDriftDatabase _noteDriftDatabase;
//
//   NoteRepository({required NoteFirestoreDatabase noteFirestoreDatabase, required NoteDriftDatabase noteDriftDatabase})
//     : _noteFirestoreDatabase = noteFirestoreDatabase,
//       _noteDriftDatabase = noteDriftDatabase;
//
//   Future<void> addNote({required String title,required String content}) async {
//     print("### NoteRepository: Adding note...");
//     try {
//       await _noteDriftDatabase.addNote(title: title, content: content);
//       print("### NoteRepository: Added to Drift successfully");
//     } catch (e) {
//       print("### NoteRepository: Drift error: $e");
//     }
//
//     try {
//       await _noteFirestoreDatabase.addNote(title: title, content: content);
//       print("### NoteRepository: Added to Firestore successfully");
//     } catch (e) {
//       print("### NoteRepository: Firestore error: $e");
//     }
//   }
//
//   Future<List<Note>> getNotes() async {
//     // Currently HomePage watches Drift directly, but we can implement this if needed.
//     return [];
//   }
//
//   Future<void> deleteNote(int id) async {
//     print("### NoteRepository: Deleting note $id...");
//     await _noteDriftDatabase.deleteNote(id);
//     // Note: Deleting from Firestore requires the Firestore document ID,
//     // which we currently don't store in the Drift Note model.
//   }
//
//   Future<void> updateNote(int id, String title, String content) async {
//     print("### NoteRepository: Updating note $id...");
//     await _noteDriftDatabase.updateNote(id, title, content);
//     // Note: Updating Firestore requires the Firestore document ID.
//   }
// }
