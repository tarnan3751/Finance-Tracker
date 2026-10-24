// The screen tests' seed: deterministic for a day, all `demo` provenance, inside the 60
// days before today, every category it names seeded.
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'test_seed.dart';

void main() {
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
}
