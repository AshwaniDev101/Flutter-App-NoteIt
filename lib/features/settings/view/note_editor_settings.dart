import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/overlays/app_scaffold.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../../home/view/desktop/content_panel/core/navigator.dart';
import '../providers/note_editor_settings_provider.dart';

class NoteEditorSettingsPage extends ConsumerStatefulWidget {
  const NoteEditorSettingsPage({super.key});

  @override
  ConsumerState<NoteEditorSettingsPage> createState() => _NoteEditorSettingsPageState();
}

class _NoteEditorSettingsPageState extends ConsumerState<NoteEditorSettingsPage> {
  double? _localTitleFontSize;
  double? _localContentFontSize;
  double? _localLineSpacing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(noteEditorSettingsProvider);
    final notifier = ref.read(noteEditorSettingsProvider.notifier);

    final currentTitleFontSize = _localTitleFontSize ?? settings.titleFontSize;
    final currentContentFontSize = _localContentFontSize ?? settings.contentFontSize;
    final currentLineSpacing = _localLineSpacing ?? settings.lineSpacing;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.noteEditorSettings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          ref.read(drawerNavigationProvider).navigate(context, RightPanelPageOptions.settings);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Note Editor Settings',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // LIVE PREVIEW CARD
                  _buildSectionHeader('Live Preview', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Sample Note View',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (settings.putCursorOnContent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Cursor on Content',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            style: (textTheme.titleLarge ?? const TextStyle()).copyWith(
                              fontSize: currentTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            child: const Text('Sample Note Title'),
                          ),
                          const SizedBox(height: 8),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                              fontSize: currentContentFontSize,
                              height: currentLineSpacing,
                              color: colorScheme.onSurface,
                            ),
                            child: const Text(
                              'This is a live preview of your editor content text. Adjusting the typography settings below will smoothly update text sizes, line spacing, and cursor focus behavior in real time.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FOCUS & CURSOR BEHAVIOR
                  _buildSectionHeader('Cursor & Focus', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      secondary: Icon(Icons.touch_app_outlined, color: colorScheme.primary),
                      title: const Text('Put cursor on content', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Automatically focus the body/content text field when opening or creating a note'),
                      value: settings.putCursorOnContent,
                      onChanged: (val) => notifier.setPutCursorOnContent(val),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TEXT STYLING SECTION
                  _buildSectionHeader('Typography & Text Styling', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Title Font Size
                          _buildSliderTile(
                            context: context,
                            title: 'Title Font Size',
                            valueText: '${currentTitleFontSize.round()} px',
                            value: currentTitleFontSize,
                            min: 16.0,
                            max: 36.0,
                            divisions: 20,
                            icon: Icons.title_rounded,
                            onChanged: (val) {
                              setState(() => _localTitleFontSize = val);
                            },
                            onChangeEnd: (val) {
                              notifier.setTitleFontSize(val);
                              setState(() => _localTitleFontSize = null);
                            },
                          ),

                          const Divider(height: 24),

                          // Content Font Size
                          _buildSliderTile(
                            context: context,
                            title: 'Content Font Size',
                            valueText: '${currentContentFontSize.round()} px',
                            value: currentContentFontSize,
                            min: 12.0,
                            max: 32.0,
                            divisions: 20,
                            icon: Icons.format_size_rounded,
                            onChanged: (val) {
                              setState(() => _localContentFontSize = val);
                            },
                            onChangeEnd: (val) {
                              notifier.setContentFontSize(val);
                              setState(() => _localContentFontSize = null);
                            },
                          ),

                          const Divider(height: 24),

                          // Line Spacing
                          _buildSliderTile(
                            context: context,
                            title: 'Line Spacing',
                            valueText: '${currentLineSpacing.toStringAsFixed(1)}x',
                            value: currentLineSpacing,
                            min: 1.0,
                            max: 2.5,
                            divisions: 15,
                            icon: Icons.format_line_spacing_rounded,
                            onChanged: (val) {
                              setState(() => _localLineSpacing = val);
                            },
                            onChangeEnd: (val) {
                              notifier.setLineSpacing(val);
                              setState(() => _localLineSpacing = null);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // RESET SECTION
                  _buildSectionHeader('Reset Settings', colorScheme, textTheme),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                      title: const Text('Reset Editor Settings to Defaults'),
                      subtitle: const Text('Restores default font sizes, line spacing, and cursor focus preference'),
                      onTap: () async {
                        setState(() {
                          _localTitleFontSize = null;
                          _localContentFontSize = null;
                          _localLineSpacing = null;
                        });
                        await notifier.resetToDefaults();
                        if (context.mounted) {
                          SnackBarManager.show(msg: 'Note editor settings reset to defaults');
                        }
                      },
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

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(valueText, style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
