/// The `budget_alerts` table: which budget alerts this device has raised
/// (`docs/reference/budgets.md`, **Alerts**), schema 5. Local to the device, never synced.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One raised alert: budget [budgetId] reached [thresholdBp] basis points of what was
/// available in its period starting [periodStart], at [raisedAt]. There is no foreign key
/// to `budgets`: deletes there are soft, and a restored budget keeps its alerts.
@DataClassName('BudgetAlertRow')
class BudgetAlerts extends Table {
  TextColumn get budgetId => text()();
  TextColumn get periodStart => text().map(const LocalDateColumnConverter())();
  IntColumn get thresholdBp => integer()();
  IntColumn get raisedAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {budgetId, periodStart, thresholdBp};
}
