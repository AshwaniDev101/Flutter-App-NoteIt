import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart';
import 'package:noteit/core/util/logger.dart';

/// Core Cryptographic Engine for Noteit.
///
/// Implements zero-knowledge end-to-end encryption protocols:
/// - KDF Key Derivation: PBKDF2 (SHA-256, 600,000 iterations) with 16-byte random salt.
/// - Authenticated Encryption: AES-256-GCM with 12-byte IVs and MAC AuthTags.
/// - Zero-Knowledge Validation Markers: Random gibberish canary payloads verified via `SecretBoxAuthenticationError`.
/// - Recovery Seed Phrase: BIP39 12-word mnemonic phrase derivation.
class CryptoEngine {
  CryptoEngine._();

  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final _secureRandom = Random.secure();

  /// Generates a cryptographically secure random byte array of [length] (defaults to 16 bytes).
  static Uint8List generateRandomBytes([int length = 16]) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 32-byte (256-bit) Master AES Key from [password] and [salt] using PBKDF2 (SHA-256, 600k iterations).
  static Future<SecretKeyData> deriveMasterKey(
    String password, {
    required List<int> salt,
    int iterations = 600000,
  }) async {
    try {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );
      final secretKey = SecretKey(utf8.encode(password));
      final derivedKey = await pbkdf2.deriveKey(
        secretKey: secretKey,
        nonce: salt,
      );
      return await derivedKey.extract();
    } catch (e, st) {
      AppLogger.e('CryptoEngine: Failed to derive master key via PBKDF2', error: e, stack: st);
      rethrow;
    }
  }

  /// Encrypts plain text [plainText] using AES-256-GCM with the derived 32-byte [masterKey].
  /// Returns a map containing base64 encoded strings for 'iv', 'ciphertext', and 'authTag'.
  static Future<Map<String, String>> encryptPayload(
    String plainText,
    List<int> masterKey,
  ) async {
    try {
      final secretKey = SecretKey(masterKey);
      final nonce = _aesGcm.newNonce();
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plainText),
        secretKey: secretKey,
        nonce: nonce,
      );

      return {
        'iv': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'authTag': base64Encode(secretBox.mac.bytes),
      };
    } catch (e, st) {
      AppLogger.e('CryptoEngine: Failed to encrypt payload', error: e, stack: st);
      rethrow;
    }
  }

  /// Decrypts AES-256-GCM ciphertext using [masterKey].
  /// Throws [SecretBoxAuthenticationError] if authentication check fails (wrong key/corrupted payload).
  static Future<String> decryptPayload({
    required String ciphertextBase64,
    required String ivBase64,
    required String authTagBase64,
    required List<int> masterKey,
  }) async {
    try {
      final secretKey = SecretKey(masterKey);
      final cipherText = base64Decode(ciphertextBase64);
      final nonce = base64Decode(ivBase64);
      final macBytes = base64Decode(authTagBase64);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clearTextBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(clearTextBytes);
    } catch (e, st) {
      AppLogger.w('CryptoEngine: Decryption failed (invalid key or MAC auth mismatch)', e, st);
      rethrow;
    }
  }

  /// Creates a zero-knowledge validation marker ("canary payload") encrypted with [masterKey].
  /// Contains 16 bytes of random gibberish and its AES-GCM MAC AuthTag.
  static Future<Map<String, String>> createValidationMarker(
    List<int> masterKey, {
    List<int>? salt,
  }) async {
    final gibberish = generateRandomBytes(16);
    final secretKey = SecretKey(masterKey);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      gibberish,
      secretKey: secretKey,
      nonce: nonce,
    );

    final map = <String, String>{
      'iv': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'authTag': base64Encode(secretBox.mac.bytes),
    };

    if (salt != null) {
      map['salt'] = base64Encode(salt);
    }

    return map;
  }

  /// Verifies whether [masterKey] can successfully decrypt [markerData].
  /// Returns `true` if authentication succeeds, or `false` if key/password is incorrect.
  static Future<bool> verifyValidationMarker(
    Map<String, dynamic> markerData,
    List<int> masterKey,
  ) async {
    try {
      final ciphertextBase64 = markerData['ciphertext'] as String;
      final ivBase64 = markerData['iv'] as String;
      final authTagBase64 = markerData['authTag'] as String;

      final secretKey = SecretKey(masterKey);
      final cipherText = base64Decode(ciphertextBase64);
      final nonce = base64Decode(ivBase64);
      final macBytes = base64Decode(authTagBase64);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return true;
    } catch (e) {
      AppLogger.d('CryptoEngine: Validation marker verification failed (incorrect password attempt)');
      return false;
    }
  }

  /// Generates a random 12-word BIP39 recovery mnemonic seed phrase.
  static String generateRecoveryPhrase() {
    return bip39.generateMnemonic();
  }

  /// Derives a 32-byte recovery key from a list of 12 mnemonic words and salt.
  static Future<SecretKeyData> deriveRecoveryKey(
    List<String> words, {
    required List<int> salt,
  }) async {
    final mnemonic = words.join(' ').trim().toLowerCase();
    return await deriveMasterKey(mnemonic, salt: salt);
  }

  /// Encrypts raw bytes (e.g., master key) using a wrapping key (e.g., recovery key).
  static Future<String> wrapKey({
    required List<int> keyToWrap,
    required List<int> wrappingKey,
  }) async {
    final secretKey = SecretKey(wrappingKey);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      keyToWrap,
      secretKey: secretKey,
      nonce: nonce,
    );
    final jsonPayload = {
      'iv': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'authTag': base64Encode(secretBox.mac.bytes),
    };
    return jsonEncode(jsonPayload);
  }

  /// Decrypts a wrapped key JSON payload using a wrapping key (e.g., recovery key).
  static Future<Uint8List> unwrapKey({
    required String wrappedKeyJson,
    required List<int> wrappingKey,
  }) async {
    final map = jsonDecode(wrappedKeyJson) as Map<String, dynamic>;
    final ciphertextBase64 = map['ciphertext'] as String;
    final ivBase64 = map['iv'] as String;
    final authTagBase64 = map['authTag'] as String;

    final secretKey = SecretKey(wrappingKey);
    final cipherText = base64Decode(ciphertextBase64);
    final nonce = base64Decode(ivBase64);
    final macBytes = base64Decode(authTagBase64);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearTextBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(clearTextBytes);
  }
}
