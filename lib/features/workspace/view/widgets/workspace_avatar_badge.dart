import 'package:flutter/material.dart';
import 'package:noteit/core/helpers/platform_helper.dart';

import '../helpers/workspace_badge_helper.dart';

class WorkspaceAvatarBadge extends StatefulWidget {
  final String activeWorkspaceName;
  final String? photoUrl;
  final VoidCallback onTap;

  const WorkspaceAvatarBadge({
    super.key,
    required this.activeWorkspaceName,
    this.photoUrl,
    required this.onTap,
  });

  @override
  State<WorkspaceAvatarBadge> createState() => _WorkspaceAvatarBadgeState();
}

class _WorkspaceAvatarBadgeState extends State<WorkspaceAvatarBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;
    final badgeColor = WorkspaceBadgeHelper.getColor(context, widget.activeWorkspaceName);
    final textColor = badgeColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    double badgeSize = 32;

    if (PlatformHelper.isWideLayout(context)) {
      badgeSize = 26;
    }
    return Tooltip(
      message: 'Workspaces',
      child: InkWell(
        customBorder: const CircleBorder(),
        onHover: (hovered) {
          if (_isHovered != hovered) {
            setState(() => _isHovered = hovered);
          }
        },
        onTap: widget.onTap,
        onSecondaryTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: badgeColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: badgeSize,
              width: badgeSize,
              child: Stack(
                children: [
                  if (hasPhoto)
                    Positioned.fill(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              WorkspaceBadgeHelper.getInitial(widget.activeWorkspaceName),
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        WorkspaceBadgeHelper.getInitial(widget.activeWorkspaceName),
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isHovered
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
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
}
