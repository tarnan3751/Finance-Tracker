/// The `record_clocks` table: the sync engine's clock per field of every synced entity
/// (`docs/reference/sync-app.md`).
library;

import 'package:drift/drift.dart';

/// The packed clock of the change that last set [field] of one entity. The field
/// [createClockField] holds the clock of the entity's earliest create instead. An entity
/// with no rows here has no sync record.
@DataClassName('RecordClockRow')
@TableIndex(name: 'record_clocks_hlc', columns: {#hlc})
class RecordClocks extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get field => text()();
  TextColumn get hlc => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId, field};
}

/// The reserved field holding the clock of an entity's create (no entity field starts
/// with an underscore).
const String createClockField = '_create';
