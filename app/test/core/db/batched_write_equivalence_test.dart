// The batched write path leaves the database exactly as the one-at-a-time path does
// (sync-app.md, **Recording**): two devices with the same history, one writing each
// transaction with upsert and delete, the other the same changes with upsertAll and
// deleteAll (one read per chunk, one batch of rows, one recording through
// LocalEditor.recordChanges and the store's readAll, writeAll and appendAll), hold the
// same dump (every table but the device-local conflicts), the same conflicts and an
// index equal to the view after each phase: new rows with tags and splits, edits of
// manual rows, of a record held with a newer device's field, of a record held for splits
// in another currency and of a Plaid row's overrides, an edit that settles a conflict,
// and deletes.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_archive.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';
import '../../helpers/fts_oracle.dart';

/// One device: its own clocks for the repository, the store and the recorder, so both
/// devices see the same sequence of instants whatever order each path reads them in.
final class _Device {
  _Device() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftSyncStore(database, SteppingClock()..frozen = true);
    final SteppingClock wall = SteppingClock();
    final ChangeRecorder recorder = EngineChangeRecorder(
      store,
      () async => hlc,
      () => wall.nowUtc().millisecondsSinceEpoch,
    );
    final SteppingClock clock = SteppingClock();
    accounts = DriftAccountRepository(database, clock, recorder: recorder);
    transactions = DriftTransactionRepository(
      database,
      clock,
      recorder: recorder,
    );
  }

  late final AppDatabase database;
  late final DriftSyncStore store;
  late final DriftAccountRepository accounts;
  late final DriftTransactionRepository transactions;
  final HlcClock hlc = HlcClock('dev-a');

  // Merges another device's [entry], as a pulled page does.
  Future<void> pull(ChangeLogEntry entry) => store.transaction(() async {
    hlc.receive(entry.hlc, entry.hlc.wallMillis);
    final MergeOutcome out = merge(
      await store.read(entry.entityType, entry.entityId),
      entry,
    );
    if (out.applied) await store.write(out.record);
  });

  Future<List<String>> conflicts() async => [
    for (final ConflictRow c
        in await (database.select(database.conflicts)..orderBy([
              (c) => OrderingTerm.asc(c.entityId),
              (c) => OrderingTerm.asc(c.field),
            ]))
            .get())
      '${c.entityId}.${c.field} ${c.localHlc} ${c.remoteHlc} ${c.entityLabel}',
  ];
}

final Hlc _remote = Hlc(
  DateTime.utc(2026, 10, 24, 14).millisecondsSinceEpoch,
  0,
  'dev-b',
);

ChangeLogEntry _create(Map<String, Object?> fields, Hlc at) => ChangeLogEntry(
  entityType: EntityType.transaction,
  entityId: fields['id']! as String,
  operation: ChangeOperation.create,
  payload: {...fields}..remove('deleted_at'),
  hlc: at,
  deviceId: at.nodeId,
  synced: true,
);

void main() {
  late _Device single;
  late _Device batched;

  setUp(() async {
    single = _Device();
    batched = _Device();
    final Transaction plaid = testTransaction(
      'p1',
      'a1',
      -999,
      name: 'STARBUCKS',
    ).copyWith(source: DataSource.plaid);
    for (final _Device d in [single, batched]) {
      await d.accounts.upsert(testAccount('a1'));
      await d.accounts.upsert(testAccount('a2'));
      await d.transactions.applyPlaid([plaid]);
      // A newer device's record with a field this version does not know.
      await d.pull(
        _create({
          ...transactionRecordJson(testTransaction('h1', 'a1', -100)),
          'future_field': 'kept',
        }, _remote),
      );
      // A record with a split in another currency than its amount.
      await d.pull(
        _create(
          transactionRecordJson(
            testTransaction(
              'x1',
              'a2',
              -500,
              splits: [
                TransactionSplit(categoryId: 'c1', amount: Money(-500, 'EUR')),
              ],
            ),
          ),
          Hlc(_remote.wallMillis, 1, 'dev-b'),
        ),
      );
    }
  });
  tearDown(() async {
    await single.database.close();
    await batched.database.close();
  });

  Future<void> same() async {
    final List<BackupTable> want = await dumpDatabase(single.database);
    final List<BackupTable> got = await dumpDatabase(batched.database);
    expect([for (final t in got) t.name], [for (final t in want) t.name]);
    for (int i = 0; i < want.length; i++) {
      expect(got[i].columns, want[i].columns, reason: want[i].name);
      for (int r = 0; r < want[i].rows.length || r < got[i].rows.length; r++) {
        expect(
          r < got[i].rows.length ? got[i].rows[r] : null,
          r < want[i].rows.length ? want[i].rows[r] : null,
          reason: '${want[i].name} row $r',
        );
      }
    }
    expect(await batched.conflicts(), await single.conflicts());
    await expectIndexMatchesView(single.database);
    await expectIndexMatchesView(batched.database);
  }

  test('new rows, edits, a settled conflict and deletes', () async {
    final List<Transaction> created = [
      for (int i = 0; i < 40; i++)
        testTransaction(
          'm$i',
          i.isEven ? 'a1' : 'a2',
          -10 * i,
          name: 'Shop $i',
          notes: i % 4 == 0 ? 'note $i' : null,
          tags: i % 3 == 0 ? ['t$i', 'shared'] : const [],
          splits: i % 5 == 0
              ? [
                  TransactionSplit(
                    categoryId: 'c1',
                    amount: Money(-4 * i, 'USD'),
                  ),
                  TransactionSplit(
                    categoryId: 'c2',
                    amount: Money(-6 * i, 'USD'),
                  ),
                ]
              : const [],
        ),
    ];
    for (final Transaction t in created) {
      await single.transactions.upsert(t);
    }
    await batched.transactions.upsertAll(created);
    await same();

    // This device's notes on m1, which another device's edit overwrote: a conflict;
    // and one on m2's name, which stays.
    for (final _Device d in [single, batched]) {
      final EntityRecord m1 = (await d.store.read(
        EntityType.transaction,
        'm1',
      ))!;
      final EntityRecord m2 = (await d.store.read(
        EntityType.transaction,
        'm2',
      ))!;
      await d.store.recordConflicts([
        FieldConflict(
          entityType: EntityType.transaction,
          entityId: 'm1',
          field: 'notes',
          localValue: 'mine',
          localClock: m1.fieldClocks['notes']!,
          remoteValue: null,
          remoteClock: m1.fieldClocks['notes']!,
        ),
        FieldConflict(
          entityType: EntityType.transaction,
          entityId: 'm2',
          field: 'name',
          localValue: 'Mine',
          localClock: m2.fieldClocks['name']!,
          remoteValue: 'Shop 2',
          remoteClock: m2.fieldClocks['name']!,
        ),
      ]);
    }
    final DateTime later = DateTime.utc(2026, 10, 25, 9);
    final Transaction h1 = (await single.transactions.getByIds(['h1']))['h1']!;
    final Transaction x1 = (await single.transactions.getByIds(['x1']))['x1']!;
    final Transaction p1 = (await single.transactions.getByIds(['p1']))['p1']!;
    final List<Transaction> edits = [
      for (final Transaction t in created.take(20))
        t.copyWith(
          notes: 'edited ${t.id}',
          userCategoryId: 'c9',
          tags: t.tags.isEmpty ? ['new'] : t.tags,
          updatedAt: later,
        ),
      // Unchanged: written, not recorded.
      created[30],
      h1.copyWith(name: 'Held, edited', updatedAt: later),
      x1.copyWith(notes: 'Held split', updatedAt: later),
      p1.copyWith(userCategoryId: 'c3', tags: ['coffee'], updatedAt: later),
    ];
    for (final Transaction t in edits) {
      await single.transactions.upsert(t);
    }
    await batched.transactions.upsertAll(edits);
    await same();
    expect(await single.conflicts(), hasLength(1), reason: 'm1 settled');

    final List<String> gone = [
      for (int i = 0; i < 40; i += 3) 'm$i',
      'h1',
      'x1',
      'missing',
    ];
    for (final String id in gone) {
      await single.transactions.delete(id);
    }
    await batched.transactions.deleteAll(gone);
    await same();
    expect(await single.conflicts(), hasLength(1), reason: 'm2 stays');
  });
}
