
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteit/core/routing/routing.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Online Backup'),
            subtitle: const Text('Ashwani Yadav'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage alerts and sounds'),
            onTap: () {},
          ),

          ListTile(
            title: const Text('Master password'),
            subtitle: const Text('Reset or clear master password'),
            onTap: () {

              context.push(AppRoutes.masterPassword);
            },
          ),
        ],
      ),
    );
  }
}
