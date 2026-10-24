/// The `held_records` table: sync records the entity tables cannot hold yet
/// (`docs/reference/sync-app.md`).
library;

import 'package:drift/drift.dart';

/// The fields (JSON) of one entity's sync record that its table cannot hold exactly, and
/// why: `incomplete` (no row yet), `unrepresentable` (fields the table cannot store, such
/// as splits in another currency than the amount), `unknown_fields` (fields this version
/// does not know), `unsupported_type` (an entity the app does not store yet). Its clocks
/// stay in `record_clocks`, and the store reads the record from here while it is held.
/// A later merge the table can hold exactly deletes this row.
@DataClassName('HeldRecordRow')
class HeldRecords extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get fields => text()();
  TextColumn get reason => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId};

  @override
  List<String> get customConstraints => const [
    "CHECK (reason IN ('incomplete', 'unrepresentable', 'unknown_fields', "
        "'unsupported_type'))",
  ];
}
