/// The `goal_contributions` table: what the user put toward each goal
/// (`docs/reference/goals.md`), schema 12.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// Contributions, positive to add and negative to withdraw, `amount_minor` in
/// `currency`. No foreign key to `goals`: a contribution another device recorded may
/// arrive before its goal, and goal deletes are soft.
@DataClassName('GoalContributionRow')
@TableIndex(name: 'goal_contributions_goal', columns: {#goalId})
class GoalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  TextColumn get date => text().map(const LocalDateColumnConverter())();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
