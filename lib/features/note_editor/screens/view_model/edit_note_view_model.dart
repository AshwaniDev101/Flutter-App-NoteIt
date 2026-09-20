import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

import '../../../../core/helpers/device_helper.dart';
import '../../../../database/sync/sync_orchestrator.dart';


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
      final deviceInfo = await DeviceHelper.getDeviceInfo();

      await ref.read(noteDriftDatabaseProvider).addNote(
        title: title,
        content: content,
        creationPlatform: deviceInfo['platform'],
        creationDevice: deviceInfo['deviceName'],
      );

      // Fire background sync via Orchestrator
      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }


  Future<void> updateNote(String uuid, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).updateNote(uuid, title, content);

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }


  Future<void> lockNote(String uuid, {bool isLocked = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).lockNote(uuid, isLocked: isLocked);

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteNote(String uuid) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).softDeleteNotes(
        [uuid],
        platform: defaultTargetPlatform.name,
      );

      ref.read(syncOrchestratorProvider).triggerSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final editNoteViewModelProvider = NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
);