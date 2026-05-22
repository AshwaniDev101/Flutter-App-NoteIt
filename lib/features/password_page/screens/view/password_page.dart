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
      backgroundColor: Colors.black.withOpacity(0.25),
      body: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Center(
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
                // const CircleAvatar(
                //   radius: 28,
                //   child: Icon(
                //     Icons.lock,
                //     size: 30,
                //   ),
                // ),
                //
                // const SizedBox(height: 18),
                // const Text(
                //   'Locked Note',
                //   style: TextStyle(
                //     fontSize: 22,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                //
                // const SizedBox(height: 8),
                //
                // Text(
                //   'Enter password to continue',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Colors.grey.shade600,
                //   ),
                // ),

                const SizedBox(height: 20),

                TextField(
                  controller: _controller,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.password),
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton(
                        onPressed: _unlock,
                        child: const Text('Unlock'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}