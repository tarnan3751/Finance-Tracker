/// The database side of a backup (`docs/reference/backup.md`, **The content**,
/// **Restore**): the canonical dump of every table, the tolerant import into a fresh
/// database, and whether an install has data a restore would overwrite.
///
/// **The dump** covers every Drift table in the schema's order (`allTables`, new tables
/// appended), each sorted by its primary key, each value in its JSON form by the column's
/// declared type: an INTEGER as an integer, a BOOLEAN as `true`/`false`, a TEXT as a
/// string (the ISO dates, the `Decimal`s), a BLOB as base64, and an audit instant (a
/// column through `UtcMillisColumnConverter`) as a UTC ISO string with milliseconds;
/// `Money` is already integer `_minor` columns beside a `currency`. The full-text
/// objects and `sqlite_sequence` are not Drift tables and are not dumped, and the tables
/// of [backupExcludedTables] (device-local: `conflicts`) are left out. A table with
/// no primary key, or a column of another type (a REAL, a Drift `dateTime()`), makes
/// [dumpDatabase] throw, so a schema change that adds one fails the gate.
///
/// **The import** runs on a database just created at the current schema, opened without
/// the full-text objects (`allowFullTextSearch: false`), so the first normal open builds
/// and fills them. With foreign keys off, in one transaction: each table in the
/// backup's order (parents before `transaction_tags` and `transaction_splits`), unknown
/// tables and columns dropped, the tables of [backupExcludedTables] ignored if present,
/// missing columns left to their SQL default (the schema policy is additive); the `app_meta` rows of [restoreDroppedMetaKeys] and the
/// full-text definition skipped; `PRAGMA foreign_key_check` must find nothing; then
/// the device's identity is reset: [DriftSyncStore.substituteNode] moves the unsynced
/// outbox, its field clocks, the persisted clock and `device_id` to a new provisional
/// node, wall and counter kept, so the restored install never stamps with its source's
/// node and its first session adopts the server's id for it. Any failure rolls the
/// whole import back. Pure Dart, no Flutter import.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// The `app_meta` keys a restore drops, so the new device works them out itself; the app
/// lock's settings describe the device they were chosen on (`features/lock/`), so the
/// restored device starts with the lock off and its flavor's screenshot default.
const Set<String> restoreDroppedMetaKeys = {
  AppMetaKeys.remindersZone,
  AppMetaKeys.remindersScheduledAt,
  AppMetaKeys.snapshotsWrittenOn,
  AppMetaKeys.lockEnabled,
  AppMetaKeys.lockTimeoutSeconds,
  AppMetaKeys.secureScreen,
};

/// The tables a backup leaves out and a restore ignores: device-local state that means
/// nothing on another install (`conflicts`, this device's sync conflicts,
/// `docs/reference/sync-app.md`, **Conflicts**).
const Set<String> backupExcludedTables = {'conflicts'};

// The tables an empty install may hold rows in: its own bookkeeping, which a restore
// replaces.
const Set<String> _bookkeeping = {'app_meta', 'sync_meta', 'app_settings'};

/// Every table of [database], dumped in one read transaction.
Future<List<BackupTable>> dumpDatabase(AppDatabase database) =>
    database.transaction(() async {
      final List<BackupTable> tables = [];
      for (final TableInfo<Table, Object?> table in database.allTables) {
        _checkDumpable(table);
        if (backupExcludedTables.contains(table.actualTableName)) continue;
        final List<GeneratedColumn> columns = table.$columns;
        final String order = table.$primaryKey
            .map((c) => '"${c.name}"')
            .join(', ');
        final List<QueryRow> rows = await database
            .customSelect(
              'SELECT ${columns.map((c) => '"${c.name}"').join(', ')} '
              'FROM "${table.actualTableName}" ORDER BY $order',
            )
            .get();
        tables.add(
          BackupTable(
            table.actualTableName,
            [for (final GeneratedColumn c in columns) c.name],
            [
              for (final QueryRow row in rows)
                [
                  for (final GeneratedColumn c in columns)
                    _toJson(c, row.data[c.name]),
                ],
            ],
          ),
        );
      }
      return tables;
    });

/// The receipt paths [tables] reference (`transactions.receipt_path`, live or deleted),
/// sorted.
List<String> referencedReceipts(List<BackupTable> tables) {
  final BackupTable transactions = tables.firstWhere(
    (t) => t.name == 'transactions',
  );
  final int column = transactions.columns.indexOf('receipt_path');
  return {
    for (final List<Object?> row in transactions.rows)
      if (row[column] case final String path) path,
  }.toList()..sort();
}

/// The `sync_meta` value under [key] in [tables], or null.
String? syncMetaIn(List<BackupTable> tables, String key) {
  final BackupTable meta = tables.firstWhere((t) => t.name == 'sync_meta');
  for (final List<Object?> row in meta.rows) {
    if (row[meta.columns.indexOf('key')] == key) {
      return row[meta.columns.indexOf('value')] as String?;
    }
  }
  return null;
}

/// Whether [database] holds anything a restore would overwrite: any row outside its
/// bookkeeping tables (`app_meta`, `sync_meta`, `app_settings`) but the seeded system
/// categories.
Future<bool> hasLocalData(AppDatabase database) async {
  for (final TableInfo<Table, Object?> table in database.allTables) {
    final String name = table.actualTableName;
    if (_bookkeeping.contains(name) || backupExcludedTables.contains(name)) {
      continue;
    }
    final String where = name == 'categories' ? ' WHERE is_system = 0' : '';
    if ((await database
            .customSelect('SELECT 1 FROM "$name"$where LIMIT 1')
            .get())
        .isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// Imports [tables] into [database], which must be new and opened without the
/// full-text objects (this file's header); [newNodeId] is the restored install's
/// provisional node. [onRows] is told the rows imported so far. Throws
/// [BackupImportFailedException] when a row or a foreign key does not fit, after rolling
/// everything back; returns the tables and columns dropped as unknown.
Future<({Set<String> tables, Set<String> columns})> importTables(
  AppDatabase database,
  List<BackupTable> tables, {
  required String newNodeId,
  void Function(int rows)? onRows,
}) async {
  final Map<String, TableInfo<Table, Object?>> known = {
    for (final TableInfo<Table, Object?> t in database.allTables)
      t.actualTableName: t,
  };
  final Set<String> droppedTables = {};
  final Set<String> droppedColumns = {};
  await database.customStatement('PRAGMA foreign_keys = OFF');
  try {
    await database.transaction(() async {
      int imported = 0;
      for (final BackupTable backup in tables) {
        if (backupExcludedTables.contains(backup.name)) continue;
        final TableInfo<Table, Object?>? table = known[backup.name];
        if (table == null) {
          droppedTables.add(backup.name);
          continue;
        }
        final Map<String, GeneratedColumn> columns = {
          for (final GeneratedColumn c in table.$columns) c.name: c,
        };
        final List<int> kept = [];
        for (int i = 0; i < backup.columns.length; i++) {
          if (columns.containsKey(backup.columns[i])) {
            kept.add(i);
          } else {
            droppedColumns.add('${backup.name}.${backup.columns[i]}');
          }
        }
        final String sql =
            'INSERT INTO "${table.actualTableName}" '
            '(${kept.map((i) => '"${backup.columns[i]}"').join(', ')}) '
            'VALUES (${List.filled(kept.length, '?').join(', ')})';
        final int keyColumn = backup.columns.indexOf('key');
        await database.batch((batch) {
          for (final List<Object?> row in backup.rows) {
            if (backup.name == 'app_meta' &&
                (restoreDroppedMetaKeys.contains(row[keyColumn]) ||
                    row[keyColumn] == ftsDefinitionKey)) {
              continue;
            }
            batch.customStatement(sql, [
              for (final int i in kept)
                _fromJson(columns[backup.columns[i]]!, row[i]),
            ]);
          }
        });
        imported += backup.rows.length;
        onRows?.call(imported);
      }
      if ((await database.customSelect('PRAGMA foreign_key_check').get())
          .isNotEmpty) {
        throw const BackupImportFailedException();
      }
      await DriftSyncStore(
        database,
        const SystemClock(),
      ).substituteNode(newNodeId);
    });
  } on BackupException {
    rethrow;
  } on SqliteException {
    throw const BackupImportFailedException();
  } on FormatException {
    throw const BackupImportFailedException();
  } finally {
    await database.customStatement('PRAGMA foreign_keys = ON');
  }
  return (tables: droppedTables, columns: droppedColumns);
}

// Whether [column] is an audit instant: mapped through `UtcMillisColumnConverter`, which
// Drift wraps in a `NullAwareTypeConverter` on a nullable column (`deleted_at`), so the
// test is on the converter's type, `DateTime` from `int`, which only that converter has.
bool _isInstant(GeneratedColumn column) =>
    column is GeneratedColumnWithTypeConverter &&
    column.converter is TypeConverter<DateTime?, int?>;

// The SQL types the dump has a JSON form for.
const Set<DriftSqlType<Object>> _dumpable = {
  DriftSqlType.bool,
  DriftSqlType.blob,
  DriftSqlType.int,
  DriftSqlType.bigInt,
  DriftSqlType.string,
};

// Throws a [StateError] when [table] cannot be dumped: no primary key to order it by,
// or a column of a type with no backup form (a REAL, a Drift `dateTime()`).
void _checkDumpable(TableInfo<Table, Object?> table) {
  if (table.$primaryKey.isEmpty) {
    throw StateError('${table.actualTableName}: no primary key to dump by');
  }
  for (final GeneratedColumn c in table.$columns) {
    if (!_dumpable.contains(c.type)) {
      throw StateError(
        '${table.actualTableName}.${c.name}: no backup form for ${c.type}',
      );
    }
  }
}

// The JSON form of [value], read from [column].
Object? _toJson(GeneratedColumn column, Object? value) {
  if (value == null) return null;
  if (_isInstant(column)) {
    return DateTime.fromMillisecondsSinceEpoch(
      value as int,
      isUtc: true,
    ).toIso8601String();
  }
  return switch (column.type) {
    DriftSqlType.bool => value != 0,
    DriftSqlType.blob => base64.encode(value as Uint8List),
    DriftSqlType.int || DriftSqlType.bigInt => value as int,
    DriftSqlType.string => value as String,
    _ => throw StateError(
      '${column.tableName}.${column.name}: no backup form for ${column.type}',
    ),
  };
}

// The SQL value of [value], the JSON form of a [column] value. Throws a
// [FormatException] for a value of the wrong kind.
Object? _fromJson(GeneratedColumn column, Object? value) {
  if (value == null) return null;
  try {
    if (_isInstant(column)) {
      final DateTime instant = DateTime.parse(value as String);
      if (!instant.isUtc || instant.microsecond != 0) {
        throw FormatException('not a UTC millisecond instant', value);
      }
      return instant.millisecondsSinceEpoch;
    }
    return switch (column.type) {
      DriftSqlType.bool => (value as bool) ? 1 : 0,
      DriftSqlType.blob => base64.decode(value as String),
      DriftSqlType.int || DriftSqlType.bigInt => value as int,
      DriftSqlType.string => value as String,
      _ => throw FormatException('no backup form', '${column.type}'),
    };
  } on TypeError {
    throw FormatException('a value of the wrong kind', column.name);
  }
}
