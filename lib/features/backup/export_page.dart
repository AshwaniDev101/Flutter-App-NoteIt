import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/util/logger.dart';
import '../../database/drift/folders/folders_dao.dart';
import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../lock/password_prompt_helper.dart';
import '../../shared/overlays/app_scaffold.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'backup_service.dart';

enum ExportFormat { json, csv }
enum ExportScope { all, notesOnly, foldersOnly }

class ExportNotesPage extends ConsumerStatefulWidget {
  const ExportNotesPage({super.key});

  @override
  ConsumerState<ExportNotesPage> createState() => _ExportNotesPageState();
}

class _ExportNotesPageState extends ConsumerState<ExportNotesPage> {
  ExportFormat _selectedFormat = ExportFormat.json;
  ExportScope _selectedScope = ExportScope.all;
  bool _includeLockedNotes = false;
  bool _isExporting = false;

  Future<void> _handleLockedNotesToggle(bool? value) async {
    if (value == true) {
      final success = await PasswordPromptHelper.promptAndVerifyForExport(context, ref);
      if (success) {
        setState(() {
          _includeLockedNotes = true;
        });
      } else {
        setState(() {
          _includeLockedNotes = false;
        });
      }
    } else {
      setState(() {
        _includeLockedNotes = false;
      });
    }
  }

  Future<void> _exportNotes() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final result = await backupService.generateBackup(
        format: _selectedFormat,
        scope: _selectedScope,
        includeLockedNotes: _includeLockedNotes,
      );

      if (result.content.isEmpty) {
        if (mounted) {
          SnackBarManager.show(
            msg: 'No data available to export based on selected scope.',
            type: SnackBarMessageType.info,
          );
        }
        return;
      }

      Uint8List fileBytes = Uint8List.fromList(utf8.encode(result.content));
      final dateStr = DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');
      final defaultFileName = 'noteit_backup_$dateStr.${result.extension}';

      Uri? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: defaultFileName,
        bytes: fileBytes,
      );

      if (outputFile == null) {
        AppLogger.d('ExportNotesPage: Export canceled by user');
        return;
      }

      AppLogger.d('ExportNotesPage: Exported ${result.notesCount} notes and ${result.foldersCount} folders to $outputFile');

      if (mounted) {
        SnackBarManager.show(
          msg: 'Exported ${result.notesCount} notes & ${result.foldersCount} folders successfully!',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } catch (e, st) {
      AppLogger.e('ExportNotesPage: Failed to export backup', error: e, stack: st);
      if (mounted) {
        SnackBarManager.show(
          msg: 'Failed to export backup',
          description: '$e',
          type: SnackBarMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesDao = ref.watch(notesDaoProvider);
    final foldersDao = ref.watch(foldersDaoProvider);

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.export,
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating backup file...'),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  children: [
                    // TITLE & HEADER
                    Text(
                      'Export Backup',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export your notes and folders into an industry-standard backup file. Choose JSON for complete data backup or CSV for spreadsheet viewing.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // 1. SELECT SCOPE
                    Text(
                      '1. Select Export Scope',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ExportScope>(
                      segments: const [
                        ButtonSegment<ExportScope>(
                          value: ExportScope.all,
                          label: Text('All Data'),
                          icon: Icon(Icons.folder_special),
                        ),
                        ButtonSegment<ExportScope>(
                          value: ExportScope.notesOnly,
                          label: Text('Notes Only'),
                          icon: Icon(Icons.note_alt_outlined),
                        ),
                        ButtonSegment<ExportScope>(
                          value: ExportScope.foldersOnly,
                          label: Text('Folders Only'),
                          icon: Icon(Icons.folder_open),
                        ),
                      ],
                      selected: {_selectedScope},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedScope = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // 2. SELECT FORMAT
                    Text(
                      '2. Select Export Format',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RadioGroup<ExportFormat>(
                          groupValue: _selectedFormat,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFormat = val);
                          },
                          child: Column(
                            children: [
                              RadioListTile<ExportFormat>(
                                title: const Text('JSON (.json)', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Full structural backup containing notes, folders, timestamps, tags, and metadata. Recommended.'),
                                value: ExportFormat.json,
                              ),
                              const Divider(height: 1),
                              RadioListTile<ExportFormat>(
                                title: const Text('CSV (.csv)', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Tabular format containing notes and folder information. Best for viewing in Excel or Google Sheets.'),
                                value: ExportFormat.csv,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. SECURITY SETTINGS
                    if (_selectedScope != ExportScope.foldersOnly) ...[
                      Text(
                        '3. Security Settings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: const Text('Include password-protected notes', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Requires master password verification before exporting locked notes.'),
                          value: _includeLockedNotes,
                          onChanged: _handleLockedNotesToggle,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 4. EXPORT SUMMARY CARD
                    FutureBuilder(
                      future: Future.wait([
                        notesDao.getAllNotes(),
                        foldersDao.getAllFolders(),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final allNotes = snapshot.data![0] as List<Note>;
                        final allFolders = snapshot.data![1] as List<Folder>;

                        final activeFolders = _selectedScope == ExportScope.notesOnly
                            ? <Folder>[]
                            : allFolders.where((f) => f.deletedAt == null).toList();

                        final activeNotes = _selectedScope == ExportScope.foldersOnly
                            ? <Note>[]
                            : allNotes.where((n) => n.deletedAt == null).toList();

                        final lockedCount = activeNotes.where((n) => n.lockedAt != null).length;
                        final exportableNotesCount = activeNotes.where((n) => n.lockedAt == null || _includeLockedNotes).length;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Export Scope Summary',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedScope != ExportScope.foldersOnly ? '$exportableNotesCount notes' : ''}'
                                      '${_selectedScope == ExportScope.all ? ' & ' : ''}'
                                      '${_selectedScope != ExportScope.notesOnly ? '${activeFolders.length} folders' : ''} will be exported.'
                                      '${_selectedScope != ExportScope.foldersOnly && !_includeLockedNotes && lockedCount > 0 ? ' ($lockedCount locked notes excluded)' : ''}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // EXPORT BUTTON
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _exportNotes,
                        icon: const Icon(Icons.download),
                        label: Text(
                          'Generate Export File',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }
}
