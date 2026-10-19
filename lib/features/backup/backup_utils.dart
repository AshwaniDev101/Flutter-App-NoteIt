import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../database/drift/local_database.dart';

class BackupPreviewResult {
  final int notesCount;
  final int foldersCount;
  final DateTime? exportedAt;
  final String? appName;
  final List<Map<String, dynamic>> rawFolderMaps;
  final List<Map<String, dynamic>> rawNoteMaps;

  BackupPreviewResult({
    required this.notesCount,
    required this.foldersCount,
    this.exportedAt,
    this.appName,
    required this.rawFolderMaps,
    required this.rawNoteMaps,
  });
}

class BackupUtils {
  /// Safely converts various date/timestamp formats (int epoch ms, String, DateTime) into UTC DateTime
  static DateTime? parseToDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.toUtc();
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input, isUtc: true);
    }
    if (input is double) {
      return DateTime.fromMillisecondsSinceEpoch(input.toInt(), isUtc: true);
    }

    final str = input.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    final intVal = int.tryParse(str);
    if (intVal != null && intVal > 100000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal, isUtc: true);
    }

    try {
      return DateTime.parse(str).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Safely converts various date/timestamp formats into ISO 8601 String for Drift serializer
  static String? parseToIso8601String(dynamic input) {
    final dt = parseToDateTime(input);
    return dt?.toIso8601String();
  }

  /// Inspects raw backup file content and returns structured preview info
  static BackupPreviewResult inspectBackupFile(String fileString, String fileExtension) {
    List<Map<String, dynamic>> rawFolderMaps = [];
    List<Map<String, dynamic>> rawNoteMaps = [];
    DateTime? exportedAt;
    String? appName;

    final ext = fileExtension.toLowerCase().replaceAll('.', '');

    if (ext == 'json') {
      try {
        final decoded = jsonDecode(fileString);
        if (decoded is Map<String, dynamic>) {
          appName = decoded['appName']?.toString();
          exportedAt = parseToDateTime(decoded['exportedAt']);

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
      } catch (_) {}
    } else if (ext == 'csv') {
      final csvMaps = parseCsvToMaps(fileString);
      if (csvMaps.isNotEmpty) {
        final firstKeys = csvMaps.first.keys.toSet();
        // Check if CSV represents Folders only or Notes
        if (firstKeys.contains('name') && !firstKeys.contains('content') && !firstKeys.contains('title')) {
          rawFolderMaps = csvMaps;
        } else {
          rawNoteMaps = csvMaps;
        }
      }
    }

    return BackupPreviewResult(
      notesCount: rawNoteMaps.length,
      foldersCount: rawFolderMaps.length,
      exportedAt: exportedAt,
      appName: appName,
      rawFolderMaps: rawFolderMaps,
      rawNoteMaps: rawNoteMaps,
    );
  }

  /// Encodes list of maps into RFC-4180 compliant CSV string
  static String encodeCsv(List<String> headers, List<Map<String, dynamic>> rows) {
    final StringBuffer buffer = StringBuffer();

    // Header line
    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    // Data rows
    for (var row in rows) {
      final line = headers.map((header) {
        final val = row[header];
        if (val == null) return '';
        return _escapeCsvCell(val.toString());
      }).join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String _escapeCsvCell(String input) {
    final String escaped = input.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('\r') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  /// RFC-4180 compliant CSV Parser handling quotes, escaped quotes, and multiline cells
  static List<List<String>> parseCsvToRows(String input) {
    final rows = <List<String>>[];
    final currentCell = StringBuffer();
    final currentRow = <String>[];
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentCell.write('"');
            i++; // Skip escaped quote
          } else {
            inQuotes = false;
          }
        } else {
          currentCell.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentCell.toString());
          currentCell.clear();
          if (currentRow.any((cell) => cell.isNotEmpty) || currentRow.length > 1) {
            rows.add(List.from(currentRow));
          }
          currentRow.clear();
        } else {
          currentCell.write(char);
        }
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (currentRow.any((cell) => cell.isNotEmpty) || currentRow.length > 1) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Parses CSV rows into Maps based on header row
  static List<Map<String, dynamic>> parseCsvToMaps(String csvString) {
    final rows = parseCsvToRows(csvString);
    if (rows.length < 2) return [];

    final headers = rows.first.map((h) => h.trim()).toList();
    final List<Map<String, dynamic>> results = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final Map<String, dynamic> rowMap = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < row.length) {
          String val = row[j];
          String trimmedVal = val.trim();

          if (trimmedVal == 'null' || trimmedVal.isEmpty) {
            rowMap[headers[j]] = null;
          } else if (trimmedVal == 'true') {
            rowMap[headers[j]] = true;
          } else if (trimmedVal == 'false') {
            rowMap[headers[j]] = false;
          } else if (int.tryParse(trimmedVal) != null) {
            rowMap[headers[j]] = int.parse(trimmedVal);
          } else {
            rowMap[headers[j]] = val;
          }
        }
      }
      if (rowMap.isNotEmpty) {
        results.add(rowMap);
      }
    }

    return results;
  }

  /// Adjusts timestamps in folder/note maps so creation/update timestamps are set to `now`
  /// while preserving original relative creation order with 1ms increments.
  static void applyFreshTimestamps({
    required List<Map<String, dynamic>> folderMaps,
    required List<Map<String, dynamic>> noteMaps,
  }) {
    final baseNow = DateTime.now().toUtc();

    // 1. Process Folders
    if (folderMaps.isNotEmpty) {
      folderMaps.sort((a, b) => _compareTimestamps(a['createdAt'], b['createdAt']));
      for (int i = 0; i < folderMaps.length; i++) {
        final newTime = baseNow.add(Duration(milliseconds: i)).toIso8601String();
        folderMaps[i]['createdAt'] = newTime;
        folderMaps[i]['updatedAt'] = newTime;
      }
    }

    // 2. Process Notes
    if (noteMaps.isNotEmpty) {
      noteMaps.sort((a, b) => _compareTimestamps(a['createdAt'], b['createdAt']));
      final noteBaseNow = baseNow.add(Duration(milliseconds: folderMaps.length));
      for (int i = 0; i < noteMaps.length; i++) {
        final newTime = noteBaseNow.add(Duration(milliseconds: i)).toIso8601String();
        noteMaps[i]['createdAt'] = newTime;
        noteMaps[i]['updatedAt'] = newTime;
      }
    }
  }

  /// Generates new unique UUIDs for folders and notes, remapping folderId references.
  static void prepareForDuplicateImport({
    required List<Map<String, dynamic>> folderMaps,
    required List<Map<String, dynamic>> noteMaps,
  }) {
    final Map<String, String> uuidRemap = {};

    for (var fMap in folderMaps) {
      final oldUuid = fMap['uuid']?.toString();
      final newUuid = const Uuid().v4();
      if (oldUuid != null && oldUuid.isNotEmpty) {
        uuidRemap[oldUuid] = newUuid;
      }
      fMap['uuid'] = newUuid;
    }

    for (var nMap in noteMaps) {
      nMap['uuid'] = const Uuid().v4();
      final oldFolderId = nMap['folderId']?.toString();
      if (oldFolderId != null && uuidRemap.containsKey(oldFolderId)) {
        nMap['folderId'] = uuidRemap[oldFolderId];
      }
    }
  }

  static int _compareTimestamps(dynamic a, dynamic b) {
    final dtA = parseToDateTime(a);
    final dtB = parseToDateTime(b);
    if (dtA == null && dtB == null) return 0;
    if (dtA == null) return -1;
    if (dtB == null) return 1;
    return dtA.compareTo(dtB);
  }

  static Folder sanitizeFolder(Map<String, dynamic> rawMap) {
    final map = Map<String, dynamic>.from(rawMap);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    map['uuid'] ??= 'folder-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 8)}';
    map['name'] ??= 'Untitled Folder';

    if (map['colorIndex'] is! int) {
      map['colorIndex'] = int.tryParse(map['colorIndex']?.toString() ?? '') ?? 0;
    }

    map['createdAt'] = parseToIso8601String(map['createdAt']) ?? nowIso;
    map['updatedAt'] = parseToIso8601String(map['updatedAt']) ?? map['createdAt'];
    map['deletedAt'] = parseToIso8601String(map['deletedAt']);
    map['pinnedAt'] = parseToIso8601String(map['pinnedAt']);

    map['updateCounter'] = map['updateCounter'] is int ? map['updateCounter'] : int.tryParse(map['updateCounter']?.toString() ?? '') ?? 1;
    map['cloudSyncStatus'] = map['cloudSyncStatus'] is int ? map['cloudSyncStatus'] : int.tryParse(map['cloudSyncStatus']?.toString() ?? '') ?? 0;
    map['localSyncStatus'] = map['localSyncStatus'] is int ? map['localSyncStatus'] : int.tryParse(map['localSyncStatus']?.toString() ?? '') ?? 0;

    return Folder.fromJson(map);
  }

  static Note sanitizeNote(Map<String, dynamic> rawMap) {
    final map = Map<String, dynamic>.from(rawMap);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    map['uuid'] ??= 'restored-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 8)}';
    map['title'] ??= 'Untitled Note';
    map['content'] ??= '';

    if (map['color'] is! int) {
      map['color'] = int.tryParse(map['color']?.toString() ?? '') ?? 4294967295;
    }

    // Backward compatibility for legacy boolean fields
    if (map['pinnedAt'] == null && map['isPinned'] == true) {
      map['pinnedAt'] = nowIso;
    }
    if (map['archivedAt'] == null && map['isArchived'] == true) {
      map['archivedAt'] = nowIso;
    }
    if (map['lockedAt'] == null && map['isLocked'] == true) {
      map['lockedAt'] = nowIso;
    }
    if (map['updateCounter'] == null && map['versionCounter'] != null) {
      map['updateCounter'] = map['versionCounter'];
    }

    // Parse all date fields cleanly to ISO 8601 strings
    map['createdAt'] = parseToIso8601String(map['createdAt']) ?? nowIso;
    map['updatedAt'] = parseToIso8601String(map['updatedAt']) ?? map['createdAt'];
    map['pinnedAt'] = parseToIso8601String(map['pinnedAt']);
    map['archivedAt'] = parseToIso8601String(map['archivedAt']);
    map['lockedAt'] = parseToIso8601String(map['lockedAt']);
    map['reminderAt'] = parseToIso8601String(map['reminderAt']);
    map['deletedAt'] = parseToIso8601String(map['deletedAt']);

    map['updateCounter'] = map['updateCounter'] is int ? map['updateCounter'] : int.tryParse(map['updateCounter']?.toString() ?? '') ?? 1;
    map['schemaVersion'] = map['schemaVersion'] is int ? map['schemaVersion'] : int.tryParse(map['schemaVersion']?.toString() ?? '') ?? 1;
    map['contentVersion'] = map['contentVersion'] is int ? map['contentVersion'] : int.tryParse(map['contentVersion']?.toString() ?? '') ?? 1;
    map['cloudSyncStatus'] = map['cloudSyncStatus'] is int ? map['cloudSyncStatus'] : int.tryParse(map['cloudSyncStatus']?.toString() ?? '') ?? 0;
    map['localSyncStatus'] = map['localSyncStatus'] is int ? map['localSyncStatus'] : int.tryParse(map['localSyncStatus']?.toString() ?? '') ?? 0;

    return Note.fromJson(map);
  }
}
