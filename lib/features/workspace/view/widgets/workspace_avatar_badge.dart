import 'package:flutter/material.dart';

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
            color: WorkspaceBadgeHelper.getColor(widget.activeWorkspaceName),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 32,
              width: 32,
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
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
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
                            ? Colors.white.withValues(alpha: 0.25)
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
