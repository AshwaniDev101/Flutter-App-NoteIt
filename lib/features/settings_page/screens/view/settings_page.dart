import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:noteit/core/routing/routing.dart';
import '../../../../core/provider/provider.dart';
import '../../../../shared/managers/lock_manger/lock_manager.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _signInWithGoogle(WidgetRef ref) async {
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final GoogleSignInCredentials? credentials = await googleSignIn.signInOnline();

      if (credentials == null) return;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Listen to lock state for our switch toggle
    final lockState = ref.watch(lockManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            children: [
              // Preferences Section
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'General',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: Colors.blue,
                      title: 'Notifications',
                      subtitle: 'Manage alerts and sounds',
                      onTap: () {},
                    ),
                    Divider(
                        height: 1,
                        indent: 64,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    SettingsTile(
                      icon: Icons.lock_outline,
                      iconColor: Colors.orange,
                      title: 'Master password',
                      subtitle: 'Reset or clear master password',
                      onTap: () => context.push(AppRoutes.masterPassword),
                    ),
                    Divider(
                        height: 1,
                        indent: 64,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    // Switch Tile for Keeping Notes Unlocked
                    SettingsSwitchTile(
                      icon: Icons.lock_open_rounded,
                      iconColor: Colors.teal,
                      title: 'Keep notes unlocked',
                      subtitle: 'Stay unlocked during session',
                      value: lockState.keepUnlockedDuringSession,
                      onChanged: (bool value) {
                        ref.read(lockManagerProvider.notifier).setKeepUnlockedPreference(value);
                      },
                    ),

                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// EXISTING WIDGET
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}

// A tile with a Switch instead of an arrow
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}