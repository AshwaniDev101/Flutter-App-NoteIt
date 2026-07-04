import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

import '../../../../core/helpers/device_helper.dart';
import '../../../../database/sync_manager.dart';


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
      // 1. Fetch metadata before saving
      final deviceInfo = await DeviceHelper.getDeviceInfo();

      // 2. Save locally with the new device data
      await ref.read(noteDriftDatabaseProvider).addNote(
        title: title,
        content: content,
        creationPlatform: deviceInfo['platform'],
        creationDevice: deviceInfo['deviceName'],
      );

      // 3. Fire background sync
      ref.read(syncNotifierProvider.notifier).executeFullSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateNote(int id, String title, String content) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).updateNote(id, title, content);

      // Fire background sync
      ref.read(syncNotifierProvider.notifier).executeFullSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> lockNote(int id, {bool isLocked = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(noteDriftDatabaseProvider).lockNote(id, isLocked: isLocked);

      // Fire background sync
      ref.read(syncNotifierProvider.notifier).executeFullSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Completes the CRUD cycle by soft-deleting the target note
  Future<void> deleteNote(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {

      await ref.read(noteDriftDatabaseProvider).softDeleteNotes(
        [id],
        platform: defaultTargetPlatform.name,
      );

      // Fire background sync to update the cloud's trash state
      ref.read(syncNotifierProvider.notifier).executeFullSync();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final editNoteViewModelProvider = NotifierProvider<EditNoteViewModel, EditNoteState>(
      () => EditNoteViewModel(),
);