import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/util/logger.dart';
import '../../../database/firebase/auth/firebase_provider.dart';
import '../../../database/shared_preference/shared_preference_manager.dart';
import '../../../features/cloud_sync/data/cloud_sync_service.dart';
import '../../../features/folders/core/providers.dart';
import '../../../features/home/core/providers.dart';
import '../../../features/lock/lock_manger/lock_manager.dart';
import '../../../features/reminder/reminder_manager.dart';
import '../data/profile_repository.dart';
import '../data/profile_secure_storage.dart';
import '../models/profile_model.dart';
import 'profile_providers.dart';

class ProfileSwitchingState {
  final bool isSwitching;
  final Profile? targetProfile;

  const ProfileSwitchingState({
    this.isSwitching = false,
    this.targetProfile,
  });
}

final profileSwitchingProvider = NotifierProvider<ProfileSwitchingNotifier, ProfileSwitchingState>(() {
  return ProfileSwitchingNotifier();
});

class ProfileSwitchingNotifier extends Notifier<ProfileSwitchingState> {
  @override
  ProfileSwitchingState build() => const ProfileSwitchingState();

  void startSwitch(Profile target) {
    state = ProfileSwitchingState(isSwitching: true, targetProfile: target);
  }

  void endSwitch() {
    state = const ProfileSwitchingState(isSwitching: false, targetProfile: null);
  }
}

/// Riverpod provider managing the currently active user workspace profile.
final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, Profile>(() {
  return ActiveProfileNotifier();
});

class ActiveProfileNotifier extends Notifier<Profile> {
  bool _isSwitching = false;

  /// Returns true if a profile switch operation is currently in progress.
  bool get isSwitching => _isSwitching;

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
    ref.read(profileSwitchingProvider.notifier).startSwitch(targetProfile);
    try {
      AppLogger.d('ActiveProfileNotifier: Switching profile from "${state.name}" (${state.id}) to "${targetProfile.name}" (${targetProfile.id})...');

      // 0. Stop active cloud sync listeners to prevent permission-denied errors on active streams during auth swap
      ref.read(cloudSyncServiceProvider).stop();

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

      final targetSyncMode = SyncMode.values.firstWhere(
        (e) => e.name == targetProfile.syncMode,
        orElse: () => SyncMode.offline,
      );

      if (targetSyncMode.isCloud && targetProfile.linkedEmail != null) {
        final targetEmail = targetProfile.linkedEmail!.toLowerCase();
        AppLogger.d('ActiveProfileNotifier: Target profile is in Cloud mode ($targetEmail). Current Firebase session: $currentFirebaseEmail');

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
              updatedProfile = updatedProfile.copyWith(
                displayName: storedUser?.displayName ?? updatedProfile.displayName,
                photoUrl: storedUser?.photoURL ?? updatedProfile.photoUrl,
              );
              await ProfileRepository.instance.updateProfile(updatedProfile);
              await ref.read(profilesListProvider.notifier).updateProfile(updatedProfile);
            } else {
              AppLogger.w('ActiveProfileNotifier: Stored OAuth token re-auth failed or expired. Clearing stale tokens for ${targetProfile.name}.');
              await ProfileSecureStorage.instance.deleteProfileToken(targetProfile.id);
            }
          }

          // 2. If stored token re-auth wasn't available or failed, attempt lightweight silent sign in
          if (!authenticatedWithStoredToken) {
            AppLogger.d('ActiveProfileNotifier: Attempting lightweight Google Sign-In fallback...');
            final silentResult = await authRepo.signInSilentlyDetails();
            final silentUser = silentResult.user;
            final silentEmail = silentUser?.email?.toLowerCase();

            if (silentEmail == targetEmail) {
              AppLogger.d('ActiveProfileNotifier: Lightweight silent re-authentication succeeded for $targetEmail.');
              authenticatedWithStoredToken = true;
              updatedProfile = updatedProfile.copyWith(
                displayName: silentUser?.displayName ?? updatedProfile.displayName,
                photoUrl: silentUser?.photoURL ?? updatedProfile.photoUrl,
              );
              await ProfileRepository.instance.updateProfile(updatedProfile);
              await ref.read(profilesListProvider.notifier).updateProfile(updatedProfile);
              if (silentResult.credentials?.idToken != null) {
                await ProfileSecureStorage.instance.saveProfileOAuthTokens(
                  profileId: targetProfile.id,
                  idToken: silentResult.credentials!.idToken!,
                  accessToken: silentResult.credentials?.accessToken,
                );
              }
            } else {
              AppLogger.w('ActiveProfileNotifier: Lightweight silent auth unavailable or mismatched ($silentEmail vs $targetEmail). Prompting interactive Google Sign-In...');
              final interactiveResult = await authRepo.signInWithGoogleDetails();
              final interactiveUser = interactiveResult.user;

              if (interactiveUser?.email?.toLowerCase() == targetEmail) {
                AppLogger.d('ActiveProfileNotifier: Interactive Google Sign-In succeeded for $targetEmail.');
                authenticatedWithStoredToken = true;
                updatedProfile = updatedProfile.copyWith(
                  displayName: interactiveUser?.displayName ?? updatedProfile.displayName,
                  photoUrl: interactiveUser?.photoURL ?? updatedProfile.photoUrl,
                );
                await ProfileRepository.instance.updateProfile(updatedProfile);
                await ref.read(profilesListProvider.notifier).updateProfile(updatedProfile);
                if (interactiveResult.credentials?.idToken != null) {
                  await ProfileSecureStorage.instance.saveProfileOAuthTokens(
                    profileId: targetProfile.id,
                    idToken: interactiveResult.credentials!.idToken!,
                    accessToken: interactiveResult.credentials?.accessToken,
                  );
                }
              } else {
                AppLogger.w('ActiveProfileNotifier: Interactive Google Sign-In cancelled or mismatched for profile ${targetProfile.name}. Falling back to offline mode.');
                updatedProfile = targetProfile.copyWith(syncMode: 'offline');
                await ProfileRepository.instance.updateProfile(updatedProfile);
                await ref.read(profilesListProvider.notifier).updateProfile(updatedProfile);
              }
            }
          }
        } else {
          AppLogger.d('ActiveProfileNotifier: Active Firebase session already matches target profile email ($targetEmail).');
          final currentUser = authRepo.currentUser;
          if (currentUser?.photoURL != null || currentUser?.displayName != null) {
            updatedProfile = updatedProfile.copyWith(
              displayName: currentUser?.displayName ?? updatedProfile.displayName,
              photoUrl: currentUser?.photoURL ?? updatedProfile.photoUrl,
            );
            await ProfileRepository.instance.updateProfile(updatedProfile);
            await ref.read(profilesListProvider.notifier).updateProfile(updatedProfile);
          }
        }
      } else {
        AppLogger.d('ActiveProfileNotifier: Target profile "${targetProfile.name}" is operating in non-cloud mode (${targetProfile.syncMode}).');
        if (authRepo.isSignedIn) {
          AppLogger.d('ActiveProfileNotifier: Signing out active Firebase user ($currentFirebaseEmail) for non-cloud profile...');
          await authRepo.signOutFirebaseOnly();
        }
      }

      // 6. Update state -> triggers Riverpod rebuild, syncModeProvider update & SQLite handle swap
      state = updatedProfile;

      // 7. Re-arm pending reminders from newly active profile's database
      ReminderManager().rearmPendingReminders();

      AppLogger.d('ActiveProfileNotifier: Successfully switched active profile to ${updatedProfile.name}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isSwitching = false;
      ref.read(profileSwitchingProvider.notifier).endSwitch();
    }
  }

  /// Updates the current active profile's metadata without triggering database handle teardown.
  void updateActiveProfile(Profile updatedProfile) {
    if (state.id == updatedProfile.id) {
      state = updatedProfile;
    }
  }
}
