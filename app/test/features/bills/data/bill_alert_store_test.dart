// Both bill alert stores: an occurrence is new once per bill and due date, and the
// Drift one keeps it across a new store over the same database.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/bills/data/drift_bill_alert_store.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_alert_store.dart';
import 'package:finance_tracker/features/bills/domain/bill_alert_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  final DateTime at = DateTime.utc(2026, 10, 27, 14);
  final LocalDate due = LocalDate(2026, 10, 28);

  Future<void> raisesOnce(BillAlertStore store) async {
    expect(await store.markRaised('rent', due, at), isTrue);
    expect(await store.markRaised('rent', due, at), isFalse);
    expect(await store.markRaised('rent', due.addMonths(1), at), isTrue);
    expect(await store.markRaised('power', due, at), isTrue);
  }

  test('in memory', () => raisesOnce(InMemoryBillAlertStore()));

  test('Drift, kept in bill_alerts', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await raisesOnce(DriftBillAlertStore(database));
    expect(
      await DriftBillAlertStore(database).markRaised('rent', due, at),
      isFalse,
    );
    final List<BillAlertRow> rows = await database
        .select(database.billAlerts)
        .get();
    expect(rows, hasLength(3));
    expect(rows.first.raisedAt, at);
  });
}
