// new settings page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/sync/sync_engine.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../keybinding/keybindings_provider.dart';
import '../../lock/lock_manger/lock_manager.dart';
import '../../lock/password_prompt_helper.dart';
import '../../../shared/overlays/app_scaffold.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to states
    final lockState = ref.watch(lockManagerProvider);
    final currentEngine = ref.watch(syncEngineProvider);

    // Watch shortcut preferences
    final shortcutPrefs = ref.watch(shortcutPreferencesProvider);
    final bool showShortcuts = shortcutPrefs.showDynamicKeyHints || shortcutPrefs.appendShortcutToTooltips;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.settings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================== SYNCHRONIZATION SECTION ====================
                  const _SectionHeader(title: 'Synchronization'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: SegmentedButton<SyncEngine>(
                      segments: const [
                        ButtonSegment<SyncEngine>(
                          value: SyncEngine.cloud,
                          label: Text('Cloud'),
                          icon: Icon(Icons.cloud_outlined),
                        ),
                        ButtonSegment<SyncEngine>(
                          value: SyncEngine.local,
                          label: Text('Offline Sync'),
                          icon: Icon(Icons.wifi),
                        ),
                        ButtonSegment<SyncEngine>(
                          value: SyncEngine.offline,
                          label: Text('No Sync'),
                          icon: Icon(Icons.signal_wifi_off),
                        ),
                      ],
                      selected: {currentEngine},
                      onSelectionChanged: (Set<SyncEngine> newSelection) async {
                        final selectedMode = newSelection.first;

                        final bool success = await ref
                            .read(syncEngineProvider.notifier)
                            .requestEngineChange(selectedMode);

                        if (success) {
                          ref.read(syncOrchestratorProvider).triggerSync();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== GENERAL & SECURITY SECTION ====================
                  const _SectionHeader(title: 'General & Security'),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Reminders & Alarms',
                    onTap: () {
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.reminderSettings);
                    },
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsRow(
                    icon: Icons.lock_outline,
                    title: 'Master password',
                    subtitle: lockState.hasMasterPassword
                        ? 'Update or remove master password'
                        : 'Set up master password',
                    onTap: () {
                      PasswordPromptHelper.showMasterPasswordManagement(context, ref);
                    },
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsSwitchRow(
                    icon: Icons.lock_open_rounded,
                    title: 'Keep notes unlocked during session',
                    value: lockState.keepUnlockedDuringSession,
                    onChanged: (bool value) {
                      ref.read(lockManagerProvider.notifier).setKeepUnlockedPreference(value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // ==================== INTERFACE & KEYBOARD SECTION ====================
                  const _SectionHeader(title: 'Interface & Keyboard'),
                  const SizedBox(height: 8),
                  _SettingsSwitchRow(
                    icon: Icons.keyboard_alt_outlined,
                    title: 'Show keyboard shortcuts',
                    value: showShortcuts,
                    onChanged: (bool value) {
                      ref.read(shortcutPreferencesProvider.notifier).toggleHints(value);
                      ref.read(shortcutPreferencesProvider.notifier).toggleTooltips(value);
                    },
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsRow(
                    icon: Icons.tune_outlined,
                    title: 'Default views & layout',
                    onTap: () {
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.defaultSettings);
                    },
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsRow(
                    icon: Icons.access_time_rounded,
                    title: 'Time & Date',
                    onTap: () {
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.timeSettings);
                    },
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsRow(
                    icon: Icons.edit_note_rounded,
                    title: 'Note Editor Preferences',
                    subtitle: 'Font size, line spacing, cursor position, and bottom spacing',
                    onTap: () {
                      ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.noteEditorSettings);
                    },
                  ),

                  const SizedBox(height: 24),

                  // ==================== DATA MANAGEMENT SECTION ====================
                  const _SectionHeader(title: 'Data Management'),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    icon: Icons.download_outlined,
                    title: 'Export Notes',
                    onTap: () => ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.export),
                  ),
                  Divider(height: 1, indent: 36, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SettingsRow(
                    icon: Icons.upload_outlined,
                    title: 'Import Notes',
                    onTap: () => ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.import),
                  ),
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      secondary: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
    );
  }
}
