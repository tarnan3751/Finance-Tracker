/// 64-bit FNV-1a, used to turn names into PCG32 stream selectors and to fingerprint the
/// committed golden outputs. Not a cryptographic hash: it detects change, nothing more.
library;

import 'dart:convert';

const int _offsetBasis = 0xcbf29ce484222325;
const int _prime = 0x100000001b3;

/// The FNV-1a hash of [bytes]. Dart's native `int` multiply wraps modulo 2^64, which is
/// exactly the arithmetic FNV-1a specifies; the result is the 64-bit pattern as an `int`.
int fnv1a64(List<int> bytes) {
  var hash = _offsetBasis;
  for (final byte in bytes) {
    hash = (hash ^ (byte & 0xff)) * _prime;
  }
  return hash;
}

/// The FNV-1a hash of [text]'s UTF-8 bytes.
int fnv1a64String(String text) => fnv1a64(utf8.encode(text));

/// [hash] as sixteen lowercase hex digits, the unsigned 64-bit form.
String fnv1a64Hex(int hash) {
  final high = (hash >>> 32).toRadixString(16).padLeft(8, '0');
  final low = (hash & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return '$high$low';
}
