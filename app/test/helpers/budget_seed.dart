// Budgets for screen tests, over the test seed (test_seed.dart) on testClock's today,
// 24 October 2026, with periods from the 1st: Food and drink at $7.00 (82 % spent and
// projected over), Rent and utilities at $1,200.00 (over, at 120 %), and Transportation
// at $150.00 with carry-over from September (on pace, $150.00 carried).
//
//   await pumpApp(tester, overrides: [storeOverride(seededStore()), budgetsOverride(seededBudgets())]);
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';

/// A budget [id] on the system category [plaidCode] of [cents] USD a month from the 1st,
/// starting in September 2026.
Budget testBudget(
  String id,
  String plaidCode,
  int cents, {
  bool rollover = false,
  int periodStartDay = 1,
}) => Budget(
  id: id,
  categoryId: systemCategoryId(plaidCode),
  period: BudgetPeriodKind.monthly,
  periodStartDay: periodStartDay,
  amount: Money(cents, 'USD'),
  rollover: rollover,
  startDate: LocalDate(2026, 9, periodStartDay),
);

/// The three budgets of the header.
List<Budget> testBudgets() => [
  testBudget('budget-food', 'FOOD_AND_DRINK', 700),
  testBudget('budget-rent', 'RENT_AND_UTILITIES', 120000),
  testBudget('budget-transport', 'TRANSPORTATION', 15000, rollover: true),
];

/// An in-memory budget repository holding [budgets] ([testBudgets] by default).
InMemoryBudgetRepository seededBudgets([List<Budget>? budgets]) =>
    InMemoryBudgetRepository(
      testClock,
      recorder: const NoChangeRecorder(),
      initial: budgets ?? testBudgets(),
    );

/// The override that makes [budgets] the app's budget repository.
Override budgetsOverride(InMemoryBudgetRepository budgets) =>
    budgetRepositoryProvider.overrideWithValue(budgets);
