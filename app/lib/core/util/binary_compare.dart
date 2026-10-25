/// Text order as SQLite's `BINARY` collation gives it, for code that orders what the
/// database also orders (the in-memory repositories, the rules engine). Pure Dart.
library;

import 'dart:convert';

/// [a] against [b] as SQLite's `BINARY` collation compares text: by the bytes of their
/// UTF-8 encodings (Dart's `compareTo` compares UTF-16 code units, which orders characters
/// above U+FFFF differently).
int compareBinary(String a, String b) {
  final List<int> x = utf8.encode(a);
  final List<int> y = utf8.encode(b);
  final int length = x.length < y.length ? x.length : y.length;
  for (int i = 0; i < length; i++) {
    if (x[i] != y[i]) return x[i] - y[i];
  }
  return x.length - y.length;
}
