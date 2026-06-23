import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:noteit/core/secrets/app_secrets.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Determine if we are running on Windows Desktop
  final isWindows = !kIsWeb && Platform.isWindows;


  // Your Desktop Client ID, You have set it up yourself
  // Go to project Credentials > click create credentials > OAuth client ID > now ur on 'Create OAuth client ID' page> Select Application type to "Desktop app" and Name it anything example : "Desktop-Client-1"
  // Once you click 'Create' button you be given *ClientID* and *Client Secretes* copy them and keep them safe
  // https://console.cloud.google.com/apis/credentials?project=note-it-master

  // For Web Client ID u can get it from  https://console.cloud.google.com/apis/credentials?project=note-it-master
  // or from "console.firebase.google.com" under Authentication > Sign-in methode > Enable Google Sign In, Click on "Web SDK configuration" You will get the "Web client ID"

  return GoogleSignIn(
    params: GoogleSignInParams(
      clientId: isWindows ? AppSecrets.windowsClientId: AppSecrets.webClientId,

      // Provide the secret ONLY for Windows Desktop; leave null for Web/Mobile
      clientSecret: isWindows ? AppSecrets.windowsClientSecret : null,
    ),
  );
});


final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
