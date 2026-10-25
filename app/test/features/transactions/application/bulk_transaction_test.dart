// A bulk action reads its rows and writes the batch inside one sync-store transaction,
// so nothing synced in between is written back: in memory, the reads and the write sit
// between the store transaction's start and end; over Drift, a write the database
// refuses part way rolls the whole batch back, recording nothing.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../../contract/repository_fixture.dart';

/// A sync store that only logs its transactions.
final class _LoggingStore implements SyncStore {
  _LoggingStore(this.log);

  final List<String> log;

  @override
  Future<T> transaction<T>(Future<T> Function() body) async {
    log.add('begin');
    try {
      return await body();
    } finally {
      log.add('end');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The in-memory repository, logging the reads and writes a bulk action makes.
final class _LoggingTransactions extends InMemoryTransactionRepository {
  _LoggingTransactions(super.store, this.log)
    : super(recorder: const NoChangeRecorder());

  final List<String> log;

  @override
  Stream<Transaction?> watchById(String id) {
    log.add('read $id');
    return super.watchById(id);
  }

  @override
  Future<void> upsertAll(List<Transaction> batch) {
    log.add('write ${batch.length}');
    return super.upsertAll(batch);
  }

  @override
  Future<void> deleteAll(List<String> ids) {
    log.add('delete ${ids.length}');
    return super.deleteAll(ids);
  }
}

void main() {
  test(
    'in memory: the reads and the write share one store transaction',
    () async {
      final SteppingClock clock = SteppingClock();
      final InMemoryStore store = InMemoryStore(clock);
      addTearDown(store.close);
      final List<String> log = [];
      final _LoggingTransactions transactions = _LoggingTransactions(
        store,
        log,
      );
      await InMemoryAccountRepository(
        store,
        recorder: const NoChangeRecorder(),
      ).upsert(testAccount('a1'));
      await transactions.upsert(testTransaction('m1', 'a1', -100));
      await transactions.upsert(testTransaction('m2', 'a1', -200));
      final TransactionActions actions = TransactionActions(
        transactions,
        MemoryReceiptStore(),
        clock,
        syncStore: _LoggingStore(log),
      );

      log.clear();
      await actions.setHidden([
        testTransaction('m1', 'a1', -100),
        testTransaction('m2', 'a1', -200),
      ], true);
      expect(log, ['begin', 'read m1', 'read m2', 'write 2', 'end']);

      log.clear();
      await actions.deleteAll(['m1', 'm2']);
      expect(log, ['begin', 'delete 2', 'end']);
    },
  );

  test('Drift: a write refused part way rolls the whole bulk action back', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SteppingClock clock = SteppingClock();
    final DriftSyncStore syncStore = DriftSyncStore(database, clock);
    final HlcClock hlc = HlcClock('device-a');
    final ChangeRecorder recorder = EngineChangeRecorder(
      syncStore,
      () async => hlc,
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
    final DriftTransactionRepository transactions = DriftTransactionRepository(
      database,
      clock,
      recorder: recorder,
    );
    await DriftAccountRepository(
      database,
      clock,
      recorder: recorder,
    ).upsert(testAccount('a1'));
    await transactions.upsert(testTransaction('m1', 'a1', -100));
    await transactions.upsert(testTransaction('m2', 'a1', -200));
    final int outbox = (await syncStore.unsynced(limit: 1000)).length;
    // The test's own trigger refuses the second row's write, inside the batch.
    await database.customStatement(
      "CREATE TRIGGER refuse_m2 BEFORE UPDATE ON transactions WHEN NEW.id = 'm2' "
      "BEGIN SELECT RAISE(ABORT, 'refused by the test'); END",
    );
    final TransactionActions actions = TransactionActions(
      transactions,
      MemoryReceiptStore(),
      clock,
      syncStore: syncStore,
    );

    await expectLater(
      actions.setHidden([
        testTransaction('m1', 'a1', -100),
        testTransaction('m2', 'a1', -200),
      ], true),
      throwsA(anything),
    );
    expect((await transactions.watchById('m1').first)!.hidden, isFalse);
    expect((await syncStore.unsynced(limit: 1000)).length, outbox);
  });
}
