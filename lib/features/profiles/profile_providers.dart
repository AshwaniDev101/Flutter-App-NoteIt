import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

/// Riverpod provider exposing access to [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository.instance;
});

/// Riverpod provider exposing an unmodifiable list of all available user profiles.
final profilesListProvider = NotifierProvider<ProfilesListNotifier, List<Profile>>(() {
  return ProfilesListNotifier();
});

class ProfilesListNotifier extends Notifier<List<Profile>> {
  @override
  List<Profile> build() {
    return ref.watch(profileRepositoryProvider).getProfiles();
  }

  /// Refreshes the active profiles list from the repository.
  void refresh() {
    state = ref.read(profileRepositoryProvider).getProfiles();
  }

  /// Creates a new profile and refreshes the profiles list state.
  Future<Profile> createProfile({
    required String name,
    String? linkedEmail,
    String syncMode = 'offline',
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final newProfile = await repo.createProfile(
      name: name,
      linkedEmail: linkedEmail,
      syncMode: syncMode,
    );
    refresh();
    return newProfile;
  }

  /// Updates an existing profile and refreshes the profiles list state.
  Future<bool> updateProfile(Profile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    final success = await repo.updateProfile(profile);
    if (success) refresh();
    return success;
  }

  /// Sets a profile as default and refreshes the profiles list state.
  Future<bool> setDefaultProfile(String profileId) async {
    final repo = ref.read(profileRepositoryProvider);
    final success = await repo.setDefaultProfile(profileId);
    if (success) refresh();
    return success;
  }

  /// Deletes a non-default profile and refreshes the profiles list state.
  Future<bool> deleteProfile(String profileId) async {
    final repo = ref.read(profileRepositoryProvider);
    final success = await repo.deleteProfile(profileId);
    if (success) refresh();
    return success;
  }
}
