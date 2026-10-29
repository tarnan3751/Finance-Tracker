// The fake server's datasets from the persona engine: every persona's household is a
// valid dataset whose Items, accounts and transactions the API serves as the engine gave
// them, with every recurring expectation as a demo stream whose members are the seed's
// transactions of that name on that account, and the liabilities (auto loans left
// out), and the brokerage's holdings, securities and investment transactions (the
// family's; none for the others); the empty dataset links nothing; and the demo
// flavor's fake serves the persona the demo shows, linked, with Houndstooth Bank still
// to link, while the demo repositories start from the same streams, liabilities and
// investments.
import 'package:finance_tracker/core/api/api_models.dart'
    hide Holding, InvestmentTransaction, Security;
import 'package:finance_tracker/core/api/api_models.dart' as wire;
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/investments/data/demo_holding_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Liability, Security;
import 'package:shared_models/shared_models.dart'
    as models
    show Holding, InvestmentTransaction, Liability, Security;

import 'support/fake_api.dart';

void main() {
  final LocalDate asOf = LocalDate(2026, 10, 24);

  for (final PersonaId persona in PersonaId.values) {
    test(
      'the ${persona.slug} household is served as the engine gave it',
      () async {
        final DemoSeed seed = generateDemoSeed(persona, 1, asOf, days: 120);
        final FakeServer server = newFakeServer(
          dataset: FakeDataset.fromDemoSeed(seed),
        );
        final FakeClient client = FakeClient.signedIn(server);
        server.seedLinkedItems('ada@example.com');

        final List<Account> accounts = await client.api.listAccounts();
        expect(
          accounts.map((a) => a.id).toSet(),
          seed.household.accounts.map((a) => a.id).toSet(),
        );
        final List<Transaction> transactions = [];
        int since = 0;
        while (true) {
          final VersionPage<Transaction> page = await client.api
              .listTransactions(since: since);
          transactions.addAll(page.items);
          since = page.nextSince;
          if (!page.hasMore) break;
        }
        expect(
          transactions.map((t) => t.id).toSet(),
          seed.household.transactions.map((t) => t.id).toSet(),
        );
        expect(transactions.every((t) => t.source == DataSource.demo), isTrue);
        final Transaction first = seed.household.transactions.first;
        expect(
          transactions.firstWhere((t) => t.id == first.id).amount,
          first.amount,
        );
        expect(
          (await client.api.listItems()).map((i) => i.item.id).toSet(),
          seed.household.items.map((i) => i.id).toSet(),
        );

        final List<RecurringStream> streams = await client.api
            .listRecurringStreams();
        expect(streams.map((s) => s.id).toSet(), {
          for (final r in seed.household.recurring) 'demo-stream-${r.key}',
        });
        expect(streams.toSet(), demoRecurringStreams(seed).toSet());
        for (final RecurringExpectation r in seed.household.recurring) {
          final RecurringStream s = streams.firstWhere(
            (s) => s.id == 'demo-stream-${r.key}',
          );
          expect(s.source, RecurringSource.demo);
          expect(s.accountId, r.accountId);
          expect(s.cadence, r.cadence);
          expect(s.isSubscription, r.isSubscription);
          expect(s.averageAmount.isPositive, r.isInflow, reason: r.key);
          final Money magnitude = s.averageAmount.abs();
          expect(
            magnitude >= r.minAmount && magnitude <= r.maxAmount,
            isTrue,
            reason: r.key,
          );
          final List<Transaction> members = [
            for (final String id in s.transactionIds)
              transactions.firstWhere((t) => t.id == id),
          ];
          expect(
            members.every(
              (t) => t.accountId == r.accountId && t.name == r.name,
            ),
            isTrue,
            reason: r.key,
          );
          if (r.cadence != RecurringCadence.annually &&
              r.cadence != RecurringCadence.unknown) {
            expect(members, isNotEmpty, reason: r.key);
          }
          expect(s.nextExpected!.isAfter(asOf), isTrue, reason: r.key);
          if (s.lastExpected case final LocalDate last) {
            expect(last.isAfter(asOf), isFalse, reason: r.key);
          }
        }

        final Liabilities liabilities = await client.api.getLiabilities();
        expect(liabilities.toJson(), demoLiabilities(seed).toJson());
        final List<models.Liability> entities = liabilities.toEntities();
        expect(entities.every((l) => l.source == DataSource.demo), isTrue);
        final int autoLoans = seed.household.liabilities
            .where((l) => l is LoanLiability && l.kind == LoanKind.auto)
            .length;
        expect(
          entities,
          hasLength(seed.household.liabilities.length - autoLoans),
        );

        final wire.Holdings holdings = await client.api.listHoldings();
        expect(holdings.toJson(), demoHoldings(seed).toJson());
        expect(holdings.holdings, hasLength(seed.household.holdings.length));
        final List<wire.InvestmentTransaction> investments = [];
        since = 0;
        while (true) {
          final VersionPage<wire.InvestmentTransaction> page = await client.api
              .listInvestmentTransactions(since: since);
          investments.addAll(page.items);
          since = page.nextSince;
          if (!page.hasMore) break;
        }
        expect(
          investments.map((t) => t.id).toSet(),
          seed.household.investmentTransactions.map((t) => t.id).toSet(),
        );
        expect(
          [
            ...holdings.holdings.map((h) => h.source),
            ...holdings.securities.map((s) => s.source),
            ...investments.map((t) => t.source),
          ].every((s) => s == DataSource.demo),
          isTrue,
        );
        if (persona != PersonaId.family) {
          expect(holdings.holdings, isEmpty);
          expect(investments, isEmpty);
          return;
        }
        // The family's 401k: the three ETFs, each position's value the engine's, and
        // the account reporting their value plus its cash.
        expect(holdings.securities.map((s) => s.tickerSymbol).toSet(), {
          'VTI',
          'VXUS',
          'BND',
        });
        final Account ira = accounts.singleWhere(
          (a) => a.type == AccountType.investment,
        );
        final List<models.Holding> held = holdings.toEntities().holdings;
        expect(held.every((h) => h.accountId == ira.id), isTrue);
        for (final Holding h in seed.household.holdings) {
          final models.Holding mapped = held.singleWhere(
            (m) => m.securityId == demoSecurityId(h.security.ticker),
          );
          expect(mapped.institutionValue, h.value);
          expect(mapped.costBasis, h.costBasis);
          expect(
            mapped.quantity.unscaled,
            BigInt.from(h.quantityMilli),
            reason: h.security.ticker,
          );
          expect(mapped.quantity.scale, 3);
        }
        expect(
          (ira.currentBalance! - Money.sum(held.map((h) => h.institutionValue)))
              .isNegative,
          isFalse,
        );
        // In the app's sign: contributions in, buys out, which the cash between
        // the window's opening and the as-of date nets to.
        final List<models.InvestmentTransaction> rows = [
          for (final wire.InvestmentTransaction t in investments) t.toEntity(),
        ];
        expect(
          rows.where((t) => t.type == 'cash').every((t) => t.amount.isPositive),
          isTrue,
        );
        expect(
          rows.where((t) => t.type == 'buy').every((t) => t.amount.isNegative),
          isTrue,
        );
        expect(rows.where((t) => t.type == 'buy'), isNotEmpty);
      },
    );
  }

  test('the empty dataset links nothing', () async {
    final FakeServer server = newFakeServer(dataset: FakeDataset.empty());
    final FakeClient client = FakeClient.signedIn(server);
    server.seedLinkedItems('ada@example.com');
    expect(await client.api.listAccounts(), isEmpty);
  });

  test("the demo flavor's fake serves the persona the demo shows, and one more "
      'bank to link', () async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.demo()),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    final DemoSeed seed = container.read(demoSeedProvider);
    final FakeDataset dataset = container.read(fakeServerProvider).dataset;
    expect(dataset.items.map((i) => i.id).toList(), [
      ...seed.household.items.map((i) => i.id),
      'demo-houndstooth',
    ]);
    // The demo user has the household's Items; the sample's is there to link.
    final FinanceApi api = container.read(financeApiProvider);
    final List<String> linked = [
      for (final i in await api.listItems()) i.item.id,
    ];
    expect(linked, unorderedEquals(seed.household.items.map((i) => i.id)));

    // The demo repositories start from what the fake serves for those Items.
    expect({
      for (final StreamView v
          in await container
              .read(recurringStreamRepositoryProvider)
              .watchAll()
              .first)
        v.stream,
    }, (await api.listRecurringStreams()).toSet());
    expect(
      (await container.read(liabilityRepositoryProvider).watchAll().first)
          .toSet(),
      (await api.getLiabilities()).toEntities().toSet(),
    );
    expect(await api.listRecurringStreams(), isNotEmpty);
  });

  test("the demo's family persona starts its investment repositories from what "
      'the fake serves', () async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.demo()),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    container.read(demoPersonaProvider.notifier).select(PersonaId.family);
    final FinanceApi api = container.read(financeApiProvider);
    final List<HoldingView> stored = await container
        .read(holdingRepositoryProvider)
        .watchAll()
        .first;
    final ({List<models.Holding> holdings, List<models.Security> securities})
    served = (await api.listHoldings()).toEntities();
    expect(stored.map((v) => v.holding).toSet(), served.holdings.toSet());
    expect(stored, hasLength(3));
    expect(stored.every((v) => v.security != null), isTrue);
    final String ira = stored.first.holding.accountId;
    final List<models.InvestmentTransaction> rows = await container
        .read(investmentTransactionRepositoryProvider)
        .watchByAccount(ira)
        .first;
    final VersionPage<wire.InvestmentTransaction> page = await api
        .listInvestmentTransactions();
    expect(rows.map((t) => t.id).toSet(), {
      for (final wire.InvestmentTransaction t in page.items) t.id,
    });
    expect(rows, isNotEmpty);
  });

  test('two positions in one security list it once', () {
    final GeneratedHousehold h = generateDemoSeed(
      PersonaId.family,
      1,
      asOf,
      days: 120,
    ).household;
    final Holding vti = h.holdings.first;
    final String other = h.accounts.firstWhere((a) => a.id != vti.accountId).id;
    final DemoSeed seed = DemoSeed(
      GeneratedHousehold(
        persona: h.persona,
        seed: h.seed,
        asOf: h.asOf,
        window: h.window,
        institutions: h.institutions,
        items: h.items,
        accounts: h.accounts,
        openingBalances: h.openingBalances,
        transactions: h.transactions,
        transfers: h.transfers,
        interestTransactionIds: h.interestTransactionIds,
        recurring: h.recurring,
        holdings: [
          ...h.holdings,
          Holding(
            accountId: other,
            security: vti.security,
            quantityMilli: 1000,
            costBasis: vti.price,
            price: vti.price,
            priceAsOf: vti.priceAsOf,
          ),
        ],
        openingHoldings: h.openingHoldings,
        investmentTransactions: h.investmentTransactions,
        liabilities: h.liabilities,
        anomalies: h.anomalies,
      ),
    );
    final wire.Holdings mapped = demoHoldings(seed);
    expect(mapped.holdings, hasLength(h.holdings.length + 1));
    expect(
      mapped.securities.map((s) => s.id).toList(),
      mapped.securities.map((s) => s.id).toSet().toList(),
    );
    expect(mapped.securities, hasLength(h.holdings.length));
    final ({List<models.Holding> holdings, List<models.Security> securities})
    entities = mapped.toEntities();
    expect(
      () => DemoHoldingRepository(
        holdings: entities.holdings,
        securities: entities.securities,
      ).close(),
      returnsNormally,
    );
    expect(() => FakeDataset.fromDemoSeed(seed), returnsNormally);
  });
}
