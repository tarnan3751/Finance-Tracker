/// The `conflicts` table: this device's own values a pulled change overwrote within ten
/// minutes (`docs/reference/sync-app.md`, **Conflicts**; `docs/reference/data.md`, schema
/// 13).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One conflict per entity and field: the value this device wrote ([localValue], JSON
/// text) under [localHlc], the value that replaced it ([remoteValue]) under [remoteHlc]
/// (each clock carries its device), the entity's label when it has one ([entityLabel]:
/// its name, kept current by the store's writes), and when it was seen ([seenAt]).
/// Local to the device: never recorded in the change log, never synced; dropped once
/// the field's clock moves on or the entity is deleted, and thirty days after [seenAt].
@DataClassName('ConflictRow')
class Conflicts extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get field => text()();
  TextColumn get localValue => text()();
  TextColumn get localHlc => text()();
  TextColumn get remoteValue => text()();
  TextColumn get remoteHlc => text()();
  TextColumn get entityLabel => text().nullable()();
  IntColumn get seenAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId, field};
}
