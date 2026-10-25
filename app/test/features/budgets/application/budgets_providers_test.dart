// The budgets providers over the in-memory repositories: the statuses follow the
// budgets, the categories, the transactions and today, reading only the periods they
// need; the alert watcher evaluates once
// the statuses settle, outside any build, and tells each new alert once.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Notifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/repository_fixture.dart';

/// A clock the test moves by hand, in UTC.
final class _MovableClock implements Clock {
  DateTime utc = DateTime.utc(2026, 10, 20, 12);

  @override
  tz.Location get location => tz.UTC;

  @override
  DateTime nowUtc() => utc;

  @override
  DateTime todayLocalMidnight() => DateTime.utc(utc.year, utc.month, utc.day);

  @override
  LocalDate today() => LocalDate.fromDateTime(utc);
}

/// The in-memory transactions, keeping every query watched.
final class _QueryRecordingTransactions extends InMemoryTransactionRepository {
  _QueryRecordingTransactions(super.store, {required super.recorder});

  final List<TransactionQuery> queries = [];

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) {
    queries.add(query);
    return super.watch(query);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Category food = Category(
    id: 'food',
    name: 'Food',
    isSystem: false,
    icon: 'i',
    color: 0,
  );
  const Category snacks = Category(
    id: 'snacks',
    name: 'Snacks',
    parentId: 'food',
    isSystem: false,
    icon: 'i',
    color: 0,
  );
  final Budget budget = Budget(
    id: 'b1',
    categoryId: 'food',
    period: BudgetPeriodKind.monthly,
    periodStartDay: 1,
    amount: Money(10000, 'USD'),
    rollover: true,
    startDate: LocalDate(2026, 9, 1),
  );

  late _MovableClock clock;
  late ProviderContainer container;
  late _QueryRecordingTransactions transactions;
  setUp(() async {
    clock = _MovableClock();
    container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(clock),
        transactionRepositoryProvider.overrideWith(
          (ref) => transactions = _QueryRecordingTransactions(
            ref.watch(inMemoryStoreProvider),
            recorder: ref.watch(changeRecorderProvider),
          ),
        ),
        budgetAlertDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    await container.read(accountRepositoryProvider).upsert(testAccount('a1'));
    await container.read(categoryRepositoryProvider).upsert(food);
  });

  Future<void> spend(
    String id,
    int minor,
    LocalDate date, {
    String? category,
  }) => container
      .read(transactionRepositoryProvider)
      .upsert(
        testTransaction(
          id,
          'a1',
          -minor,
          date: date,
          userCategoryId: category ?? 'food',
        ),
      );

  // The statuses once they settle after the changes so far.
  Future<List<BudgetStatus>> statuses() async {
    await pumpEventQueue();
    return container.read(budgetStatusesProvider.future);
  }

  test('no budgets: no statuses', () async {
    final ProviderSubscription<AsyncValue<List<BudgetStatus>>> sub = container
        .listen(budgetStatusesProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await statuses(), isEmpty);
  });

  test(
    'the statuses follow budgets, transactions, categories and today',
    () async {
      final ProviderSubscription<AsyncValue<List<BudgetStatus>>> sub = container
          .listen(budgetStatusesProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(budgetRepositoryProvider).upsert(budget);
      await spend('t-sep', 4000, LocalDate(2026, 9, 10));
      await spend('t-oct', 3000, LocalDate(2026, 10, 5));
      BudgetStatus s = (await statuses()).single;
      expect(s.spent, Money(3000, 'USD'));
      expect(s.carried, Money(6000, 'USD'));

      await spend('t-snack', 500, LocalDate(2026, 10, 6), category: 'snacks');
      expect((await statuses()).single.spent, Money(3000, 'USD'));
      await container.read(categoryRepositoryProvider).upsert(snacks);
      expect((await statuses()).single.spent, Money(3500, 'USD'));

      await container
          .read(budgetRepositoryProvider)
          .upsert(budget.copyWith(rollover: false));
      s = (await statuses()).single;
      expect(s.carried, Money(0, 'USD'));

      clock.utc = DateTime.utc(2026, 11, 2, 12);
      container.invalidate(todayProvider);
      s = (await statuses()).single;
      expect(s.period.start, LocalDate(2026, 11, 1));
      expect(s.spent, Money(0, 'USD'));
    },
  );

  test('a budget without rollover reads only its current period; with '
      'rollover, from its first', () async {
    final ProviderSubscription<AsyncValue<List<BudgetStatus>>> sub = container
        .listen(budgetStatusesProvider, (_, _) {});
    addTearDown(sub.close);
    final Budget old = budget.copyWith(
      rollover: false,
      startDate: LocalDate(2024, 1, 15),
    );
    await container.read(budgetRepositoryProvider).upsert(old);
    await spend('t-old', 4000, LocalDate(2025, 6, 10));
    await spend('t-oct', 3000, LocalDate(2026, 10, 5));
    BudgetStatus s = (await statuses()).single;
    expect(s.spent, Money(3000, 'USD'));
    expect(s.carried, Money(0, 'USD'));
    expect(
      transactions.queries.last.range,
      LocalDateRange(LocalDate(2026, 10, 1), LocalDate(2026, 11, 1)),
    );

    await container
        .read(budgetRepositoryProvider)
        .upsert(old.copyWith(rollover: true));
    s = (await statuses()).single;
    expect(
      transactions.queries.last.range,
      LocalDateRange(LocalDate(2024, 1, 1), LocalDate(2026, 11, 1)),
    );
    // 33 earlier periods (January 2024 to September 2026), one spending $40.
    expect(s.carried, Money(10000 * 33 - 4000, 'USD'));
    expect(s.spent, Money(3000, 'USD'));
  });

  test(
    'the watcher tells each new alert once, after the statuses settle',
    () async {
      final ProviderSubscription<void> sub = container.listen(
        budgetAlertWatcherProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      List<String> told() => [
        for (final InAppNotification n in container.read(
          inAppNotificationsProvider,
        ))
          n.notification.key,
      ];
      await container
          .read(budgetRepositoryProvider)
          .upsert(budget.copyWith(rollover: false));
      await spend('t1', 5000, LocalDate(2026, 10, 5));
      await spend('t2', 3500, LocalDate(2026, 10, 6));
      await pumpEventQueue();
      expect(told(), isEmpty, reason: 'not before the debounce');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await pumpEventQueue();
      expect(told(), ['budget/b1/2026-10-01/8000']);
      final AppNotification n = container
          .read(inAppNotificationsProvider)
          .single
          .notification;
      expect((n as BudgetThresholdNotification).spent, Money(8500, 'USD'));

      await spend('t3', 100, LocalDate(2026, 10, 7));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await pumpEventQueue();
      expect(told(), hasLength(1));

      await spend('t4', 2000, LocalDate(2026, 10, 8));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await pumpEventQueue();
      expect(told(), [
        'budget/b1/2026-10-01/10000',
        'budget/b1/2026-10-01/8000',
      ]);
    },
  );
}
