
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:noteit/core/routing/routing.dart';

import '../../core/provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/logger.dart';

class HomepageDrawer extends ConsumerWidget {
  /// Optional callback for desktop overlay to close on item selection
  final VoidCallback? onDestinationSelected;

  const HomepageDrawer({
    super.key,
    this.onDestinationSelected,
  });

  void _navigate(BuildContext context, String route) {
    // Safely close mobile drawer if open (does nothing on desktop)
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }

    // Notify desktop overlay if provided
    onDestinationSelected?.call();

    // Navigate to destination
    context.push(route);
  }

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
      AppLogger.d('Google Sign-In failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          // USER PROFILE HEADER
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final User? user = snapshot.data;
              final bool isSignedIn = user != null;

              return Container(
                padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 20),
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
                      radius: 32,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage:
                      isSignedIn && user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      child: !isSignedIn || user.photoURL == null
                          ? Icon(Icons.person, size: 32, color: colorScheme.onPrimaryContainer)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSignedIn ? (user.displayName ?? 'No Name') : 'Welcome to Note-it',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSignedIn ? (user.email ?? '') : 'Sign in to sync your notes',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),

          // NAVIGATION ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              children: [
                _DrawerItem(
                  icon: Icons.notes_rounded,
                  title: 'All Notes',
                  onTap: () {
                    final scaffold = Scaffold.maybeOf(context);
                    if (scaffold != null && scaffold.isDrawerOpen) {
                      scaffold.closeDrawer();
                    }
                    onDestinationSelected?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Trash',
                  onTap: () => _navigate(context, AppRoutes.trash),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(indent: 12, endIndent: 12),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 6.0),
                  child: Text(
                    'Preferences',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Dark Mode Switch
                ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      final newTheme = value ? AppThemeType.dark : AppThemeType.light;
                      ref.read(themeProvider.notifier).setTheme(newTheme);
                    },
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                _DrawerItem(
                  icon: Icons.palette_outlined,
                  title: 'Themes',
                  onTap: () => _navigate(context, AppRoutes.themes),
                ),
                _DrawerItem(
                  icon: Icons.phonelink_outlined,
                  title: 'Local Sync',
                  onTap: () => _navigate(context, AppRoutes.roleSelector),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => _navigate(context, AppRoutes.settings),
                ),
                _DrawerItem(
                  icon: Icons.bug_report_outlined,
                  title: 'Dev Tools',
                  onTap: () => _navigate(context, AppRoutes.dev),
                ),
              ],
            ),
          ),

          // BOTTOM AUTH CONTROLS
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final bool isSignedIn = snapshot.data != null;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: isSignedIn
                        ? OutlinedButton.icon(
                      onPressed: () async {
                        final googleSignIn = ref.read(googleSignInProvider);
                        await googleSignIn.signOut();
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: Icon(Icons.logout_rounded, color: colorScheme.onSurfaceVariant),
                      label: Text('Sign Out', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                        : FilledButton.tonalIcon(
                      onPressed: () => _signInWithGoogle(ref),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign in with Google'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  const _DrawerItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: ListTile(
        leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        hoverColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      ),
    );
  }
}