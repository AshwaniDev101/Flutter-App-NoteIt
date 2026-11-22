import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/sync/sync_engine.dart';
import 'package:noteit/core/sync/sync_orchestrator.dart';
import '../keybinding/keybindings_provider.dart';
import '../lock/lock_manger/lock_manager.dart';
import '../lock/password_prompt_helper.dart';
import '../home/core/providers.dart';
import '../home/view/desktop/content_panel/core/navigator.dart';
import '../workspace/providers/workspace_providers.dart';
import 'shared/settings_widgets.dart';

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
    final syncMode = ref.watch(syncModeProvider);
    final currentEngine = syncMode.isCloud
        ? SyncEngine.cloud
        : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

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
            child: Column(
              children: [
                for (int i = 0; i < SyncEngine.values.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  Builder(
                    builder: (context) {
                      final engine = SyncEngine.values[i];
                      final isSelected = currentEngine == engine;
                      return SettingsSelectionTile(
                        icon: engine.icon,
                        title: engine.label,
                        subtitle: engine.description,
                        isSelected: isSelected,
                        onTap: () async {
                          if (isSelected) return;
                          SyncMode targetMode;
                          switch (engine) {
                            case SyncEngine.cloud:
                              targetMode = SyncMode.cloud;
                              break;
                            case SyncEngine.local:
                              targetMode = syncMode.isLocal ? syncMode : SyncMode.localUndefined;
                              break;
                            case SyncEngine.offline:
                              targetMode = SyncMode.offline;
                              break;
                          }
                          final bool success = await ref
                              .read(syncModeProvider.notifier)
                              .requestModeChange(targetMode);

                          if (success) {
                            ref.read(syncOrchestratorProvider).triggerSync();
                          }
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== KEYBOARD & SHORTCUTS SECTION ====================
          const SettingsSectionHeader(title: 'Keyboard & Shortcuts'),
          SettingsCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.keyboard_rounded,
                  title: 'Keyboard Shortcuts',
                  subtitle: 'Customize keyboard shortcuts and keybinding chord rules',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.keybindingSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsSwitchTile(
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Show keyboard shortcuts',
                  subtitle: 'Display keyboard hints and tooltips in the UI',
                  value: showShortcuts,
                  onChanged: (bool value) {
                    ref.read(shortcutPreferencesProvider.notifier).toggleHints(value);
                    ref.read(shortcutPreferencesProvider.notifier).toggleTooltips(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== EDITOR & INTERFACE SECTION ====================
          const SettingsSectionHeader(title: 'Editor & Interface'),
          SettingsCard(
            child: Column(
              children: [
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
                  icon: Icons.tune_outlined,
                  title: 'Default Views & Layout',
                  subtitle: 'Default layout, view mode, and sorting options',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.defaultSettings);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsSwitchTile(
                  icon: Icons.workspaces_outlined,
                  title: 'Enable workspace',
                  subtitle: 'Show workspace switcher badge on the homepage',
                  value: ref.watch(workspaceEnableProvider),
                  onChanged: (bool value) {
                    ref.read(workspaceEnableProvider.notifier).setWorkspaceEnable(value);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SettingsSwitchTile(
                  icon: Icons.devices_outlined,
                  title: 'Enable device filter',
                  subtitle: 'Show device filter button on the control bar',
                  value: ref.watch(showDeviceFilterProvider),
                  onChanged: (bool value) {
                    ref.read(showDeviceFilterProvider.notifier).setShowDeviceFilter(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== GENERAL SECTION ====================
          const SettingsSectionHeader(title: 'General'),
          SettingsCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Reminders & Alarms',
                  subtitle: 'Manage reminder notifications and sound alerts',
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
                  icon: Icons.access_time_rounded,
                  title: 'Time & Date',
                  subtitle: 'Configure date format and time display settings',
                  onTap: () {
                    nav.navigate(context, RightPanelPageOptions.timeSettings);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== SECURITY SECTION ====================
          const SettingsSectionHeader(title: 'Security'),
          SettingsCard(
            child: Column(
              children: [
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
                  title: 'Keep notes unlocked',
                  subtitle: 'Avoid password prompt for locked notes within active session',
                  value: lockState.keepUnlockedDuringSession,
                  onChanged: (bool value) {
                    ref.read(lockManagerProvider.notifier).setKeepUnlockedPreference(value);
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
                  subtitle: 'Backup notes and export data to file',
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
                  subtitle: 'Restore notes or import from backup files',
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
