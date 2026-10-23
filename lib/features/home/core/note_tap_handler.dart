import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/router/router.dart';
import 'package:noteit/core/util/platform_helper.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/features/home/core/providers.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/lock/lock_manger/lock_manager.dart';
import 'package:noteit/features/lock/password_prompt_helper.dart';

/// Centralized utility for handling note taps across home views (Mobile and Desktop).
///
/// Handles:
/// 1. Security verification for locked notes (prompting master password if not yet unlocked in current session).
/// 2. Adaptive cross-platform navigation:
///    - Mobile: Pushes `AppRoutes.edit` route onto navigation stack.
///    - Desktop: Updates `activeNoteProvider` and switches right panel view to `RightPanelPageOptions.noteEditor`.
class NoteTapHandler {
  /// Opens the given [noteWithFolder], verifying master password lock if necessary.
  static Future<void> openNote(BuildContext context, WidgetRef ref, NoteWithFolder noteWithFolder) async {
    final isWide = PlatformHelper.isWideLayout(context);
    final isSessionUnlocked = ref.read(lockManagerProvider).sessionUnlockedNoteIds.contains(noteWithFolder.note.uuid);

    // If note is locked and hasn't been unlocked during this session, prompt for password
    if (noteWithFolder.note.lockedAt != null && !isSessionUnlocked) {
      final success = await PasswordPromptHelper.promptAndVerify(context, ref, noteWithFolder);
      if (!success) return; // User cancelled or failed verification
    }

    if (!context.mounted) return;

    if (isWide) {
      final rightPanelNotifier = ref.read(desktopRightPanelViewProvider.notifier);
      final currentView = rightPanelNotifier.currentView;

      ref.read(activeNoteProvider.notifier).setNote(noteWithFolder);

      if (currentView == RightPanelPageOptions.noteEditor) {
        rightPanelNotifier.setView(RightPanelPageOptions.noteEditor);
      } else {
        rightPanelNotifier.pushView(RightPanelPageOptions.noteEditor);
      }
    } else {
      // Mobile: Push edit page route with note parameter
      context.push(AppRoutes.edit, extra: noteWithFolder);
    }
  }
}
