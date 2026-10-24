// The demo seed: deterministic for a day, all `demo` provenance, inside the 60 days before
// today, every category it names seeded, and what the demo flavor's providers serve.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final LocalDate today = LocalDate(2026, 10, 24);

  test('the same day gives the same seed', () {
    final DemoSeed a = buildDemoSeed(today);
    final DemoSeed b = buildDemoSeed(today);
    expect(a.accounts, equals(b.accounts));
    expect(a.transactions, equals(b.transactions));
    expect(
      buildDemoSeed(today.addDays(1)).transactions.first.date,
      a.transactions.first.date.addDays(1),
    );
  });

  test(
    'two manual accounts and a dozen demo transactions in the last 60 days',
    () {
      final DemoSeed seed = buildDemoSeed(today);
      expect(seed.accounts, hasLength(2));
      expect(seed.accounts.every((a) => a.itemId == null), isTrue);
      expect(seed.transactions, hasLength(12));
      expect(seed.transactions.map((t) => t.id).toSet(), hasLength(12));
      for (final Transaction t in seed.transactions) {
        expect(t.source, DataSource.demo);
        expect(t.date.isBefore(today), isTrue);
        expect(t.date.daysUntil(today), lessThanOrEqualTo(60));
      }
    },
  );

  test('every category the seed names is a system category', () {
    final Set<String> system = {for (final c in systemCategories) c.id};
    for (final Transaction t in buildDemoSeed(today).transactions) {
      if (t.userCategoryId != null) expect(system, contains(t.userCategoryId));
      for (final TransactionSplit s in t.splits) {
        expect(system, contains(s.categoryId));
      }
    }
  });

  test(
    "the demo flavor's repositories serve the seed for the clock's today",
    () async {
      // 03:00 UTC on 25 October is still 24 October in New York.
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          ...overridesFor(AppConfig.demo()),
          clockProvider.overrideWithValue(
            FixedClock(
              DateTime.utc(2026, 10, 25, 3),
              tz.getLocation('America/New_York'),
            ),
          ),
        ],
      );

      final List<Transaction> transactions = await container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .first;
      expect(
        transactions,
        equals(
          buildDemoSeed(today).transactions.reversed.toList()..sort((a, b) {
            final int byDate = b.date.compareTo(a.date);
            return byDate != 0 ? byDate : b.id.compareTo(a.id);
          }),
        ),
      );
      expect(
        await container
            .read(accountRepositoryProvider)
            .watchDerivedBalances()
            .first,
        {
          'demo-checking': Money(492591, 'USD'),
          'demo-card': Money(-575, 'USD'),
        },
      );
      expect(
        await container.read(categoryRepositoryProvider).watchAll().first,
        hasLength(systemCategories.length),
      );
    },
  );
}
