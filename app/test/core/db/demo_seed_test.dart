// The demo flavor's data from the persona engine: the persona chosen at start, what the
// demo repositories serve (the household's accounts and transactions, all `demo`, with
// opening balances so derived balances match the reported ones), and a persona switch.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('the starting persona is the dart-define slug, else the renter', () {
    expect(initialDemoPersona('family'), PersonaId.family);
    expect(initialDemoPersona('small_business'), PersonaId.smallBusiness);
    expect(initialDemoPersona(''), PersonaId.renter);
    expect(initialDemoPersona('landlord'), PersonaId.renter);
    expect(initialDemoPersona(), PersonaId.renter);
  });

  ProviderContainer demo() => ProviderContainer.test(
    overrides: [
      ...overridesFor(AppConfig.demo()),
      // 03:00 UTC on 25 October is still 24 October in New York.
      clockProvider.overrideWithValue(
        FixedClock(
          DateTime.utc(2026, 10, 25, 3),
          tz.getLocation('America/New_York'),
        ),
      ),
    ],
  );

  test(
    "the demo flavor serves the renter's household as of the clock's today",
    () async {
      final ProviderContainer container = demo();
      final DemoSeed seed = generateDemoSeed(
        PersonaId.renter,
        1,
        LocalDate(2026, 10, 24),
      );
      final List<Account> accounts = await container
          .read(accountRepositoryProvider)
          .watchAll()
          .first;
      expect(
        accounts.map((a) => a.id).toSet(),
        seed.household.accounts.map((a) => a.id).toSet(),
      );
      final List<Transaction> transactions = await container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .first;
      final int openings = seed.household.openingBalances
          .where((o) => !o.amount.isZero)
          .length;
      expect(
        transactions,
        hasLength(seed.household.transactions.length + openings),
      );
      expect(transactions.every((t) => t.source == DataSource.demo), isTrue);
      expect(transactions.first.date, LocalDate(2026, 10, 24));
      final Iterable<Transaction> opening = transactions.where(
        (t) => t.name == 'Opening balance',
      );
      expect(opening, hasLength(openings));
      expect(opening.map((t) => t.date).toSet(), {
        seed.household.window.start.addDays(-1),
      });

      // Derived from the history, each balance is what the account reports.
      final Map<String, Money?> derived = await container
          .read(accountRepositoryProvider)
          .watchDerivedBalances()
          .first;
      for (final Account account in seed.household.accounts) {
        if (account.type == AccountType.investment) continue;
        expect(derived[account.id], account.currentBalance, reason: account.id);
      }
      expect(
        await container.read(categoryRepositoryProvider).watchAll().first,
        hasLength(systemCategories.length),
      );
    },
  );

  test(
    "choosing another persona reloads the demo's data from its seed",
    () async {
      final ProviderContainer container = demo();
      // A demo transaction (the demo's accounts are linked, so they cannot go).
      await container
          .read(transactionRepositoryProvider)
          .delete('demo-renter-checking-opening');
      container.read(demoPersonaProvider.notifier).select(PersonaId.family);
      final List<Account> accounts = await container
          .read(accountRepositoryProvider)
          .watchAll()
          .first;
      expect(accounts.every((a) => a.id.startsWith('demo-family-')), isTrue);
      expect(
        accounts,
        hasLength(
          generateDemoSeed(
            PersonaId.family,
            1,
            LocalDate(2026, 10, 24),
          ).household.accounts.length,
        ),
      );
      container.read(demoPersonaProvider.notifier).select(PersonaId.renter);
      expect(
        await container
            .read(transactionRepositoryProvider)
            .watchById('demo-renter-checking-opening')
            .first,
        isNotNull,
        reason: "the demo's edits are not kept",
      );
    },
  );

  test('every persona loads through the store rules', () {
    for (final PersonaId persona in PersonaId.values) {
      final ProviderContainer container = demo();
      container.read(demoPersonaProvider.notifier).select(persona);
      expect(() => container.read(inMemoryStoreProvider), returnsNormally);
    }
  });
}
