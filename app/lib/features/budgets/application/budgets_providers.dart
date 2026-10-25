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
