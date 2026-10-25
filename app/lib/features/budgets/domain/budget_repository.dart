/// The user's budgets (`docs/reference/budgets.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// two budgets of the persona it shows); all pass
/// `test/contract/budget_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads and writes budgets. Every stream starts with the current value and emits again
/// only when that value changes. Deletes are soft; [restore] is the only way back.
abstract interface class BudgetRepository {
  /// The live budgets, by `categoryId`, then by id.
  Stream<List<Budget>> watchAll();

  /// Budget [id], or null when there is no such live budget.
  Stream<Budget?> watchById(String id);

  /// Inserts or replaces [budget]. Throws `EntityDeletedException`
  /// (`core/db/database_exceptions.dart`) when the budget is deleted.
  Future<void> upsert(Budget budget);

  /// Soft-deletes budget [id]; does nothing when there is no such live budget.
  Future<void> delete(String id);

  /// Restores deleted budget [id]; does nothing when there is no such deleted budget.
  Future<void> restore(String id);
}
