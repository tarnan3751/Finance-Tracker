/// Password hashing with Argon2id, stored as PHC strings (`docs/reference/server.md`,
/// **Passwords**).
///
/// A hash is `$argon2id$v=19$m=<KiB>,t=<iterations>,p=<lanes>$<salt>$<hash>` with
/// unpadded standard base64, a 16-byte random salt and a 32-byte hash. Verification reads
/// the parameters from the stored string, so hashes made under older parameters keep
/// verifying; [PasswordHasher.needsRehash] says when a successful login should store a
/// fresh hash under the current ones.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:finance_tracker_server/src/config.dart';

/// A parsed PHC string.
final class PhcHash {
  /// A hash with its parameters.
  const PhcHash({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
    required this.salt,
    required this.hash,
  });

  /// Parses [text]; a [FormatException] when it is not an Argon2id v19 PHC string.
  factory PhcHash.parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) {
      throw const FormatException('Not an Argon2id PHC string');
    }
    return PhcHash(
      memoryKib: int.parse(match[1]!),
      iterations: int.parse(match[2]!),
      parallelism: int.parse(match[3]!),
      salt: _decode(match[4]!),
      hash: _decode(match[5]!),
    );
  }

  static final _pattern = RegExp(
    r'^\$argon2id\$v=19\$m=([0-9]{1,9}),t=([0-9]{1,9}),p=([0-9]{1,3})'
    r'\$([A-Za-z0-9+/]+)\$([A-Za-z0-9+/]+)$',
  );

  /// `m`, in KiB.
  final int memoryKib;

  /// `t`.
  final int iterations;

  /// `p`.
  final int parallelism;

  /// The salt.
  final List<int> salt;

  /// The derived hash.
  final List<int> hash;

  /// The PHC string.
  String encode() =>
      '\$argon2id\$v=19\$m=$memoryKib,t=$iterations,p=$parallelism'
      '\$${_encode(salt)}\$${_encode(hash)}';

  static String _encode(List<int> bytes) =>
      base64.encode(bytes).replaceAll('=', '');

  static List<int> _decode(String text) =>
      base64.decode(base64.normalize(text));
}

/// Hashes and verifies passwords with Argon2id under [parameters].
final class PasswordHasher {
  /// A hasher for new hashes under [parameters]; [random] makes salts.
  PasswordHasher(this.parameters, {Random? random})
    : _random = random ?? Random.secure();

  /// The parameters of new hashes.
  final Argon2Parameters parameters;

  final Random _random;

  static const _saltLength = 16;
  static const _hashLength = 32;

  /// A PHC string for [password].
  Future<String> hash(String password) async {
    final salt = [for (var i = 0; i < _saltLength; i++) _random.nextInt(256)];
    final derived = await _derive(
      password,
      salt,
      memoryKib: parameters.memoryKib,
      iterations: parameters.iterations,
      parallelism: parameters.parallelism,
      length: _hashLength,
    );
    return PhcHash(
      memoryKib: parameters.memoryKib,
      iterations: parameters.iterations,
      parallelism: parameters.parallelism,
      salt: salt,
      hash: derived,
    ).encode();
  }

  /// Whether [password] matches [phc], compared in constant time. A malformed [phc] is a
  /// [FormatException].
  Future<bool> verify(String password, String phc) async {
    final stored = PhcHash.parse(phc);
    final derived = await _derive(
      password,
      stored.salt,
      memoryKib: stored.memoryKib,
      iterations: stored.iterations,
      parallelism: stored.parallelism,
      length: stored.hash.length,
    );
    return constantTimeEquals(derived, stored.hash);
  }

  /// Whether [phc] was made under parameters other than [parameters].
  bool needsRehash(String phc) {
    final stored = PhcHash.parse(phc);
    return stored.memoryKib != parameters.memoryKib ||
        stored.iterations != parameters.iterations ||
        stored.parallelism != parameters.parallelism ||
        stored.hash.length != _hashLength;
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt, {
    required int memoryKib,
    required int iterations,
    required int parallelism,
    required int length,
  }) async {
    final key = await Argon2id(
      parallelism: parallelism,
      memory: memoryKib,
      iterations: iterations,
      hashLength: length,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return key.extractBytes();
  }
}

/// Whether [a] and [b] are equal, in time that depends only on their lengths.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
