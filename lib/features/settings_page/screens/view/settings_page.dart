import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'; // Updated import
import 'package:noteit/core/routing/routing.dart';


class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // Pass WidgetRef to access Riverpod providers
  Future<void> _signInWithGoogle(WidgetRef ref) async {
    try {
      // Access the universal Google Sign In instance
      final googleSignIn = ref.read(googleSignInProvider);

      // Triggers the correct flow (Browser/Popup/Local Server) based on platform
      final GoogleSignInCredentials? credentials = await googleSignIn.signInOnline();

      if (credentials == null) return; // User canceled

      // Pass the retrieved tokens directly to Firebase
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
  Widget build(BuildContext context, WidgetRef ref) { // Added WidgetRef
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            // Account
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Account',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final User? user = snapshot.data;
                  final bool isSignedIn = user != null;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Profile header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: isSignedIn && user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: !isSignedIn || user.photoURL == null
                                    ? Icon(Icons.person, size: 30, color: colorScheme.onSurfaceVariant)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSignedIn ? (user.displayName ?? 'No Name') : 'Not signed in',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isSignedIn) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email ?? '',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Auth actions
                          SizedBox(
                            width: double.infinity,
                            child: isSignedIn
                                ? OutlinedButton.icon(
                              onPressed: () async {
                                // Update sign out to use the provider as well
                                final googleSignIn = ref.read(googleSignInProvider);
                                await googleSignIn.signOut();
                                await FirebaseAuth.instance.signOut();
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                              ),
                            )
                                : FilledButton.icon(
                              onPressed: () => _signInWithGoogle(ref), // Pass ref here
                              icon: const Icon(Icons.login),
                              label: const Text('Sign in with Google'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
            ),

            const SizedBox(height: 24),

            // Preferences
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Preferences',
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
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
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
                  Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withOpacity(0.5)),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    iconColor: Colors.orange,
                    title: 'Master password',
                    subtitle: 'Reset or clear master password',
                    onTap: () => context.push(AppRoutes.masterPassword),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          hoverColor: theme.colorScheme.primary.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
        ),
      ),
    );
  }
}