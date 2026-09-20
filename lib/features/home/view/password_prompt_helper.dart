import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/drift/drift_database.dart';

import '../../unlock/lock_manger/lock_manager.dart';
import '../../unlock/view/password_page.dart';

class PasswordPromptHelper {
  static Future<bool> promptAndVerify(BuildContext context, WidgetRef ref, Note note) async {
    final String? enteredPassword = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Password Dialog',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const PasswordPage(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (enteredPassword != null && enteredPassword.isNotEmpty && context.mounted) {
      final lockManager = ref.read(lockManagerProvider.notifier);

      if (!lockManager.hasMasterPassword) {
        await lockManager.setupMasterPassword(enteredPassword);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Master Password Set!')));
      }

      final success = lockManager.verifyAndSessionUnlock(note.uuid, enteredPassword);

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
      }

      return success;
    }

    return false;
  }
}