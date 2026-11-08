import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/database/firebase/auth/firebase_provider.dart';
import '../../../shared/overlays/snack_bar_manager.dart';
import '../active_profile_provider.dart';
import '../profile_model.dart';
import '../profile_providers.dart';
import '../profile_secure_storage.dart';

/// Modal dialog for creating a new user profile workspace or editing an existing profile.
class CreateProfileDialog extends ConsumerStatefulWidget {
  final Profile? profileToEdit;

  const CreateProfileDialog({
    super.key,
    this.profileToEdit,
  });

  bool get isEditing => profileToEdit != null;

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  User? _dialogUser;
  String? _dialogIdToken;
  String? _dialogAccessToken;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileToEdit?.name ?? '');
    
    // When editing an existing profile, check if the current auth user matches
    if (widget.isEditing) {
      final activeUser = ref.read(authStateProvider).value;
      if (activeUser != null && activeUser.email == widget.profileToEdit?.linkedEmail) {
        _dialogUser = activeUser;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    // If not authenticated via Google, require a valid name in the text field
    if (_dialogUser == null && !(_formKey.currentState?.validate() ?? false)) return;

    var name = _nameController.text.trim();
    final dialogUser = _dialogUser;

    // Fallback name if Google signed in and name field left empty
    if (name.isEmpty && dialogUser != null) {
      name = (dialogUser.displayName?.isNotEmpty ?? false)
          ? dialogUser.displayName!
          : (dialogUser.email?.isNotEmpty ?? false)
              ? dialogUser.email!.split('@').first
              : 'Google Profile';
      _nameController.text = name;
    }

    if (name.isEmpty) {
      SnackBarManager.show(
        msg: 'Please enter a profile name',
        type: SnackBarMessageType.acknowledgment,
      );
      return;
    }

    final linkedEmail = dialogUser?.email;
    final displayName = dialogUser?.displayName;
    final photoUrl = dialogUser?.photoURL;
    final syncMode = (dialogUser != null && linkedEmail != null) ? 'cloud' : 'offline';
    final refreshToken = dialogUser?.uid; // Secure storage key identifier

    if (widget.isEditing) {
      final updated = widget.profileToEdit!.copyWith(
        name: name,
        displayName: displayName ?? widget.profileToEdit!.displayName,
        photoUrl: photoUrl ?? widget.profileToEdit!.photoUrl,
        linkedEmail: linkedEmail ?? widget.profileToEdit!.linkedEmail,
        syncMode: syncMode,
      );
      await ref.read(profilesListProvider.notifier).updateProfile(updated);

      if (_dialogIdToken != null && _dialogIdToken!.isNotEmpty) {
        await ProfileSecureStorage.instance.saveProfileOAuthTokens(
          profileId: updated.id,
          idToken: _dialogIdToken!,
          accessToken: _dialogAccessToken,
        );
      }

      if (ref.read(activeProfileProvider).id == updated.id) {
        ref.read(activeProfileProvider.notifier).updateActiveProfile(updated);
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        SnackBarManager.show(
          msg: 'Profile updated to "$name".',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } else {
      final newProfile = await ref.read(profilesListProvider.notifier).createProfile(
            name: name,
            displayName: displayName,
            photoUrl: photoUrl,
            linkedEmail: linkedEmail,
            syncMode: syncMode,
            refreshToken: refreshToken,
            idToken: _dialogIdToken,
            accessToken: _dialogAccessToken,
          );

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        await ref.read(activeProfileProvider.notifier).switchProfile(newProfile);
        SnackBarManager.show(
          msg: 'Created and switched to "$name" profile.',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.isEditing;
    final displayUser = _dialogUser;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.add_to_photos_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Profile' : 'Create New Profile',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: displayUser != null ? 'Profile Name (Optional)' : 'Profile Name *',
                    hintText: 'e.g. Work, Personal, Side Projects',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.workspace_premium_rounded),
                  ),
                  validator: (val) {
                    if (displayUser == null && (val == null || val.trim().isEmpty)) {
                      return 'Please enter a profile name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'To sync over cloud sign in',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (displayUser != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Unlink'),
                        onPressed: () async {
                          setState(() => _dialogUser = null);
                          if (widget.isEditing && widget.profileToEdit != null) {
                            await ref.read(profilesListProvider.notifier).unlinkGoogleAccount(widget.profileToEdit!.id);
                            await ref.read(authRepositoryProvider).signOut();
                          }
                          SnackBarManager.show(
                            msg: 'Account unlinked from this profile.',
                            type: SnackBarMessageType.acknowledgment,
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (displayUser == null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(_isSigningIn ? 'Signing in...' : 'Sign in with Google'),
                    onPressed: _isSigningIn
                        ? null
                        : () async {
                            setState(() => _isSigningIn = true);
                            try {
                              final result = await ref.read(authRepositoryProvider).signInWithGoogleDetails();
                              final user = result.user;
                              final creds = result.credentials;

                              if (user != null) {
                                final userEmail = user.email ?? '';
                                final isDuplicate = ref
                                    .read(profileRepositoryProvider)
                                    .isEmailAlreadyLinked(
                                      userEmail,
                                      excludeProfileId: widget.profileToEdit?.id,
                                    );

                                if (isDuplicate) {
                                  SnackBarManager.show(
                                    msg: 'Google account ($userEmail) is already linked to another profile.',
                                    type: SnackBarMessageType.acknowledgment,
                                  );
                                  await ref.read(authRepositoryProvider).signOut();
                                } else {
                                  setState(() {
                                    _dialogUser = user;
                                    _dialogIdToken = creds?.idToken;
                                    _dialogAccessToken = creds?.accessToken;
                                    // Auto-fill profile name if field is empty
                                    if (_nameController.text.trim().isEmpty) {
                                      _nameController.text = (user.displayName?.isNotEmpty ?? false)
                                          ? user.displayName!
                                          : (user.email?.isNotEmpty ?? false)
                                              ? user.email!.split('@').first
                                              : 'Google Profile';
                                    }
                                  });
                                  SnackBarManager.show(
                                    msg: 'Signed in as ${user.email}',
                                    type: SnackBarMessageType.acknowledgment,
                                  );
                                }
                              }
                            } finally {
                              if (mounted) setState(() => _isSigningIn = false);
                            }
                          },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primary,
                          backgroundImage: (displayUser.photoURL != null && displayUser.photoURL!.isNotEmpty)
                              ? NetworkImage(displayUser.photoURL!)
                              : null,
                          child: (displayUser.photoURL == null || displayUser.photoURL!.isEmpty)
                              ? Text(
                                  (displayUser.displayName?.isNotEmpty ?? false)
                                      ? displayUser.displayName![0].toUpperCase()
                                      : (displayUser.email?.isNotEmpty ?? false)
                                          ? displayUser.email![0].toUpperCase()
                                          : 'U',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (displayUser.displayName != null && displayUser.displayName!.isNotEmpty)
                                Text(
                                  displayUser.displayName!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (displayUser.email != null && displayUser.email!.isNotEmpty)
                                Text(
                                  displayUser.email!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(isEditing ? 'Save Changes' : 'Create Profile'),
        ),
      ],
    );
  }
}
