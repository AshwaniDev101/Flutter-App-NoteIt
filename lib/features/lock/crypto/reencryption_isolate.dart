import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:noteit/core/crypto/crypto_engine.dart';
import 'package:noteit/core/util/logger.dart';

/// Item representing a locked note payload to be re-encrypted.
class ReencryptionItem {
  final String uuid;
  final String encryptedPayload;
  final String encryptionIv;

  ReencryptionItem({
    required this.uuid,
    required this.encryptedPayload,
    required this.encryptionIv,
  });
}

/// Data payload passed into the background [ReencryptionIsolateWorker] isolate.
class ReencryptionRequest {
  final List<ReencryptionItem> notes;
  final List<int> oldMasterKey;
  final List<int> newMasterKey;

  ReencryptionRequest({
    required this.notes,
    required this.oldMasterKey,
    required this.newMasterKey,
  });
}

/// Output payload returned by the background [ReencryptionIsolateWorker] isolate to the main thread.
class ReencryptedResult {
  final String uuid;
  final String ciphertext;
  final String iv;
  final String authTag;

  ReencryptedResult({
    required this.uuid,
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });
}

/// Dedicated Isolate worker for performing heavy CPU-bound batch AES decryption + re-encryption tasks.
///
/// **Architecture & Concurrency Design**:
/// To prevent SQLite database locks across isolates (e.g. `database is locked` error),
/// this isolate performs pure CPU-bound cryptographic tasks (Step A: Decrypt with oldMasterKey -> Step B: Encrypt with newMasterKey)
/// off the main UI thread in parallel, and returns the array of [ReencryptedResult] back
/// to the main thread where Drift SQLite executes the batch write on a single database connection.
class ReencryptionIsolateWorker {
  /// Offloads batch note decryption and re-encryption to a background Isolate via Flutter's `compute`.
  static Future<List<ReencryptedResult>> batchReencrypt({
    required List<ReencryptionItem> notes,
    required List<int> oldMasterKey,
    required List<int> newMasterKey,
  }) async {
    try {
      AppLogger.d("ReencryptionIsolateWorker: Starting background isolate batch re-encryption for ${notes.length} notes.");
      final request = ReencryptionRequest(
        notes: notes,
        oldMasterKey: oldMasterKey,
        newMasterKey: newMasterKey,
      );

      final results = await compute(_reencryptTask, request);
      AppLogger.d("ReencryptionIsolateWorker: Successfully re-encrypted ${results.length} notes in background isolate.");
      return results;
    } catch (e, st) {
      AppLogger.e("ReencryptionIsolateWorker: Failed during background isolate re-encryption", error: e, stack: st);
      rethrow;
    }
  }

  static Future<List<ReencryptedResult>> _reencryptTask(ReencryptionRequest request) async {
    final results = <ReencryptedResult>[];

    for (final item in request.notes) {
      String ciphertextBase64 = item.encryptedPayload;
      String authTagBase64 = item.encryptedPayload;
      if (item.encryptedPayload.startsWith('{')) {
        try {
          final map = jsonDecode(item.encryptedPayload) as Map<String, dynamic>;
          ciphertextBase64 = map['ciphertext'] as String? ?? ciphertextBase64;
          authTagBase64 = map['authTag'] as String? ?? authTagBase64;
        } catch (_) {}
      }

      // Step A: Decrypt using oldMasterKey inside background isolate
      final clearText = await CryptoEngine.decryptPayload(
        ciphertextBase64: ciphertextBase64,
        ivBase64: item.encryptionIv,
        authTagBase64: authTagBase64,
        masterKey: request.oldMasterKey,
      );

      // Step B: Re-encrypt using newMasterKey inside background isolate
      final encrypted = await CryptoEngine.encryptPayload(clearText, request.newMasterKey);

      results.add(
        ReencryptedResult(
          uuid: item.uuid,
          ciphertext: encrypted['ciphertext']!,
          iv: encrypted['iv']!,
          authTag: encrypted['authTag']!,
        ),
      );
    }

    return results;
  }
}
