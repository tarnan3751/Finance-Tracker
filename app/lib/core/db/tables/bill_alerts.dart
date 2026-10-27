/// The `bill_alerts` table: which bill occurrences this device has told the user are due
/// (`docs/reference/bills.md`, **Reminders**), schema 10. Local to the device, never
/// synced.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One raised notification: bill [billId]'s occurrence due [dueDate], at [raisedAt]. No
/// foreign key to `bills`: deletes there are soft, and a restored bill keeps its alerts.
@DataClassName('BillAlertRow')
class BillAlerts extends Table {
  TextColumn get billId => text()();
  TextColumn get dueDate => text().map(const LocalDateColumnConverter())();
  IntColumn get raisedAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {billId, dueDate};
}
