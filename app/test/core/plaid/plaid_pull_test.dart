// The Plaid pull over the in-app fake server into the Drift repositories (the dev and
// prod path), and once into the in-memory ones: Items, linked accounts and transactions
// applied as the server sent them, paging by sync_version with the cursor saved per
// page, a failed page leaving the cursor, a cursor past the server restarting from 0, an
// unlinked Item's data going, an override pulled before its row landing on it, single
// flight, the arrival seam, nothing recorded, the rules applied on arrival, and the
// recurring streams, the liabilities and the holdings replaced and the investment
// transactions paged from their cursor, a failure of any list leaving the run and the
// other lists whole, and each whole run announced.
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_models.dart'
    hide Holding, InvestmentTransaction, Security;
import 'package:finance_tracker/core/api/api_models.dart' as wire;
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_plaid_pull_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/investments/data/drift_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/drift_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/items/data/drift_item_repository.dart';
import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/liabilities/data/drift_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/recurring/data/drift_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/rules/application/rule_runner.dart';
import 'package:finance_tracker/features/rules/data/drift_rule_repository.dart';
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
    streams: DriftRecurringStreamRepository(
      database,
      clock,
      recorder: recorder(),
    ),
    liabilities: DriftLiabilityRepository(database, clock),
    holdings: DriftHoldingRepository(database, clock),
    investmentTransactions: DriftInvestmentTransactionRepository(
      database,
      clock,
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
        streams: DriftRecurringStreamRepository(
          database,
          clock,
          recorder: recorder(),
        ),
        liabilities: DriftLiabilityRepository(database, clock),
        holdings: DriftHoldingRepository(database, clock),
        investmentTransactions: DriftInvestmentTransactionRepository(
          database,
          clock,
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

  group('recurring streams', () {
    DriftRecurringStreamRepository streams() =>
        DriftRecurringStreamRepository(database, clock, recorder: recorder());

    RecurringStream detected(String id) => RecurringStream(
      id: id,
      accountId: 'manual-acc',
      merchantName: 'Gym',
      cadence: RecurringCadence.monthly,
      averageAmount: Money(-4000, 'USD'),
      status: RecurringStatus.active,
      isSubscription: false,
      source: RecurringSource.detected,
    );

    test('are replaced by the server\'s list, the detected ones and the '
        'overrides kept, nothing recorded', () async {
      final RecurringStream netflix =
          server.dataset.items.single.recurringStreams.single;
      await streams().replaceDetected([detected('det-1')]);
      await streams().applyPlaid([
        netflix.copyWith(id: 'gone', source: RecurringSource.plaid),
      ]);
      await link();
      await pull().run();
      final List<StreamView> views = await streams().watchAll().first;
      expect(
        [for (final StreamView v in views) v.stream],
        [detected('det-1'), netflix],
      );
      expect(views.last.stream.transactionIds, netflix.transactionIds);
      expect(await syncStore.unsynced(), isEmpty);

      await streams().setOverride(netflix.id, (o) => o.withMuted(true));
      await pull().run();
      expect((await streams().watchById(netflix.id).first)!.muted, isTrue);
    });

    test('a failed list is logged and leaves the transactions pulled and the '
        'stored streams as they were', () async {
      final RecurringStream old = detected('old')
          .copyWith(source: RecurringSource.demo);
      await streams().applyPlaid([old]);
      await link();
      server.failNext('listRecurringStreams', 500);
      await pull().run();
      expect(await live(), hasLength(12));
      expect(await store.transactionsSince(), 12);
      expect(await store.pulledAt(), isNotNull);
      expect(
        [for (final StreamView v in await streams().watchAll().first) v.stream],
        [old],
      );

      await pull().run();
      expect(
        (await streams().watchAll().first).single.stream.id,
        'sample-stream-netflix',
      );
    });
  });

  group('liabilities', () {
    test('are replaced by the server\'s list, the payload as sent, nothing '
        'recorded', () async {
      final DriftLiabilityRepository liabilities = DriftLiabilityRepository(
        database,
        clock,
      );
      await liabilities.applyPlaid([
        const Liability(
          accountId: 'gone',
          kind: LiabilityKind.student,
          source: DataSource.demo,
          payload: {},
        ),
      ]);
      await link();
      await pull().run();
      final CreditLiability sent =
          server.dataset.items.single.liabilities.credit.single;
      final Liability card = (await liabilities.watchAll().first).single;
      expect(card, sent.toLiability());
      expect(card.source, DataSource.demo);
      expect(card.aprs.single.percentageBasisPoints, 2499);
      expect(card.minimumPaymentAmount, Money(2500, 'USD'));
      expect(card.payload, sent.toJson());
      expect(await syncStore.unsynced(), isEmpty);
    });

    test('a failed list leaves the transactions and the streams pulled, and '
        'the stored liabilities as they were', () async {
      final DriftLiabilityRepository liabilities = DriftLiabilityRepository(
        database,
        clock,
      );
      await link();
      server.failNextNetwork('getLiabilities');
      await pull().run();
      expect(await live(), hasLength(12));
      expect(
        await DriftRecurringStreamRepository(
          database,
          clock,
          recorder: recorder(),
        ).watchAll().first,
        hasLength(1),
      );
      expect(await store.pulledAt(), isNotNull);
      expect(await liabilities.watchAll().first, isEmpty);
      await pull().run();
      expect(await liabilities.watchAll().first, hasLength(1));
    });
  });

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
    final InMemoryRecurringStreamRepository memoryStreams =
        InMemoryRecurringStreamRepository(clock, recorder: recording);
    addTearDown(memoryStreams.close);
    final InMemoryLiabilityRepository memoryLiabilities =
        InMemoryLiabilityRepository();
    addTearDown(memoryLiabilities.close);
    final InMemoryHoldingRepository memoryHoldings =
        InMemoryHoldingRepository();
    addTearDown(memoryHoldings.close);
    final InMemoryInvestmentTransactionRepository memoryInvestments =
        InMemoryInvestmentTransactionRepository();
    addTearDown(memoryInvestments.close);
    await PlaidPull(
      api: client.api,
      store: memoryStore,
      items: InMemoryItemRepository(memory),
      accounts: InMemoryAccountRepository(memory, recorder: recording),
      transactions: InMemoryTransactionRepository(memory, recorder: recording),
      streams: memoryStreams,
      liabilities: memoryLiabilities,
      holdings: memoryHoldings,
      investmentTransactions: memoryInvestments,
      clock: clock,
    ).run();
    expect(memory.items(), hasLength(1));
    expect(memory.accounts(), hasLength(3));
    expect(memory.count(TransactionQuery.all), 12);
    expect([
      for (final StreamView v in await memoryStreams.watchAll().first) v.stream,
    ], server.dataset.items.single.recurringStreams);
    expect(
      await memoryLiabilities.watchAll().first,
      server.dataset.items.single.liabilities.toEntities(),
    );
    expect(await memoryStore.transactionsSince(), 12);
    expect(await memoryStore.investmentTransactionsSince(), 0);
    expect(await memoryHoldings.watchAll().first, isEmpty);
    expect(await outbox.unsynced(), isEmpty);
  });

  group('investments', () {
    // The sample Item with a 401k: two holdings (one of a security the server does not
    // list), one security, and three investment transactions.
    FakeDataset withInvestments() {
      final FakeItemData sample = newFakeServer().dataset.items.single;
      final Account ira = sample.accounts.first.copyWith(
        id: 'sample-ira',
        type: AccountType.investment,
        subtype: '401k',
        name: 'Plaid 401k',
        currentBalance: Money(554763, 'USD'),
        availableBalance: null,
        displayOrder: 3,
      );
      wire.InvestmentTransaction row(String id, String date, int amount) =>
          wire.InvestmentTransaction(
            id: id,
            accountId: ira.id,
            securityId: amount < 0 ? 'sec_vti' : null,
            date: LocalDate.parse(date),
            name: amount < 0 ? 'BUY VTI' : 'PAYROLL CONTRIBUTION',
            type: amount < 0 ? 'buy' : 'cash',
            subtype: amount < 0 ? 'buy' : 'contribution',
            quantity: amount < 0 ? '0.9643' : '0',
            price: amount < 0 ? '280.00' : '0',
            amount: Money(amount, 'USD'),
            syncVersion: 0,
            source: DataSource.demo,
          );
      return FakeDataset(
        items: [
          FakeItemData(
            id: sample.id,
            institution: sample.institution,
            accounts: [...sample.accounts, ira],
            transactions: sample.transactions,
            recurringStreams: sample.recurringStreams,
            liabilities: sample.liabilities,
            holdings: [
              wire.Holding(
                accountId: ira.id,
                securityId: 'sec_vti',
                quantity: '11.2439',
                institutionPrice: '298.00',
                institutionPriceAsOf: LocalDate(2026, 10, 23),
                institutionValue: Money(335068, 'USD'),
                costBasis: Money(324000, 'USD'),
                currencyCode: 'USD',
                source: DataSource.demo,
              ),
              wire.Holding(
                accountId: ira.id,
                securityId: 'sec_unlisted',
                quantity: '1',
                institutionPrice: '219695',
                institutionValue: Money(21969500, 'USD'),
                currencyCode: 'USD',
                source: DataSource.demo,
              ),
            ],
            securities: [
              wire.Security(
                id: 'sec_vti',
                name: 'Vanguard Total Stock Market ETF',
                tickerSymbol: 'VTI',
                type: 'etf',
                isCashEquivalent: false,
                closePrice: '298.00',
                closePriceAsOf: LocalDate(2026, 10, 23),
                currencyCode: 'USD',
                source: DataSource.demo,
              ),
            ],
            investmentTransactions: [
              row('inv-1', '2026-09-07', 45000),
              row('inv-2', '2026-09-07', -27000),
              row('inv-3', '2026-10-07', 45000),
            ],
          ),
        ],
      );
    }

    late DriftHoldingRepository holdings;
    late DriftInvestmentTransactionRepository investments;

    setUp(() {
      server = newFakeServer(dataset: withInvestments());
      client = FakeClient.signedIn(server);
      holdings = DriftHoldingRepository(database, clock);
      investments = DriftInvestmentTransactionRepository(database, clock);
    });

    Future<List<InvestmentTransaction>> ira() =>
        investments.watchByAccount('sample-ira').first;

    test(
      'the holdings and securities are replaced by the server\'s, the '
      'investment transactions paged from their cursor, nothing recorded',
      () async {
        await holdings.applyPlaid([
          Holding(
            accountId: 'gone',
            securityId: 'sec_old',
            quantity: Decimal.parse('1'),
            institutionPrice: Decimal.parse('1'),
            institutionValue: Money(100, 'USD'),
            source: DataSource.demo,
          ),
        ], const []);
        await link();
        await pull(pageSize: 2).run();
        final wire.Holdings sent = wire.Holdings(
          holdings: server.dataset.items.single.holdings,
          securities: server.dataset.items.single.securities,
        );
        final List<HoldingView> stored = await holdings.watchAll().first;
        expect(
          [for (final HoldingView v in stored) v.holding],
          [sent.toEntities().holdings.last, sent.toEntities().holdings.first],
        );
        expect(stored.last.security, sent.toEntities().securities.single);
        expect(stored.first.security, isNull);
        expect(stored.last.holding.quantity.toString(), '11.2439');
        expect(stored.last.holding.source, DataSource.demo);
        final List<InvestmentTransaction> rows = await ira();
        expect(
          [for (final InvestmentTransaction t in rows) t.id],
          ['inv-3', 'inv-2', 'inv-1'],
        );
        expect(rows[1].amount, Money(-27000, 'USD'));
        expect(rows[1].price, Decimal.parse('280.00'));
        expect(rows[1].source, DataSource.demo);
        // The transactions took versions 1 to 12, the investment transactions 13 to 15.
        expect(
          [for (final InvestmentTransaction t in rows) t.syncVersion],
          [15, 14, 13],
        );
        expect(await store.investmentTransactionsSince(), 15);
        expect(await syncStore.unsynced(), isEmpty);
      },
    );

    test('an unlinked Item\'s rows come back as tombstones and its holdings '
        'go', () async {
      await link();
      await pull().run();
      await client.api.deleteItem('sample-item-1');
      await pull().run();
      expect(await ira(), isEmpty);
      expect(await holdings.watchAll().first, isEmpty);
      final List<InvestmentTransactionRow> kept = await database
          .select(database.investmentTransactions)
          .get();
      expect(kept, hasLength(3));
      expect(kept.every((r) => r.deletedAt != null), isTrue);
      expect(await store.investmentTransactionsSince(), 30);
    });

    test('a failed list leaves the run and the other lists whole', () async {
      await link();
      server.failNextNetwork('listHoldings');
      await pull().run();
      expect(await live(), hasLength(12));
      expect(await holdings.watchAll().first, isEmpty);
      expect(await ira(), hasLength(3));
      expect(await store.pulledAt(), isNotNull);

      await store.saveInvestmentTransactionsSince(13);
      server.failNextNetwork('listInvestmentTransactions');
      await pull().run();
      expect(await holdings.watchAll().first, hasLength(2));
      expect(await store.investmentTransactionsSince(), 13);
    });

    test('a cursor past the server restarts from 0 once', () async {
      await link();
      await store.saveInvestmentTransactionsSince(99);
      await pull().run();
      expect(await ira(), hasLength(3));
      expect(await store.investmentTransactionsSince(), 15);
    });
  });

  test(
    'each whole run is announced once it is saved; a failed one is not',
    () async {
      final PlaidPull plaid = pull();
      final List<DateTime> runs = [];
      final sub = plaid.completed.listen(runs.add);
      addTearDown(sub.cancel);
      await link();
      await plaid.run();
      await pumpEventQueue();
      expect(runs, [await store.pulledAt()]);
      server.failNextNetwork('listItems');
      await expectLater(plaid.run(), throwsA(anything));
      await pumpEventQueue();
      expect(runs, hasLength(1));
    },
  );

  group('the rules on arrival', () {
    // Every pulled transaction is in USD; this rule matches them all.
    final Rule tagAll = Rule(
      id: 'rule-all',
      name: 'Everything',
      position: 0,
      conditions: [
        RuleCondition(
          kind: RuleConditionKind.amountBetween,
          minAmount: Money(0, 'USD'),
        ),
      ],
      actions: const [
        RuleAction(
          kind: RuleActionKind.setCategory,
          value: 'plaid:FOOD_AND_DRINK_COFFEE',
        ),
        RuleAction(kind: RuleActionKind.addTag, value: 'pulled'),
      ],
    );

    PlaidPull rulesPull() {
      final DriftTransactionRepository transactions =
          DriftTransactionRepository(database, clock, recorder: recorder());
      final DriftCategoryRepository categories = DriftCategoryRepository(
        database,
        clock,
        recorder: recorder(),
      );
      return PlaidPull(
        api: client.api,
        store: store,
        items: DriftItemRepository(database),
        accounts: DriftAccountRepository(database, clock, recorder: recorder()),
        transactions: transactions,
        streams: DriftRecurringStreamRepository(
          database,
          clock,
          recorder: recorder(),
        ),
        liabilities: DriftLiabilityRepository(database, clock),
        holdings: DriftHoldingRepository(database, clock),
        investmentTransactions: DriftInvestmentTransactionRepository(
          database,
          clock,
        ),
        clock: clock,
        arrival: RuleRunner(
          rules: DriftRuleRepository(database, clock, recorder: recorder()),
          categories: categories,
          transactions: transactions,
          syncStore: syncStore,
        ),
      );
    }

    setUp(() async {
      await DriftCategoryRepository(
        database,
        clock,
        recorder: recorder(),
      ).ensureSeeded();
      await DriftRuleRepository(
        database,
        clock,
        recorder: recorder(),
      ).upsert(tagAll);
    });

    test('a row whose write fails partway rolls back alone, and the page '
        'commits', () async {
      await link();
      // The server's rows as bank rows, kept to compare with what is stored.
      final _PlaidSourced api = _PlaidSourced(client.api);
      final List<Transaction> page = (await client.api.listTransactions(
        limit: 3,
      )).items;
      final String failing = page[1].id;
      final ChangeRecorder throwing = _ThrowingRecorder(recorder(), failing);
      final DriftTransactionRepository transactions =
          DriftTransactionRepository(database, clock, recorder: throwing);
      await PlaidPull(
        api: api,
        store: store,
        items: DriftItemRepository(database),
        accounts: DriftAccountRepository(database, clock, recorder: recorder()),
        transactions: transactions,
        streams: DriftRecurringStreamRepository(
          database,
          clock,
          recorder: recorder(),
        ),
        liabilities: DriftLiabilityRepository(database, clock),
        holdings: DriftHoldingRepository(database, clock),
        investmentTransactions: DriftInvestmentTransactionRepository(
          database,
          clock,
        ),
        clock: clock,
        arrival: RuleRunner(
          rules: DriftRuleRepository(database, clock, recorder: recorder()),
          categories: DriftCategoryRepository(
            database,
            clock,
            recorder: recorder(),
          ),
          transactions: transactions,
          syncStore: syncStore,
        ),
        pageSize: 3,
      ).run();

      expect(await store.transactionsSince(), 12, reason: 'every page saved');
      final Map<String, Transaction> stored = {
        for (final Transaction t in await live()) t.id: t,
      };
      final Map<String, List<ChangeLogEntry>> outbox = {};
      for (final ChangeLogEntry e in await syncStore.unsynced(limit: 1000)) {
        (outbox[e.entityId] ??= []).add(e);
      }
      for (final Transaction sent in page) {
        final Transaction row = stored[sent.id]!;
        expect(row.source, DataSource.plaid, reason: sent.id);
        expect(row.updatedAt, sent.updatedAt, reason: sent.id);
        if (sent.id == failing) {
          expect(row.userCategoryId, isNull);
          expect(row.tags, isEmpty);
          expect(await syncStore.read(EntityType.transaction, failing), isNull);
          expect(outbox[failing], isNull);
          continue;
        }
        expect(row.tags, ['pulled'], reason: sent.id);
        final Set<String> owned = {
          'tags',
          if (sent.splits.isEmpty) 'user_category_id',
        };
        if (sent.splits.isEmpty) {
          expect(row.userCategoryId, 'plaid:FOOD_AND_DRINK_COFFEE');
        }
        expect(outbox[sent.id], hasLength(1), reason: sent.id);
        expect(outbox[sent.id]!.single.payload.keys.toSet(), owned);
      }
    });

    test(
      'the arriving transactions come in filed and tagged by the rule',
      () async {
        await link();
        await rulesPull().run();
        final List<Transaction> rows = await live();
        expect(rows, hasLength(12));
        for (final Transaction t in rows) {
          expect(t.tags, contains('pulled'), reason: t.id);
          if (t.splits.isEmpty && t.userCategoryId == null) {
            fail('${t.id} was not filed');
          }
        }
      },
    );

    test('an override pulled earlier is respected: the rule writes over the '
        'row as stored, not as the page first inserted it', () async {
      final Hlc at = Hlc(clock.nowUtc().millisecondsSinceEpoch, 0, 'device-b');
      await syncStore.write(
        EntityRecord(
          type: EntityType.transaction,
          id: 'sample-txn-01',
          fields: const {'notes': 'from my phone'},
          fieldClocks: {'notes': at},
        ),
      );
      await link();
      await rulesPull().run();
      final Transaction row = (await live()).firstWhere(
        (t) => t.id == 'sample-txn-01',
      );
      expect(row.notes, 'from my phone');
      expect(row.tags, contains('pulled'));
    });

    test(
      'a page with nothing to change, and a second run, write nothing more',
      () async {
        await link();
        await rulesPull().run();
        final List<Transaction> once = await live();
        await rulesPull().run();
        expect(await live(), once);
      },
    );
  });
}

/// The fake server's transactions as bank rows (`source: plaid`); the rest of the API as
/// the fake serves it, for what the pull calls.
final class _PlaidSourced implements FinanceApi {
  _PlaidSourced(this._inner);

  final FinanceApi _inner;

  @override
  Future<List<LinkedItem>> listItems() => _inner.listItems();

  @override
  Future<List<Account>> listAccounts() => _inner.listAccounts();

  @override
  Future<Uint8List> getInstitutionLogo(String institutionId) =>
      _inner.getInstitutionLogo(institutionId);

  @override
  Future<List<RecurringStream>> listRecurringStreams() =>
      _inner.listRecurringStreams();

  @override
  Future<Liabilities> getLiabilities() => _inner.getLiabilities();

  @override
  Future<wire.Holdings> listHoldings() => _inner.listHoldings();

  @override
  Future<VersionPage<wire.InvestmentTransaction>> listInvestmentTransactions({
    int since = 0,
    int limit = 500,
  }) => _inner.listInvestmentTransactions(since: since, limit: limit);

  @override
  Future<VersionPage<Transaction>> listTransactions({
    int since = 0,
    int limit = 500,
  }) async {
    final VersionPage<Transaction> page = await _inner.listTransactions(
      since: since,
      limit: limit,
    );
    return (
      items: [
        for (final Transaction t in page.items)
          t.copyWith(source: DataSource.plaid),
      ],
      nextSince: page.nextSince,
      hasMore: page.hasMore,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used by the pull');
}

/// Records through [_inner], then throws for transaction [_failOn]: a write that fails
/// after its row and its entry are written.
final class _ThrowingRecorder implements ChangeRecorder {
  _ThrowingRecorder(this._inner, this._failOn);

  final ChangeRecorder _inner;
  final String _failOn;

  @override
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {
    await _inner.record(type, id, before, after);
    if (id == _failOn) throw StateError('the write failed after the row');
  }
}
