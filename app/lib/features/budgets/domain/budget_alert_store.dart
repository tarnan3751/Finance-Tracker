/// Which budget alerts this device has raised (`docs/reference/budgets.md`, **Alerts**):
/// one per budget, period and threshold. Local to the device, never synced.
///
/// Implementations: Drift over `budget_alerts` (dev and prod), in memory (tests and the
/// demo flavor).
library;

import 'package:shared_models/shared_models.dart';

/// Records raised budget alerts.
abstract interface class BudgetAlertStore {
  /// Records that budget [budgetId] reached [thresholdBp] in its period starting
  /// [periodStart], at [raisedAt]; true when it was not recorded before (the alert is
  /// new), false when it was.
  Future<bool> markRaised(
    String budgetId,
    LocalDate periodStart,
    int thresholdBp,
    DateTime raisedAt,
  );
}
