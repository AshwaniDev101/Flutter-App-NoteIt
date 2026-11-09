import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/profile_model.dart';

class ProfileBadgeHelper {
  // Exactly 30 high-contrast Material Design colors (600-800 shades).
  // These specific shades guarantee pure white (#FFFFFF) text is always readable.
  static const List<Color> _palette = [
    Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828), // Reds
    Color(0xFFD81B60), Color(0xFFC2185B), Color(0xFFAD1457), // Pinks
    Color(0xFF8E24AA), Color(0xFF7B1FA2), Color(0xFF6A1B9A), // Purples
    Color(0xFF5E35B1), Color(0xFF512DA8), Color(0xFF4527A0), // Deep Purples
    Color(0xFF3949AB), Color(0xFF303F9F), Color(0xFF283593), // Indigos
    Color(0xFF1E88E5), Color(0xFF1976D2), Color(0xFF1565C0), // Blues
    Color(0xFF0288D1), Color(0xFF0277BD),                    // Light Blues
    Color(0xFF00838F),                                       // Cyan
    Color(0xFF00796B), Color(0xFF00695C),                    // Teals
    Color(0xFF388E3C), Color(0xFF2E7D32),                    // Greens
    Color(0xFFEF6C00),                                       // Orange
    Color(0xFFF4511E), Color(0xFFE64A19),                    // Deep Oranges
    Color(0xFF6D4C41), Color(0xFF5D4037),                    // Browns
    Color(0xFF546E7A), Color(0xFF455A65),                    // Blue Greys
  ];

  /// Uses the DJB2 algorithm for a completely deterministic integer.
  /// Guarantees the same name yields the same color across Android, Web, and Windows.
  static int _generateHash(String text) {
    int hash = 5381;
    for (int i = 0; i < text.length; i++) {
      hash = ((hash << 5) + hash) + text.codeUnitAt(i);
    }
    return hash.abs();
  }

  /// Returns the deterministic background color from the 30-color palette.
  static Color getColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF9E9E9E); // Fallback Grey

    // Lowercase ensures 'Ashwin' and 'ashwin' resolve to the exact same hash
    final normalized = name.trim().toLowerCase();
    final index = (_generateHash(normalized) % _palette.length).abs();

    return _palette[index];
  }

  /// Extracts the initial character for the avatar text.
  static String getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";

    // Handles multi-word names (e.g. returning 'A' for "Ashwani Yadav")
    return trimmed[0].toUpperCase();
  }

  /// Checks whether [authUser] matches [profile]'s linked Google account.
  static bool isAuthForProfile(Profile profile, User? authUser, {bool isCloud = true}) {
    return profile.syncMode == 'cloud' &&
        authUser != null &&
        profile.linkedEmail != null &&
        profile.linkedEmail!.isNotEmpty &&
        authUser.email?.toLowerCase() == profile.linkedEmail?.toLowerCase();
  }

  /// Resolves the effective photo URL for a profile.
  /// If [profile.syncMode] == 'cloud', returns [authUser.photoURL] (if matching) or cached [profile.photoUrl].
  static String? getEffectivePhotoUrl(Profile profile, User? authUser, {bool isCloud = true}) {
    if (profile.syncMode == 'cloud') {
      final isAuth = authUser != null &&
          authUser.email != null &&
          authUser.email!.isNotEmpty &&
          profile.linkedEmail != null &&
          authUser.email!.toLowerCase() == profile.linkedEmail!.toLowerCase();

      return (isAuth && (authUser.photoURL?.isNotEmpty ?? false) ? authUser.photoURL : null) ??
          profile.photoUrl;
    }
    return null;
  }

  /// Resolves the effective display name for a profile.
  static String getEffectiveDisplayName(Profile profile, User? authUser, {bool isCloud = true}) {
    if (profile.syncMode == 'cloud') {
      final isAuth = authUser != null &&
          authUser.email != null &&
          authUser.email!.isNotEmpty &&
          profile.linkedEmail != null &&
          authUser.email!.toLowerCase() == profile.linkedEmail!.toLowerCase();

      if (isAuth && (authUser.displayName?.isNotEmpty ?? false)) {
        return authUser.displayName!;
      }
      if (profile.displayName?.isNotEmpty ?? false) {
        return profile.displayName!;
      }
    }
    return profile.name;
  }

  /// Resolves the effective email for a profile.
  static String? getEffectiveEmail(Profile profile, User? authUser, {bool isCloud = true}) {
    final isAuth = isAuthForProfile(profile, authUser, isCloud: isCloud);
    return isAuth ? (profile.linkedEmail ?? authUser?.email) : profile.linkedEmail;
  }
}

/// A crisp Google 4-color 'G' logo badge for linked accounts.
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

    // Red: Top sweep
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.356, 1.484, false, paint);

    // Yellow: Bottom-left sweep
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.18, 1.0, false, paint);

    // Green: Bottom-right sweep
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.2, 1.98, false, paint);

    // Blue: Right-top arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.87, 1.07, false, paint);

    // Horizontal bar of G
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
