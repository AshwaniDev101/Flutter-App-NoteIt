import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core utilities
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/core/util/device_info.dart';

// Database and Sync
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/database/sync/sync_orchestrator.dart';

// Features
import 'package:noteit/features/note_editor/screens/view/desktop_edit_page.dart';
import 'package:noteit/shared/core/note_action_controller.dart';

/// Represents the UI state for the note editor.
///
/// Tracks background processing states and holds potential error messages
/// encountered during database operations.
class EditNoteState {
  final bool isLoading;
  final String? error;

  const EditNoteState({
    required this.isLoading,
    this.error,
  });

  /// Creates a copy of this state with the given fields replaced with the new values.
  EditNoteState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return EditNoteState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error, // Explicitly allows clearing the error if passed as null
    );
  }
}

/// ViewModel responsible for managing note operations in the editor.
///
/// Handles creating, updating, locking, and deleting notes within the local Drift database.
/// Every successful operation automatically triggers a background cloud synchronization.
class EditNoteViewModel extends Notifier<EditNoteState> {
  @override
  EditNoteState build() {
    // Initial state: not loading, no errors.
    return const EditNoteState(isLoading: false, error: null);
  }

  /// Creates and saves a completely new note to the local database.
  ///
  /// [title] The title of the note.
  /// [content] The body text or JSON content of the note.
  /// [contentVersion] Enum dictating the format of the content (e.g., plain text vs. checklist).
  ///
  /// Returns the newly created [NoteWithFolder] object if successful, or `null` if an error occurs.
  Future<NoteWithFolder?> saveNote(
      String title,
      String content,
      ContentVersion contentVersion, {
        String? folderId,
      }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Retrieve dynamic device information for analytics and sync metadata
      final deviceInfo = await ref.read(deviceInfoProvider.future);

      // Insert into local database
      final newUuid = await ref.read(notesDaoProvider).addNote(
        title: title,
        content: content,
        creationPlatform: deviceInfo.extractPlatform,
        creationDevice: deviceInfo.extractName,
        contentVersion: contentVersion.value,
        folderId: folderId, // Pass the folderId to the database
      );

      AppLogger.d('EditNoteViewModel: Saved new note ($newUuid)');

      // Fire background sync via Orchestrator
      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);

      // Fetch and return the newly created note from the database to update the UI state
      return await ref.read(notesDaoProvider).getNoteById(newUuid);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error saving new note', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());

      return null;
    }
  }

  /// Updates an existing note's content and metadata.
  ///
  /// [uuid] The unique identifier of the note to update.
  /// [title] The updated title.
  /// [content] The updated body text or JSON content.
  /// [contentVersion] Enum dictating the format of the content.
  Future<void> updateNote(String uuid, String title, String content, ContentVersion contentVersion) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(notesDaoProvider).updateNote(
        uuid: uuid,
        title: title,
        content: content,
        contentVersion: contentVersion.value,
      );

      AppLogger.d('EditNoteViewModel: Updated note ($uuid)');

      // Fire background sync via Orchestrator
      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error updating note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggles the lock status of a specific note.
  ///
  /// [uuid] The unique identifier of the note.
  /// [isLocked] Determines whether to lock (true) or unlock (false) the note. Defaults to true.
  Future<void> lockNote(String uuid, {bool isLocked = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (isLocked) {
        await ref.read(noteActionsControllerProvider).lockNotes([uuid]);
      } else {
        await ref.read(notesDaoProvider).lockNote(uuid, isLocked: false);
        AppLogger.d('EditNoteViewModel: Unlocked note $uuid');
        ref.read(syncOrchestratorProvider).triggerSync();
      }

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error locking note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Soft-deletes a note by marking it as deleted in the database.
  ///
  /// [uuid] The unique identifier of the note to delete.
  Future<void> deleteNote(String uuid) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteActionsControllerProvider).deleteNotes(
        [uuid],
        PlatformHelper.name,
      );

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error deleting note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Global provider for the [EditNoteViewModel].
///
/// Used to interact with the note editor state and perform database operations.
final editNoteViewModelProvider = NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
);