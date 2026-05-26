import 'package:flutter/material.dart';

class MasterPasswordPage extends StatelessWidget {
  const MasterPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Password')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Current master password"),
              const TextField(obscureText: true),

              const SizedBox(height: 16),
              const Text("New master password"),
              const TextField(obscureText: true),
              const SizedBox(height: 16),
              const Text("Confirm new master password"),
              const TextField(obscureText: true),
              const SizedBox(height: 24),

              const Text("The master password is used to encrypt and decrypt notes for protection and backup."),
              const SizedBox(height: 24),
              Text(
                "Warning: If you forget your master password, you will not be able to recover your encrypted notes.",
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(onPressed: () {}, child: const Text('Update Password')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
