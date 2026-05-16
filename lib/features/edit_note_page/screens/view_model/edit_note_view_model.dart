import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/firebase_database.dart';
import 'package:noteit/database/repository.dart';

import '../../../../database/drift/drift_database.dart';

class EditNoteState {
  final bool isSaved;
  final bool isEditing;
  final bool isLoading;
  final String? error;

  const EditNoteState({
    required this.isSaved,
    required this.isEditing,
    required this.isLoading,
    this.error,
  });

  EditNoteState copyWith({
    bool? isSaved,
    bool? isEditing,
    bool? isLoading,
    String? error,
  }) {
    return EditNoteState(
      isSaved: isSaved ?? this.isSaved,
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EditNoteViewModel extends Notifier<EditNoteState> {
  @override
  EditNoteState build() {
    return const EditNoteState(
      isSaved: false,
      isEditing: true,
      isLoading: false,
      error: null,
    );
  }

  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing);
  }

  Future<void> saveNote(String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // await ref.read(noteDriftDatabaseProvider).addNote(title: title, content: content);
      print("### EditNoteViewModel Note Added!");
      await ref.read(noteFirebaseDatabaseProvider).addNote(title: title, content: content);


      state = state.copyWith(
        isSaved: true,
        isEditing: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
        print("### EditNoteViewModel Updating Note!");
      await ref.read(noteFirebaseDatabaseProvider).updateNote(documentId: id,title: title,content: content); //updateNote(id, title, content);

      state = state.copyWith(
        isSaved: true,
        isEditing: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final editNoteViewModelProvider =
NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
);