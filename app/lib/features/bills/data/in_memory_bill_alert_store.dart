/// A [BillAlertStore] in memory: the tests' and the demo flavor's.
library;

import 'package:finance_tracker/features/bills/domain/bill_alert_store.dart';
import 'package:shared_models/shared_models.dart';

/// Raised bill notifications, for the life of the object.
final class InMemoryBillAlertStore implements BillAlertStore {
  final Set<(String, LocalDate)> _raised = {};

  @override
  Future<bool> markRaised(
    String billId,
    LocalDate dueDate,
    DateTime raisedAt,
  ) async => _raised.add((billId, dueDate));
}
