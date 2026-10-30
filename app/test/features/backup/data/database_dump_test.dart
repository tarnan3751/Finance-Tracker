// The database side of a backup: the import is tolerant the additive way (a table or
// column this build does not know is dropped, a column the backup lacks takes its
// default), refuses rows that break a foreign key or a constraint and leaves nothing
// behind, skips the device keys and the full-text definition, and resets the device's
// identity; an install's data is everything but its bookkeeping and the system
// categories; the device-local conflicts are left out both ways; a backup of a newer
// schema, or naming a file outside the receipts folder,
// is refused before anything is touched.
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/backup/domain/backup_cipher.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../backup_test_support.dart';

const String _account =
    'INSERT INTO accounts (id, type, name, currency, is_hidden, display_order, '
    "created_at, updated_at) VALUES ('a1', 'depository', 'Checking', 'USD', 0, 0, 1, 1)";
const String _transaction =
    'INSERT INTO transactions (id, account_id, amount_minor, currency, date, pending, '
    "name, source, created_at, updated_at) VALUES ('t1', 'a1', -100, 'USD', "
    "'2026-10-24', 0, 'Coffee', 'manual', 1, 1)";

AppDatabase fresh() =>
    AppDatabase(NativeDatabase.memory(), allowFullTextSearch: false);

BackupTable table(List<BackupTable> tables, String name) =>
    tables.firstWhere((t) => t.name == name);

void main() {
  late AppDatabase source;
  late AppDatabase target;
  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = fresh();
    await target.verifyOpen();
    await source.customStatement(_account);
    await source.customStatement(_transaction);
    await source.customStatement(
      'INSERT INTO transaction_tags (transaction_id, position, tag) '
      "VALUES ('t1', 0, 'morning')",
    );
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  test(
    'every table of the current schema dumps, so a schema change keeps export '
    'working',
    () async {
      final AppDatabase empty = AppDatabase(NativeDatabase.memory());
      addTearDown(empty.close);
      final List<BackupTable> tables = await dumpDatabase(empty);
      expect(tables.map((t) => t.name), [
        for (final t in empty.allTables)
          if (!backupExcludedTables.contains(t.actualTableName))
            t.actualTableName,
      ]);
    },
  );

  test('the conflicts are device-local: never exported, ignored on import, '
      'and no reason to call an install non-empty', () async {
    const String conflict =
        'INSERT INTO conflicts (entity_type, entity_id, field, local_value, '
        "local_hlc, remote_value, remote_hlc, seen_at) VALUES ('transaction', 't1', "
        "'notes', '\"a\"', '001761318000000-00000-dev-a', '\"b\"', "
        "'001761318060000-00000-dev-b', 1)";
    await source.customStatement(conflict);
    final List<BackupTable> dumped = await dumpDatabase(source);
    expect(dumped.map((t) => t.name), isNot(contains('conflicts')));
    // A backup that carries one anyway (another build's) lands without it.
    final List<BackupTable> carrying = [
      ...dumped,
      const BackupTable(
        'conflicts',
        ['entity_type', 'entity_id', 'field'],
        [
          ['transaction', 't1', 'notes'],
        ],
      ),
    ];
    final dropped = await importTables(target, carrying, newNodeId: 'n');
    expect(await target.customSelect('SELECT 1 FROM conflicts').get(), isEmpty);
    expect(dropped.tables, isEmpty);
    final AppDatabase only = AppDatabase(NativeDatabase.memory());
    addTearDown(only.close);
    await only.customStatement(conflict);
    expect(await hasLocalData(only), isFalse);
  });

  test('nullable instants dump as UTC ISO strings and round-trip', () async {
    await source.customStatement(
      'UPDATE accounts SET deleted_at = 2000, balances_as_of = 1700000000123',
    );
    await source.customStatement(
      "UPDATE transactions SET deleted_at = 1700000000456 WHERE id = 't1'",
    );
    final List<BackupTable> dump = await dumpDatabase(source);
    final BackupTable accounts = table(dump, 'accounts');
    Object? at(BackupTable t, String column) =>
        t.rows.single[t.columns.indexOf(column)];
    expect(at(accounts, 'created_at'), '1970-01-01T00:00:00.001Z');
    expect(at(accounts, 'deleted_at'), '1970-01-01T00:00:02.000Z');
    expect(at(accounts, 'balances_as_of'), '2023-11-14T22:13:20.123Z');
    expect(
      at(table(dump, 'transactions'), 'deleted_at'),
      '2023-11-14T22:13:20.456Z',
    );
    await importTables(target, dump, newNodeId: 'local-new');
    expect(
      (await target
              .customSelect(
                "SELECT deleted_at, balances_as_of FROM accounts WHERE id = 'a1'",
              )
              .getSingle())
          .data,
      {'deleted_at': 2000, 'balances_as_of': 1700000000123},
    );
    expect(
      jsonEncode([
        for (final BackupTable t in await dumpDatabase(target))
          if (t.name != 'sync_meta' && t.name != 'app_meta') t.rows,
      ]),
      jsonEncode([
        for (final BackupTable t in dump)
          if (t.name != 'sync_meta' && t.name != 'app_meta') t.rows,
      ]),
    );
  });

  test('an instant that is not an ISO string is refused', () async {
    await source.customStatement('UPDATE accounts SET deleted_at = 2000');
    final List<BackupTable> dump = await dumpDatabase(source);
    final BackupTable accounts = table(dump, 'accounts');
    final int deleted = accounts.columns.indexOf('deleted_at');
    await expectLater(
      importTables(target, [
        BackupTable(accounts.name, accounts.columns, [
          [...accounts.rows.single]..[deleted] = 2000,
        ]),
      ], newNodeId: 'local-new'),
      throwsA(isA<BackupImportFailedException>()),
    );
  });

  test(
    'drops what it does not know and defaults what the backup lacks',
    () async {
      final List<BackupTable> dump = await dumpDatabase(source);
      final BackupTable accounts = table(dump, 'accounts');
      final BackupTable transactions = table(dump, 'transactions');
      final int hidden = transactions.columns.indexOf('hidden');
      final List<BackupTable> changed = [
        for (final BackupTable t in dump)
          if (t.name == 'accounts')
            BackupTable(
              t.name,
              [...t.columns, 'nickname'],
              [
                for (final List<Object?> r in accounts.rows) [...r, 'Main'],
              ],
            )
          else if (t.name == 'transactions')
            // An older schema: no `hidden` column (schema 6 added it, default false).
            BackupTable(t.name, [...t.columns]..removeAt(hidden), [
              for (final List<Object?> r in transactions.rows)
                [...r]..removeAt(hidden),
            ])
          else
            t,
        const BackupTable(
          'wishlists',
          ['id', 'name'],
          [
            ['w1', 'Bike'],
          ],
        ),
      ];
      final ({Set<String> tables, Set<String> columns}) dropped =
          await importTables(target, changed, newNodeId: 'local-new');
      expect(dropped.tables, {'wishlists'});
      expect(dropped.columns, {'accounts.nickname'});
      final List<BackupTable> after = await dumpDatabase(target);
      expect(table(after, 'accounts').rows, accounts.rows);
      expect(table(after, 'transactions').rows, transactions.rows);
      expect(table(after, 'transaction_tags').rows, [
        ['t1', 0, 'morning'],
      ]);
    },
  );

  test('a row whose parent is missing rolls everything back', () async {
    final List<BackupTable> dump = await dumpDatabase(source);
    final List<BackupTable> orphaned = [
      for (final BackupTable t in dump)
        t.name == 'transaction_tags'
            ? BackupTable(t.name, t.columns, [
                ...t.rows,
                ['t-missing', 0, 'orphan'],
              ])
            : t,
    ];
    await expectLater(
      importTables(target, orphaned, newNodeId: 'local-new'),
      throwsA(isA<BackupImportFailedException>()),
    );
    expect(await hasLocalData(target), isFalse);
    expect(
      (await target.customSelect('PRAGMA foreign_keys').getSingle())
          .data
          .values
          .single,
      1,
    );
  });

  test(
    'a row that breaks a constraint, or a value of the wrong kind, too',
    () async {
      final List<BackupTable> dump = await dumpDatabase(source);
      BackupTable accounts = table(dump, 'accounts');
      final int type = accounts.columns.indexOf('type');
      accounts = BackupTable(accounts.name, accounts.columns, [
        [...accounts.rows.single]..[type] = 'spaceship',
      ]);
      await expectLater(
        importTables(target, [accounts], newNodeId: 'local-new'),
        throwsA(isA<BackupImportFailedException>()),
      );
      final int created = accounts.columns.indexOf('created_at');
      await expectLater(
        importTables(target, [
          BackupTable(accounts.name, accounts.columns, [
            [...table(dump, 'accounts').rows.single]..[created] = 12,
          ]),
        ], newNodeId: 'local-new'),
        throwsA(isA<BackupImportFailedException>()),
      );
      expect(await hasLocalData(target), isFalse);
    },
  );

  test('skips the device keys and the full-text definition', () async {
    for (final String key in [
      'reminders_zone',
      'reminders_scheduled_at',
      'snapshots_written_on',
      'install_date',
    ]) {
      await source.customStatement(
        'INSERT INTO app_meta (key, value) VALUES (?, ?)',
        [key, 'x'],
      );
    }
    await importTables(target, await dumpDatabase(source), newNodeId: 'n');
    expect(
      (await target.customSelect('SELECT key FROM app_meta ORDER BY key').get())
          .map((r) => r.read<String>('key')),
      ['install_date'],
    );
  });

  test('has data: anything but the bookkeeping and the system categories', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await hasLocalData(db), isFalse);
    await DriftCategoryRepository(
      db,
      const SystemClock(),
      recorder: const NoChangeRecorder(),
    ).ensureSeeded();
    await db.customStatement(
      "INSERT INTO app_settings (key, value) VALUES ('theme_mode', '\"dark\"')",
    );
    await db.customStatement(
      "INSERT INTO sync_meta (key, value) VALUES ('device_id', 'local-x')",
    );
    expect(await hasLocalData(db), isFalse);
    await db.customStatement(
      'INSERT INTO saved_filters (id, name, query_json, position, created_at, '
      "updated_at) VALUES ('f', 'F', '{}', 0, 1, 1)",
    );
    expect(await hasLocalData(db), isTrue);
  });

  group('openBackup refuses before anything is touched', () {
    Future<Uint8List> seal({
      int schema = 12,
      List<BackupReceipt> receipts = const [],
    }) async => sealBackup(
      SealRequest(
        tables: await dumpDatabase(source),
        receipts: receipts,
        schemaVersion: schema,
        appVersion: '1.0.0+1',
        createdAt: DateTime.utc(2026, 10, 30),
        userId: null,
        passphrase: 'correct horse battery',
        kdf: testKdf,
        salt: Uint8List(16),
        baseNonce: Uint8List(24),
      ),
      (_) {},
    );

    test('a newer schema', () async {
      final Uint8List file = await seal(schema: 13);
      await expectLater(
        openBackup(file, 'correct horse battery', (_) {}, schemaVersion: 12),
        throwsA(isA<BackupTooNewException>()),
      );
      expect(
        (await openBackup(
          file,
          'correct horse battery',
          (_) {},
          schemaVersion: 13,
        )).manifest.schemaVersion,
        13,
      );
    });

    test('a receipt outside the receipts folder', () async {
      final Uint8List file = await seal(
        receipts: [BackupReceipt('../databases/x.jpg', Uint8List(3))],
      );
      await expectLater(
        openBackup(file, 'correct horse battery', (_) {}),
        throwsA(isA<BackupDamagedException>()),
      );
      expect(isReceiptPath('receipts/t1.jpg'), isTrue);
      expect(isReceiptPath('receipts/../t1.jpg'), isFalse);
    });

    test('a wrong passphrase, with the progress it made', () async {
      final List<BackupProgress> seen = [];
      await expectLater(
        openBackup(await seal(), 'correct horse batterx', seen.add),
        throwsA(isA<WrongPassphraseException>()),
      );
      expect(seen.single.stage, BackupStage.deriving);
      final Uint8List file = await seal();
      seen.clear();
      final OpenedBackup opened = await openBackup(
        file,
        'correct horse battery',
        seen.add,
      );
      expect(seen.first.stage, BackupStage.deriving);
      expect(seen.last.stage, BackupStage.checking);
      expect(seen.last.done, frameCount(file.length - backupHeaderLength - 16));
      expect(opened.frameKey, hasLength(32));
    });
  });
}
