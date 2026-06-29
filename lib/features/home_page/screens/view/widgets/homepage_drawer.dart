import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:noteit/core/routing/routing.dart';

import '../../../../../core/provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';

class HomepageDrawer extends ConsumerWidget {
  const HomepageDrawer({super.key});

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Check current theme brightness to dictate the toggle's visual state
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // MODERN CUSTOM HEADER
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final User? user = snapshot.data;
              final bool isSignedIn = user != null;

              return Container(
                padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: isSignedIn && user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: !isSignedIn || user.photoURL == null
                          ? Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSignedIn ? (user.displayName ?? 'No Name') : 'Welcome to Note-it',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSignedIn ? (user.email ?? '') : 'Sign in to sync your notes',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // MAIN SCROLLABLE LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              children: [
                _DrawerItem(
                  icon: Icons.notes_rounded,
                  title: 'All Notes',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Trash',
                  onTap: () {
                    Navigator.pop(context);
                    // context.push(AppRoutes.trash);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(indent: 16, endIndent: 16),
                ),

                // Preferences Section
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                  child: Text(
                    'Preferences',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Dark Mode Toggle
                ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      // Toggle between standard Light and Dark modes
                      final newTheme = value ? AppThemeType.dark : AppThemeType.light;
                      ref.read(themeProvider.notifier).setTheme(newTheme);
                    },
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                _DrawerItem(
                  icon: Icons.color_lens_outlined,
                  title: 'Themes',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.themes);
                  },
                ),
                _DrawerItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Master Password',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.masterPassword);
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    // Navigator.pop(context);
                    context.push(AppRoutes.settings);
                    // context.push(AppRoutes.settings);
                  },
                ),
              ],
            ),
          ),

          // BOTTOM FOOTER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final bool isSignedIn = snapshot.data != null;

                  return Align(
                    alignment: Alignment.centerLeft, // Aligns button nicely to the left
                    child: isSignedIn
                        ? OutlinedButton.icon(
                      onPressed: () async {
                        final googleSignIn = ref.read(googleSignInProvider);
                        await googleSignIn.signOut();
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: Icon(Icons.logout_rounded, color: colorScheme.onSurfaceVariant),
                      label: Text(
                        'Sign Out',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        // Gives it a subtle border matching your theme
                        side: BorderSide(color: colorScheme.outlineVariant),
                        // Makes it a rounded square instead of a pill
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                        : FilledButton.tonalIcon(
                      onPressed: () => _signInWithGoogle(ref),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign in with Google'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        hoverColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      ),
    );
  }
}