// A backup's plaintext: the manifest, the dump and the receipts round-trip; the dump's
// bytes are canonical; any line that does not match the manifest (a row count, the
// dump's hash, a receipt's hash or count, a table out of order, bytes after the end)
// is damage. And the passphrase rule and its hint.
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';
import 'package:finance_tracker/features/backup/domain/passphrase_strength.dart';
import 'package:flutter_test/flutter_test.dart';

final List<BackupTable> tables = [
  const BackupTable(
    'accounts',
    ['id', 'name', 'current_balance_minor', 'hidden', 'created_at'],
    [
      ['a1', 'Checking é\n"quoted"', 123456, false, '2026-10-24T15:00:00.000Z'],
      ['a2', 'Savings', null, true, '2026-10-24T15:00:00.001Z'],
    ],
  ),
  const BackupTable('app_meta', ['key', 'value'], []),
];

final List<BackupReceipt> receipts = [
  BackupReceipt('receipts/t2.jpg', Uint8List.fromList([4, 5, 6])),
  BackupReceipt('receipts/t1.jpg', Uint8List.fromList([1, 2, 3])),
];

BackupManifest manifestOf(Uint8List dump, {int receipts = 2}) => BackupManifest(
  schemaVersion: 12,
  appVersion: '1.0.0+1',
  createdAt: DateTime.utc(2026, 10, 30, 9, 41),
  userId: 'user-1',
  deviceId: 'device-1',
  tables: {for (final BackupTable t in tables) t.name: t.rows.length},
  receipts: receipts,
  dumpSha256: sha256Hex(dump),
);

Uint8List plaintext() {
  final Uint8List dump = encodeDump(tables);
  return encodePlaintext(manifestOf(dump), dump, receipts);
}

List<String> lines(Uint8List plain) =>
    const LineSplitter().convert(utf8.decode(plain));

Uint8List join(List<String> lines) =>
    Uint8List.fromList(utf8.encode('${lines.join('\n')}\n'));

void main() {
  test('round-trips, the receipts in path order', () {
    final BackupContent content = decodePlaintext(plaintext());
    expect(content.manifest.toJson(), manifestOf(encodeDump(tables)).toJson());
    expect(content.tables.map((t) => t.name), ['accounts', 'app_meta']);
    expect(content.tables.first.columns, tables.first.columns);
    expect(content.tables.first.rows, tables.first.rows);
    expect(content.receipts.map((r) => r.path), [
      'receipts/t1.jpg',
      'receipts/t2.jpg',
    ]);
    expect(content.receipts.first.bytes, [1, 2, 3]);
    expect(content.manifest.rowCount, 2);
  });

  test('the dump is canonical: one line per header and row, in order', () {
    expect(encodeDump(tables), encodeDump(tables));
    expect(lines(encodeDump(tables)), [
      '{"table":"accounts","columns":["id","name","current_balance_minor","hidden",'
          '"created_at"],"rows":2}',
      r'["a1","Checking é\n\"quoted\"",123456,false,"2026-10-24T15:00:00.000Z"]',
      '["a2","Savings",null,true,"2026-10-24T15:00:00.001Z"]',
      '{"table":"app_meta","columns":["key","value"],"rows":0}',
    ]);
  });

  test('the manifest is the first line, its keys in a fixed order', () {
    expect(
      lines(plaintext()).first,
      '{"format":"FTBK","format_version":1,"schema_version":12,'
      '"app_version":"1.0.0+1","created_at":"2026-10-30T09:41:00.000Z",'
      '"user_id":"user-1","device_id":"device-1","tables":{"accounts":2,'
      '"app_meta":0},"receipts":2,"dump_sha256":"${sha256Hex(encodeDump(tables))}"}',
    );
  });

  group('is damage', () {
    void damaged(Uint8List plain) => expect(
      () => decodePlaintext(plain),
      throwsA(isA<BackupDamagedException>()),
    );

    test('when a row changes (the dump hash)', () {
      final List<String> l = lines(plaintext());
      l[2] = l[2].replaceFirst('123456', '123457');
      damaged(join(l));
    });

    test('when a row is missing', () {
      damaged(join(lines(plaintext())..removeAt(3)));
    });

    test('when a receipt changes, is missing or one is added', () {
      final List<String> l = lines(plaintext());
      final Map<String, Object?> r = jsonDecode(l.last) as Map<String, Object?>;
      r['bytes'] = base64.encode([9, 9, 9]);
      damaged(join([...l.sublist(0, l.length - 1), jsonEncode(r)]));
      damaged(join(l.sublist(0, l.length - 1)));
      damaged(join([...l, l.last]));
    });

    test('when the tables are out of the manifest\'s order', () {
      final Uint8List dump = encodeDump(tables.reversed.toList());
      damaged(encodePlaintext(manifestOf(dump), dump, receipts));
    });

    test(
      'when a line is not JSON, the manifest is not one, or a line is cut',
      () {
        final List<String> l = lines(plaintext());
        damaged(join([...l]..[2] = '["a1",'));
        damaged(join([...l]..[0] = '{"format":"OTHER"}'));
        final Uint8List plain = plaintext();
        damaged(Uint8List.sublistView(plain, 0, plain.length - 1));
      },
    );

    test('when the manifest names another format version than the header', () {
      final List<String> l = lines(plaintext());
      final Map<String, Object?> m =
          jsonDecode(l.first) as Map<String, Object?>;
      m['format_version'] = 2;
      damaged(join([jsonEncode(m), ...l.skip(1)]));
    });

    test('when a row has the wrong number of values', () {
      final List<String> l = lines(plaintext());
      l[3] = '["a2","Savings",null,true]';
      final Uint8List dump = join(l.sublist(1, 5));
      damaged(join([jsonEncode(manifestOf(dump).toJson()), ...l.sublist(1)]));
    });
  });

  group('the passphrase', () {
    test('needs 12 characters, counted as code points', () {
      expect(passphraseStrength('a' * 11), PassphraseStrength.tooShort);
      expect(passphraseStrength('a' * 12), PassphraseStrength.weak);
      // Eleven emoji are 22 UTF-16 units but 11 characters.
      expect(passphraseStrength('\u{1F600}' * 11), PassphraseStrength.tooShort);
    });

    test('is hinted by length and variety', () {
      expect(passphraseStrength('abcdefghijkl'), PassphraseStrength.weak);
      expect(passphraseStrength('abcdefghijklmn'), PassphraseStrength.fair);
      expect(passphraseStrength('abcdefGHIJ12'), PassphraseStrength.fair);
      expect(passphraseStrength('abcdefGHIJ12mnop'), PassphraseStrength.strong);
      expect(
        passphraseStrength('correct horse battery staple'),
        PassphraseStrength.strong,
      );
    });
  });
}
