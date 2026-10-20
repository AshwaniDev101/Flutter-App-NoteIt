import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/sync/sync_engine.dart';
import '../../../../database/sync/sync_orchestrator.dart';
import '../../keybinding/keybindings_provider.dart';
import '../../lock/lock_manger/lock_manager.dart';
import '../../lock/password_prompt_helper.dart';
import '../../../shared/app_scaffold.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Listen to states
    final lockState = ref.watch(lockManagerProvider);
    final currentEngine = ref.watch(syncEngineProvider);

    // Watch shortcut preferences
    final shortcutPrefs = ref.watch(shortcutPreferencesProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.settings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================== SYNCHRONIZATION SECTION ====================
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Synchronization',
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sync_alt, color: Colors.blueAccent, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Sync Engine',
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Choose how your notes are backed up and shared.',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<SyncEngine>(
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
                            onSelectionChanged: (Set<SyncEngine> newSelection) {
                              final selectedMode = newSelection.first;

                              ref.read(syncEngineProvider.notifier).setEngine(selectedMode);

                              ref.read(syncOrchestratorProvider).triggerSync();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== GENERAL SECTION ====================
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'General & Security',
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Icons.notifications_outlined,
                          iconColor: Colors.teal,
                          title: 'Notifications',
                          subtitle: 'Manage alerts and sounds',
                          onTap: () {},
                        ),
                        Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        SettingsTile(
                          icon: Icons.lock_outline,
                          iconColor: Colors.amber,
                          title: 'Master password',
                          subtitle: lockState.hasMasterPassword
                              ? 'Update or remove master password'
                              : 'Set up master password',
                          onTap: () {
                            PasswordPromptHelper.showMasterPasswordManagement(context, ref);
                          },
                        ),
                        Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        SettingsSwitchTile(
                          icon: Icons.lock_open_rounded,
                          iconColor: Colors.amber.shade300,
                          title: 'Keep notes unlocked',
                          subtitle: 'Stay unlocked during session',
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Interface & Keyboard',
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        SettingsSwitchTile(
                          icon: Icons.keyboard_alt_outlined,
                          iconColor: Colors.white,
                          title: 'Dynamic key hints',
                          subtitle: 'Show key badges when holding Ctrl/Cmd',
                          value: shortcutPrefs.showDynamicKeyHints,
                          onChanged: (bool value) {
                            ref.read(shortcutPreferencesProvider.notifier).toggleHints(value);
                          },
                        ),
                        Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        SettingsSwitchTile(
                          icon: Icons.info_outline,
                          iconColor: Colors.white,
                          title: 'Shortcuts in tooltips',
                          subtitle: 'Append shortcuts to hover labels (e.g., Ctrl+N)',
                          value: shortcutPrefs.appendShortcutToTooltips,
                          onChanged: (bool value) {
                            ref.read(shortcutPreferencesProvider.notifier).toggleTooltips(value);
                          },
                        ),
                        Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        SettingsTile(
                          icon: Icons.tune_outlined,
                          iconColor: Colors.purpleAccent,
                          title: 'Default views & layout',
                          subtitle: 'Configure default page views, sort orders, and window size',
                          onTap: () {
                            ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.defaultSettings);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ======================== OTHEr =======================================
                  SettingsTile(
                    icon: Icons.download,
                    iconColor: Colors.pinkAccent,
                    title: 'Export Notes',
                    subtitle: 'Download notes to a folder',
                    onTap: () => ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.export),
                  ),

                  SettingsTile(
                    icon: Icons.upload,
                    iconColor: Colors.redAccent,
                    title: 'Import Notes',
                    subtitle: 'Upload notes from a folder',
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

// EXISTING WIDGET
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.outline),
      onTap: onTap,
    );
  }
}

// A tile with a Switch instead of an arrow
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
    );
  }
}
