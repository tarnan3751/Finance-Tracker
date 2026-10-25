/// The `saved_filters` table: the transaction list's saved filters, schema 6, kept on
/// this device only (`docs/reference/transactions.md`, **Saved filters**).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// Saved filters. `query_json` is the JSON object of `TransactionFilters.toJson`.
@DataClassName('SavedFilterRow')
@TableIndex(name: 'saved_filters_position', columns: {#position})
class SavedFilters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get queryJson => text()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
