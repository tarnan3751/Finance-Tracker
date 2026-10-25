/// What the budgets screens show, and the budget alerts (`docs/reference/budgets.md`);
/// the repositories are `budgetRepositoryProvider` and `budgetAlertStoreProvider`
/// (`core/di/providers.dart`).
library;

import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/budgets/application/budget_alert_evaluator.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'budgets_providers.g.dart';

/// The live budgets, by category, then id.
@riverpod
Stream<List<Budget>> budgets(Ref ref) =>
    ref.watch(budgetRepositoryProvider).watchAll();

/// Every live budget's status for today, in [budgets]' order: recomputed when the
/// budgets, the categories, the transactions in the budgets' periods or today change.
@riverpod
Stream<List<BudgetStatus>> budgetStatuses(Ref ref) async* {
  final LocalDate today = ref.watch(todayProvider);
  final List<Budget> budgets = await ref.watch(budgetsProvider.future);
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  if (budgets.isEmpty) {
    yield const [];
    return;
  }
  final CategoryLookup lookup = categoryLookup(categories);
  // From the earliest period a status reads (the first period of a budget with
  // rollover, else the current one) to the latest current period's end.
  LocalDate? from;
  LocalDate? to;
  for (final Budget b in budgets) {
    final LocalDateRange current = periodContaining(today, b.periodStartDay);
    final LocalDate first = periodContaining(
      b.startDate,
      b.periodStartDay,
    ).start;
    final LocalDate start = b.rollover && first.isBefore(current.start)
        ? first
        : current.start;
    if (from == null || start.isBefore(from)) from = start;
    if (to == null || current.end.isAfter(to)) to = current.end;
  }
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionQuery(range: LocalDateRange(from!, to!)))
      .map(
        (transactions) => [
          for (final Budget b in budgets)
            budgetStatus(b, today, transactions, lookup),
        ],
      );
}

/// Which period the budgets screens show: 0 for each budget's current period, -1 for the
/// one before, 1 for the one after.
@riverpod
class BudgetPeriodOffset extends _$BudgetPeriodOffset {
  @override
  int build() => 0;

  /// Shows the period [offset] periods after the current one.
  void select(int offset) => state = offset;
}

/// Every live budget's status in the period [offset] periods after its current one, in
/// [budgets]' order: today's status for 0, else the status on that period's last day.
/// It reads one query, from the earliest period a status needs (the first period with
/// rollover, else the shown one) to the latest shown period's end.
@riverpod
Stream<List<BudgetStatus>> budgetPeriodStatuses(Ref ref, int offset) async* {
  final LocalDate today = ref.watch(todayProvider);
  LocalDate dayFor(Budget b) => offset == 0
      ? today
      : periodAt(today, b.periodStartDay, offset).end.addDays(-1);
  final List<Budget> budgets = await ref.watch(budgetsProvider.future);
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  if (budgets.isEmpty) {
    yield const [];
    return;
  }
  final CategoryLookup lookup = categoryLookup(categories);
  LocalDate? from;
  LocalDate? to;
  for (final Budget b in budgets) {
    final LocalDateRange current = periodContaining(
      dayFor(b),
      b.periodStartDay,
    );
    final LocalDate first = periodContaining(
      b.startDate,
      b.periodStartDay,
    ).start;
    final LocalDate start = b.rollover && first.isBefore(current.start)
        ? first
        : current.start;
    if (from == null || start.isBefore(from)) from = start;
    if (to == null || current.end.isAfter(to)) to = current.end;
  }
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionQuery(range: LocalDateRange(from!, to!)))
      .map(
        (transactions) => [
          for (final Budget b in budgets)
            budgetStatus(b, dayFor(b), transactions, lookup),
        ],
      );
}

/// What budget [budgetId] counts in the period [offset] periods after its current one,
/// newest first; empty when there is no such live budget.
@riverpod
Stream<List<BudgetEntry>> budgetPeriodEntries(
  Ref ref,
  String budgetId,
  int offset,
) async* {
  final LocalDate today = ref.watch(todayProvider);
  final List<Budget> budgets = await ref.watch(budgetsProvider.future);
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final Budget? budget = budgets.where((b) => b.id == budgetId).firstOrNull;
  if (budget == null) {
    yield const [];
    return;
  }
  final CategoryLookup lookup = categoryLookup(categories);
  final LocalDateRange period = periodAt(today, budget.periodStartDay, offset);
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(TransactionQuery(range: period))
      .map((transactions) => entriesIn(period, budget, transactions, lookup));
}

/// How long after the last change to the statuses the alerts are evaluated.
@Riverpod(keepAlive: true)
Duration budgetAlertDebounce(Ref ref) => const Duration(seconds: 1);

/// Raises the budget alerts, through [appNotifier].
@Riverpod(keepAlive: true)
BudgetAlertEvaluator budgetAlertEvaluator(Ref ref) => BudgetAlertEvaluator(
  ref.watch(budgetAlertStoreProvider),
  ref.watch(appNotifierProvider),
  ref.watch(clockProvider),
);

/// Evaluates the budget alerts [budgetAlertDebounce] after the statuses last changed,
/// outside any build, while something listens: `bootstrap` does, for the life of the
/// app.
@riverpod
class BudgetAlertWatcher extends _$BudgetAlertWatcher {
  Timer? _timer;

  @override
  void build() {
    final BudgetAlertEvaluator evaluator = ref.watch(
      budgetAlertEvaluatorProvider,
    );
    final Duration debounce = ref.watch(budgetAlertDebounceProvider);
    ref.onDispose(() => _timer?.cancel());
    ref.listen(budgetStatusesProvider, (_, next) {
      final List<BudgetStatus>? statuses = next.value;
      if (statuses == null) return;
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(evaluator.evaluate(statuses)));
    }, fireImmediately: true);
  }
}
