// The fake server's datasets from the persona engine: every persona's household is a
// valid dataset whose Items, accounts and transactions the API serves as the engine gave
// them; the empty dataset links nothing; and the demo flavor's fake serves the persona
// the demo shows.
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

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
      },
    );
  }

  test('the empty dataset links nothing', () async {
    final FakeServer server = newFakeServer(dataset: FakeDataset.empty());
    final FakeClient client = FakeClient.signedIn(server);
    server.seedLinkedItems('ada@example.com');
    expect(await client.api.listAccounts(), isEmpty);
  });

  test("the demo flavor's fake serves the persona the demo shows", () async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.demo()),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    final DemoSeed seed = container.read(demoSeedProvider);
    final FakeDataset dataset = container.read(fakeServerProvider).dataset;
    expect(
      dataset.items.map((i) => i.id).toList(),
      seed.household.items.map((i) => i.id).toList(),
    );
  });
}
