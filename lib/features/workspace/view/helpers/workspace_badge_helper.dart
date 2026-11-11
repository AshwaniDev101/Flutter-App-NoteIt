import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/workspace_model.dart';

class WorkspaceBadgeHelper {
  static const List<Color> _palette = [
    Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828),
    Color(0xFFD81B60), Color(0xFFC2185B), Color(0xFFAD1457),
    Color(0xFF8E24AA), Color(0xFF7B1FA2), Color(0xFF6A1B9A),
    Color(0xFF5E35B1), Color(0xFF512DA8), Color(0xFF4527A0),
    Color(0xFF3949AB), Color(0xFF303F9F), Color(0xFF283593),
    Color(0xFF1E88E5), Color(0xFF1976D2), Color(0xFF1565C0),
    Color(0xFF0288D1), Color(0xFF0277BD),
    Color(0xFF00838F),
    Color(0xFF00796B), Color(0xFF00695C),
    Color(0xFF388E3C), Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFFF4511E), Color(0xFFE64A19),
    Color(0xFF6D4C41), Color(0xFF5D4037),
    Color(0xFF546E7A), Color(0xFF455A65),
  ];

  static int _generateHash(String text) {
    int hash = 5381;
    for (int i = 0; i < text.length; i++) {
      hash = ((hash << 5) + hash) + text.codeUnitAt(i);
    }
    return hash.abs();
  }

  static Color getColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF9E9E9E);

    final normalized = name.trim().toLowerCase();
    final index = (_generateHash(normalized) % _palette.length).abs();

    return _palette[index];
  }

  static String getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    return trimmed[0].toUpperCase();
  }

  static String? getEffectivePhotoUrl(User? authUser, {required bool isCloudMode}) {
    if (isCloudMode) {
      return authUser?.photoURL;
    }
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
