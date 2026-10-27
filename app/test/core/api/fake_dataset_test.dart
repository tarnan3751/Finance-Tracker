// The fake server's datasets from the persona engine: every persona's household is a
// valid dataset whose Items, accounts and transactions the API serves as the engine gave
// them, with every recurring expectation as a demo stream whose members are the seed's
// transactions of that name on that account, and the liabilities (auto loans left
// out); the empty dataset links nothing; and the demo flavor's fake serves the persona
// the demo shows, linked, with Houndstooth Bank still to link, while the demo
// repositories start from the same streams and liabilities.
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart' hide Liability;
import 'package:shared_models/shared_models.dart' as models show Liability;

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
}
