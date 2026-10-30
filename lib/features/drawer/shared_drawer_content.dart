import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../database/firebase/auth/firebase_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class SharedDrawerContent extends ConsumerStatefulWidget {
  final RightPanelPageOptions? selectedOption;
  final void Function(RightPanelPageOptions) onOptionSelected;
  final VoidCallback onClose;

  const SharedDrawerContent({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onClose,
  });

  @override
  ConsumerState<SharedDrawerContent> createState() => _SharedDrawerContentState();
}

class _SharedDrawerContentState extends ConsumerState<SharedDrawerContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Top Logo & App Identity ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'N', // NoteIt Logo Placeholder
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'NoteIt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // --- 2. Scrollable Navigation ---
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(title: 'WORKSPACE'),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.trash,
                      isSelected: widget.selectedOption == RightPanelPageOptions.trash,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.trash),
                    ),
                    const SizedBox(height: 16),

                    const _SectionHeader(title: 'SYSTEM'),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.localSync,
                      isSelected: widget.selectedOption == RightPanelPageOptions.localSync,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.localSync),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.themes,
                      isSelected: widget.selectedOption == RightPanelPageOptions.themes,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.themes),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.settings,
                      isSelected: widget.selectedOption == RightPanelPageOptions.settings,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.settings),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.devTools,
                      isSelected: widget.selectedOption == RightPanelPageOptions.devTools,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.devTools),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.archivePage,
                      isSelected: widget.selectedOption == RightPanelPageOptions.archivePage,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.archivePage),
                    ),

                    const SizedBox(height: 24),

                    // Version Info
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            "Version: ${AppEnv.version}",
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            "Build: ${AppEnv.buildNumber}",
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- 3. Unified Footer (Actions & Theme) ---
          Divider(height: 1, color: colorScheme.surfaceContainerHighest),

          Container(
            color: colorScheme.surfaceContainerLowest, // Optional: slightly distinct footer background
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Auth Button
                StreamBuilder<User?>(
                  initialData: FirebaseAuth.instance.currentUser,
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isSignedIn = user != null;

                    return _ActionContainer(
                      title: isSignedIn ? 'Sign Out' : 'Sign In',
                      subtitle: isSignedIn ? (user.displayName ?? 'Account') : 'Sync your data',
                      icon: isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
                      backgroundColor: isSignedIn ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                      foregroundColor: isSignedIn ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                      onTap: () async {
                        if (isSignedIn) {
                          await ref.read(authRepositoryProvider).signOut();
                        } else {
                          await ref.read(authRepositoryProvider).signInWithGoogle();
                        }
                        widget.onClose();
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Theme Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.light_mode_rounded,
                      size: 18,
                      color: !isDarkMode ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isDarkMode,
                      inactiveThumbColor: colorScheme.surface,
                      inactiveTrackColor: colorScheme.surfaceContainerHighest,
                      onChanged: (value) {
                        final newTheme = value ? AppThemeType.dark : AppThemeType.light;
                        ref.read(themeProvider.notifier).setTheme(newTheme);
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.dark_mode_rounded,
                      size: 18,
                      color: isDarkMode ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  final RightPanelPageOptions option;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactDrawerTile({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                  option.icon,
                  size: 20,
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
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
          border: Border.all(
            color: foregroundColor.withValues(alpha: 0.1),
            width: 1,
          ),
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
                    style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: foregroundColor.withValues(alpha: 0.8), fontSize: 12),
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