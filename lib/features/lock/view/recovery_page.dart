import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/util/logger.dart';
import '../lock_manger/lock_manager.dart';
import 'widgets/lock_dialog_shell.dart';


/// Modal dialog page enabling users to restore master password access using their 12-word BIP39 recovery seed phrase.
class RecoveryPage extends ConsumerStatefulWidget {
  const RecoveryPage({super.key});

  @override
  ConsumerState<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends ConsumerState<RecoveryPage> {
  final TextEditingController _phraseController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phraseController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phraseText = _phraseController.text.trim();
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    final words = phraseText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.length != 12) {
      AppLogger.w("RecoveryPage: Validation failed - recovery phrase word count is ${words.length} instead of 12");
      setState(() => _errorMessage = 'Recovery phrase must be exactly 12 words');
      return;
    }
    if (newPass.length < 8) {
      AppLogger.w("RecoveryPage: Validation failed - new password length < 8");
      setState(() => _errorMessage = 'New password must be at least 8 characters');
      return;
    }
    if (newPass != confirmPass) {
      AppLogger.w("RecoveryPage: Validation failed - passwords do not match");
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final lockNotifier = ref.read(lockManagerProvider.notifier);
      final success = await lockNotifier.recoverWithPhrase(words, newPass);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          AppLogger.d("RecoveryPage: Password successfully recovered via 12-word recovery seed!");
          Navigator.pop(context, true);
        } else {
          AppLogger.w("RecoveryPage: Failed to verify 12-word recovery phrase against recovery marker");
          setState(() => _errorMessage = 'Invalid 12-word recovery phrase');
        }
      }
    } catch (e, st) {
      AppLogger.e("RecoveryPage: Unexpected error during password recovery", error: e, stack: st);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An error occurred during recovery. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LockDialogShell(
      width: 380,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key_rounded, size: 36, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            "Account Recovery",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your 12-word recovery phrase to set a new master password.",
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // Phrase input
          TextField(
            controller: _phraseController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'word1 word2 word3 ... (12 words)',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // New Password
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'New Master Password',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),

          // Confirm Password
          TextField(
            controller: _confirmPassController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Confirm New Password',
              errorText: _errorMessage,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Restore Access'),
            ),
          ),
        ],
      ),
    );
  }
}
