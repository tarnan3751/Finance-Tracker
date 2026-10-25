// The full-text index (data.md, **Full-text search**): the host has FTS5, and after every
// write path the index equals the view (expectIndexMatchesView); a database opened
// without FTS5 drops the triggers and gains the index back, rebuilt, when FTS5 returns;
// an index built with an older definition version is rebuilt at open.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';
import '../../helpers/fts_oracle.dart';

void main() {
  test(
    'the host SQLite has FTS5, so the gate tests the full-text path',
    () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final String version =
          (await database
                  .customSelect('SELECT sqlite_version() AS v')
                  .getSingle())
              .read<String>('v');
      final bool fts = await database.fullTextSearch;
      // The gate's test output names the path this host took.
      // ignore: avoid_print
      print(
        'full-text search: ${fts ? 'FTS5' : 'LIKE fallback'} (SQLite $version)',
      );
      expect(fts, isTrue);
    },
  );

  group('the index after each write path', () {
    late AppDatabase database;
    late DriftAccountRepository accounts;
    late DriftTransactionRepository transactions;
    late DriftSyncStore syncStore;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      final SteppingClock clock = SteppingClock();
      syncStore = DriftSyncStore(database, clock);
      final HlcClock hlc = HlcClock('device-a');
      final ChangeRecorder recorder = EngineChangeRecorder(
        syncStore,
        () async => hlc,
        () => clock.nowUtc().millisecondsSinceEpoch,
      );
      accounts = DriftAccountRepository(database, clock, recorder: recorder);
      transactions = DriftTransactionRepository(
        database,
        clock,
        recorder: recorder,
      );
      await accounts.upsert(testAccount('a1'));
      await accounts.upsert(testAccount('a2'));
      await transactions.upsert(
        testTransaction(
          't1',
          'a1',
          -450,
          name: 'Café Crème',
          merchantName: 'Blue Bottle',
          notes: 'with Zoë',
          tags: ['work', 'coffee'],
        ),
      );
      await transactions.upsert(
        testTransaction('t2', 'a2', -1800, name: 'UBER'),
      );
    });
    tearDown(() => database.close());

    test('inserts', () => expectIndexMatchesView(database));

    test('an edit of the text and of the tags', () async {
      await transactions.upsert(
        testTransaction('t1', 'a1', -450, name: 'Tea', tags: ['trip']),
      );
      await expectIndexMatchesView(database);
      await transactions.upsert(testTransaction('t1', 'a1', -450, name: 'Tea'));
      await expectIndexMatchesView(database);
    });

    test('an edit that leaves the text alone', () async {
      await transactions.upsert(
        testTransaction('t2', 'a2', -1900, name: 'UBER', hidden: true),
      );
      await expectIndexMatchesView(database);
    });

    test('a batch, a delete, a restore and deleteAll', () async {
      await transactions.upsertAll([
        testTransaction('t1', 'a1', -450, name: 'Café', tags: ['x', 'y', 'z']),
        testTransaction('t3', 'a1', -100, name: 'New one', notes: 'n'),
      ]);
      await expectIndexMatchesView(database);
      await transactions.delete('t3');
      await transactions.restore('t3');
      await transactions.deleteAll(['t1', 't3']);
      await expectIndexMatchesView(database);
    });

    test("an account's cascade and its restore", () async {
      await accounts.delete('a1');
      await expectIndexMatchesView(database);
      await accounts.restore('a1');
      await expectIndexMatchesView(database);
    });

    test('the Plaid apply path', () async {
      final Transaction plaid = testTransaction(
        'p1',
        'a2',
        -999,
        name: 'STARBUCKS #123',
        merchantName: 'Starbucks',
      ).copyWith(source: DataSource.plaid);
      await transactions.applyPlaid([plaid]);
      await transactions.applyPlaid([
        plaid.copyWith(name: 'STARBUCKS STORE 123'),
        plaid.copyWith(id: 'p2', deletedAt: testInstant),
      ]);
      await expectIndexMatchesView(database);
    });

    test('a record merged by sync', () async {
      final Hlc at = Hlc(
        DateTime.utc(2026, 10, 2).millisecondsSinceEpoch,
        0,
        'b',
      );
      final Map<String, Object?> fields = transactionRecordJson(
        testTransaction('s1', 'a1', -5, name: 'From the other device'),
      );
      await syncStore.write(
        EntityRecord(
          type: EntityType.transaction,
          id: 's1',
          fields: fields,
          fieldClocks: {for (final String f in fields.keys) f: at},
          createdAt: at,
        ),
      );
      await expectIndexMatchesView(database);
    });

    test('a row removed outright takes its key and its tags along', () async {
      await database.customStatement(
        "DELETE FROM transactions WHERE id = 't1'",
      );
      await expectIndexMatchesView(database);
      expect(
        await database
            .customSelect('SELECT count(*) AS n FROM $ftsKeysTable')
            .getSingle()
            .then((r) => r.read<int>('n')),
        1,
      );
    });

    test('VACUUM keeps the index, since its rowids are its own', () async {
      await database.customStatement(
        "DELETE FROM transactions WHERE id = 't1'",
      );
      await transactions.upsert(testTransaction('t3', 'a1', -1, name: 'Later'));
      await database.customStatement('VACUUM');
      await expectIndexMatchesView(database);
    });
  });

  group('a database opened without FTS5', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('fts_test');
      file = File('${directory.path}/db.sqlite');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    Future<AppDatabase> open({required bool fts}) async {
      final AppDatabase database = AppDatabase(
        NativeDatabase(file),
        allowFullTextSearch: fts,
      );
      await database.verifyOpen();
      return database;
    }

    Future<void> insert(AppDatabase database, String id, String name) async {
      await database.customStatement(
        'INSERT INTO accounts (id, type, name, currency, is_hidden, display_order, '
        'created_at, updated_at, sync_version) '
        "VALUES ('a', 'depository', 'A', 'USD', 0, 0, 0, 0, 0) "
        'ON CONFLICT DO NOTHING',
      );
      await writeTransactionRow(
        database,
        testTransaction(id, 'a', -1, name: name, tags: ['tag']),
        currency: 'USD',
      );
    }

    test('an index built with an older definition is rebuilt', () async {
      final AppDatabase first = await open(fts: true);
      await insert(first, 't1', 'Before');
      Future<String?> version(AppDatabase db) async =>
          (await db
                  .customSelect(
                    'SELECT value FROM app_meta WHERE key = ?',
                    variables: [Variable.withString(ftsDefinitionKey)],
                  )
                  .getSingleOrNull())
              ?.read<String>('value');
      expect(await version(first), '$ftsDefinitionVersion');
      // An older definition's database: another version, and an index out of step.
      await first.customStatement(
        "UPDATE app_meta SET value = '0' WHERE key = '$ftsDefinitionKey'",
      );
      await first.customStatement('DELETE FROM $ftsTable');
      await first.close();

      final AppDatabase again = await open(fts: true);
      expect(await version(again), '$ftsDefinitionVersion');
      expect(
        (await fullTextObjects(again)).values.toSet(),
        ftsCreateStatements.toSet(),
      );
      await expectIndexMatchesView(again);
      await again.close();
    });

    test(
      'drops the triggers, writes, and is rebuilt when FTS5 returns',
      () async {
        final AppDatabase first = await open(fts: true);
        await insert(first, 't1', 'Before');
        await first.close();

        final AppDatabase without = await open(fts: false);
        expect(await without.fullTextSearch, isFalse);
        expect((await fullTextObjects(without)).keys.toSet(), {
          ftsSourceView,
          ftsKeysTable,
          ftsTable,
        }, reason: 'the triggers are dropped; the table stays, inert');
        await insert(without, 't2', 'Meanwhile');
        await without.close();

        final AppDatabase back = await open(fts: true);
        expect(await back.fullTextSearch, isTrue);
        await expectIndexMatchesView(back);
        expect(
          await back
              .customSelect(
                'SELECT transaction_id FROM $ftsTable WHERE $ftsTable MATCH ?',
                variables: [Variable.withString('"meanwhile"*')],
              )
              .get()
              .then(
                (rows) => [
                  for (final r in rows) r.read<String>('transaction_id'),
                ],
              ),
          ['t2'],
        );
        await back.close();
      },
    );
  });
}
