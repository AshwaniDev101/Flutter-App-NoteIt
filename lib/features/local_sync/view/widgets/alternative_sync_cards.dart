import 'package:flutter/material.dart';

/// Reusable expandable cards displayed at the bottom of local sync screens to allow users
/// who entered local sync by mistake to switch to Cloud or Offline mode directly.
class AlternativeSyncCards extends StatefulWidget {
  final VoidCallback onSelectCloud;
  final VoidCallback onSelectOffline;

  const AlternativeSyncCards({
    super.key,
    required this.onSelectCloud,
    required this.onSelectOffline,
  });

  @override
  State<AlternativeSyncCards> createState() => _AlternativeSyncCardsState();
}

class _AlternativeSyncCardsState extends State<AlternativeSyncCards> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final headerColor = _isExpanded
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clickable Header to Expand/Collapse
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                          child: const Text('WANT A DIFFERENT SYNC OPTION?'),
                        ),
                        const SizedBox(width: 4),
                        TweenAnimationBuilder<Color?>(
                          duration: const Duration(milliseconds: 200),
                          tween: ColorTween(begin: headerColor, end: headerColor),
                          builder: (context, color, child) {
                            return AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: color,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
          ),
        ),

        // Animated Body Container
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOptionCard(
                        context: context,
                        title: 'Cloud Mode?',
                        subtitle: 'Sync notes seamlessly over the internet across all your devices',
                        icon: Icons.cloud_outlined,
                        accentColor: colorScheme.primary,
                        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.18),
                        borderColor: colorScheme.primary.withValues(alpha: 0.25),
                        onTap: widget.onSelectCloud,
                      ),
                      const SizedBox(height: 10),
                      _buildOptionCard(
                        context: context,
                        title: 'No Syncing?',
                        subtitle: 'Turn off sync and keep notes stored on this device only',
                        icon: Icons.signal_wifi_off_rounded,
                        accentColor: colorScheme.onSurfaceVariant,
                        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderColor: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        onTap: widget.onSelectOffline,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
