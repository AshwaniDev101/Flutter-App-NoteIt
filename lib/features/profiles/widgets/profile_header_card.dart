import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_orchestrator.dart';
import '../active_profile_provider.dart';
import '../helpers/profile_badge_helper.dart';
import '../profile_model.dart';
import '../profile_providers.dart';
import 'create_profile_dialog.dart';

/// Full-width profile switcher header card rendered at the top of the app drawer.
class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final syncMode = ref.watch(syncModeProvider);
    final currentEngine = syncMode.isCloud
        ? SyncEngine.cloud
        : (syncMode.isLocal ? SyncEngine.local : SyncEngine.offline);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Selector
          PopupMenuButton<String>(
            tooltip: 'Switch or manage profiles',
            offset: const Offset(0, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            onSelected: (value) => _handleMenuSelection(value, context, ref, profiles),
            itemBuilder: (ctx) => _buildMenuItems(profiles, activeProfile, theme, colorScheme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ProfileBadgeHelper.getColor(activeProfile.name),
                    child: Text(
                      ProfileBadgeHelper.getInitial(activeProfile.name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeProfile.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),

          // 2. Sync Menu Option
          SyncMenuButton(
            currentEngine: currentEngine,
            onEngineSelected: (engine) => _handleSyncChange(engine, ref, syncMode),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuSelection(String value, BuildContext context, WidgetRef ref, List<Profile> profiles) async {
    if (value == 'create_profile') {
      showDialog(context: context, builder: (ctx) => const CreateProfileDialog());
    } else {
      final selected = profiles.firstWhere((p) => p.id == value);
      await ref.read(activeProfileProvider.notifier).switchProfile(selected);
    }
  }

  Future<void> _handleSyncChange(SyncEngine selectedEngine, WidgetRef ref, SyncMode currentMode) async {
    SyncMode targetMode;
    switch (selectedEngine) {
      case SyncEngine.cloud:
        targetMode = SyncMode.cloud;
        break;
      case SyncEngine.local:
        targetMode = currentMode.isLocal ? currentMode : SyncMode.localUndefined;
        break;
      case SyncEngine.offline:
        targetMode = SyncMode.offline;
        break;
    }

    final success = await ref.read(syncModeProvider.notifier).requestModeChange(targetMode);
    if (success) {
      ref.read(syncOrchestratorProvider).triggerSync();
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(List<Profile> profiles, Profile activeProfile, ThemeData theme, ColorScheme colorScheme) {
    return [
      ...profiles.map((profile) {
        final isSelected = profile.id == activeProfile.id;
        return PopupMenuItem<String>(
          value: profile.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: ProfileBadgeHelper.getColor(profile.name),
                child: Text(
                  ProfileBadgeHelper.getInitial(profile.name),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
            ],
          ),
        );
      }),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'create_profile',
        child: Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text('Create New Profile', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ];
  }
}

// ==========================================
// SYNC MENU WIDGET (Based on ViewMenuButton Template)
// ==========================================
class SyncMenuButton extends StatefulWidget {
  final SyncEngine currentEngine;
  final ValueChanged<SyncEngine> onEngineSelected;

  const SyncMenuButton({
    super.key,
    required this.currentEngine,
    required this.onEngineSelected,
  });

  @override
  State<SyncMenuButton> createState() => _SyncMenuButtonState();
}

class _SyncMenuButtonState extends State<SyncMenuButton> {
  final MenuController _menuController = MenuController();

  static const _syncOptions = [
    SyncEngine.cloud,
    SyncEngine.local,
    SyncEngine.offline,
  ];

  String _getLabel(SyncEngine engine) {
    switch (engine) {
      case SyncEngine.cloud: return 'Cloud';
      case SyncEngine.local: return 'Local Network';
      case SyncEngine.offline: return 'Offline';
    }
  }

  IconData _getIcon(SyncEngine engine) {
    switch (engine) {
      case SyncEngine.cloud: return Icons.cloud_outlined;
      case SyncEngine.local: return Icons.wifi;
      case SyncEngine.offline: return Icons.signal_wifi_off;
    }
  }

  void _showMobileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Text(
                'Sync Layout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16, height: 1),
            _buildSectionHeader(context, 'SYNC SETTINGS'),
            ..._syncOptions.map(
                  (engine) => _buildViewTile(context, engine, onTap: () {
                Navigator.pop(context);
              }),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Checking for mobile/desktop layout. (You can replace this with PlatformHelper.isWideLayout(context) if imported)
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final triggerWidget = InkWell(
      onTap: () {
        if (isMobile) {
          _showMobileBottomSheet(context);
        } else {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
        }
      },
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Text(
              'Sync Mode',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _getLabel(widget.currentEngine),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );

    if (isMobile) {
      return triggerWidget;
    }

    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return triggerWidget;
      },
      menuChildren: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 2,
          margin: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'SYNC MODE'),
                  ..._syncOptions.map((engine) {
                    return _buildViewTile(context, engine, onTap: () {
                      _menuController.close();
                    });
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildViewTile(BuildContext context, SyncEngine engine, {required VoidCallback onTap}) {
    final isSelected = engine == widget.currentEngine;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        _getIcon(engine),
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        _getLabel(engine),
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary, size: 20) : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () {
        widget.onEngineSelected(engine);
        onTap();
      },
    );
  }
}