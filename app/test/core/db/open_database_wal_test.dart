// Two connections on one file (`docs/reference/background.md`, **The database**): every
// connection opens in WAL, a database kept with a rollback journal opens in WAL with its
// data, the busy handler waits its timeout in wall time (the VM's profiler, on in a
// test, cuts SQLite's own sleeps short with signals on Linux), a write that meets the
// other connection's transaction waits for it instead of failing, and a transaction its
// connection never committed leaves nothing behind (what the background cycle's
// deadline relies on when its engine goes).
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  // Two connections to one file are the point here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late File file;
  late InMemoryDatabaseKeyStore keys;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('ft-wal-');
    file = File('${directory.path}/$databaseFileName');
    keys = InMemoryDatabaseKeyStore();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<AppDatabase> open() async =>
      AppDatabase(await openDatabaseExecutor(file, keyStore: keys));

  Future<Object?> pragma(AppDatabase db, String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).data.values.single;

  test('every connection is in WAL', () async {
    final AppDatabase first = await open();
    final AppDatabase second = await open();
    addTearDown(first.close);
    addTearDown(second.close);
    for (final AppDatabase db in [first, second]) {
      await db.verifyOpen();
      expect(await pragma(db, 'journal_mode'), 'wal');
    }
  });

  test(
    'a write that meets a lock is retried for the timeout, in wall time',
    () {
      Database connection() => sqlite3.open('${directory.path}/raw.db')
        ..busyHandler = busyWaiter(timeoutMillis: 400)
        ..select('PRAGMA journal_mode = WAL;');
      final Database holder = connection()
        ..execute('CREATE TABLE t (k TEXT PRIMARY KEY)');
      final Database waiter = connection();
      addTearDown(holder.close);
      addTearDown(waiter.close);
      holder
        ..execute('BEGIN IMMEDIATE')
        ..execute("INSERT INTO t VALUES ('held')");
      final Stopwatch watch = Stopwatch()..start();
      expect(
        () => waiter.execute("INSERT INTO t VALUES ('waiting')"),
        throwsA(
          isA<SqliteException>().having((e) => e.resultCode, 'resultCode', 5),
        ),
      );
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(400));
      holder.execute('COMMIT');
      // A second meeting waits its own timeout again.
      holder
        ..execute('BEGIN IMMEDIATE')
        ..execute("INSERT INTO t VALUES ('held again')");
      watch.reset();
      expect(
        () => waiter.execute("INSERT INTO t VALUES ('waiting')"),
        throwsA(isA<SqliteException>()),
      );
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(400));
      holder.execute('COMMIT');
      waiter.execute("INSERT INTO t VALUES ('waiting')");
    },
  );

  test(
    'a database kept with a rollback journal opens in WAL with its data',
    () async {
      final AppDatabase before = await open();
      await DriftAppMetaStore(before).write('k', 'v');
      await before.customStatement('PRAGMA journal_mode = DELETE');
      expect(await pragma(before, 'journal_mode'), 'delete');
      await before.close();

      final AppDatabase after = await open();
      addTearDown(after.close);
      expect(await pragma(after, 'journal_mode'), 'wal');
      expect(await DriftAppMetaStore(after).read('k'), 'v');
    },
  );

  test(
    "a write that meets the other connection's transaction waits for it",
    () async {
      final AppDatabase app = await open();
      final AppDatabase worker = await open();
      addTearDown(app.close);
      addTearDown(worker.close);
      await app.verifyOpen();
      await worker.verifyOpen();

      final Completer<void> inside = Completer<void>();
      final Completer<void> release = Completer<void>();
      final Future<void> held = app.transaction(() async {
        await DriftAppMetaStore(app).write('app', '1');
        inside.complete();
        await release.future;
      });
      await inside.future;
      bool committed = false;
      final Future<void> waiting = DriftAppMetaStore(worker)
          .write('worker', '1')
          .then((_) => expect(committed, isTrue));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      committed = true;
      release.complete();
      await held;
      await waiting;
      expect(await DriftAppMetaStore(app).read('worker'), '1');
      expect(await DriftAppMetaStore(worker).read('app'), '1');
    },
  );

  test('a transaction its connection never committed leaves nothing', () async {
    final AppDatabase app = await open();
    await app.verifyOpen();
    await app.close();

    final Database raw = sqlite3.open(file.path);
    databaseSetup(hexKey: keys.key, requireEncryption: true)(raw);
    raw
      ..execute('BEGIN')
      ..execute("INSERT INTO app_meta (key, value) VALUES ('cut', 'short')");
    // The connection goes with its transaction open, as a cycle's engine does when the
    // deadline passes.
    raw.close();

    final AppDatabase after = await open();
    addTearDown(after.close);
    expect(await DriftAppMetaStore(after).read('cut'), isNull);
  });
}
