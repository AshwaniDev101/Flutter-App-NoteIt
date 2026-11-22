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
  bool _acknowledgedWeakRisk = false;

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
    _confirmController.addListener(_onConfirmChanged);
  }

  void _onPasswordChanged() {
    final pass = _passController.text;
    if (pass.isEmpty) {
      setState(() {
        _strengthScore = 0;
        _acknowledgedWeakRisk = false;
        _errorMessage = null;
      });
      return;
    }
    final result = _zxcvbn.evaluate(pass);
    setState(() {
      _strengthScore = result.score?.toInt() ?? 0;
      _acknowledgedWeakRisk = false;
      _errorMessage = null;
    });
  }

  void _onConfirmChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _passController.removeListener(_onPasswordChanged);
    _confirmController.removeListener(_onConfirmChanged);
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final pass = _passController.text;
    final confirm = _confirmController.text;
    if (pass.length < 4) return false;
    if (pass != confirm) return false;
    if (_strengthScore < 3 && !_acknowledgedWeakRisk) return false;
    return true;
  }

  void _submit() {
    final pass = _passController.text;
    final confirm = _confirmController.text;

    if (pass.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (_strengthScore < 3 && !_acknowledgedWeakRisk) {
      setState(() => _errorMessage = 'Please confirm you understand the risk');
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

          // Warning Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Note-It is Zero-Knowledge. If you forget this password, there is no recovery.",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
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

          // Weak Password Risk Confirmation Banner
          if (_passController.text.length >= 4 && _strengthScore < 3) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Simple password detected. Weak passwords offer lower protection against offline brute-force attacks.",
                          style: textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _acknowledgedWeakRisk = !_acknowledgedWeakRisk),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acknowledgedWeakRisk,
                            onChanged: (val) => setState(() => _acknowledgedWeakRisk = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "I understand the risk of a simple password",
                            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            onSubmitted: (_) => _canSubmit ? _submit() : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Set Password & Lock'),
            ),
          ),
        ],
      ),
    );
  }
}
