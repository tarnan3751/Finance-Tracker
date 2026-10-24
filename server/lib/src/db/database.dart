/// The server's SQLite database (`docs/reference/server.md`, **Storage**).
///
/// One `sqlite3` connection with `foreign_keys = ON` (and `journal_mode = WAL` for a file),
/// guarded by a [Mutex]: `sqlite3` is synchronous, but handlers await hashing and
/// encryption between statements, so every access goes through [transaction] or [read],
/// which never interleave. Neither may be called from inside the other, and no Plaid call
/// runs while one is open.
library;

import 'dart:io';

import 'package:finance_tracker_server/src/db/migrations.dart';
import 'package:finance_tracker_server/src/db/mutex.dart';
import 'package:sqlite3/sqlite3.dart';

/// The database, migrated to the current schema when opened.
final class AppDatabase {
  AppDatabase._(this._db) {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('PRAGMA busy_timeout = 5000');
  }

  /// Opens (creating it and its directory) the database file at [path] and migrates it.
  factory AppDatabase.open(String path) {
    Directory(File(path).parent.path).createSync(recursive: true);
    final db = AppDatabase._(sqlite3.open(path));
    db._db.execute('PRAGMA journal_mode = WAL');
    migrate(db._db);
    return db;
  }

  /// A new in-memory database, migrated, for tests.
  factory AppDatabase.inMemory() {
    final db = AppDatabase._(sqlite3.openInMemory());
    migrate(db._db);
    return db;
  }

  final Database _db;
  final Mutex _mutex = Mutex();

  /// Runs [body] in one `BEGIN IMMEDIATE` transaction: committed when it returns, rolled
  /// back (and the error rethrown) when it throws.
  Future<T> transaction<T>(Future<T> Function(Tx tx) body) =>
      _mutex.run(() async {
        _db.execute('BEGIN IMMEDIATE');
        try {
          final result = await body(Tx._(_db));
          _db.execute('COMMIT');
          return result;
        } catch (_) {
          _db.execute('ROLLBACK');
          rethrow;
        }
      });

  /// Runs [body] for reads (or a single atomic statement) without a transaction.
  Future<T> read<T>(T Function(Tx tx) body) =>
      _mutex.run(() async => body(Tx._(_db)));

  /// Closes the connection.
  Future<void> close() => _mutex.run(() async => _db.close());
}

/// The statements available inside [AppDatabase.transaction] and [AppDatabase.read].
final class Tx {
  Tx._(this._db);

  final Database _db;

  /// Runs a query.
  ResultSet select(String sql, [List<Object?> parameters = const []]) =>
      _db.select(sql, parameters);

  /// The first row of a query, or null.
  Row? first(String sql, [List<Object?> parameters = const []]) {
    final rows = _db.select(sql, parameters);
    return rows.isEmpty ? null : rows.first;
  }

  /// Runs a statement and returns the number of rows it changed.
  int execute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
    return _db.updatedRows;
  }

  /// The rowid of the last insert.
  int get lastInsertRowId => _db.lastInsertRowId;
}
