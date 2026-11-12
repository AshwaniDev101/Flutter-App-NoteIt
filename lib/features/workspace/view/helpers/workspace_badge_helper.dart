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
        padding: EdgeInsets.all(size * 0.18),
        child: CustomPaint(
          size: Size(size, size),
          painter: const _GoogleGLogoPainter(),
        ),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final outerRadius = w / 2;
    final innerRadius = w * 0.28;

    final rect = Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2);
    final strokeWidth = outerRadius - innerRadius;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.356, 1.484, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.18, 1.0, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.2, 1.98, false, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.87, 1.07, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.38, w * 0.95, h * 0.62),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
