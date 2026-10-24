/// The `categories` table: the system categories seeded from Plaid's taxonomy and the
/// user's own.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// Categories. `color` is ARGB.
@DataClassName('CategoryRow')
@TableIndex(name: 'categories_parent', columns: {#parentId})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  BoolColumn get isSystem => boolean()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get plaidCategory => text().nullable()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
