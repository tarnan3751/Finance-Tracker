/// What an import leaves on the device (`docs/reference/import.md`, **Presets** and
/// **Imports**): the mapping saved per header ([ImportPreset], `app_meta`
/// `import_presets`) and the record of each import ([ImportBatch], `app_meta`
/// `import_history`), both JSON lists, newest first, at most [importRecordsKept]. They are
/// device-local and never synced. Pure Dart.
///
/// A preset names each column by its header text and its occurrence among headers with
/// that text, so it reads back against the header it was saved for. A value that does
/// not decode reads as an empty list ([ImportRecordsFormatException] tells the caller,
/// which logs only its type), so a damaged entry never blocks an import.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:shared_models/shared_models.dart';

/// How many presets and how many imports are kept.
const int importRecordsKept = 20;

/// The signature of a header row: the SHA-256, lower-case hex, of its fields trimmed and
/// joined by U+001F.
String headerSignature(List<String> header) => sha256
    .convert(utf8.encode(header.map((f) => f.trim()).join('\u001f')))
    .toString();

/// A stored list that did not decode.
final class ImportRecordsFormatException implements Exception {
  /// The exception.
  const ImportRecordsFormatException();

  @override
  String toString() => 'ImportRecordsFormatException';
}

/// A mapping remembered for a header.
final class ImportPreset {
  /// The preset for the header whose [headerSignature] is [signature].
  const ImportPreset({
    required this.signature,
    required this.columns,
    required this.debitCredit,
    required this.dateFormat,
    required this.separator,
    required this.outflowsNegative,
    required this.delimiter,
    required this.headerRow,
    required this.accountId,
    required this.savedAt,
  });

  /// The preset of [mapping] over [header], the row at [headerRow] of a file split on
  /// [delimiter], into account [accountId].
  factory ImportPreset.of(
    List<String> header,
    ImportMapping mapping, {
    required String delimiter,
    required int headerRow,
    required String? accountId,
    required DateTime savedAt,
  }) {
    final List<String> names = [for (final String f in header) f.trim()];
    return ImportPreset(
      signature: headerSignature(header),
      columns: {
        for (final MapEntry(key: ImportRole role, value: int column)
            in mapping.columns.entries)
          if (column < names.length)
            role: (
              name: names[column],
              occurrence: names
                  .sublist(0, column)
                  .where((n) => n == names[column])
                  .length,
            ),
      },
      debitCredit: mapping.debitCredit,
      dateFormat: mapping.dateFormat,
      separator: mapping.separator,
      outflowsNegative: mapping.outflowsNegative,
      delimiter: delimiter,
      headerRow: headerRow,
      accountId: accountId,
      savedAt: savedAt,
    );
  }

  final String signature;

  /// Each role's column, by its header text and its occurrence among equal headers.
  final Map<ImportRole, ({String name, int occurrence})> columns;
  final bool debitCredit;
  final ImportDateFormat dateFormat;
  final DecimalSeparator separator;
  final bool outflowsNegative;
  final String delimiter;
  final int headerRow;

  /// The account imported into, if it still exists.
  final String? accountId;

  /// When it was saved, a UTC instant.
  final DateTime savedAt;

  /// This preset, for account [id].
  ImportPreset withAccount(String id) => ImportPreset(
    signature: signature,
    columns: columns,
    debitCredit: debitCredit,
    dateFormat: dateFormat,
    separator: separator,
    outflowsNegative: outflowsNegative,
    delimiter: delimiter,
    headerRow: headerRow,
    accountId: id,
    savedAt: savedAt,
  );

  /// The mapping over [header]: each role at the column whose text it names.
  ImportMapping mappingFor(List<String> header) {
    final List<String> names = [for (final String f in header) f.trim()];
    final Map<ImportRole, int> resolved = {};
    for (final MapEntry(key: ImportRole role, value: ref) in columns.entries) {
      int seen = 0;
      for (int i = 0; i < names.length; i++) {
        if (names[i] != ref.name) continue;
        if (seen++ == ref.occurrence) {
          resolved[role] = i;
          break;
        }
      }
    }
    return ImportMapping(
      columns: resolved,
      debitCredit: debitCredit,
      dateFormat: dateFormat,
      separator: separator,
      outflowsNegative: outflowsNegative,
    );
  }

  Map<String, Object?> toJson() => {
    'signature': signature,
    'columns': {
      for (final MapEntry(key: ImportRole role, value: ref) in columns.entries)
        role.name: {'name': ref.name, 'occurrence': ref.occurrence},
    },
    'debit_credit': debitCredit,
    'date_format': dateFormat.name,
    'separator': separator.name,
    'outflows_negative': outflowsNegative,
    'delimiter': delimiter,
    'header_row': headerRow,
    'account_id': accountId,
    'saved_at': const UtcInstantConverter().toJson(savedAt),
  };

  static ImportPreset _fromJson(Object? json) {
    if (json case {
      'signature': final String signature,
      'columns': final Map<String, Object?> columns,
      'debit_credit': final bool debitCredit,
      'date_format': final String dateFormat,
      'separator': final String separator,
      'outflows_negative': final bool outflowsNegative,
      'delimiter': final String delimiter,
      'header_row': final int headerRow,
      'account_id': final String? accountId,
      'saved_at': final String savedAt,
    }) {
      return ImportPreset(
        signature: signature,
        columns: {
          for (final MapEntry(key: String role, value: Object? ref)
              in columns.entries)
            _byName(ImportRole.values, role): switch (ref) {
              {'name': final String name, 'occurrence': final int occurrence} =>
                (name: name, occurrence: occurrence),
              _ => throw const ImportRecordsFormatException(),
            },
        },
        debitCredit: debitCredit,
        dateFormat: _byName(ImportDateFormat.values, dateFormat),
        separator: _byName(DecimalSeparator.values, separator),
        outflowsNegative: outflowsNegative,
        delimiter: delimiter,
        headerRow: headerRow,
        accountId: accountId,
        savedAt: _instant(savedAt),
      );
    }
    throw const ImportRecordsFormatException();
  }
}

/// One import, as "Imports" lists it.
final class ImportBatch {
  /// The import [id] of [count] transactions, [transactionIds], into [accountId].
  const ImportBatch({
    required this.id,
    required this.importedAt,
    required this.fileName,
    required this.sha256,
    required this.accountId,
    required this.count,
    required this.transactionIds,
    this.pending = false,
    this.undoneAt,
  });

  final String id;

  /// When it was written, a UTC instant.
  final DateTime importedAt;

  /// The file's name, when the system gave one.
  final String? fileName;

  /// The file's SHA-256, lower-case hex: the same file imported again is warned of.
  final String sha256;
  final String accountId;
  final int count;
  final List<String> transactionIds;

  /// Whether it was recorded before its rows were written and not yet marked complete:
  /// an import cut short between the two, sorted out when the history is next read.
  final bool pending;

  /// When "Undo this import" deleted its transactions, a UTC instant; null until then.
  final DateTime? undoneAt;

  /// This batch, undone at [at].
  ImportBatch undone(DateTime at) => _with(pending: pending, undoneAt: at);

  /// This batch, its rows written.
  ImportBatch completed() => _with(pending: false, undoneAt: undoneAt);

  ImportBatch _with({required bool pending, required DateTime? undoneAt}) =>
      ImportBatch(
        id: id,
        importedAt: importedAt,
        fileName: fileName,
        sha256: sha256,
        accountId: accountId,
        count: count,
        transactionIds: transactionIds,
        pending: pending,
        undoneAt: undoneAt,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'imported_at': const UtcInstantConverter().toJson(importedAt),
    'file_name': fileName,
    'sha256': sha256,
    'account_id': accountId,
    'count': count,
    'transaction_ids': transactionIds,
    'pending': pending,
    'undone_at': undoneAt == null
        ? null
        : const UtcInstantConverter().toJson(undoneAt!),
  };

  static ImportBatch _fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'imported_at': final String importedAt,
      'file_name': final String? fileName,
      'sha256': final String sha256,
      'account_id': final String accountId,
      'count': final int count,
      'transaction_ids': final List<Object?> ids,
      'pending': final bool pending,
      'undone_at': final String? undoneAt,
    }) {
      return ImportBatch(
        id: id,
        importedAt: _instant(importedAt),
        fileName: fileName,
        sha256: sha256,
        accountId: accountId,
        count: count,
        transactionIds: [
          for (final Object? t in ids)
            t is String ? t : throw const ImportRecordsFormatException(),
        ],
        pending: pending,
        undoneAt: undoneAt == null ? null : _instant(undoneAt),
      );
    }
    throw const ImportRecordsFormatException();
  }
}

/// The presets stored as [json]; throws [ImportRecordsFormatException] when it does not
/// decode.
List<ImportPreset> decodePresets(String? json) =>
    _decodeList(json, ImportPreset._fromJson);

/// The imports stored as [json]; throws [ImportRecordsFormatException] when it does not
/// decode.
List<ImportBatch> decodeHistory(String? json) =>
    _decodeList(json, ImportBatch._fromJson);

/// [presets] with [preset] first, in place of one for the same header, at most
/// [importRecordsKept], as JSON.
String encodePresets(List<ImportPreset> presets, ImportPreset preset) =>
    jsonEncode([
      for (final ImportPreset p in [
        preset,
        ...presets.where((p) => p.signature != preset.signature),
      ].take(importRecordsKept))
        p.toJson(),
    ]);

/// [history] with [batch] in place of the one with its id, or first when it is new, at
/// most [importRecordsKept] (the oldest goes, and its Undo with it), as JSON.
String encodeHistory(List<ImportBatch> history, ImportBatch batch) {
  final bool known = history.any((b) => b.id == batch.id);
  return encodeHistoryList(
    known
        ? [for (final ImportBatch b in history) b.id == batch.id ? batch : b]
        : [batch, ...history],
  );
}

/// [history], at most [importRecordsKept], as JSON.
String encodeHistoryList(List<ImportBatch> history) => jsonEncode([
  for (final ImportBatch b in history.take(importRecordsKept)) b.toJson(),
]);

List<T> _decodeList<T>(String? json, T Function(Object?) item) {
  if (json == null || json.isEmpty) return const [];
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    throw const ImportRecordsFormatException();
  }
  if (decoded is! List<Object?>) throw const ImportRecordsFormatException();
  return [for (final Object? e in decoded) item(e)];
}

T _byName<T extends Enum>(List<T> values, String name) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  throw const ImportRecordsFormatException();
}

DateTime _instant(String text) {
  try {
    return const UtcInstantConverter().fromJson(text);
  } on FormatException {
    throw const ImportRecordsFormatException();
  }
}
