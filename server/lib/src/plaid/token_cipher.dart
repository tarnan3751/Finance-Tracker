/// Plaid access tokens encrypted at rest (`docs/reference/server.md`, **Items**).
///
/// AES-256-GCM with the 32-byte `TOKEN_ENCRYPTION_KEY`, a random 12-byte nonce per
/// encryption, and the Item's own id as associated data, so a ciphertext copied onto
/// another Item's row fails authentication. The stored ciphertext is the cipher text
/// followed by the 16-byte tag.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A stored ciphertext and its nonce.
typedef SealedToken = ({Uint8List ciphertext, Uint8List nonce});

/// Encrypts and decrypts access tokens.
final class TokenCipher {
  /// A cipher keyed with [key] (32 bytes).
  TokenCipher(List<int> key) : _key = SecretKey(List<int>.unmodifiable(key)) {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', 'must be 32 bytes');
    }
  }

  static final _algorithm = AesGcm.with256bits();

  final SecretKey _key;

  /// [token] sealed for the Item [itemId].
  Future<SealedToken> seal(String token, {required String itemId}) async {
    final box = await _algorithm.encrypt(
      utf8.encode(token),
      secretKey: _key,
      aad: utf8.encode(itemId),
    );
    return (
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      nonce: Uint8List.fromList(box.nonce),
    );
  }

  /// The token sealed in [ciphertext] for [itemId]. A tampered ciphertext, nonce or Item id
  /// throws [SecretBoxAuthenticationError].
  Future<String> open(
    List<int> ciphertext, {
    required List<int> nonce,
    required String itemId,
  }) async {
    final macLength = _algorithm.macAlgorithm.macLength;
    if (ciphertext.length < macLength) throw SecretBoxAuthenticationError();
    final split = ciphertext.length - macLength;
    final clear = await _algorithm.decrypt(
      SecretBox(
        ciphertext.sublist(0, split),
        nonce: nonce,
        mac: Mac(ciphertext.sublist(split)),
      ),
      secretKey: _key,
      aad: utf8.encode(itemId),
    );
    return utf8.decode(clear);
  }
}
