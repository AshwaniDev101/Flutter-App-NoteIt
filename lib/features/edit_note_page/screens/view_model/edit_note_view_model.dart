import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

class EditNoteState {
  final bool isLoading;
  final String? error;

  const EditNoteState({
    required this.isLoading,
    this.error,
  });

  EditNoteState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return EditNoteState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EditNoteViewModel extends Notifier<EditNoteState> {
  @override
  EditNoteState build() {
    return const EditNoteState(
      isLoading: false,
      error: null,
    );
  }

  Future<void> saveNote(String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).addNote(
        title: title,
        content: content,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateNote(int id, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).updateNote(id, title, content);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> lockNote(int id, {bool isLocked = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).lockNote(id, isLocked: isLocked);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Completes the CRUD cycle by removing the target note from the Drift database
  Future<void> deleteNote(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {

      // await ref.read(noteDriftDatabaseProvider).deleteNote(id);
      await ref.read(noteDriftDatabaseProvider).softDeleteNotes([id]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final editNoteViewModelProvider = NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
);