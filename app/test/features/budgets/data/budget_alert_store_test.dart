// The two budget alert stores: an alert is new once per budget, period and threshold.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/budgets/data/drift_budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/domain/budget_alert_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  final Map<
    String,
    Future<(BudgetAlertStore, Future<void> Function())> Function()
  >
  stores = {
    'in memory': () async => (InMemoryBudgetAlertStore(), () async {}),
    'Drift': () async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      return (DriftBudgetAlertStore(database), database.close);
    },
  };
  for (final MapEntry(:key, :value) in stores.entries) {
    test('$key: each budget, period and threshold is new once', () async {
      final (BudgetAlertStore store, Future<void> Function() close) =
          await value();
      addTearDown(close);
      final DateTime at = DateTime.utc(2026, 10, 24, 15);
      final LocalDate october = LocalDate(2026, 10, 1);
      expect(await store.markRaised('b1', october, 8000, at), isTrue);
      expect(await store.markRaised('b1', october, 8000, at), isFalse);
      expect(await store.markRaised('b1', october, 10000, at), isTrue);
      expect(
        await store.markRaised('b1', LocalDate(2026, 11, 1), 8000, at),
        isTrue,
      );
      expect(await store.markRaised('b2', october, 8000, at), isTrue);
      expect(await store.markRaised('b1', october, 10000, at), isFalse);
    });
  }
}
