/// The `change_log` table: the sync outbox, one row per local change-log entry
/// (`docs/reference/sync-app.md`).
library;

import 'package:drift/drift.dart';

/// A local change-log entry. `seq` is the local order of appending; `hlc` is the packed
/// clock (unique: a device's clocks never repeat, and the packed form sorts as the clock);
/// `payload` the changed fields as JSON; `entity_type` and `operation` their JSON names.
/// An entry is in the outbox while `synced` is false and `rejected_reason` null; one the
/// relay refused for good keeps its reason (`invalid`, `conflicting_duplicate`).
@DataClassName('ChangeLogRow')
@TableIndex(
  name: 'change_log_outbox',
  columns: {#synced, #rejectedReason, #hlc},
)
class ChangeLog extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get hlc => text().unique()();
  TextColumn get deviceId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get rejectedReason => text().nullable()();
}
