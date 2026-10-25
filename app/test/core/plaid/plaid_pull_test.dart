// The Plaid pull over the in-app fake server into the Drift repositories (the dev and
// prod path), and once into the in-memory ones: Items, linked accounts and transactions
// applied as the server sent them, paging by sync_version with the cursor saved per
// page, a failed page leaving the cursor, a cursor past the server restarting from 0, an
// unlinked Item's data going, an override pulled before its row landing on it, single
// flight, the arrival seam, and nothing recorded.
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_plaid_pull_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/items/data/drift_item_repository.dart';
import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';
import '../api/support/fake_api.dart';

/// Counts what arrives and can fail on a chosen call.
final class _Arrivals implements ArrivalProcessor {
  final List<List<String>> pages = [];
  int? failOnCall;

  @override
  Future<void> onArrived(List<Transaction> added) async {
    pages.add([for (final Transaction t in added) t.id]);
    if (failOnCall == pages.length) throw StateError('arrival failed');
  }
}

/// Keeps every row it is given.
final class _Seen implements ArrivalProcessor {
  final List<Transaction> rows = [];

  @override
  Future<void> onArrived(List<Transaction> added) async => rows.addAll(added);
}

void main() {
  late FakeServer server;
  late FakeClient client;
  late AppDatabase database;
  late DriftSyncStore syncStore;
  late DriftPlaidPullStore store;
  late _Arrivals arrivals;
  late SteppingClock clock;

  setUp(() {
    server = newFakeServer();
    client = FakeClient.signedIn(server);
    database = AppDatabase(NativeDatabase.memory());
    clock = SteppingClock();
    syncStore = DriftSyncStore(database, clock);
    store = DriftPlaidPullStore(database, syncStore);
    arrivals = _Arrivals();
  });
  tearDown(() => database.close());

  ChangeRecorder recorder() => EngineChangeRecorder(
    syncStore,
    () async => HlcClock('device-a'),
    () => clock.nowUtc().millisecondsSinceEpoch,
  );

  PlaidPull pull({int pageSize = 500}) => PlaidPull(
    api: client.api,
    store: store,
    items: DriftItemRepository(database),
    accounts: DriftAccountRepository(database, clock, recorder: recorder()),
    transactions: DriftTransactionRepository(
      database,
      clock,
      recorder: recorder(),
    ),
    clock: clock,
    arrival: arrivals,
    pageSize: pageSize,
  );

  // Links the sample Item and lets its first sync complete, as the Link flow does.
  Future<void> link() async {
    await client.api.exchangePublicToken('public-demo-sample-item-1');
    await client.api.syncItem('sample-item-1');
    await client.api.syncItem('sample-item-1');
  }

  Future<List<Transaction>> live() => DriftTransactionRepository(
    database,
    clock,
    recorder: recorder(),
  ).watch(TransactionQuery.all).first;

  test('pulls the Items, accounts and transactions as the server sent them, '
      'recording nothing', () async {
    await link();
    await pull().run();

    final List<LinkedBank> items = await DriftItemRepository(database)
        .watchAll()
        .first;
    expect(items.map((b) => b.id), ['sample-item-1']);
    expect(items.single.institution.name, 'First Platypus Bank');
    expect(items.single.item.status, ItemStatus.healthy);
    final List<Account> accounts = await DriftAccountRepository(
      database,
      clock,
      recorder: recorder(),
    ).watchAll().first;
    expect(accounts, hasLength(3));
    expect(accounts.every((a) => a.itemId == 'sample-item-1'), isTrue);
    final List<Transaction> rows = await live();
    expect(rows, hasLength(12));
    expect(rows.every((t) => t.source == DataSource.demo), isTrue);
    expect(rows.every((t) => t.syncVersion > 0), isTrue);
    expect(await store.transactionsSince(), 12);
    expect(await store.pulledAt(), isNotNull);
    expect(await syncStore.unsynced(), isEmpty);
    expect(arrivals.pages, hasLength(1));
    expect(arrivals.pages.single, unorderedEquals(rows.map((t) => t.id)));
  });

  test('pages by sync_version and saves the cursor after each page; a failed '
      'page is rolled back and leaves the cursor', () async {
    await link();
    arrivals.failOnCall = 2;
    await expectLater(pull(pageSize: 5).run(), throwsStateError);
    expect(await store.transactionsSince(), 5);
    expect(await live(), hasLength(5));
    expect(await store.pulledAt(), isNull);

    server.calls.clear();
    await pull(pageSize: 5).run();
    expect(await store.transactionsSince(), 12);
    expect(await live(), hasLength(12));
    expect(
      server.calls.where((c) => c == 'listTransactions'),
      hasLength(2),
      reason: 'from 5: one page of 5, then the last 2',
    );
  });

  test('a cursor past the server restarts from 0 once', () async {
    await link();
    await store.saveTransactionsSince(999);
    await pull().run();
    expect(await store.transactionsSince(), 12);
    expect(await live(), hasLength(12));
  });

  test('an unlinked Item goes with its accounts and transactions', () async {
    await link();
    await pull().run();
    await client.api.deleteItem('sample-item-1');
    await pull().run();

    expect(await DriftItemRepository(database).watchAll().first, isEmpty);
    expect(
      await DriftAccountRepository(
        database,
        clock,
        recorder: recorder(),
      ).watchAll().first,
      isEmpty,
    );
    expect(await live(), isEmpty);
    expect(await syncStore.unsynced(), isEmpty);
  });

  test('an override pulled before its Plaid row lands on the row', () async {
    final Hlc at = Hlc(clock.nowUtc().millisecondsSinceEpoch, 0, 'device-b');
    await syncStore.write(
      EntityRecord(
        type: EntityType.transaction,
        id: 'sample-txn-01',
        fields: const {'notes': 'from my phone'},
        fieldClocks: {'notes': at},
      ),
    );
    expect((await syncStore.watchLedger().first).held, 1);
    await link();
    await pull().run();

    final Transaction row = (await live()).firstWhere(
      (t) => t.id == 'sample-txn-01',
    );
    expect(row.notes, 'from my phone');
    expect((await syncStore.watchLedger().first).held, 0);
  });

  test(
    'the arrival processor sees a held override already on its row',
    () async {
      final Hlc at = Hlc(clock.nowUtc().millisecondsSinceEpoch, 0, 'device-b');
      await syncStore.write(
        EntityRecord(
          type: EntityType.transaction,
          id: 'sample-txn-02',
          fields: const {'user_category_id': 'cat-coffee'},
          fieldClocks: {'user_category_id': at},
        ),
      );
      final _Seen seen = _Seen();
      await link();
      await PlaidPull(
        api: client.api,
        store: store,
        items: DriftItemRepository(database),
        accounts: DriftAccountRepository(database, clock, recorder: recorder()),
        transactions: DriftTransactionRepository(
          database,
          clock,
          recorder: recorder(),
        ),
        clock: clock,
        arrival: seen,
      ).run();
      final Transaction arrived = seen.rows.firstWhere(
        (t) => t.id == 'sample-txn-02',
      );
      expect(arrived.userCategoryId, 'cat-coffee');
      expect(seen.rows, hasLength(12));
    },
  );

  test(
    'single flight: calls during a run share one more run after it',
    () async {
      await link();
      final PlaidPull p = pull();
      server.calls.clear();
      final Future<void> first = p.run();
      final Future<void> second = p.run();
      final Future<void> third = p.run();
      expect(identical(second, third), isTrue);
      await Future.wait([first, second, third]);
      expect(server.calls.where((c) => c == 'listItems'), hasLength(2));
      expect(arrivals.pages.last, isEmpty, reason: 'the rerun inserts nothing');
    },
  );

  test('fetches a logo once, and again after a failed fetch', () async {
    final Uint8List png = Uint8List.fromList([137, 80, 78, 71, 13, 10]);
    final FakeItemData sample = newFakeServer().dataset.items.single;
    server = newFakeServer(
      dataset: FakeDataset(
        items: [
          FakeItemData(
            id: sample.id,
            institution: sample.institution,
            institutionLogo: png,
            accounts: sample.accounts,
            transactions: sample.transactions,
          ),
        ],
      ),
    );
    client = FakeClient.signedIn(server);
    await link();
    server.failNext('getInstitutionLogo', 500);
    await pull().run();
    final DriftItemRepository items = DriftItemRepository(database);
    expect((await items.watchById('sample-item-1').first)!.logo, isNull);
    expect(
      await store.pulledAt(),
      isNotNull,
      reason: 'a logo never fails the pull',
    );

    await pull().run();
    expect((await items.watchById('sample-item-1').first)!.logo, png);
    server.calls.clear();
    await pull().run();
    expect(server.calls, isNot(contains('getInstitutionLogo')));
  });

  test('the in-memory repositories take the same pull', () async {
    await link();
    final InMemoryStore memory = InMemoryStore(clock);
    addTearDown(memory.close);
    final InMemorySyncStore outbox = InMemorySyncStore();
    final ChangeRecorder recording = EngineChangeRecorder(
      outbox,
      () async => HlcClock('device-a'),
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
    final InMemoryPlaidPullStore memoryStore = InMemoryPlaidPullStore();
    await PlaidPull(
      api: client.api,
      store: memoryStore,
      items: InMemoryItemRepository(memory),
      accounts: InMemoryAccountRepository(memory, recorder: recording),
      transactions: InMemoryTransactionRepository(memory, recorder: recording),
      clock: clock,
    ).run();
    expect(memory.items(), hasLength(1));
    expect(memory.accounts(), hasLength(3));
    expect(memory.count(TransactionQuery.all), 12);
    expect(await memoryStore.transactionsSince(), 12);
    expect(await outbox.unsynced(), isEmpty);
  });
}
