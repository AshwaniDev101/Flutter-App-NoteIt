import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

import '../../core/provider/provider.dart';
import '../../core/routing/routing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/logger.dart';

enum DrawerOption {
  allNotes(
    'All Notes',
    'View, search, and manage all your saved notes',
    Icons.grid_view_rounded,
  ),
  trash(
    'Trash',
    'Recover deleted items or empty the recycle bin',
    Icons.delete_outline_rounded,
  ),
  themes(
    'Themes',
    'Personalize your colors, background, and appearance',
    Icons.palette_outlined,
  ),
  localSync(
    'Local Sync',
    'Connect and synchronize across your local network',
    Icons.phonelink_outlined,
  ),
  settings(
    'Settings',
    'Configure app preferences, accounts, and behavior',
    Icons.settings_outlined,
  ),
  devTools(
    'Dev Tools',
    'Advanced debugging and diagnostic utilities',
    Icons.bug_report_outlined,
  );

  final String label;
  final String description;
  final IconData icon;

  const DrawerOption(this.label, this.description, this.icon);
}

class AppDrawer extends ConsumerWidget {
  final DrawerOption? selectedOption;

  const AppDrawer({
    super.key,
    this.selectedOption = DrawerOption.allNotes,
  });

  void _handleNavigation(BuildContext context, DrawerOption option) {
    Navigator.of(context).pop();

    switch (option) {
      case DrawerOption.allNotes:
        break;
      case DrawerOption.trash:
        context.push(AppRoutes.trash);
        break;
      case DrawerOption.themes:
        context.push(AppRoutes.themes);
        break;
      case DrawerOption.localSync:
        context.push(AppRoutes.roleSelector);
        break;
      case DrawerOption.settings:
        context.push(AppRoutes.settings);
        break;
      case DrawerOption.devTools:
        context.push(AppRoutes.dev);
        break;
    }
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Logo / App Identity ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'N', // NoteIt Logo Placeholder
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // --- Scrollable Navigation ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const _SectionHeader(title: 'WORKSPACE'),
                  _CompactDrawerTile(
                    option: DrawerOption.allNotes,
                    isSelected: selectedOption == DrawerOption.allNotes,
                    onTap: () => _handleNavigation(context, DrawerOption.allNotes),
                  ),
                  _CompactDrawerTile(
                    option: DrawerOption.trash,
                    isSelected: selectedOption == DrawerOption.trash,
                    onTap: () => _handleNavigation(context, DrawerOption.trash),
                  ),

                  const SizedBox(height: 16),

                  const _SectionHeader(title: 'SYSTEM'),
                  _CompactDrawerTile(
                    option: DrawerOption.localSync,
                    isSelected: selectedOption == DrawerOption.localSync,
                    onTap: () => _handleNavigation(context, DrawerOption.localSync),
                  ),
                  _CompactDrawerTile(
                    option: DrawerOption.themes,
                    isSelected: selectedOption == DrawerOption.themes,
                    onTap: () => _handleNavigation(context, DrawerOption.themes),
                  ),
                  _CompactDrawerTile(
                    option: DrawerOption.settings,
                    isSelected: selectedOption == DrawerOption.settings,
                    onTap: () => _handleNavigation(context, DrawerOption.settings),
                  ),
                  _CompactDrawerTile(
                    option: DrawerOption.devTools,
                    isSelected: selectedOption == DrawerOption.devTools,
                    onTap: () => _handleNavigation(context, DrawerOption.devTools),
                  ),
                ],
              ),
            ),

            // --- Primary Action Button (Sign In / Out) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final isSignedIn = user != null;

                  if (isSignedIn) {
                    return _ActionContainer(
                      title: 'Sign Out',
                      subtitle: user.displayName ?? 'Account',
                      icon: Icons.logout_rounded,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      onTap: () async {
                        final googleSignIn = ref.read(googleSignInProvider);
                        await googleSignIn.signOut();
                        await FirebaseAuth.instance.signOut();
                      },
                    );
                  } else {
                    return _ActionContainer(
                      title: 'Sign In',
                      subtitle: 'Sync your data',
                      icon: Icons.add_circle_outline_rounded,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      onTap: () => _signInWithGoogle(ref),
                    );
                  }
                },
              ),
            ),

            // --- Bottom Theme Toggle ---
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Light',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: !isDarkMode ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: !isDarkMode ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: isDarkMode,
                    activeThumbColor: Colors.blue,
                    inactiveThumbColor: colorScheme.surface,
                    inactiveTrackColor: colorScheme.surfaceContainerHighest,
                    onChanged: (value) {
                      final newTheme = value ? AppThemeType.dark : AppThemeType.light;
                      ref.read(themeProvider.notifier).setTheme(newTheme);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dark',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: isDarkMode ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  final DrawerOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const  _CompactDrawerTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surfaceContainerHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 20,
                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}