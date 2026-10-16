import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/util/logger.dart';
import '../../database/drift/notes/notes_dao.dart';
import '../lock/password_prompt_helper.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/snack_bar_manager.dart';
import '../home/view/desktop/right_panel/core/navigator.dart';

enum ExportFormat { json, csv }

class ExportNotesPage extends ConsumerStatefulWidget {
  const ExportNotesPage({super.key});

  @override
  ConsumerState<ExportNotesPage> createState() => _ExportNotesPageState();
}

class _ExportNotesPageState extends ConsumerState<ExportNotesPage> {
  ExportFormat _selectedFormat = ExportFormat.json;
  bool _includeLockedNotes = false;
  bool _isExporting = false;

  // Schema fields mapped to their selection state.
  final Map<String, bool> _fieldSelections = {
    'uuid': true,
    'title': true,
    'content': true,
    'color': false,
    'pinnedAt': false,
    'archivedAt': false,
    'lockedAt': false,
    'tags': true,
    'folderId': false,
    'reminderAt': false,
    'localAttachmentPath': false,
    'cloudAttachmentUrl': false,
    'ownerUid': false,
    'createdAt': true,
    'updatedAt': true,
    'deletedAt': false,
    'schemaVersion': false,
    'contentVersion': false,
    'updateCounter': false,
    'cloudSyncStatus': false,
    'localSyncStatus': false,
    'creationPlatform': false,
    'creationDevice': false,
    'lastEditedPlatform': false,
    'lastEditedDevice': false,
    'deletedPlatform': false,
    'deletedDevice': false,
  };



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
      final notesDao = ref.read(notesDaoProvider);
      final allNotes = await notesDao.watchAllNotes().first;

      final notesToExport = allNotes.where((note) {
        if (note.deletedAt != null) return false;

        // UPGRADED: isLocked is now lockedAt != null
        if (note.lockedAt != null && !_includeLockedNotes) return false;

        return true;
      }).toList();

      if (notesToExport.isEmpty) {
        if (mounted) {
          SnackBarManager.show(
            msg: 'No notes available to export.',
            type: SnackBarMessageType.info,
          );
        }
        return;
      }

      List<Map<String, dynamic>> exportData = notesToExport.map((note) {
        final Map<String, dynamic> noteMap = note.toJson();
        final Map<String, dynamic> filteredMap = {};

        _fieldSelections.forEach((field, isSelected) {
          if (isSelected) {
            filteredMap[field] = noteMap[field];
          }
        });
        return filteredMap;
      }).toList();

      String fileContent = '';
      String extension = '';

      if (_selectedFormat == ExportFormat.json) {
        fileContent = const JsonEncoder.withIndent('  ').convert(exportData);
        extension = 'json';
      } else if (_selectedFormat == ExportFormat.csv) {
        fileContent = _convertToCsv(exportData);
        extension = 'csv';
      }

      Uint8List fileBytes = Uint8List.fromList(utf8.encode(fileContent));

      final dateStr = DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');
      final defaultFileName = 'notes_backup_$dateStr.$extension';

      Uri? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Export File',
        fileName: defaultFileName,
        bytes: fileBytes,
      );

      if (outputFile == null) {
        AppLogger.d('ExportNotesPage: Export canceled by user');
        return;
      }

      AppLogger.d('ExportNotesPage: Exported ${notesToExport.length} notes to $outputFile');

      if (mounted) {
        SnackBarManager.show(
          msg: 'Exported ${notesToExport.length} notes successfully!',
          type: SnackBarMessageType.acknowledgment,
        );
      }
    } catch (e, st) {
      AppLogger.e('ExportNotesPage: Failed to export notes', error: e, stack: st);
      if (mounted) {
        SnackBarManager.show(
          msg: 'Failed to export',
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

  String _convertToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln(headers.join(','));

    for (var row in data) {
      final values = headers.map((header) {
        final val = row[header];
        if (val == null) return '';

        String stringVal = val.toString().replaceAll('"', '""');
        if (stringVal.contains(',') || stringVal.contains('\n')) {
          return '"$stringVal"';
        }
        return stringVal;
      }).join(',');

      csvBuffer.writeln(values);
    }

    return csvBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.export,
      body: _isExporting
          ? const Center(child: CircularProgressIndicator())
          : Center(
            // ConstrainedBox prevents UI from stretching across the entire monitor
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                // controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                children: [
                  // FORMAT SELECTION
                  Text(
                    '1. Select Format',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: RadioGroup<ExportFormat>(
                      groupValue: _selectedFormat,
                      onChanged: (val) => setState(() => _selectedFormat = val!),
                      child: Column(
                        children: [
                          RadioListTile<ExportFormat>(
                            title: const Text('JSON (.json)'),
                            subtitle: const Text('Best for importing back into the app'),
                            value: ExportFormat.json,
                          ),
                          RadioListTile<ExportFormat>(
                            title: const Text('CSV (.csv)'),
                            subtitle: const Text('Best for viewing in Excel or Sheets'),
                            value: ExportFormat.csv,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SECURITY SETTINGS
                  Text(
                    '2. Security',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: CheckboxListTile(
                      title: const Text('Include password-protected notes'),
                      subtitle: const Text('Requires password verification'),
                      value: _includeLockedNotes,
                      onChanged: _handleLockedNotesToggle,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FIELD SELECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '3. Fields to Export',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final allSelected = _fieldSelections.values.every((v) => v);
                            _fieldSelections.updateAll((key, value) => !allSelected);
                          });
                        },
                        child: const Text('Select All / None'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        // By giving children a fixed width, Wrap acts like a neat grid on desktop
                        children: _fieldSelections.keys.map((field) {
                          return SizedBox(
                            width: 170, // Fixed width for columns
                            child: CheckboxListTile(
                              dense: true, // Keeps it compact
                              contentPadding: EdgeInsets.zero, // Removes default messy padding
                              title: Text(field, style: Theme.of(context).textTheme.bodySmall),
                              value: _fieldSelections[field],
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setState(() {
                                  _fieldSelections[field] = val ?? false;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // EXPORT BUTTON
                  SizedBox(
                    height: 54, // Taller, highly clickable button
                    child: FilledButton.icon(
                      onPressed: _exportNotes,
                      icon: const Icon(Icons.download),
                      label: Text('Generate Export File', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
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