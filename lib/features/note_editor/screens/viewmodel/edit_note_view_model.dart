import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/note_editor/screens/view/desktop_edit_page.dart';

import '../../../../core/device_info.dart';
import '../../../../database/sync/sync_orchestrator.dart';

class EditNoteState {
  final bool isLoading;
  final String? error;

  const EditNoteState({required this.isLoading, this.error});

  EditNoteState copyWith({bool? isLoading, String? error}) {
    return EditNoteState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EditNoteViewModel extends Notifier<EditNoteState> {
  @override
  EditNoteState build() {
    return const EditNoteState(isLoading: false, error: null);
  }

  Future<void> saveNote(String title, String content, ContentVersion contentVersion) async {
    state = state.copyWith(isLoading: true, error: null);

    final deviceInfo = await ref.read(deviceInfoProvider.future);

    try {

      final newUuid = await ref
          .read(notesDaoProvider)
          .addNote(
            title: title,
            content: content,
            creationPlatform: deviceInfo.extractPlatform,
            creationDevice: deviceInfo.extractName,
           contentVersion: contentVersion.value,
          );

      AppLogger.d('EditNoteViewModel: Saved new note ($newUuid)');

      // Fire background sync via Orchestrator
      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error saving new note', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateNote(String uuid, String title, String content, ContentVersion contentVersion) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(notesDaoProvider).updateNote(uuid: uuid, title: title, content: content,contentVersion:  contentVersion.value,);
      AppLogger.d('EditNoteViewModel: Updated note ($uuid)');

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error updating note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> lockNote(String uuid, {bool isLocked = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(notesDaoProvider).lockNote(uuid, isLocked: isLocked);
      AppLogger.d('EditNoteViewModel: Locked note $uuid (isLocked: $isLocked)');

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error locking note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteNote(String uuid) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(notesDaoProvider).softDeleteNotes([
        uuid,
      ], platform: PlatformHelper.name);

      AppLogger.d('EditNoteViewModel: Soft deleted note ($uuid)');

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('EditNoteViewModel: Error deleting note $uuid', error: e, stack: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final editNoteViewModelProvider =
    NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
    );
