import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/snack_bar_manager.dart';
import '../lock_manger/lock_manager.dart';
import 'widgets/lock_dialog_shell.dart';

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage> {
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  String? _errorMessage;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPass = _currentPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (currentPass.isEmpty) {
      setState(() => _errorMessage = 'Current password cannot be empty');
      return;
    }

    final lockNotifier = ref.read(lockManagerProvider.notifier);
    if (!lockNotifier.verifyPassword(currentPass)) {
      setState(() => _errorMessage = 'Current password is incorrect');
      return;
    }

    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'New password cannot be empty');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'New passwords do not match');
      return;
    }

    if (newPass == currentPass) {
      setState(() => _errorMessage = 'New password must be different');
      return;
    }

    final success = await lockNotifier.setupMasterPassword(newPass);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        SnackBarManager.show(
          msg: 'Master Password Updated!',
          type: SnackBarMessageType.acknowledgment,
        );
      } else {
        setState(() => _errorMessage = 'Failed to update password');
      }
    }
  }

  Future<void> _removePassword() async {
    final currentPass = _currentPassController.text.trim();

    if (currentPass.isEmpty) {
      setState(() => _errorMessage = 'Enter current password to remove it');
      return;
    }

    final lockNotifier = ref.read(lockManagerProvider.notifier);
    if (!lockNotifier.verifyPassword(currentPass)) {
      setState(() => _errorMessage = 'Current password is incorrect');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Master Password?'),
        content: const Text(
          'This will remove password protection from all your locked notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await lockNotifier.removeMasterPassword();
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          SnackBarManager.show(
            msg: 'Master Password Removed!',
            type: SnackBarMessageType.acknowledgment,
          );
        } else {
          setState(() => _errorMessage = 'Failed to remove password');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LockDialogShell(
      width: 360,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              "Update Master Password",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Current Password Field
            TextField(
              controller: _currentPassController,
              obscureText: _obscureCurrent,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Current Password',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // New Password Field
            TextField(
              controller: _newPassController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Password Field
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirm New Password',
                filled: true,
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _updatePassword(),
            ),
            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _updatePassword,
                child: const Text('Update Password'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                onPressed: _removePassword,
                child: const Text('Remove Master Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
