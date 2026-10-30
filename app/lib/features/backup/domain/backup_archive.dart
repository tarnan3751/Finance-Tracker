/// A backup's plaintext (`docs/reference/backup.md`, **The content**): UTF-8 NDJSON,
/// one JSON value per line.
///
/// 1. The manifest ([BackupManifest]).
/// 2. The dump: per table, in the schema's order, a header line `{"table": name,
///    "columns": [...], "rows": n}` then its `n` rows, each a JSON array of the column
///    values in the header's order, sorted by primary key. The values are already in
///    their JSON form ([BackupTable]); the SHA-256 of these lines is the manifest's
///    `dump_sha256`.
/// 3. The receipts, in path order: `{"receipt": path, "sha256": hex, "bytes": base64}`.
///
/// The bytes are canonical: the same tables and receipts give the same dump, so two
/// backups of one database differ only in the manifest's `created_at` and the file's
/// salt and nonce. Pure Dart, no Flutter import.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';

/// One table of the dump: its [columns] and its [rows], each value already its JSON form
/// (null, a bool, an int or a String).
final class BackupTable {
  /// The table [name].
  const BackupTable(this.name, this.columns, this.rows);

  /// The table's SQL name.
  final String name;

  /// The column names, in the schema's order.
  final List<String> columns;

  /// The rows, sorted by primary key; each as long as [columns].
  final List<List<Object?>> rows;
}

/// One receipt file: its path (`receipts/<id>.jpg`) and its bytes.
final class BackupReceipt {
  /// The receipt at [path].
  const BackupReceipt(this.path, this.bytes);

  /// The receipt's relative path.
  final String path;

  /// Its bytes.
  final Uint8List bytes;
}

/// A backup's content, read back.
final class BackupContent {
  /// The content.
  const BackupContent(this.manifest, this.tables, this.receipts);

  /// The manifest.
  final BackupManifest manifest;

  /// The tables, in dump order.
  final List<BackupTable> tables;

  /// The receipts, in path order.
  final List<BackupReceipt> receipts;
}

const int _newline = 0x0a;

/// The dump of [tables]: their lines, each ending in a newline.
Uint8List encodeDump(List<BackupTable> tables) {
  final BytesBuilder out = BytesBuilder(copy: false);
  void line(Object? value) => out
    ..add(utf8.encode(jsonEncode(value)))
    ..addByte(_newline);
  for (final BackupTable t in tables) {
    line({'table': t.name, 'columns': t.columns, 'rows': t.rows.length});
    t.rows.forEach(line);
  }
  return out.takeBytes();
}

/// The SHA-256 of [bytes], lowercase hex.
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// The plaintext: [manifest]'s line, [dump] ([encodeDump]), then [receipts] sorted by
/// path.
Uint8List encodePlaintext(
  BackupManifest manifest,
  Uint8List dump,
  List<BackupReceipt> receipts,
) {
  final BytesBuilder out = BytesBuilder(copy: false)
    ..add(utf8.encode(jsonEncode(manifest.toJson())))
    ..addByte(_newline)
    ..add(dump);
  for (final BackupReceipt r in [
    ...receipts,
  ]..sort((a, b) => a.path.compareTo(b.path))) {
    out
      ..add(
        utf8.encode(
          jsonEncode({
            'receipt': r.path,
            'sha256': sha256Hex(r.bytes),
            'bytes': base64.encode(r.bytes),
          }),
        ),
      )
      ..addByte(_newline);
  }
  return out.takeBytes();
}

/// Reads [plaintext] back, checking it whole: the manifest (its format version the
/// header's), each table's header and row
/// count against it, the dump's SHA-256, each receipt's SHA-256 and their count, and
/// nothing after the last receipt. Throws [BackupDamagedException] on any mismatch.
BackupContent decodePlaintext(Uint8List plaintext) {
  int at = 0;
  // The bytes of the next line, without its newline; null at the end.
  Uint8List? nextLine() {
    if (at >= plaintext.length) return null;
    final int end = plaintext.indexOf(_newline, at);
    if (end < 0) throw const BackupDamagedException();
    final Uint8List line = Uint8List.sublistView(plaintext, at, end);
    at = end + 1;
    return line;
  }

  Object? json(Uint8List? line) {
    if (line == null) throw const BackupDamagedException();
    try {
      return jsonDecode(utf8.decode(line));
    } on FormatException {
      throw const BackupDamagedException();
    }
  }

  try {
    final BackupManifest manifest = BackupManifest.fromJson(json(nextLine()));
    // The header already said version 1; a manifest that says otherwise is not ours.
    if (manifest.formatVersion != backupFormatVersion) {
      throw const BackupDamagedException();
    }
    final int dumpStart = at;
    final List<BackupTable> tables = [];
    for (final MapEntry<String, int> expected in manifest.tables.entries) {
      final Map<String, Object?> header =
          json(nextLine())! as Map<String, Object?>;
      final List<String> columns = (header['columns']! as List<Object?>)
          .cast<String>();
      if (header['table'] != expected.key || header['rows'] != expected.value) {
        throw const BackupDamagedException();
      }
      final List<List<Object?>> rows = [];
      for (int i = 0; i < expected.value; i++) {
        final List<Object?> row = json(nextLine())! as List<Object?>;
        if (row.length != columns.length) throw const BackupDamagedException();
        rows.add(row);
      }
      tables.add(BackupTable(expected.key, columns, rows));
    }
    if (sha256Hex(Uint8List.sublistView(plaintext, dumpStart, at)) !=
        manifest.dumpSha256) {
      throw const BackupDamagedException();
    }
    final List<BackupReceipt> receipts = [];
    for (int i = 0; i < manifest.receipts; i++) {
      final Map<String, Object?> r = json(nextLine())! as Map<String, Object?>;
      final Uint8List bytes = base64.decode(r['bytes']! as String);
      if (sha256Hex(bytes) != r['sha256']) {
        throw const BackupDamagedException();
      }
      receipts.add(BackupReceipt(r['receipt']! as String, bytes));
    }
    if (at != plaintext.length) throw const BackupDamagedException();
    return BackupContent(manifest, tables, receipts);
  } on BackupException {
    rethrow;
  } on Object {
    // A line of the wrong shape (a cast, a missing key, bad base64).
    throw const BackupDamagedException();
  }
}
