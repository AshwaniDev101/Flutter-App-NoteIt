import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

import '../../core/routing/routing.dart';
import '../../core/provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/logger.dart';

enum DrawerOption {
  allNotes(
    'All Notes',
    'View, search, and manage all your saved notes',
    Icons.notes_rounded,
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

class DrawerMenuButton extends ConsumerStatefulWidget {
  const DrawerMenuButton({super.key});

  @override
  ConsumerState<DrawerMenuButton> createState() => _DrawerMenuButtonState();
}

class _DrawerMenuButtonState extends ConsumerState<DrawerMenuButton> {
  final MenuController _menuController = MenuController();

  void _handleOptionSelected(DrawerOption option) {
    _menuController.close();

    switch (option) {
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
      case DrawerOption.allNotes:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.settings_rounded),
        );
      },
      menuChildren: [
        DrawerMenu(
          onOptionSelected: _handleOptionSelected,
          onClose: () => _menuController.close(),
        ),
      ],
    );
  }
}

class DrawerMenu extends ConsumerWidget {
  final void Function(DrawerOption) onOptionSelected;
  final VoidCallback onClose;

  const DrawerMenu({
    super.key,
    required this.onOptionSelected,
    required this.onClose,
  });

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

    return Card(
      color: colorScheme.surface,
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final User? user = snapshot.data;
                    final bool isSignedIn = user != null;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: isSignedIn && user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: !isSignedIn || user.photoURL == null
                              ? Icon(Icons.person, size: 28, color: colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSignedIn ? (user.displayName ?? 'No Name') : 'Local Account',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSignedIn ? (user.email ?? '') : 'Sign in to sync your preferences and notes across devices',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
                          icon: Icon(
                            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          onPressed: () {
                            final newTheme = isDarkMode ? AppThemeType.light : AppThemeType.dark;
                            ref.read(themeProvider.notifier).setTheme(newTheme);
                          },
                        ),
                      ],
                    );
                  }
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: DrawerOption.values.map((option) {
                  return _SettingsTile(
                    option: option,
                    onTap: () => onOptionSelected(option),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final bool isSignedIn = snapshot.data != null;

                  if (isSignedIn) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final googleSignIn = ref.read(googleSignInProvider);
                          await googleSignIn.signOut();
                          await FirebaseAuth.instance.signOut();
                          onClose();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text("Sign Out"),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        ),
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await _signInWithGoogle(ref);
                        },
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: const Text('Sign in with Google'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  final DrawerOption option;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.option,
    required this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 308,
          decoration: BoxDecoration(
            color: _isHovering ? colorScheme.surfaceContainerHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: _isHovering ? colorScheme.outlineVariant : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.option.icon,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.option.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.option.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}