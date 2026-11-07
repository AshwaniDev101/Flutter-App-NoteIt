import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

import '../../core/config/app_env.dart';

class SharedDrawerContent extends ConsumerStatefulWidget {
  final RightPanelPageOptions? selectedOption;
  final void Function(RightPanelPageOptions) onOptionSelected;
  final VoidCallback onClose;

  const SharedDrawerContent({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onClose,
  });

  @override
  ConsumerState<SharedDrawerContent> createState() => _SharedDrawerContentState();
}

class _SharedDrawerContentState extends ConsumerState<SharedDrawerContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- App Branding Header ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/icons/note_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 20,
                  ),
                  children: [
                    TextSpan(
                      text: 'Note',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: 'It',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- 2. Scrollable Navigation ---
        Flexible(
          fit: FlexFit.loose,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'WORKSPACE'),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.trash,
                      isSelected: widget.selectedOption == RightPanelPageOptions.trash,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.trash),
                    ),
                    const SizedBox(height: 16),

                    const _SectionHeader(title: 'SYSTEM'),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.localSync,
                      isSelected: widget.selectedOption == RightPanelPageOptions.localSync,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.localSync),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.themes,
                      isSelected: widget.selectedOption == RightPanelPageOptions.themes,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.themes),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.settings,
                      isSelected: widget.selectedOption == RightPanelPageOptions.settings,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.settings),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.devTools,
                      isSelected: widget.selectedOption == RightPanelPageOptions.devTools,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.devTools),
                    ),
                    _CompactDrawerTile(
                      option: RightPanelPageOptions.archivePage,
                      isSelected: widget.selectedOption == RightPanelPageOptions.archivePage,
                      onTap: () => widget.onOptionSelected(RightPanelPageOptions.archivePage),
                    ),

                    const SizedBox(height: 24),

                    // Version Info
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            "Version: ${AppEnv.version}",
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            "Build: ${AppEnv.buildNumber}",
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  final RightPanelPageOptions option;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactDrawerTile({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                  option.icon,
                  size: 20,
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}