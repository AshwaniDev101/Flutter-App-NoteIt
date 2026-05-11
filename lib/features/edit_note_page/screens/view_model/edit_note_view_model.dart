import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      await ref.read(driftDbProvider).addNote(title, content);

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

  Future<void> updateNote(int id, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(driftDbProvider).updateNote(id, title, content);

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