import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../database/drift/local_database.dart';
import '../../database/drift/notes/notes_dao.dart';

class ImportNotesPage extends ConsumerStatefulWidget {
  const ImportNotesPage({super.key});

  @override
  ConsumerState<ImportNotesPage> createState() => _ImportNotesPageState();
}

class _ImportNotesPageState extends ConsumerState<ImportNotesPage> {
  PlatformFile? _selectedFile;
  bool _isImporting = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _pickFile() async {
    try {

      PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _statusMessage = null;
          _isError = false;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _processImport() async {
    if (_selectedFile == null) return;

    setState(() {
      _isImporting = true;
      _statusMessage = 'Reading file...';
      _isError = false;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final fileString = utf8.decode(bytes);

      final notesDao = ref.read(notesDaoProvider);
      List<dynamic> rawData = [];

      if (_selectedFile!.extension == 'json') {
        rawData = jsonDecode(fileString) as List<dynamic>;
      } else if (_selectedFile!.extension == 'csv') {
        rawData = _parseCsvToJson(fileString);
      }

      if (rawData.isEmpty) {
        throw Exception("The file is empty or formatted incorrectly.");
      }

      setState(() {
        _statusMessage = 'Restoring ${rawData.length} notes...';
      });

      List<Note> parsedNotes = [];
      int failedCount = 0;

      for (var rawMap in rawData) {
        try {
          final map = rawMap as Map<String, dynamic>;

          map['uuid'] ??= 'restored-${DateTime.now().millisecondsSinceEpoch}-${map.hashCode}';
          map['title'] ??= 'Untitled Note';
          map['content'] ??= '';
          map['color'] ??= 4294967295; // Default white/transparent
          map['isPinned'] ??= false;
          map['isArchived'] ??= false;
          map['isLocked'] ??= false;
          map['position'] ??= 0;
          map['hasAttachments'] ??= false;
          map['isShared'] ??= false;
          map['cloudSyncStatus'] ??= 0;
          map['localSyncStatus'] ??= 0;
          map['versionCounter'] ??= 1;
          map['contentType'] ??= 'plain_text';
          map['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;
          map['updatedAt'] ??= DateTime.now().millisecondsSinceEpoch;

          parsedNotes.add(Note.fromJson(map));
        } catch (e) {
          debugPrint("Failed to parse a note: $e");
          failedCount++; // Keep track of failures instead of crashing the whole process
        }
      }

      if (parsedNotes.isEmpty) {
        throw Exception("Failed to parse all notes. Data format might be incompatible.");
      }

      // Insert/Update into database
      await notesDao.importNotes(parsedNotes);

      setState(() {
        _isImporting = false;
        _isError = failedCount > 0;
        _statusMessage = failedCount > 0
            ? 'Imported ${parsedNotes.length} notes, but $failedCount failed.'
            : 'Successfully imported ${parsedNotes.length} notes!';
      });

    } catch (e) {
      setState(() {
        _isImporting = false;
        _isError = true;
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  List<Map<String, dynamic>> _parseCsvToJson(String csvString) {
    if (csvString.trim().isEmpty) return [];

    final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length < 2) return [];

    final headers = lines.first.split(',');
    List<Map<String, dynamic>> results = [];

    for (int i = 1; i < lines.length; i++) {
      final RegExp csvSplitter = RegExp(r',(?=(?:[^"]*"[^"]*")*[^"]*$)');
      final values = lines[i].split(csvSplitter);

      Map<String, dynamic> rowMap = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < values.length) {
          String val = values[j].trim();

          if (val.startsWith('"') && val.endsWith('"')) {
            val = val.substring(1, val.length - 1).replaceAll('""', '"');
          }

          // Properly handle nulls so Drift doesn't try to parse 'null' as a String
          if (val == 'null' || val.isEmpty) {
            rowMap[headers[j]] = null;
          } else if (val == 'true') {
            rowMap[headers[j]] = true;
          } else if (val == 'false') {
            rowMap[headers[j]] = false;
          } else if (int.tryParse(val) != null) {
            rowMap[headers[j]] = int.parse(val);
          } else {
            rowMap[headers[j]] = val;
          }
        }
      }
      results.add(rowMap);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Notes'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            children: [
              Text(
                'Restore your Backup',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a previously exported .json or .csv file to restore your notes. '
                    'If a note already exists, it will be updated. JSON format is highly recommended for perfect restoration.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null
                            ? 'Selected: ${_selectedFile!.name}'
                            : 'No file selected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Choose File'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isError
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isError ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: (_selectedFile == null || _isImporting) ? null : _processImport,
                  icon: _isImporting
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                      : const Icon(Icons.restore),
                  label: Text(
                    _isImporting ? 'Processing...' : 'Restore Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}