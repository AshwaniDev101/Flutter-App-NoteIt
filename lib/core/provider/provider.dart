import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:noteit/core/secrets/app_secrets.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Determine if we are running on Windows Desktop
  final isWindows = !kIsWeb && Platform.isWindows;


  return GoogleSignIn(
    params: GoogleSignInParams(
      clientId: isWindows ? AppSecrets.windowsClientId: AppSecrets.webClientId,

      // Provide the secret ONLY for Windows Desktop; leave null for Web/Mobile
      clientSecret: isWindows ? AppSecrets.windowsClientSecret : null,
    ),
  );
});