// Budgets for screen tests, over the test seed (test_seed.dart) on testClock's today,
// 24 October 2026, with periods from the 1st: Food and drink at $7.00 (82 % spent and
// projected over), Rent and utilities at $1,200.00 (over, at 120 %), and Transportation
// at $150.00 with carry-over from September (on pace, $150.00 carried).
//
//   await pumpApp(tester, overrides: [storeOverride(seededStore()), budgetsOverride(seededBudgets())]);
//
// openTestAlerts raises the alerts of the two budgets past a threshold, one read, and
// opens the alerts sheet from the Budgets screen.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/budgets/presentation/budgets_screen.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Notifier;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
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

/// Adds the alerts of the food budget (80 %, unread) and the rent budget (100 %, read)
/// to the in-app list of the app on the Budgets screen, and opens the alerts sheet.
Future<void> openTestAlerts(WidgetTester tester) async {
  final InAppNotifications alerts = ProviderScope.containerOf(
    tester.element(find.byType(BudgetsScreen)),
  ).read(inAppNotificationsProvider.notifier);
  BudgetThresholdNotification alert(
    String budget,
    String code,
    int thresholdBp,
    int availableCents,
    DateTime raisedAt,
  ) => BudgetThresholdNotification(
    budgetId: budget,
    categoryId: systemCategoryId(code),
    periodStart: LocalDate(2026, 10, 1),
    thresholdBp: thresholdBp,
    spent: Money(availableCents, 'USD').percent(thresholdBp),
    available: Money(availableCents, 'USD'),
    raisedAt: raisedAt,
  );
  final BudgetThresholdNotification rent = alert(
    'budget-rent',
    'RENT_AND_UTILITIES',
    10000,
    120000,
    DateTime.utc(2026, 10, 10, 18),
  );
  alerts
    ..add(rent)
    ..markRead(rent.key)
    ..add(
      alert(
        'budget-food',
        'FOOD_AND_DRINK',
        8000,
        700,
        DateTime.utc(2026, 10, 23, 18),
      ),
    );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Alerts, 1 unread'));
  await tester.pumpAndSettle();
}
