/// The `goals` table: the user's savings goals (`docs/reference/goals.md`), schema 12.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// Goals. The target is `target_minor` in `currency`; `linked_account_ids` is a JSON
/// array of account ids; `kind` is the `GoalKind` name. The contributions are rows of
/// `goal_contributions`.
@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get kind => textEnum<GoalKind>()();
  TextColumn get linkedAccountIds => text()();
  TextColumn get targetDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  TextColumn get createdOn => text().map(const LocalDateColumnConverter())();
  TextColumn get note => text().nullable()();
  IntColumn get archivedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
