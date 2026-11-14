import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteit/core/crypto/crypto_engine.dart';
import 'package:noteit/features/lock/crypto/reencryption_isolate.dart';

void main() {
  group('CryptoEngine Tests', () {
    test('Derives 32-byte master key from password and salt', () async {
      final salt = CryptoEngine.generateRandomBytes(16);
      final keyData = await CryptoEngine.deriveMasterKey('StrongPass123!', salt: salt, iterations: 1000);
      final bytes = keyData.bytes;

      expect(bytes.length, equals(32));
    });

    test('Encrypts and decrypts payload successfully', () async {
      final salt = CryptoEngine.generateRandomBytes(16);
      final keyData = await CryptoEngine.deriveMasterKey('MyPassword', salt: salt, iterations: 1000);
      final masterKey = keyData.bytes;

      const originalText = 'Super Secret Note Content';
      final encrypted = await CryptoEngine.encryptPayload(originalText, masterKey);

      expect(encrypted.containsKey('iv'), isTrue);
      expect(encrypted.containsKey('ciphertext'), isTrue);
      expect(encrypted.containsKey('authTag'), isTrue);

      final decrypted = await CryptoEngine.decryptPayload(
        ciphertextBase64: encrypted['ciphertext']!,
        ivBase64: encrypted['iv']!,
        authTagBase64: encrypted['authTag']!,
        masterKey: masterKey,
      );

      expect(decrypted, equals(originalText));
    });

    test('Throws exception on incorrect key decryption', () async {
      final salt = CryptoEngine.generateRandomBytes(16);
      final correctKeyData = await CryptoEngine.deriveMasterKey('CorrectPassword', salt: salt, iterations: 1000);
      final wrongKeyData = await CryptoEngine.deriveMasterKey('WrongPassword', salt: salt, iterations: 1000);

      final encrypted = await CryptoEngine.encryptPayload('Secret Note', correctKeyData.bytes);

      expect(
        () async => await CryptoEngine.decryptPayload(
          ciphertextBase64: encrypted['ciphertext']!,
          ivBase64: encrypted['iv']!,
          authTagBase64: encrypted['authTag']!,
          masterKey: wrongKeyData.bytes,
        ),
        throwsA(anything),
      );
    });

    test('Creates and verifies validation marker correctly', () async {
      final salt = CryptoEngine.generateRandomBytes(16);
      final correctKeyData = await CryptoEngine.deriveMasterKey('SecretMasterPass', salt: salt, iterations: 1000);
      final wrongKeyData = await CryptoEngine.deriveMasterKey('WrongMasterPass', salt: salt, iterations: 1000);

      final marker = await CryptoEngine.createValidationMarker(correctKeyData.bytes, salt: salt);

      final isValidWithCorrectKey = await CryptoEngine.verifyValidationMarker(marker, correctKeyData.bytes);
      expect(isValidWithCorrectKey, isTrue);

      final isValidWithWrongKey = await CryptoEngine.verifyValidationMarker(marker, wrongKeyData.bytes);
      expect(isValidWithWrongKey, isFalse);
    });

    test('Generates and derives 12-word recovery mnemonic seed phrase', () async {
      final phrase = CryptoEngine.generateRecoveryPhrase();
      final words = phrase.split(' ');

      expect(words.length, equals(12));

      final salt = CryptoEngine.generateRandomBytes(16);
      final recoveryKeyData = await CryptoEngine.deriveRecoveryKey(words, salt: salt);

      expect(recoveryKeyData.bytes.length, equals(32));
    });

    test('ReencryptionIsolateWorker batch re-encrypts payloads in background isolate', () async {
      final salt = CryptoEngine.generateRandomBytes(16);
      final oldKeyData = await CryptoEngine.deriveMasterKey('OldPass123!', salt: salt, iterations: 1000);
      final newKeyData = await CryptoEngine.deriveMasterKey('NewPass456!', salt: salt, iterations: 1000);

      const note1Text = 'First secret note content';
      const note2Text = 'Second secret note content';

      final enc1 = await CryptoEngine.encryptPayload(note1Text, oldKeyData.bytes);
      final enc2 = await CryptoEngine.encryptPayload(note2Text, oldKeyData.bytes);

      final payload1 = jsonEncode({
        'ciphertext': enc1['ciphertext'],
        'authTag': enc1['authTag'],
      });
      final payload2 = jsonEncode({
        'ciphertext': enc2['ciphertext'],
        'authTag': enc2['authTag'],
      });

      final items = [
        ReencryptionItem(uuid: 'note-1', encryptedPayload: payload1, encryptionIv: enc1['iv']!),
        ReencryptionItem(uuid: 'note-2', encryptedPayload: payload2, encryptionIv: enc2['iv']!),
      ];

      final results = await ReencryptionIsolateWorker.batchReencrypt(
        notes: items,
        oldMasterKey: oldKeyData.bytes,
        newMasterKey: newKeyData.bytes,
      );

      expect(results.length, equals(2));

      final res1 = results.firstWhere((r) => r.uuid == 'note-1');
      final decrypted1 = await CryptoEngine.decryptPayload(
        ciphertextBase64: res1.ciphertext,
        ivBase64: res1.iv,
        authTagBase64: res1.authTag,
        masterKey: newKeyData.bytes,
      );
      expect(decrypted1, equals(note1Text));

      final res2 = results.firstWhere((r) => r.uuid == 'note-2');
      final decrypted2 = await CryptoEngine.decryptPayload(
        ciphertextBase64: res2.ciphertext,
        ivBase64: res2.iv,
        authTagBase64: res2.authTag,
        masterKey: newKeyData.bytes,
      );
      expect(decrypted2, equals(note2Text));
    });
  });
}
