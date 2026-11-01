// Guards the local write path's round trips (docs/reference/sync-app.md, **Recording**):
// the statements each path sends to SQLite, counted by a QueryInterceptor, stay under
// ceilings set at about one and a half times what the batched path sends. A count is
// deterministic where a time is not, so this runs in the gate; a path that goes back to
// a statement or two per row (a per-row read, clock save, savepoint or row write) fails
// it at once. This file counts statements; a separate perf test times the same paths.
// Each test prints what it counted.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../contract/repository_fixture.dart';

/// Counts what reaches the executor: each statement, each batch (one round trip,
/// whatever it holds), each transaction or savepoint begun and each one committed.
final class _Counter extends QueryInterceptor {
  int count = 0;

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    count++;
    return parent.beginTransaction();
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    count++;
    return inner.send();
  }

  @override
  Future<void> runBatched(QueryExecutor e, BatchedStatements statements) {
    count++;
    return e.runBatched(statements);
  }

  @override
  Future<void> runCustom(QueryExecutor e, String s, List<Object?> a) {
    count++;
    return e.runCustom(s, a);
  }

  @override
  Future<int> runInsert(QueryExecutor e, String s, List<Object?> a) {
    count++;
    return e.runInsert(s, a);
  }

  @override
  Future<int> runUpdate(QueryExecutor e, String s, List<Object?> a) {
    count++;
    return e.runUpdate(s, a);
  }

  @override
  Future<int> runDelete(QueryExecutor e, String s, List<Object?> a) {
    count++;
    return e.runDelete(s, a);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String s,
    List<Object?> a,
  ) {
    count++;
    return e.runSelect(s, a);
  }
}

/// A device on the dev wiring's write path: the Drift repositories recording through
/// the Drift sync store.
final class _Device {
  _Device(String node) : hlc = HlcClock(node) {
    database = AppDatabase(NativeDatabase.memory().interceptWith(counter));
    store = DriftSyncStore(database, clock);
    final ChangeRecorder recorder = EngineChangeRecorder(
      store,
      () async => hlc,
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
    accounts = DriftAccountRepository(database, clock, recorder: recorder);
    transactions = DriftTransactionRepository(
      database,
      clock,
      recorder: recorder,
    );
  }

  final _Counter counter = _Counter();
  final SteppingClock clock = SteppingClock();
  final HlcClock hlc;
  late final AppDatabase database;
  late final DriftSyncStore store;
  late final DriftAccountRepository accounts;
  late final DriftTransactionRepository transactions;

  // The statements [body] sends.
  Future<int> count(String what, Future<void> Function() body) async {
    final int before = counter.count;
    await body();
    final int n = counter.count - before;
    // ignore: avoid_print
    print('write path: $what, $n statements');
    return n;
  }
}

List<Transaction> _rows(int n) => [
  for (int i = 0; i < n; i++)
    testTransaction(
      'imp-$i',
      'a1',
      -(i % 5000),
      date: LocalDate(2020, 1, 1).addDays(i ~/ 5),
      name: 'MERCHANT ${i % 97} PURCHASE',
      tags: i % 10 == 0 ? const ['trip'] : const [],
    ).copyWith(source: DataSource.import),
];

void main() {
  late _Device device;

  setUp(() async {
    device = _Device('dev-a');
    await device.accounts.upsert(testAccount('a1'));
  });
  tearDown(() => device.database.close());

  test('an import of 1,000 rows', () async {
    expect(
      await device.count(
        'upsertAll of 1,000 new rows',
        () => device.transactions.upsertAll(_rows(1000)),
      ),
      lessThan(_ceilings.import),
    );
  });

  test('a bulk edit of 1,000 rows, then a delete of them', () async {
    final List<Transaction> rows = _rows(1000);
    await device.transactions.upsertAll(rows);
    final DateTime later = DateTime.utc(2026, 10, 25);
    expect(
      await device.count(
        'upsertAll of 1,000 edited rows',
        () => device.transactions.upsertAll([
          for (final Transaction t in rows)
            t.copyWith(userCategoryId: 'groceries', updatedAt: later),
        ]),
      ),
      lessThan(_ceilings.bulkEdit),
    );
    expect(
      await device.count(
        'deleteAll of 1,000 rows',
        () => device.transactions.deleteAll([
          for (final Transaction t in rows) t.id,
        ]),
      ),
      lessThan(_ceilings.deleteAll),
    );
  });

  test('a pull of 5,000 entries from another device', () async {
    final _Device other = _Device('dev-b');
    addTearDown(other.database.close);
    await other.accounts.upsert(testAccount('a1'));
    await other.transactions.upsertAll(_rows(5000));
    final InMemorySyncRelay relay = InMemorySyncRelay(
      nowWallMillis: () => other.clock.nowUtc().millisecondsSinceEpoch,
    );
    await SyncSession(
      other.store,
      relay,
      other.hlc,
      nowWallMillis: () => other.clock.nowUtc().millisecondsSinceEpoch,
    ).run();
    final _Device fresh = _Device('dev-c');
    addTearDown(fresh.database.close);
    await fresh.database.verifyOpen();
    late SyncReport report;
    expect(
      await fresh.count('a pull of 5,001 entries', () async {
        report = await SyncSession(
          fresh.store,
          relay,
          fresh.hlc,
          nowWallMillis: () => fresh.clock.nowUtc().millisecondsSinceEpoch,
        ).run();
      }),
      lessThan(_ceilings.pull),
    );
    expect(report.applied, 5001);
  });
}

// About one and a half times what the batched path sends (68, 56, 62 and 50,117 when
// these ceilings were set); the per-row path sent about 25, 31 and 32 statements a row
// for the first three. The pull still writes each entry on its own (about 10 a row).
const ({int import, int bulkEdit, int deleteAll, int pull}) _ceilings = (
  import: 100,
  bulkEdit: 85,
  deleteAll: 95,
  pull: 75000,
);
