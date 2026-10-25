/// A [BudgetAlertStore] held in memory: the tests' and the demo flavor's.
library;

import 'package:finance_tracker/features/budgets/domain/budget_alert_store.dart';
import 'package:shared_models/shared_models.dart';

/// Raised alerts kept for the life of the object.
final class InMemoryBudgetAlertStore implements BudgetAlertStore {
  final Set<(String, LocalDate, int)> _raised = {};

  @override
  Future<bool> markRaised(
    String budgetId,
    LocalDate periodStart,
    int thresholdBp,
    DateTime raisedAt,
  ) async => _raised.add((budgetId, periodStart, thresholdBp));
}
