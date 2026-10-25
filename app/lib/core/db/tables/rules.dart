/// The `rules` table: the user's rules (`docs/reference/rules.md`), schema 4.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// Rules. `conditions` and `actions` are the JSON lists of `RuleCondition.toJson` and
/// `RuleAction.toJson` (an amount bound is `Money`'s JSON: integer minor units and a
/// currency).
@DataClassName('RuleRow')
@TableIndex(name: 'rules_position', columns: {#position})
class Rules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer()();
  TextColumn get conditions => text()();
  TextColumn get actions => text()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
