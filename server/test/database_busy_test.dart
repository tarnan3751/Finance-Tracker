// The database's wait on another connection's lock (lib/src/db/database.dart): a write
// that meets a transaction another connection holds waits for it and runs after it
// (it sees what that transaction committed), and the wait is the timeout in wall time (the VM's profiler, on in a test, cuts
// SQLite's own sleeps short with signals on Linux), again for each meeting.
import 'dart:io';
import 'dart:isolate';

import 'package:finance_tracker_server/src/db/database.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// Holds a write transaction on the database at [path] for [millis], adding the user
/// `holder` in it, and tells [ready] once it holds it; run in an isolate of its own,
/// since a connection waiting in its busy handler blocks the isolate it runs in.
void _holdLock((String, int, SendPort) args) {
  final (String path, int millis, SendPort ready) = args;
  final Database holder = sqlite3.open(path);
  holder
    ..execute('BEGIN IMMEDIATE')
    ..execute(
      'INSERT INTO users (id, email, password_hash, display_name, created_at) '
      "VALUES ('holder', 'holder@example.test', 'x', 'Holder', 0)",
    );
  ready.send(null);
  sleep(Duration(milliseconds: millis));
  holder
    ..execute('COMMIT')
    ..close();
}

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('ft-server-db-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('a write that meets a held transaction runs after it', () async {
    final String path = '${directory.path}/server.db';
    final AppDatabase db = AppDatabase.open(path);
    addTearDown(db.close);

    final ReceivePort ready = ReceivePort();
    final SendPort tell = ready.sendPort;
    final Future<void> holding = Isolate.run(
      () => _holdLock((path, 400, tell)),
    );
    await ready.first;
    // Begun while the holder's transaction is open, so it starts only once that one
    // has committed: it sees the holder's row.
    final bool sawHolder = await db.transaction((tx) async {
      final bool seen =
          tx.first("SELECT id FROM users WHERE id = 'holder'") != null;
      tx.execute(
        'INSERT INTO users (id, email, password_hash, display_name, created_at) '
        "VALUES ('u1', 'waiter@example.test', 'x', 'Waiter', 0)",
      );
      return seen;
    });
    expect(sawHolder, isTrue);
    await holding;
    expect(
      await db.read(
        (tx) => [
          for (final row in tx.select('SELECT id FROM users ORDER BY id'))
            row['id'],
        ],
      ),
      ['holder', 'u1'],
    );
  });

  test(
    'a write that meets a lock is retried for the timeout, in wall time',
    () {
      Database connection() => sqlite3.open('${directory.path}/raw.db')
        ..busyHandler = busyWaiter(timeoutMillis: 400)
        ..execute('PRAGMA journal_mode = WAL');
      final Database holder = connection()
        ..execute('CREATE TABLE t (k TEXT PRIMARY KEY)');
      final Database waiter = connection();
      addTearDown(holder.close);
      addTearDown(waiter.close);
      for (final String round in ['held', 'held again']) {
        holder
          ..execute('BEGIN IMMEDIATE')
          ..execute('INSERT INTO t VALUES (?)', [round]);
        final Stopwatch watch = Stopwatch()..start();
        expect(
          () => waiter.execute("INSERT INTO t VALUES ('waiting')"),
          throwsA(
            isA<SqliteException>().having((e) => e.resultCode, 'resultCode', 5),
          ),
        );
        expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(400));
        holder.execute('COMMIT');
      }
      waiter.execute("INSERT INTO t VALUES ('waiting')");
    },
  );
}
