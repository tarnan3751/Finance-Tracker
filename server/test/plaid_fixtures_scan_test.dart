// The committed Plaid fixtures carry no secret: every file under test/fixtures/plaid/ is
// scanned for live token prefixes, a client_id or secret key whose value is not redacted,
// and any run of 24 or more hex digits (Plaid's keys and tokens are hex). A capture added
// later must pass the same scan (docs/reference/testing-tools.md).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _hexRun = RegExp('[0-9a-fA-F]{24,}');
const _tokenPrefixes = ['access-sandbox-', 'public-sandbox-', 'link-sandbox-'];

/// Every (key, value) pair in [node], at any depth.
Iterable<(String, Object?)> _pairs(Object? node) sync* {
  switch (node) {
    case final Map<String, Object?> m:
      for (final MapEntry(:key, :value) in m.entries) {
        yield (key, value);
        yield* _pairs(value);
      }
    case final List<Object?> l:
      for (final v in l) {
        yield* _pairs(v);
      }
  }
}

void main() {
  final files =
      Directory(p.join('test', 'fixtures', 'plaid'))
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the fixtures are there', () => expect(files, hasLength(26)));

  for (final file in files) {
    test('${p.basename(file.path)} carries no secret', () {
      final text = file.readAsStringSync();
      for (final prefix in _tokenPrefixes) {
        expect(text, isNot(contains(prefix)));
      }
      expect(_hexRun.firstMatch(text)?[0], isNull, reason: 'a hex run');
      for (final (key, value) in _pairs(jsonDecode(text))) {
        if (key == 'client_id' || key == 'secret') {
          expect(
            value,
            isA<String>().having((v) => v, 'value', contains('REDACTED')),
          );
        }
        if (key.endsWith('_token') && value is String) {
          expect(value, endsWith('-REDACTED'), reason: key);
        }
      }
    });
  }
}
