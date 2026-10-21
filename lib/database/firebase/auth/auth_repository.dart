import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import '../../../../core/util/logger.dart';
import 'firebase_provider.dart';

class AuthRepository {
  final Ref ref;

  AuthRepository(this.ref);

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  GoogleSignIn get _googleSignIn => ref.read(googleSignInProvider);

  /// Current Firebase User
  User? get currentUser => _auth.currentUser;

  /// Check if user is currently signed in
  bool get isSignedIn => currentUser != null;

  /// Signs in with Google and Firebase.
  /// Returns the authenticated [User] on success, or `null` if cancelled or failed.
  Future<User?> signInWithGoogle() async {
    try {
      AppLogger.d('AuthRepository: Initiating Google Sign-In...');
      final GoogleSignInCredentials? credentials = await _googleSignIn.signInOnline();

      if (credentials == null) {
        AppLogger.d('AuthRepository: Google Sign-In cancelled by user.');
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      AppLogger.d('AuthRepository: Successfully authenticated as ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e, st) {
      AppLogger.e('AuthRepository: Google Sign-In failed', error: e, stack: st);
      return null;
    }
  }

  /// Signs out from both Google and Firebase.
  Future<void> signOut() async {
    try {
      AppLogger.d('AuthRepository: Signing out from Google and Firebase...');
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.d('AuthRepository: Sign-out complete.');
    } catch (e, st) {
      AppLogger.e('AuthRepository: Sign-out error', error: e, stack: st);
    }
  }
}
