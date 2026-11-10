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

  /// Signs in with Google and Firebase (Interactive Web/App UI).
  /// Returns the authenticated [User] on success, or `null` if cancelled or failed.
  Future<User?> signInWithGoogle() async {
    final result = await signInWithGoogleDetails();
    return result.user;
  }

  /// Signs in with Google and Firebase, returning both the [User] and [GoogleSignInCredentials].
  Future<({User? user, GoogleSignInCredentials? credentials})> signInWithGoogleDetails() async {
    try {
      AppLogger.d('AuthRepository: Initiating interactive Google Sign-In (Online)... Active Firebase user: ${currentUser?.email}');
      final GoogleSignInCredentials? credentials = await _googleSignIn.signInOnline();

      if (credentials == null) {
        AppLogger.d('AuthRepository: Interactive Google Sign-In cancelled or returned null credentials.');
        return (user: null, credentials: null);
      }

      AppLogger.d('AuthRepository: Received Google credentials from online flow. Exchanging with Firebase...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      AppLogger.d('AuthRepository: Successfully authenticated via interactive sign-in as ${userCredential.user?.email} (UID: ${userCredential.user?.uid})');
      return (user: userCredential.user, credentials: credentials);
    } catch (e, st) {
      AppLogger.e('AuthRepository: Interactive Google Sign-In failed', error: e, stack: st);
      return (user: null, credentials: null);
    }
  }

  /// Re-authenticates Firebase directly using stored OAuth tokens from WorkspaceSecureStorage.
  Future<User?> signInWithStoredTokens({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      AppLogger.d('AuthRepository: Re-authenticating Firebase using stored OAuth tokens...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      AppLogger.d('AuthRepository: Successfully authenticated using stored OAuth tokens as ${userCredential.user?.email} (UID: ${userCredential.user?.uid})');
      return userCredential.user;
    } catch (e, st) {
      AppLogger.w('AuthRepository: Re-authentication using stored OAuth tokens failed: $e', e, st);
      return null;
    }
  }

  /// Attempts silent Google and Firebase Sign-In using background credentials without UI popups.
  /// Returns the authenticated [User] on success, or `null` if silent auth is unavailable.
  Future<User?> signInSilently() async {
    final result = await signInSilentlyDetails();
    return result.user;
  }

  /// Attempts silent Google and Firebase Sign-In using background credentials without UI popups.
  /// Returns both [User] and [GoogleSignInCredentials] on success, or `(null, null)` if unavailable.
  Future<({User? user, GoogleSignInCredentials? credentials})> signInSilentlyDetails() async {
    try {
      AppLogger.d('AuthRepository: Attempting silent Google Sign-In (Lightweight)... Active Firebase user: ${currentUser?.email}');
      final GoogleSignInCredentials? credentials = await _googleSignIn.lightweightSignIn();

      if (credentials == null) {
        AppLogger.d('AuthRepository: Silent Google Sign-In returned null credentials.');
        return (user: null, credentials: null);
      }

      AppLogger.d('AuthRepository: Received background Google credentials. Exchanging with Firebase...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      AppLogger.d('AuthRepository: Successfully silent-authenticated as ${userCredential.user?.email} (UID: ${userCredential.user?.uid})');
      return (user: userCredential.user, credentials: credentials);
    } catch (e, st) {
      AppLogger.w('AuthRepository: Silent Google Sign-In failed: $e', e, st);
      return (user: null, credentials: null);
    }
  }

  /// Signs out from Firebase only, keeping Google account session cached for fast background profile switching.
  Future<void> signOutFirebaseOnly() async {
    try {
      AppLogger.d('AuthRepository: Signing out active Firebase session (${currentUser?.email})...');
      await _auth.signOut();
      AppLogger.d('AuthRepository: Firebase sign-out complete.');
    } catch (e, st) {
      AppLogger.e('AuthRepository: Firebase sign-out error', error: e, stack: st);
    }
  }

  /// Signs out from both Google and Firebase.
  Future<void> signOut() async {
    try {
      AppLogger.d('AuthRepository: Signing out active user (${currentUser?.email}) from Google and Firebase...');
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.d('AuthRepository: Sign-out complete.');
    } catch (e, st) {
      AppLogger.e('AuthRepository: Sign-out error', error: e, stack: st);
    }
  }
}
