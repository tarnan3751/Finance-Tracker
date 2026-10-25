/// The [BudgetAlertStore] of the dev and prod flavors, over `budget_alerts`.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/budgets/domain/budget_alert_store.dart';
import 'package:shared_models/shared_models.dart';

/// Raised alerts in [AppDatabase].
final class DriftBudgetAlertStore implements BudgetAlertStore {
  /// The store over [_database].
  DriftBudgetAlertStore(this._database);

  final AppDatabase _database;

  @override
  Future<bool> markRaised(
    String budgetId,
    LocalDate periodStart,
    int thresholdBp,
    DateTime raisedAt,
  ) => _database.transaction(() async {
    final int before = await _count(budgetId, periodStart, thresholdBp);
    if (before > 0) return false;
    await _database
        .into(_database.budgetAlerts)
        .insert(
          BudgetAlertsCompanion.insert(
            budgetId: budgetId,
            periodStart: periodStart,
            thresholdBp: thresholdBp,
            raisedAt: raisedAt,
          ),
        );
    return true;
  });

  Future<int> _count(String budgetId, LocalDate periodStart, int bp) async =>
      (await (_database.select(_database.budgetAlerts)..where(
                (a) =>
                    a.budgetId.equals(budgetId) &
                    a.periodStart.equalsValue(periodStart) &
                    a.thresholdBp.equals(bp),
              ))
              .get())
          .length;
}
