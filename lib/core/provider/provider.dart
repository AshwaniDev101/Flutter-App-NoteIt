import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Determine if we are running on Windows Desktop
  final isWindows = !kIsWeb && Platform.isWindows;

  return GoogleSignIn(
    params: GoogleSignInParams(
      // Use your Web or Desktop Client ID depending on the platform target
      clientId: isWindows
          ? 'CLIENT_ID.apps.googleusercontent.com'
          : '707715729232-ulbe4pm7fn9jbn11usgqtrkn3ov11q2h.apps.googleusercontent.com',

      // Provide the secret ONLY for Windows Desktop; leave null for Web/Mobile
      clientSecret: isWindows ? 'CLIENT_SECRET' : null,
    ),
  );
});