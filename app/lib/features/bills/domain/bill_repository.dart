/// The user's bills (`docs/reference/bills.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// two bills of the persona it shows); all pass `test/contract/bill_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads and writes bills. Every stream starts with the current value and emits again
/// only when that value changes. Deletes are soft; [restore] is the only way back.
abstract interface class BillRepository {
  /// The live bills, by first due date, then by id.
  Stream<List<BillReminder>> watchAll();

  /// Bill [id], or null when there is no such live bill.
  Stream<BillReminder?> watchById(String id);

  /// Inserts or replaces [bill]. Throws `EntityDeletedException`
  /// (`core/db/database_exceptions.dart`) when the bill is deleted.
  Future<void> upsert(BillReminder bill);

  /// Soft-deletes bill [id]; does nothing when there is no such live bill.
  Future<void> delete(String id);

  /// Restores deleted bill [id]; does nothing when there is no such deleted bill.
  Future<void> restore(String id);
}
