/// The `budgets` table: the user's budgets (`docs/reference/budgets.md`), schema 5.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// Budgets. `amount_minor` is in `currency`; `start_date` is the first day of the
/// budget's first period.
@DataClassName('BudgetRow')
@TableIndex(name: 'budgets_category', columns: {#categoryId})
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get period => textEnum<BudgetPeriodKind>()();
  IntColumn get periodStartDay => integer()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  BoolColumn get rollover => boolean()();
  TextColumn get startDate => text().map(const LocalDateColumnConverter())();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // The period kinds of BudgetPeriodKind (a test checks they match) and the start days
  // `shared_models` allows, so no period ever clamps to a short month.
  @override
  List<String> get customConstraints => const [
    "CHECK (period IN ('monthly'))",
    'CHECK (period_start_day BETWEEN 1 AND 28)',
  ];
}
