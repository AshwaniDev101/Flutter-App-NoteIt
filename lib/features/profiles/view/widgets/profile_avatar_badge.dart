import 'package:flutter/material.dart';

import '../helpers/profile_badge_helper.dart';

class ProfileAvatarBadge extends StatefulWidget {
  final String activeProfileName;
  final String? photoUrl;
  final VoidCallback onTap;

  const ProfileAvatarBadge({
    super.key,
    required this.activeProfileName,
    this.photoUrl,
    required this.onTap,
  });

  @override
  State<ProfileAvatarBadge> createState() => _ProfileAvatarBadgeState();
}

class _ProfileAvatarBadgeState extends State<ProfileAvatarBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return Tooltip(
      message: 'Profiles',
      child: Material(
        color: ProfileBadgeHelper.getColor(widget.activeProfileName),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onHover: (hovered) {
            if (_isHovered != hovered) {
              setState(() => _isHovered = hovered);
            }
          },
          onTap: widget.onTap,
          onSecondaryTap: widget.onTap,
          child: SizedBox(
            height: 24,
            width: 24,
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
                            ProfileBadgeHelper.getInitial(widget.activeProfileName),
                            style: const TextStyle(
                              fontSize: 10,
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
                      ProfileBadgeHelper.getInitial(widget.activeProfileName),
                      style: const TextStyle(
                        fontSize: 10,
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
                          ? Colors.transparent
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
