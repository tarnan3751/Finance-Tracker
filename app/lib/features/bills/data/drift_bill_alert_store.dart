/// The [BillAlertStore] of the dev and prod flavors, over `bill_alerts`.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/bills/domain/bill_alert_store.dart';
import 'package:shared_models/shared_models.dart';

/// Raised bill notifications in [AppDatabase].
final class DriftBillAlertStore implements BillAlertStore {
  /// The store over [_database].
  DriftBillAlertStore(this._database);

  final AppDatabase _database;

  @override
  Future<bool> markRaised(
    String billId,
    LocalDate dueDate,
    DateTime raisedAt,
  ) => _database.transaction(() async {
    final BillAlertRow? row =
        await (_database.select(_database.billAlerts)..where(
              (a) => a.billId.equals(billId) & a.dueDate.equalsValue(dueDate),
            ))
            .getSingleOrNull();
    if (row != null) return false;
    await _database
        .into(_database.billAlerts)
        .insert(
          BillAlertsCompanion.insert(
            billId: billId,
            dueDate: dueDate,
            raisedAt: raisedAt,
          ),
        );
    return true;
  });
}
