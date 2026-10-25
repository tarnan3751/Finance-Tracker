// The contract every BudgetRepository implementation passes: the in-memory, demo and
// Drift ones, each from its own test file under test/features/budgets/data/.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A budget [id] on [categoryId].
Budget testBudget(
  String id, {
  String categoryId = 'plaid:FOOD_AND_DRINK',
  int amount = 40000,
  String currency = 'USD',
  bool rollover = false,
}) => Budget(
  id: id,
  categoryId: categoryId,
  period: BudgetPeriodKind.monthly,
  periodStartDay: 25,
  amount: Money(amount, currency),
  rollover: rollover,
  startDate: LocalDate(2026, 8, 25),
);

/// Registers the contract tests for the fixtures [create] builds.
void runBudgetRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('BudgetRepository contract', () {
    late BudgetRepository budgets;

    setUp(() async => budgets = (await create()).budgets);
    if (dispose != null) tearDown(dispose);

    List<String> ids(List<Budget> list) => [for (final Budget b in list) b.id];

    test('a fresh repository has no budgets', () async {
      expect(await budgets.watchAll().first, isEmpty);
      expect(await budgets.watchById('b1').first, isNull);
    });

    test('upsert stores the budget as given, and replaces it', () async {
      final Budget euro = testBudget('b1', amount: 12345, currency: 'EUR');
      await budgets.upsert(euro);
      expect(await budgets.watchAll().first, [euro]);
      expect(await budgets.watchById('b1').first, euro);
      final Budget edited = euro.copyWith(
        rollover: true,
        periodStartDay: 1,
        startDate: LocalDate(2024, 2, 29),
      );
      await budgets.upsert(edited);
      expect(await budgets.watchAll().first, [edited]);
      expect(await budgets.watchById('b1').first, edited);
    });

    test('budgets are ordered by category, then by id', () async {
      await budgets.upsert(
        testBudget('b3', categoryId: 'plaid:TRANSPORTATION'),
      );
      await budgets.upsert(testBudget('b2'));
      await budgets.upsert(
        testBudget('b1', categoryId: 'plaid:TRANSPORTATION'),
      );
      await budgets.upsert(testBudget('b0', categoryId: 'Zebra'));
      expect(ids(await budgets.watchAll().first), ['b0', 'b2', 'b1', 'b3']);
    });

    test('a watcher gets the current budgets, then each change', () async {
      final Future<List<List<String>>> seen = budgets
          .watchAll()
          .map(ids)
          .take(3)
          .toList();
      final Future<List<int?>> one = budgets
          .watchById('b1')
          .map((b) => b?.amount.minorUnits)
          .take(4)
          .toList();
      await pumpEventQueue();
      await budgets.upsert(testBudget('b1'));
      await pumpEventQueue();
      await budgets.upsert(testBudget('b2'));
      await pumpEventQueue();
      await budgets.upsert(testBudget('b1', amount: 5));
      await pumpEventQueue();
      await budgets.delete('b1');
      expect(await seen, [
        <String>[],
        ['b1'],
        ['b1', 'b2'],
      ]);
      expect(await one, [null, 40000, 5, null]);
    });

    test('delete hides the budget; restore brings it back as it was', () async {
      await budgets.upsert(testBudget('b1', rollover: true));
      await budgets.upsert(testBudget('b2'));
      await budgets.delete('b1');
      expect(ids(await budgets.watchAll().first), ['b2']);
      expect(await budgets.watchById('b1').first, isNull);
      await budgets.restore('b1');
      expect(await budgets.watchAll().first, [
        testBudget('b1', rollover: true),
        testBudget('b2'),
      ]);
      expect(
        await budgets.watchById('b1').first,
        testBudget('b1', rollover: true),
      );
    });

    test('deleting or restoring what is not there does nothing', () async {
      await budgets.delete('missing');
      await budgets.restore('missing');
      await budgets.upsert(testBudget('b1'));
      await budgets.restore('b1');
      await budgets.delete('b1');
      await budgets.delete('b1');
      expect(await budgets.watchAll().first, isEmpty);
    });

    test('an upsert of a deleted budget throws and changes nothing', () async {
      await budgets.upsert(testBudget('b1'));
      await budgets.delete('b1');
      await expectLater(
        budgets.upsert(testBudget('b1', amount: 1)),
        throwsA(isA<EntityDeletedException>()),
      );
      await budgets.restore('b1');
      expect(await budgets.watchAll().first, [testBudget('b1')]);
    });
  });
}
