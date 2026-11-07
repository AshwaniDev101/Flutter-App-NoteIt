// ==========================================
// SYNC MENU WIDGET (Based on ViewMenuButton Template)
// ==========================================
import 'package:flutter/material.dart';

import '../../../core/sync/sync_engine.dart';

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