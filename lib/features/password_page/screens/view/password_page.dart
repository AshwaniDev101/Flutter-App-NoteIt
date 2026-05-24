import 'dart:ui';

import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _unlock() {
    final password = _controller.text.trim();

    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.25),

      // background tap dismiss
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Center(

            // swallow taps on the card itself so it doesn't trigger the background dismiss
            child: GestureDetector(
              onTap: () {}, // no-op
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Enter Master Password",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      obscureText: true,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _unlock(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _unlock,
                            child: const Text('ok'),
                          ),
                        ),
                      ],
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