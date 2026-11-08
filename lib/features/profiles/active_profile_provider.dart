import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/util/logger.dart';
import '../../database/firebase/auth/firebase_provider.dart';
import '../../database/shared_preference/shared_preference_manager.dart';
import '../../features/folders/core/providers.dart';
import '../../features/home/core/providers.dart';
import '../../features/lock/lock_manger/lock_manager.dart';
import '../../features/reminder/reminder_manager.dart';
import 'profile_model.dart';
import 'profile_repository.dart';
import 'profile_secure_storage.dart';

/// Riverpod provider managing the currently active user workspace profile.
final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, Profile>(() {
  return ActiveProfileNotifier();
});

class ActiveProfileNotifier extends Notifier<Profile> {
  bool _isSwitching = false;

  @override
  Profile build() {
    final prefs = ref.watch(sharedPreferenceProvider);
    final savedProfileId = prefs.activeProfileId;
    final repo = ProfileRepository.instance;

    if (savedProfileId != null) {
      final profile = repo.getProfileById(savedProfileId);
      if (profile != null) {
        return profile;
      }
    }

    // Default fallback to primary 'Default' profile
    return ProfileRepository.defaultProfile;
  }

  /// Switches the active profile to [targetProfile].
  ///
  /// Executes the clean 7-step switching teardown & re-arm sequence:
  /// 1. Clears active UI selection states (selected note, folder, search query).
  /// 2. Flushes session lock tokens.
  /// 3. Cancels pending OS system notifications for previous profile.
  /// 4. Saves [targetProfile.id] in SharedPreferences & updates `lastUsedAt`.
  /// 5. Configures profile syncMode & performs silent/interactive auth switching.
  /// 6. Updates Riverpod state -> triggers SQLite connection swap via `localDatabaseProvider`.
  /// 7. Re-arms pending reminders from the new active profile's database.
  Future<void> switchProfile(Profile targetProfile) async {
    if (state.id == targetProfile.id || _isSwitching) return;

    _isSwitching = true;
    try {
      AppLogger.d('ActiveProfileNotifier: Switching profile from "${state.name}" (${state.id}) to "${targetProfile.name}" (${targetProfile.id})...');

      // 1. Clear active UI selection states
      ref.read(activeNoteProvider.notifier).clear();
      ref.read(activeFolderProvider.notifier).clear();
      ref.read(searchQueryProvider.notifier).clear();

      // 2. Clear unlocked note sessions for security
      ref.read(lockManagerProvider.notifier).clearAllSessions();

      // 3. Cancel scheduled local OS notifications for previous profile
      await ReminderManager().cancelAllNotifications();

      // 4. Update SharedPreferences & touch lastUsedAt timestamp
      await ref.read(sharedPreferenceProvider).setActiveProfileId(targetProfile.id);
      await ProfileRepository.instance.touchProfileLastUsed(targetProfile.id);

      // 5. Handle Google Auth session & syncMode configuration without calling syncModeProvider (prevents CircularDependencyError)
      Profile updatedProfile = targetProfile;
      final authRepo = ref.read(authRepositoryProvider);
      final currentFirebaseEmail = authRepo.currentUser?.email?.toLowerCase();

      if (targetProfile.linkedEmail != null) {
        final targetEmail = targetProfile.linkedEmail!.toLowerCase();
        AppLogger.d('ActiveProfileNotifier: Target profile is Google-linked to $targetEmail. Current Firebase session: $currentFirebaseEmail');

        updatedProfile = targetProfile.copyWith(syncMode: 'cloud');
        await ProfileRepository.instance.updateProfile(updatedProfile);

        if (currentFirebaseEmail != targetEmail) {
          bool authenticatedWithStoredToken = false;

          // 1. Try re-authenticating with stored OAuth tokens from hardware storage
          final storedTokens = await ProfileSecureStorage.instance.getProfileOAuthTokens(targetProfile.id);
          if (storedTokens != null && storedTokens.containsKey('idToken')) {
            AppLogger.d('ActiveProfileNotifier: Found hardware-stored OAuth tokens for ${targetProfile.name}. Attempting direct Firebase credential re-auth...');
            final storedUser = await authRepo.signInWithStoredTokens(
              idToken: storedTokens['idToken']!,
              accessToken: storedTokens['accessToken'],
            );

            if (storedUser?.email?.toLowerCase() == targetEmail) {
              AppLogger.d('ActiveProfileNotifier: Direct Firebase re-auth via stored OAuth tokens succeeded for $targetEmail (100% Silent).');
              authenticatedWithStoredToken = true;
            } else {
              AppLogger.w('ActiveProfileNotifier: Stored OAuth token re-auth resulted in email mismatch or failure (${storedUser?.email}).');
            }
          }

          // 2. If stored token re-auth wasn't available or failed, attempt lightweight silent sign in
          if (!authenticatedWithStoredToken) {
            AppLogger.d('ActiveProfileNotifier: Attempting lightweight Google Sign-In fallback...');
            final silentUser = await authRepo.signInSilently();
            final silentEmail = silentUser?.email?.toLowerCase();

            if (silentEmail == targetEmail) {
              AppLogger.d('ActiveProfileNotifier: Lightweight silent re-authentication succeeded for $targetEmail.');
            } else {
              AppLogger.w('ActiveProfileNotifier: Lightweight silent auth unavailable or mismatched ($silentEmail vs $targetEmail). Prompting interactive Google Sign-In...');
              final interactiveUser = await authRepo.signInWithGoogle();

              if (interactiveUser?.email?.toLowerCase() == targetEmail) {
                AppLogger.d('ActiveProfileNotifier: Interactive Google Sign-In succeeded for $targetEmail.');
              } else {
                AppLogger.w('ActiveProfileNotifier: Interactive Google Sign-In cancelled or mismatched for profile ${targetProfile.name}.');
              }
            }
          }
        } else {
          AppLogger.d('ActiveProfileNotifier: Active Firebase session already matches target profile email ($targetEmail).');
        }
      } else {
        AppLogger.d('ActiveProfileNotifier: Target profile "${targetProfile.name}" is an offline profile (no linked Google email).');
        updatedProfile = targetProfile.copyWith(syncMode: 'offline');
        await ProfileRepository.instance.updateProfile(updatedProfile);

        if (authRepo.isSignedIn) {
          AppLogger.d('ActiveProfileNotifier: Signing out active user ($currentFirebaseEmail) for non-Google profile...');
          await authRepo.signOut();
        }
      }

      // 6. Update state -> triggers Riverpod rebuild, syncModeProvider update & SQLite handle swap
      state = updatedProfile;

      // 7. Re-arm pending reminders from newly active profile's database
      ReminderManager().rearmPendingReminders();

      AppLogger.d('ActiveProfileNotifier: Successfully switched active profile to ${updatedProfile.name}');
    } finally {
      _isSwitching = false;
    }
  }

  /// Updates the current active profile's metadata without triggering database handle teardown.
  void updateActiveProfile(Profile updatedProfile) {
    if (state.id == updatedProfile.id) {
      state = updatedProfile;
    }
  }
}
