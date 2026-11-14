import 'package:flutter/material.dart';
import 'package:zxcvbn/zxcvbn.dart';
import 'widgets/lock_dialog_shell.dart';

class SetupPasswordPage extends StatefulWidget {
  const SetupPasswordPage({super.key});

  @override
  State<SetupPasswordPage> createState() => _SetupPasswordPageState();
}

class _SetupPasswordPageState extends State<SetupPasswordPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final Zxcvbn _zxcvbn = Zxcvbn();

  String? _errorMessage;
  int _strengthScore = 0;

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final pass = _passController.text;
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
    _passController.removeListener(_onPasswordChanged);
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pass = _passController.text;
    final confirm = _confirmController.text;

    if (pass.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (_strengthScore < 3) {
      setState(() => _errorMessage = 'Password is too weak. Add symbols, numbers or spaces');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    Navigator.pop(context, pass);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 36, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            "Create Master Password",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // New Password Field
          TextField(
            controller: _passController,
            obscureText: _obscurePass,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'New Master Password',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Strength Indicator
          if (_passController.text.isNotEmpty) ...[
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
                  style: textTheme.bodySmall?.copyWith(color: _getStrengthColor(), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Confirm Password Field
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Confirm Master Password',
              filled: true,
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Set Password & Lock'),
            ),
          ),
        ],
      ),
    );
  }
}
