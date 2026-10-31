/// The server's SQLite database (`docs/reference/server.md`, **Storage**).
///
/// One `sqlite3` connection with `foreign_keys = ON`, a busy handler that waits five
/// seconds of wall time ([busyWaiter]) and, for a file, `journal_mode = WAL`, guarded by a
/// [Mutex]: `sqlite3` is synchronous, but handlers await hashing and
/// encryption between statements, so every access goes through [transaction] or [read],
/// which never interleave. Neither may be called from inside the other, and no Plaid call
/// runs while one is open.
///
/// The wait is a handler of our own, not `PRAGMA busy_timeout`, as in the app
/// (`app/lib/core/db/open_database.dart`): SQLite's own handler counts the sleeps it
/// asked for, not the time they took, and a signal (the Dart VM profiler's `SIGPROF` on
/// Linux) cuts each one short, so its five seconds can pass in a fraction of one.
library;

import 'dart:io';
import 'dart:math';

import 'package:finance_tracker_server/src/db/migrations.dart';
import 'package:finance_tracker_server/src/db/mutex.dart';
import 'package:sqlite3/sqlite3.dart';

/// The database, migrated to the current schema when opened.
final class AppDatabase {
  AppDatabase._(this._db) {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.busyHandler = busyWaiter();
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

/// How long a statement that meets another connection's lock waits for it.
const int busyTimeoutMillis = 5000;

/// The longest sleep between two attempts of [busyWaiter].
const int _busyRetryMaxMillis = 20;

/// A busy handler for one connection that has SQLite try again, sleeping a little more
/// each time up to 20 ms, until [timeoutMillis] of wall time have passed since the lock
/// was first met; measured on a stopwatch, so a sleep a signal cut short only means an
/// earlier attempt.
bool Function(int count) busyWaiter({int timeoutMillis = busyTimeoutMillis}) {
  final Stopwatch waited = Stopwatch();
  return (int count) {
    if (count == 0) waited.reset();
    waited.start();
    final int left = timeoutMillis - waited.elapsedMilliseconds;
    if (left <= 0) return false;
    sleep(
      Duration(
        milliseconds: [count + 1, _busyRetryMaxMillis, left].reduce(min),
      ),
    );
    return true;
  };
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
