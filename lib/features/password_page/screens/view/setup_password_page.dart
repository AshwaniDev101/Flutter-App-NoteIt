import 'dart:ui';
import 'package:flutter/material.dart';

class SetupPasswordPage extends StatefulWidget {
  const SetupPasswordPage({super.key});

  @override
  State<SetupPasswordPage> createState() => _SetupPasswordPageState();
}

class _SetupPasswordPageState extends State<SetupPasswordPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;

  // State variables for password visibility
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pass = _passController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Password cannot be empty');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    // Return the successfully created and confirmed password
    Navigator.pop(context, pass);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.25),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context), // Dismiss on background tap
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent taps inside the card from closing it
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 32, color: colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      "Create Master Password",
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // The Warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "WARNING: There is no password recovery. If you forget this password, you will permanently lose access to all locked notes.",
                              style: textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // New Password
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePass, // Bound to state
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'New Password',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePass = !_obscurePass;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password Field
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm, // Bound to state
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        filled: true,
                        errorText: _errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}