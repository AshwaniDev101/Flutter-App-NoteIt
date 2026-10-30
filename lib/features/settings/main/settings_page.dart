import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/sync/sync_engine.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../keybinding/keybindings_provider.dart';
import '../../lock/lock_manger/lock_manager.dart';
import '../../lock/password_prompt_helper.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../common/settings_widgets.dart';

/// Main Settings Page hub providing top-level configuration sections for
/// Synchronization, General Security, Interface & Keyboard, and Data Management.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final nav = ref.read(drawerNavigationProvider);

    // Watch states
    final lockState = ref.watch(lockManagerProvider);
    final currentEngine = ref.watch(syncEngineProvider);

    // Watch shortcut preferences
    final shortcutPrefs = ref.watch(shortcutPreferencesProvider);
    final bool showShortcuts =
        shortcutPrefs.showDynamicKeyHints || shortcutPrefs.appendShortcutToTooltips;

    return SettingsPageLayout(
      option: RightPanelPageOptions.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================== SYNCHRONIZATION SECTION ====================
          const SettingsSectionHeader(title: 'Synchronization'),
          SettingsCard(
            padding: const EdgeInsets.all(12.0),
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
          const SettingsSectionHeader(title: 'General & Security'),
          SettingsCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Reminders & Alarms',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.reminderSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Master Password',
                  subtitle: lockState.hasMasterPassword
                      ? 'Update or remove master password'
                      : 'Set up master password',
                  onTap: () {
                    PasswordPromptHelper.showMasterPasswordManagement(context, ref);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsSwitchTile(
                  icon: Icons.lock_open_rounded,
                  title: 'Keep notes unlocked during session',
                  value: lockState.keepUnlockedDuringSession,
                  onChanged: (bool value) {
                    ref.read(lockManagerProvider.notifier).setKeepUnlockedPreference(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== INTERFACE & KEYBOARD SECTION ====================
          const SettingsSectionHeader(title: 'Interface & Keyboard'),
          SettingsCard(
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Show keyboard shortcuts',
                  value: showShortcuts,
                  onChanged: (bool value) {
                    ref.read(shortcutPreferencesProvider.notifier).toggleHints(value);
                    ref.read(shortcutPreferencesProvider.notifier).toggleTooltips(value);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.tune_outlined,
                  title: 'Default Views & Layout',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.defaultSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.access_time_rounded,
                  title: 'Time & Date',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.timeSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.edit_note_rounded,
                  title: 'Note Editor Preferences',
                  subtitle: 'Font size, line spacing, and cursor position',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.noteEditorSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.keyboard_rounded,
                  title: 'Keyboard Shortcuts',
                  subtitle: 'Customize keyboard shortcuts and keybinding chord rules',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.keybindingSettings);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== DATA MANAGEMENT SECTION ====================
          const SettingsSectionHeader(title: 'Data Management'),
          SettingsCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export Notes',
                  onTap: () => nav.navigate(context, RightPanelPageOptions.export),
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Import Notes',
                  onTap: () => nav.navigate(context, RightPanelPageOptions.import),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
