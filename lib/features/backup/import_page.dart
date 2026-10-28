import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/helpers/time_helper.dart';
import '../../core/util/logger.dart';
import '../../database/drift/folders/folders_dao.dart';
import '../../shared/overlays/app_scaffold.dart';
import '../../shared/overlays/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';
import 'backup_service.dart';
import 'backup_utils.dart';

class ImportNotesPage extends ConsumerStatefulWidget {
  const ImportNotesPage({super.key});

  @override
  ConsumerState<ImportNotesPage> createState() => _ImportNotesPageState();
}

class _ImportNotesPageState extends ConsumerState<ImportNotesPage> {
  PlatformFile? _selectedFile;
  int _fileSize = 0;
  BackupPreviewResult? _previewResult;
  bool _useFreshTimestamp = false;
  bool _importAsDuplicates = false;
  bool _isImporting = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _pickFile() async {
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (file != null) {
        Uint8List? bytes;
        try {
          bytes = await file.readAsBytes();
        } catch (_) {
          if (file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
        }

        BackupPreviewResult? preview;
        int computedSize = bytes?.length ?? 0;

        if (bytes != null && bytes.isNotEmpty) {
          final contentStr = utf8.decode(bytes);
          preview = BackupUtils.inspectBackupFile(contentStr, file.extension ?? '');
        }

        setState(() {
          _selectedFile = file;
          _fileSize = computedSize;
          _previewResult = preview;
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
      _statusMessage = 'Reading backup file...';
      _isError = false;
    });

    try {
      Uint8List bytes;
      try {
        bytes = await _selectedFile!.readAsBytes();
      } catch (_) {
        if (_selectedFile!.path != null) {
          bytes = await File(_selectedFile!.path!).readAsBytes();
        } else {
          throw Exception("Unable to read backup file content.");
        }
      }

      if (bytes.isEmpty) {
        throw Exception("Failed to read file content or file is empty.");
      }

      final fileString = utf8.decode(bytes);

      final foldersDao = ref.read(foldersDaoProvider);

      List<Map<String, dynamic>> rawFolderMaps = [];
      List<Map<String, dynamic>> rawNoteMaps = [];

      final fileExt = _selectedFile!.extension?.toLowerCase();

      if (fileExt == 'json') {
        final decoded = jsonDecode(fileString);
        if (decoded is Map<String, dynamic>) {
          if (decoded['folders'] is List) {
            rawFolderMaps = (decoded['folders'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          if (decoded['notes'] is List) {
            rawNoteMaps = (decoded['notes'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          } else if (decoded['data'] is List) {
            rawNoteMaps = (decoded['data'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } else if (decoded is List) {
          rawNoteMaps = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else if (fileExt == 'csv') {
        final csvMaps = BackupUtils.parseCsvToMaps(fileString);
        if (csvMaps.isNotEmpty) {
          final firstKeys = csvMaps.first.keys.toSet();
          if (firstKeys.contains('name') && !firstKeys.contains('content') && !firstKeys.contains('title')) {
            rawFolderMaps = csvMaps;
          } else {
            rawNoteMaps = csvMaps;
          }
        }
      } else {
        throw Exception("Unsupported file format. Please choose a .json or .csv file.");
      }

      if (rawNoteMaps.isEmpty && rawFolderMaps.isEmpty) {
        throw Exception("The selected file contains no notes or folders to restore.");
      }

      // Handle folder references from CSV rows if folders array wasn't explicitly provided
      if (rawFolderMaps.isEmpty && rawNoteMaps.isNotEmpty) {
        final existingFolders = await foldersDao.getAllFolders();
        final existingFolderUuids = existingFolders.map((f) => f.uuid).toSet();
        final existingFolderNames = existingFolders.map((f) => f.name.toLowerCase()).toSet();

        final Set<String> processedFolderKeys = {};

        for (var noteMap in rawNoteMaps) {
          final String? folderId = noteMap['folderId']?.toString();
          final String? folderName = noteMap['folderName']?.toString();

          if (folderId != null && folderId.isNotEmpty) {
            if (!existingFolderUuids.contains(folderId) && !processedFolderKeys.contains(folderId)) {
              processedFolderKeys.add(folderId);
              rawFolderMaps.add({
                'uuid': folderId,
                'name': (folderName != null && folderName.isNotEmpty) ? folderName : 'Imported Folder',
                'createdAt': noteMap['createdAt'],
                'updatedAt': noteMap['updatedAt'],
              });
            }
          } else if (folderName != null && folderName.isNotEmpty) {
            final key = folderName.toLowerCase();
            if (!existingFolderNames.contains(key) && !processedFolderKeys.contains(key)) {
              processedFolderKeys.add(key);
              final generatedUuid = 'folder-${DateTime.now().millisecondsSinceEpoch}-${key.hashCode}';
              noteMap['folderId'] = generatedUuid;
              rawFolderMaps.add({
                'uuid': generatedUuid,
                'name': folderName,
                'createdAt': noteMap['createdAt'],
                'updatedAt': noteMap['updatedAt'],
              });
            }
          }
        }
      }

      setState(() {
        _statusMessage = 'Restoring ${rawNoteMaps.length} notes and ${rawFolderMaps.length} folders...';
      });

      final result = await ref.read(backupServiceProvider).executeImport(
        rawFolderMaps: rawFolderMaps,
        rawNoteMaps: rawNoteMaps,
        useFreshTimestamp: _useFreshTimestamp,
        importAsDuplicates: _importAsDuplicates,
      );

      final String successMsg = 'Successfully restored ${result.importedNotes} notes & ${result.importedFolders} folders!';

      setState(() {
        _isImporting = false;
        _isError = false;
        _statusMessage = successMsg;
      });

      SnackBarManager.show(
        msg: successMsg,
        type: SnackBarMessageType.acknowledgment,
      );
    } catch (e, st) {
      AppLogger.e('ImportNotesPage: Failed to process import', error: e, stack: st);
      setState(() {
        _isImporting = false;
        _isError = true;
        _statusMessage = 'Import failed: $e';
      });

      SnackBarManager.show(
        msg: 'Import failed',
        description: '$e',
        type: SnackBarMessageType.error,
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return TimeHelper.formatFullDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.import,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            children: [
              Text(
                'Restore Backup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a previously exported .json or .csv backup file to restore your notes and folders into the local database.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // 1. FILE PICKER CARD
              Text(
                '1. Select Backup File',
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.description_outlined : Icons.upload_file,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'No backup file selected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Size: ${_formatFileSize(_fileSize)} • Format: ${_selectedFile!.extension?.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedFile != null ? 'Change File' : 'Choose File'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // PREVIEW CARD IF FILE SELECTED
              if (_previewResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup File Inspector',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contains ${_previewResult!.notesCount} Notes & ${_previewResult!.foldersCount} Folders'
                              '${_previewResult!.exportedAt != null ? ' • Exported ${_formatDate(_previewResult!.exportedAt!)}' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 2. IMPORT OPTIONS
              Text(
                '2. Import Options',
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
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: const Text('Fresh timestamp', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Updates creation and modification dates to now, preserving relative creation order with 1 ms time difference between notes.',
                      ),
                      value: _useFreshTimestamp,
                      onChanged: _isImporting
                          ? null
                          : (val) {
                              setState(() {
                                _useFreshTimestamp = val ?? false;
                              });
                            },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: const Text('Import as new copies (Duplicate)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                        'Generates new unique IDs so existing notes and folders in your database are never overwritten.',
                      ),
                      value: _importAsDuplicates,
                      onChanged: _isImporting
                          ? null
                          : (val) {
                              setState(() {
                                _importAsDuplicates = val ?? false;
                              });
                            },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // STATUS MESSAGE CONTAINER
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isError
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _isError
                                    ? Theme.of(context).colorScheme.onErrorContainer
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // ACTION BUTTON
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: (_selectedFile == null || _isImporting) ? null : _processImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.restore),
                  label: Text(
                    _isImporting ? 'Processing Backup...' : 'Restore Notes & Folders',
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
