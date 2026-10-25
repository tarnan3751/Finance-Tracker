/// The demo flavor's [BudgetRepository]: the in-memory one, holding the two budgets of
/// the persona the demo shows (`demo_budgets.dart`, through `budgetRepositoryProvider`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';

/// The demo's budgets; changes last until the app closes (or another persona is chosen)
/// and are never recorded for sync.
final class DemoBudgetRepository extends InMemoryBudgetRepository {
  /// The repository holding `initial`, stamping deletes from `clock`.
  DemoBudgetRepository(super.clock, {super.initial})
    : super(recorder: const NoChangeRecorder());
}
