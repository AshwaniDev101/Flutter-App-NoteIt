import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/helpers/platform_helper.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../shared/settings_widgets.dart';

/// Settings page for configuring desktop application window size presets.
class DefaultSettingsPage extends ConsumerStatefulWidget {
  const DefaultSettingsPage({super.key});

  @override
  ConsumerState<DefaultSettingsPage> createState() => _DefaultSettingsPageState();
}

class _DefaultSettingsPageState extends ConsumerState<DefaultSettingsPage> {
  late double _defaultWindowWidth;
  late double _defaultWindowHeight;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  void _loadDefaults() async {
    final prefs = SharedPreferenceManager.instance;
    _defaultWindowWidth = prefs.windowWidth;
    _defaultWindowHeight = prefs.windowHeight;

    if (PlatformHelper.isNativeDesktop) {
      final size = await windowManager.getSize();
      if (mounted) {
        setState(() {
          _defaultWindowWidth = size.width;
          _defaultWindowHeight = size.height;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsPageLayout(
      option: RightPanelPageOptions.windowSizePresets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          // const SettingsPageHeader(
          //   title: 'Window Presets',
          //   subtitle: 'Quickly resize application window to standard size presets',
          // ),

          if (PlatformHelper.isNativeDesktop) ...[
            const SettingsSectionHeader(title: 'Preset Window Sizes'),
            SettingsCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Window Size Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Window Size',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_defaultWindowWidth.round()} x ${_defaultWindowHeight.round()} px',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Text(
                    'Window Size Presets',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildWindowSizePresetChip(
                        label: 'Fullscreen',
                        subtitle: 'Screen Max',
                        icon: Icons.fullscreen_rounded,
                        onSelected: () async {
                          final screenSize = MediaQuery.of(context).size;
                          final width = screenSize.width > 0 ? screenSize.width : 1920.0;
                          final height = screenSize.height > 0 ? screenSize.height : 1080.0;
                          await _applyWindowSizePreset(
                            width,
                            height,
                            'Fullscreen',
                            isFullscreen: true,
                          );
                        },
                      ),
                      _buildWindowSizePresetChip(
                        label: 'Large Size',
                        subtitle: '1600 x 1000',
                        icon: Icons.desktop_windows_outlined,
                        onSelected: () {
                          _applyWindowSizePreset(1600, 1000, 'Large Size (1600x1000)');
                        },
                      ),
                      _buildWindowSizePresetChip(
                        label: 'Medium Size',
                        subtitle: '1400 x 900',
                        icon: Icons.laptop_outlined,
                        onSelected: () {
                          _applyWindowSizePreset(1400, 900, 'Medium Size (1400x900)');
                        },
                      ),
                      _buildWindowSizePresetChip(
                        label: 'Compact Size',
                        subtitle: '1024 x 700',
                        icon: Icons.tablet,
                        onSelected: () {
                          _applyWindowSizePreset(1024, 700, 'Compact Size (1024x700)');
                        },
                      ),
                      _buildWindowSizePresetChip(
                        label: 'Mobile Size',
                        subtitle: '420 x 800',
                        icon: Icons.smartphone_rounded,
                        onSelected: () {
                          _applyWindowSizePreset(420, 800, 'Mobile Size (420x800)');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SettingsCard(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Window size presets are only available on desktop platforms.'),
              ),
            ),
          ],
          SettingsResetCard(
            title: 'Reset Window Size Presets',
            subtitle:
                'Restores application window to default dimensions (1400 x 900)',
            onTap: () {
              _applyWindowSizePreset(1400, 900, 'Default Size (1400x900)');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _applyWindowSizePreset(
    double width,
    double height,
    String label, {
    bool isFullscreen = false,
  }) async {
    setState(() {
      _defaultWindowWidth = width;
      _defaultWindowHeight = height;
    });
    await SharedPreferenceManager.instance.setWindowWidth(width);
    await SharedPreferenceManager.instance.setWindowHeight(height);
    await SharedPreferenceManager.instance.setWindowMaximized(isFullscreen);

    if (PlatformHelper.isNativeDesktop) {
      if (isFullscreen) {
        if (!await windowManager.isMaximized()) {
          await windowManager.maximize();
        }
      } else {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        await windowManager.setSize(Size(width, height));
        await windowManager.center();
      }
    }

    if (mounted) {
      SnackBarManager.show(msg: 'Window resized to $label');
    }
  }

  Widget _buildWindowSizePresetChip({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: onSelected,
    );
  }
}
