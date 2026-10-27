/// Which bills this device has told the user are due (`docs/reference/bills.md`,
/// **Reminders**): one in-app notification per bill and occurrence. Local to the device,
/// never synced.
///
/// Implementations: Drift over `bill_alerts` (dev and prod), in memory (tests and the demo
/// flavor).
library;

import 'package:shared_models/shared_models.dart';

/// Records raised bill notifications.
abstract interface class BillAlertStore {
  /// Records that bill [billId]'s occurrence due [dueDate] was raised at [raisedAt]; true
  /// when it was not recorded before (the notification is new), false when it was.
  Future<bool> markRaised(String billId, LocalDate dueDate, DateTime raisedAt);
}
