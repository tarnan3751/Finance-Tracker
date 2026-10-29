// The budgets providers over the in-memory repositories: the statuses follow the
// budgets, the categories, the transactions and today, reading only the periods they
// need and leaving hidden transactions out; the alert watcher evaluates once
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

  test('a hidden transaction leaves the spending and the carry', () async {
    final ProviderSubscription<AsyncValue<List<BudgetStatus>>> sub = container
        .listen(budgetStatusesProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(budgetRepositoryProvider).upsert(budget);
    await spend('t-sep', 4000, LocalDate(2026, 9, 10));
    await spend('t-oct', 3000, LocalDate(2026, 10, 5));
    await spend('t-oct2', 1000, LocalDate(2026, 10, 6));
    BudgetStatus s = (await statuses()).single;
    expect(s.spent, Money(4000, 'USD'));
    expect(s.carried, Money(6000, 'USD'));

    final Map<String, Transaction> rows = {
      for (final Transaction t
          in await container
              .read(transactionRepositoryProvider)
              .watch(TransactionQuery.all)
              .first)
        t.id: t,
    };
    await container.read(transactionRepositoryProvider).upsertAll([
      rows['t-sep']!.copyWith(hidden: true),
      rows['t-oct']!.copyWith(hidden: true),
    ]);
    s = (await statuses()).single;
    expect(s.spent, Money(1000, 'USD'));
    expect(s.carried, Money(10000, 'USD'));

    await container
        .read(transactionRepositoryProvider)
        .upsert(rows['t-oct']!.copyWith(hidden: false));
    expect((await statuses()).single.spent, Money(4000, 'USD'));
  });

  test(
    'a hidden transaction leaves a period\'s status and its entries',
    () async {
      final ProviderSubscription<AsyncValue<List<BudgetStatus>>> current =
          container.listen(budgetPeriodStatusesProvider(0), (_, _) {});
      addTearDown(current.close);
      final ProviderSubscription<AsyncValue<List<BudgetStatus>>> previous =
          container.listen(budgetPeriodStatusesProvider(-1), (_, _) {});
      addTearDown(previous.close);
      final ProviderSubscription<AsyncValue<List<BudgetEntry>>> entries =
          container.listen(budgetPeriodEntriesProvider('b1', -1), (_, _) {});
      addTearDown(entries.close);
      await container.read(budgetRepositoryProvider).upsert(budget);
      await spend('t-sep', 4000, LocalDate(2026, 9, 10));
      await spend('t-sep2', 500, LocalDate(2026, 9, 12));
      await spend('t-oct', 3000, LocalDate(2026, 10, 5));
      await pumpEventQueue();
      Future<List<String>> entryIds() async => [
        for (final BudgetEntry e in await container.read(
          budgetPeriodEntriesProvider('b1', -1).future,
        ))
          e.transaction.id,
      ];
      expect(
        (await container.read(budgetPeriodStatusesProvider(-1).future))
            .single
            .spent,
        Money(4500, 'USD'),
      );
      expect(await entryIds(), unorderedEquals(['t-sep', 't-sep2']));

      final Transaction sep = (await container
          .read(transactionRepositoryProvider)
          .watchById('t-sep')
          .first)!;
      await container
          .read(transactionRepositoryProvider)
          .upsert(sep.copyWith(hidden: true));
      await pumpEventQueue();
      expect(
        (await container.read(budgetPeriodStatusesProvider(-1).future))
            .single
            .spent,
        Money(500, 'USD'),
      );
      expect(await entryIds(), ['t-sep2']);
      // The current period's carry no longer counts it either.
      final BudgetStatus now = (await container.read(
        budgetPeriodStatusesProvider(0).future,
      )).single;
      expect(now.spent, Money(3000, 'USD'));
      expect(now.carried, Money(10000 - 500, 'USD'));
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

  // The debounce in fake time, which only tester.pump moves, so a loaded machine cannot
  // run it out before the first check or after the last; the writes run in real time
  // (runAsync), since the repositories were made outside the fake zone.
  testWidgets(
    'the watcher tells each new alert once, after the statuses settle',
    (tester) async {
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
      await tester.runAsync(() async {
        await container
            .read(budgetRepositoryProvider)
            .upsert(budget.copyWith(rollover: false));
        await spend('t1', 5000, LocalDate(2026, 10, 5));
        await spend('t2', 3500, LocalDate(2026, 10, 6));
      });
      await tester.pump(const Duration(milliseconds: 19));
      expect(told(), isEmpty, reason: 'not before the debounce');
      await tester.pump(const Duration(milliseconds: 1));
      expect(told(), ['budget/b1/2026-10-01/8000']);
      final AppNotification n = container
          .read(inAppNotificationsProvider)
          .single
          .notification;
      expect((n as BudgetThresholdNotification).spent, Money(8500, 'USD'));

      await tester.runAsync(() => spend('t3', 100, LocalDate(2026, 10, 7)));
      await tester.pump(const Duration(milliseconds: 20));
      expect(told(), hasLength(1));

      await tester.runAsync(() => spend('t4', 2000, LocalDate(2026, 10, 8)));
      await tester.pump(const Duration(milliseconds: 20));
      expect(told(), [
        'budget/b1/2026-10-01/10000',
        'budget/b1/2026-10-01/8000',
      ]);
      // Today's midnight timer is a fake one too: gone before the test's end.
      container.dispose();
    },
  );
}
