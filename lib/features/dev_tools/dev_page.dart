import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/helpers/platform_helper.dart';
import 'package:noteit/database/drift/local_database.dart';
import 'package:noteit/database/shared_preference/shared_preference_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'package:noteit/features/lock/lock_manger/lock_manager.dart';
import 'package:noteit/shared/overlays/app_scaffold.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';
import 'package:noteit/shared/widgets/app_switch.dart';

class DevPage extends ConsumerWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Placeholder states for toggles
    final isActionTwoEnabled = true;
    final isActionFiveEnabled = false;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.devTools,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================== HEADER ====================
                  Icon(Icons.settings_suggest_outlined, size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Developer Sandbox',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placeholder layout for future developer tools and actions.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),

                  // ==================== GROUP A ====================
                  _SectionHeader(title: 'Storage & Reset Actions', colorScheme: colorScheme, textTheme: textTheme),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        DevActionTile(
                          icon: Icons.password,
                          iconColor: Colors.red,
                          title: 'Wipes Password',
                          subtitle: 'Force Wipes the Master Password',
                          enabled: true, // This one remains active
                          onTap: () async {
                            await ref.read(lockManagerProvider.notifier).removeMasterPassword();
                            if (context.mounted) {
                              SnackBarManager.show(
                                msg: 'Master password and sessions completely wiped.',
                                type: SnackBarMessageType.acknowledgment,
                              );
                            }
                          },
                        ),
                        _buildDivider(colorScheme),
                        DevActionTile(
                          icon: Icons.cleaning_services_rounded,
                          iconColor: Colors.amber.shade700,
                          title: 'Clear SharedPreferences',
                          subtitle: 'Wipes all stored app preferences and settings',
                          enabled: true,
                          onTap: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Clear SharedPreferences?',
                              content: 'This will wipe all stored app settings and preferences. Continue?',
                              confirmLabel: 'Clear All',
                              confirmColor: Colors.amber.shade800,
                            );
                            if (confirmed && context.mounted) {
                              await ref.read(sharedPreferenceProvider).clearAll();
                              if (context.mounted) {
                                SnackBarManager.show(
                                  msg: 'SharedPreferences successfully wiped.',
                                  type: SnackBarMessageType.acknowledgment,
                                );
                              }
                            }
                          },
                        ),
                        _buildDivider(colorScheme),
                        DevActionTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: Colors.red.shade700,
                          title: 'Wipe Drift DB File',
                          subtitle: 'Physically deletes note_it_db.sqlite and recreates database',
                          enabled: true,
                          onTap: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Wipe Drift Database?',
                              content: 'This will physically delete the note_it_db.sqlite file. All local notes, folders, and keybindings will be lost. Continue?',
                              confirmLabel: 'Delete DB File',
                              confirmColor: Colors.red,
                            );
                            if (confirmed && context.mounted) {
                              final db = ref.read(localDatabaseProvider);
                              await db.close();
                              await deleteDatabaseFiles();
                              ref.invalidate(localDatabaseProvider);
                              if (context.mounted) {
                                SnackBarManager.show(
                                  msg: 'Drift database file physically deleted and recreated.',
                                  type: SnackBarMessageType.acknowledgment,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // ==================== GROUP B ====================
                  _SectionHeader(title: 'Group B', colorScheme: colorScheme, textTheme: textTheme),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        DevActionTile(
                          icon: Icons.looks_3_rounded,
                          iconColor: Colors.amber.shade600,
                          title: 'Action 3',
                          subtitle: 'Action 3 description placeholder',
                          enabled: false, // Disabled
                          onTap: () {},
                        ),
                        _buildDivider(colorScheme),
                        DevActionTile(
                          icon: Icons.looks_4_rounded,
                          iconColor: Colors.green,
                          title: 'Action 4',
                          subtitle: 'Action 4 description placeholder',
                          enabled: false, // Disabled
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // ==================== GROUP C ====================
                  _SectionHeader(title: 'Group C', colorScheme: colorScheme, textTheme: textTheme),
                  Card(
                    margin: const EdgeInsets.only(bottom: 48.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        DevActionSwitchTile(
                          icon: Icons.looks_5_rounded,
                          iconColor: Colors.blue,
                          title: 'Action 5',
                          subtitle: 'Action 5 description placeholder',
                          value: isActionFiveEnabled,
                          enabled: false, // Disabled
                          onChanged: (bool value) {},
                        ),
                        _buildDivider(colorScheme),
                        DevActionTile(
                          icon: Icons.looks_6_rounded,
                          iconColor: Colors.purple,
                          title: 'Action 6',
                          subtitle: 'Action 6 description placeholder',
                          enabled: false, // Disabled
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          content: Text(content, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor ?? theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SectionHeader({
    required this.title,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class DevActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const DevActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4, // Visually disables the entire tile
      child: ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled ? iconColor.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: enabled ? iconColor : theme.colorScheme.onSurfaceVariant, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.outline),
        onTap: enabled ? onTap : null, // Prevent taps if disabled
      ),
    );
  }
}

class DevActionSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const DevActionSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = PlatformHelper.isDesktopScreen;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4, // Visually disables the entire tile
      child: ListTile(
        dense: isDesktop,
        visualDensity: isDesktop ? VisualDensity.compact : VisualDensity.standard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled ? iconColor.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: enabled ? iconColor : theme.colorScheme.onSurfaceVariant, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        trailing: AppSwitch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
        onTap: (enabled && onChanged != null) ? () => onChanged!(!value) : null,
      ),
    );
  }
}