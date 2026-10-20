import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/notes/notes_dao.dart';
import 'package:noteit/shared/snack_bar_manager.dart';

import 'lock_manger/lock_manager.dart';
import 'view/master_password_page.dart';
import 'view/setup_password_page.dart';
import 'view/update_password_page.dart';

class PasswordPromptHelper {
  static Future<bool> promptAndVerify(
    BuildContext context,
    WidgetRef ref,
    NoteWithFolder noteWithFolder,
  ) async {
    final lockManager = ref.read(lockManagerProvider.notifier);

    // If no master password is set, require the user to set up and confirm a password
    if (!lockManager.hasMasterPassword) {
      final String? newPassword = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Password Dialog',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SetupPasswordPage(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      if (newPassword != null &&
          newPassword.isNotEmpty &&
          context.mounted) {
        await lockManager.setupMasterPassword(newPassword);
        SnackBarManager.show(
          msg: 'Master Password Created!',
          type: SnackBarMessageType.acknowledgment,
        );
        return lockManager.verifyAndSessionUnlock(
          noteWithFolder.note.uuid,
          newPassword,
        );
      }
      return false;
    }

    // Master password is set, prompt for verification
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const MasterPasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null &&
        enteredPassword.isNotEmpty &&
        context.mounted) {
      final success = lockManager.verifyAndSessionUnlock(
        noteWithFolder.note.uuid,
        enteredPassword,
      );

      if (!success && context.mounted) {
        SnackBarManager.show(
          msg: 'Incorrect Password',
          type: SnackBarMessageType.error,
        );
      }

      return success;
    }

    return false;
  }

  static Future<bool> promptAndVerifyForExport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lockManager = ref.read(lockManagerProvider.notifier);

    // If no master password is set, require the user to set up and confirm a password
    if (!lockManager.hasMasterPassword) {
      final String? newPassword = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Password Dialog',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SetupPasswordPage(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      if (newPassword != null &&
          newPassword.isNotEmpty &&
          context.mounted) {
        await lockManager.setupMasterPassword(newPassword);
        SnackBarManager.show(
          msg: 'Master Password Created!',
          type: SnackBarMessageType.acknowledgment,
        );
        return lockManager.verifyAndSessionUnlock(
          'global_export_session',
          newPassword,
        );
      }
      return false;
    }

    // Master password is set, prompt for verification
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const MasterPasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null &&
        enteredPassword.isNotEmpty &&
        context.mounted) {
      final success = lockManager.verifyAndSessionUnlock(
        'global_export_session',
        enteredPassword,
      );

      if (!success && context.mounted) {
        SnackBarManager.show(
          msg: 'Incorrect Password',
          type: SnackBarMessageType.error,
        );
      }

      return success;
    }

    return false;
  }

  static Future<void> showMasterPasswordManagement(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lockNotifier = ref.read(lockManagerProvider.notifier);
    final hasMasterPassword = lockNotifier.hasMasterPassword;

    if (hasMasterPassword) {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Password Dialog',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UpdatePasswordPage(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    } else {
      final String? newPassword = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Password Dialog',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SetupPasswordPage(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      if (newPassword != null && newPassword.isNotEmpty && context.mounted) {
        await lockNotifier.setupMasterPassword(newPassword);
        SnackBarManager.show(
          msg: 'Master Password Created!',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }
}
