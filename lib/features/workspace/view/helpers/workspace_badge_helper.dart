import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteit/core/theme/workspace_theme_colors.dart';

import '../../models/workspace_model.dart';

class WorkspaceBadgeHelper {
  static Color getColor(BuildContext context, String name) {
    if (name.trim().isEmpty) return Theme.of(context).colorScheme.surfaceContainerHighest;
    return WorkspaceThemeColors.of(context, name);
  }

  static String getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    return trimmed[0].toUpperCase();
  }

  static String? getEffectivePhotoUrl(User? authUser, {required bool isCloudMode}) {
    return null;
  }

  static String getEffectiveDisplayName(Workspace workspace, User? authUser) {
    return workspace.name;
  }
}

class GoogleLogoBadge extends StatelessWidget {
  final double size;

  const GoogleLogoBadge({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Image.asset(
          'assets/icons/google_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
