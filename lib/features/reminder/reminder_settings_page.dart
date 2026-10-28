import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/router.dart';
import '../../core/helpers/platform_helper.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../../database/shared_preference/shared_preference_manager.dart';

import '../../shared/overlays/app_scaffold.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import '../home/core/providers.dart';
import '../home/view/desktop/content_panel/core/navigator.dart';
import 'reminder_manager.dart';

class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  final SharedPreferenceManager _prefs = SharedPreferenceManager.instance;

  late bool _vibrationEnabled;
  late int _durationSeconds;
  late String _defaultRepeatMode;
  String? _customSoundPath;
  late String _customSoundName;

  AudioPlayer? _testAudioPlayer;
  bool _isPlayingTest = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _vibrationEnabled = _prefs.reminderVibrationEnabled;
    _durationSeconds = _prefs.reminderDurationSeconds;
    _defaultRepeatMode = _prefs.defaultRepeatMode;
    _customSoundPath = _prefs.customReminderSoundPath;
    _customSoundName = _prefs.customReminderSoundName;
  }

  @override
  void dispose() {
    _testAudioPlayer?.stop();
    _testAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _pickCustomSound() async {
    await _stopTestAudio();
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
      );

      if (file != null && file.path != null) {
        final path = file.path!;
        final name = file.name;

        await _prefs.setCustomReminderSound(path, name);
        setState(() {
          _customSoundPath = path;
          _customSoundName = name;
        });

        SnackBarManager.show(
          msg: 'Custom alarm sound set to "$name"',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } catch (e) {
      SnackBarManager.show(
        msg: 'Failed to pick audio file: $e',
        type: SnackBarMessageType.error,
      );
    }
  }

  Future<void> _resetDefaultSound() async {
    await _stopTestAudio();
    await _prefs.setCustomReminderSound(null, null);
    setState(() {
      _customSoundPath = null;
      _customSoundName = 'Default Ring (alarm_ring.mp3)';
    });

    SnackBarManager.show(
      msg: 'Reset alarm sound to default',
      type: SnackBarMessageType.acknowledgment,
    );
  }

  Future<void> _toggleTestAudio() async {
    if (_isPlayingTest) {
      await _stopTestAudio();
    } else {
      try {
        await _testAudioPlayer?.stop();
        await _testAudioPlayer?.dispose();
        _testAudioPlayer = AudioPlayer();

        setState(() => _isPlayingTest = true);

        final customFile = File(_customSoundPath ?? '');
        if (PlatformHelper.isNativeDesktop &&
            _customSoundPath != null &&
            _customSoundPath!.isNotEmpty &&
            customFile.existsSync()) {
          await _testAudioPlayer!
              .play(DeviceFileSource(_customSoundPath!));
        } else {
          await _testAudioPlayer!.play(AssetSource('alarm_ring.mp3'));
        }

        _testAudioPlayer!.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingTest = false);
        });
      } catch (e) {
        if (mounted) setState(() => _isPlayingTest = false);
        SnackBarManager.show(
          msg: 'Error playing audio preview: $e',
          type: SnackBarMessageType.error,
        );
      }
    }
  }

  Future<void> _stopTestAudio() async {
    try {
      await _testAudioPlayer?.stop();
      await _testAudioPlayer?.dispose();
      _testAudioPlayer = null;
    } catch (_) {}
    if (mounted) setState(() => _isPlayingTest = false);
  }

  Future<void> _showActiveRemindersModal() async {
    final notesDao = ref.read(notesDaoProvider);
    final pendingNotes = await notesDao.getNotesWithPendingReminders();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, modalSetState) {
            final theme = Theme.of(modalCtx);
            final colorScheme = theme.colorScheme;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalCtx).size.height * 0.75,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alarm_on_rounded, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Active Reminders (${pendingNotes.length})',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (pendingNotes.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No active reminders scheduled',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: pendingNotes.length,
                        separatorBuilder: (ctx, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final noteWithFolder = pendingNotes[index];
                          final note = noteWithFolder.note;
                          final reminderAt = note.reminderAt;

                          final formattedDate = reminderAt != null
                              ? ReminderManager.formatReminderLabel(
                                  reminderAt,
                                  note.reminderRepeatMode,
                                  note.reminderCustomDays,
                                )
                              : '';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            title: Text(
                              note.title.isNotEmpty ? note.title : 'Untitled Note',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.alarm_off_rounded, size: 20),
                              color: colorScheme.error,
                              tooltip: 'Clear Reminder',
                              onPressed: () async {
                                await ReminderManager().cancelForNote(note.uuid);
                                await notesDao.updateNoteReminder(note.uuid, null);
                                modalSetState(() {
                                  pendingNotes.removeAt(index);
                                });
                                SnackBarManager.show(
                                  msg: 'Reminder cleared',
                                  type: SnackBarMessageType.acknowledgment,
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.of(modalCtx).pop();
                              ref.read(activeNoteProvider.notifier).setNote(noteWithFolder);
                              if (PlatformHelper.isNativeDesktop) {
                                ref
                                    .read(desktopRightPanelViewProvider.notifier)
                                    .setView(RightPanelPageOptions.noteEditor);
                              } else {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.edit,
                                  arguments: noteWithFolder,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDesktop = PlatformHelper.isNativeDesktop;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.reminderSettings,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header ---
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          ref.read(drawerNavigationProvider).navigate(
                              context, RightPanelPageOptions.settings);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reminders & Alarms',
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ==================== ALARM SOUND SECTION ====================
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Alarm Sound & Tone',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Alarm Ringtone',
                                      style: textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _customSoundName,
                                      style: textTheme.bodyMedium?.copyWith(
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
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: _pickCustomSound,
                                icon: const Icon(Icons.folder_open_rounded,
                                    size: 18),
                                label: const Text('Choose Audio File'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _toggleTestAudio,
                                icon: Icon(
                                  _isPlayingTest
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  size: 18,
                                ),
                                label: Text(_isPlayingTest
                                    ? 'Stop Preview'
                                    : 'Test Sound 🔊'),
                              ),
                              if (_customSoundPath != null)
                                TextButton.icon(
                                  onPressed: _resetDefaultSound,
                                  icon: const Icon(Icons.restart_alt_rounded,
                                      size: 18),
                                  label: const Text('Reset Default'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== AUDIO & VIBRATION TOGGLES ====================
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Notifications & Behavior',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _prefs.reminderSoundListenable,
                          builder: (context, soundEnabled, _) {
                            return SwitchListTile(
                              title: const Text('Enable Alarm Sound'),
                              subtitle: const Text(
                                  'Play audio ringer when reminder goes off'),
                              value: soundEnabled,
                              secondary: const Icon(Icons.volume_up_outlined),
                              onChanged: (val) async {
                                await _prefs.setReminderSoundEnabled(val);
                              },
                            );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Enable Device Vibration'),
                          subtitle: const Text(
                              'Vibrate phone or supported hardware'),
                          value: _vibrationEnabled,
                          secondary: const Icon(Icons.vibration_outlined),
                          onChanged: (val) async {
                            setState(() => _vibrationEnabled = val);
                            await _prefs.setReminderVibrationEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== QOL SETTINGS ====================
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Quality of Life Defaults',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Ring Timeout / Auto-Stop (Desktop Only) ---
                          if (isDesktop) ...[
                            Text(
                              'Desktop Ring Duration (Auto-Stop Timeout)',
                              style: textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Controls how long the alarm audio loops on desktop before auto-stopping',
                              style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(value: 10, label: Text('10 sec')),
                                  ButtonSegment(value: 30, label: Text('30 sec')),
                                  ButtonSegment(value: 60, label: Text('60 sec')),
                                  ButtonSegment(value: 120, label: Text('2 min')),
                                ],
                                selected: {_durationSeconds},
                                onSelectionChanged: (newSelection) async {
                                  final val = newSelection.first;
                                  setState(() => _durationSeconds = val);
                                  await _prefs.setReminderDurationSeconds(val);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // --- Default Repeat Mode ---
                          Text(
                            'Default Reminder Repeat Mode',
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pre-selected repeat option when creating new reminders',
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'once', label: Text('Once')),
                                ButtonSegment(
                                    value: 'daily', label: Text('Daily')),
                                ButtonSegment(
                                    value: 'custom', label: Text('Custom')),
                              ],
                              selected: {_defaultRepeatMode},
                              onSelectionChanged: (newSelection) async {
                                final val = newSelection.first;
                                setState(() => _defaultRepeatMode = val);
                                await _prefs.setDefaultRepeatMode(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==================== MANAGE ACTIVE REMINDERS ====================
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: colorScheme.onSecondaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Reminders',
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View and manage all notes with active scheduled alarms',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: _showActiveRemindersModal,
                            icon: const Icon(Icons.list_alt_rounded, size: 18),
                            label: const Text('Manage'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
