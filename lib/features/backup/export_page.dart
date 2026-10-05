import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../database/drift/notes/notes_dao.dart';
import '../lock/password_prompt_helper.dart';

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
    'isPinned': false,
    'isArchived': false,
    'isLocked': false,
    'position': false,
    'tags': true,
    'reminderAt': false,
    'hasAttachments': false,
    'contentType': false,
    'isShared': false,
    'folderId': false,
    'ownerUid': false,
    'ownerEmail': false,
    'createdAt': true,
    'updatedAt': true,
    'deletedAt': false,
    'cloudSyncStatus': false,
    'localSyncStatus': false,
    'versionCounter': false,
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
        if (note.isLocked && !_includeLockedNotes) return false;
        return true;
      }).toList();

      if (notesToExport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No notes available to export.')),
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
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${notesToExport.length} notes successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Notes'),
        centerTitle: true, // Looks cleaner on wider screens
      ),
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
                  const Text(
                    '1. Select Format',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Text(
                    '2. Security',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const Text(
                        '3. Fields to Export',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              title: Text(field, style: const TextStyle(fontSize: 13)),
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
                      label: const Text('Generate Export File', style: TextStyle(fontSize: 16)),
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