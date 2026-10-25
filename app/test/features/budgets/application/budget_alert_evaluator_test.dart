// The alert evaluator: a threshold is raised once per budget, period and threshold; when
// one change reaches both, both are recorded and the higher is told; a new period raises
// again; nothing when nothing is available.
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/application/budget_alert_evaluator.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

final class RecordingNotifier implements Notifier {
  final List<AppNotification> told = [];

  @override
  Future<void> notify(AppNotification notification) async =>
      told.add(notification);
}

void main() {
  const Category food = Category(
    id: 'food',
    name: 'Food',
    isSystem: false,
    icon: 'i',
    color: 0,
  );
  final CategoryLookup lookup = categoryLookup([food]);
  Budget budget(String id, {int amount = 10000}) => Budget(
    id: id,
    categoryId: 'food',
    period: BudgetPeriodKind.monthly,
    periodStartDay: 1,
    amount: Money(amount, 'USD'),
    rollover: false,
    startDate: LocalDate(2026, 1, 1),
  );
  Transaction spend(LocalDate date, int minor) => Transaction(
    id: '$date-$minor',
    accountId: 'a1',
    amount: Money(-minor, 'USD'),
    date: date,
    pending: false,
    name: 'n',
    userCategoryId: 'food',
    source: DataSource.manual,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    syncVersion: 0,
  );

  late RecordingNotifier notifier;
  late BudgetAlertEvaluator evaluator;
  setUp(() {
    notifier = RecordingNotifier();
    evaluator = BudgetAlertEvaluator(
      InMemoryBudgetAlertStore(),
      notifier,
      FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC),
    );
  });

  List<String> told() => [
    for (final AppNotification n in notifier.told)
      (n as BudgetThresholdNotification).key,
  ];

  BudgetStatus status(Budget b, LocalDate today, List<int> spent) =>
      budgetStatus(b, today, [
        for (final (int i, int s) in spent.indexed) spend(today.addDays(-i), s),
      ], lookup);

  test('each threshold is raised once per period, the higher one told when '
      'both are reached together', () async {
    final LocalDate today = LocalDate(2026, 10, 20);
    await evaluator.evaluate([
      status(budget('b1'), today, [7000]),
    ]);
    expect(told(), isEmpty);
    await evaluator.evaluate([
      status(budget('b1'), today, [8500]),
    ]);
    expect(told(), ['budget/b1/2026-10-01/8000']);
    await evaluator.evaluate([
      status(budget('b1'), today, [9000]),
    ]);
    expect(told(), hasLength(1));
    await evaluator.evaluate([
      status(budget('b1'), today, [10000]),
    ]);
    expect(told().last, 'budget/b1/2026-10-01/10000');

    // b2 jumps past both at once: one notification, the higher, and neither again.
    await evaluator.evaluate([
      status(budget('b2'), today, [12000]),
    ]);
    expect(told().last, 'budget/b2/2026-10-01/10000');
    expect(told(), hasLength(3));
    await evaluator.evaluate([
      status(budget('b1'), today, [12000]),
      status(budget('b2'), today, [12000]),
    ]);
    expect(told(), hasLength(3));
    final BudgetThresholdNotification last =
        notifier.told.last as BudgetThresholdNotification;
    expect(last.spent, Money(12000, 'USD'));
    expect(last.available, Money(10000, 'USD'));
    expect(last.categoryId, 'food');
    expect(last.raisedAt, DateTime.utc(2026, 10, 24, 15));
  });

  test('a new period raises again; nothing is raised without anything '
      'available', () async {
    await evaluator.evaluate([
      status(budget('b1'), LocalDate(2026, 10, 20), [9000]),
    ]);
    await evaluator.evaluate([
      status(budget('b1'), LocalDate(2026, 11, 3), [9000]),
    ]);
    expect(told(), ['budget/b1/2026-10-01/8000', 'budget/b1/2026-11-01/8000']);
    await evaluator.evaluate([
      status(budget('b3', amount: 0), LocalDate(2026, 11, 3), [9000]),
    ]);
    expect(told(), hasLength(2));
  });

  test('evaluations run in call order, one at a time', () async {
    final LocalDate today = LocalDate(2026, 10, 20);
    await Future.wait([
      evaluator.evaluate([
        status(budget('b1'), today, [8500]),
      ]),
      evaluator.evaluate([
        status(budget('b1'), today, [8500]),
      ]),
      evaluator.evaluate([
        status(budget('b1'), today, [10500]),
      ]),
    ]);
    expect(told(), ['budget/b1/2026-10-01/8000', 'budget/b1/2026-10-01/10000']);
  });
}
