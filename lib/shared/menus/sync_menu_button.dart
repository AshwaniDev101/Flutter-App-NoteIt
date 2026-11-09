// ==========================================
// SYNC MENU WIDGET (Based on ViewMenuButton Template)
// ==========================================
import 'package:flutter/material.dart';

import '../../core/sync/sync_engine.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select Sync Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._syncOptions.map((engine) {
                final isSelected = widget.currentEngine == engine;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getIcon(engine),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _getLabel(engine),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    widget.onEngineSelected(engine);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            MenuAnchor(
              controller: _menuController,
              alignmentOffset: const Offset(0, 4),
              menuChildren: _syncOptions.map((engine) {
                final isSelected = widget.currentEngine == engine;
                return MenuItemButton(
                  leadingIcon: Icon(
                    _getIcon(engine),
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  child: Text(
                    _getLabel(engine),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  onPressed: () {
                    _menuController.close();
                    widget.onEngineSelected(engine);
                  },
                );
              }).toList(),
              builder: (context, controller, child) {
                return _buildButtonContent(context, isDesktop: true);
              },
            )
          else
            InkWell(
              onTap: () => _showMobileBottomSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: _buildButtonContent(context, isDesktop: false),
            ),
        ],
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context, {required bool isDesktop}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(widget.currentEngine),
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Method',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _getLabel(widget.currentEngine),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            Icons.arrow_drop_down,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
