import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxcvbn/zxcvbn.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../lock_manger/lock_manager.dart';
import '../password_prompt_helper.dart';
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

  final Zxcvbn _zxcvbn = Zxcvbn();

  String? _errorMessage;
  int _strengthScore = 0;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final pass = _newPassController.text;
    if (pass.isEmpty) {
      setState(() => _strengthScore = 0);
      return;
    }
    final result = _zxcvbn.evaluate(pass);
    setState(() {
      _strengthScore = result.score?.toInt() ?? 0;
    });
  }

  @override
  void dispose() {
    _newPassController.removeListener(_onPasswordChanged);
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPass = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (currentPass.isEmpty) {
      setState(() => _errorMessage = 'Current password cannot be empty');
      return;
    }

    final lockNotifier = ref.read(lockManagerProvider.notifier);
    final isCurrentValid = await lockNotifier.verifyPassword(currentPass);
    if (!isCurrentValid) {
      setState(() => _errorMessage = 'Current password is incorrect');
      return;
    }

    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'New password cannot be empty');
      return;
    }

    if (newPass.length < 8) {
      setState(() => _errorMessage = 'New password must be at least 8 characters');
      return;
    }

    if (_strengthScore < 3) {
      setState(() => _errorMessage = 'New password is too weak. Add symbols, numbers or spaces');
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
        if (context.mounted) {
          await PasswordPromptHelper.showSeedPhraseDialog(context, ref);
        }
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
    final currentPass = _currentPassController.text;

    if (currentPass.isEmpty) {
      setState(() => _errorMessage = 'Enter current password to remove it');
      return;
    }

    final lockNotifier = ref.read(lockManagerProvider.notifier);
    final isCurrentValid = await lockNotifier.verifyPassword(currentPass);
    if (!isCurrentValid) {
      setState(() => _errorMessage = 'Current password is incorrect');
      return;
    }

    if (!mounted) return;

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

  Color _getStrengthColor() {
    switch (_strengthScore) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
      default:
        return Colors.green;
    }
  }

  String _getStrengthText() {
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      default:
        return 'Strong';
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
                    color: colorScheme.onSurfaceVariant,
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Strength Indicator
            if (_newPassController.text.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_strengthScore + 1) / 5,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: _getStrengthColor(),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStrengthText(),
                    style: textTheme.bodySmall?.copyWith(
                      color: _getStrengthColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

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
                    color: colorScheme.onSurfaceVariant,
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
