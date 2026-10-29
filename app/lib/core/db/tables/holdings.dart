/// The `holdings` table: the positions of the linked investment accounts, schema 11
/// (`docs/reference/investments.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// One row per account and security, as the server last listed them: server-authoritative,
/// replaced whole by each Plaid pull, never recorded. `quantity` and `institution_price`
/// are `Decimal`s; the value and the cost basis are `*_minor` in the row's `currency`, as
/// the institution reported them. No foreign key to `accounts` or `securities`.
@DataClassName('HoldingRow')
class Holdings extends Table {
  TextColumn get accountId => text()();
  TextColumn get securityId => text()();
  TextColumn get quantity => text().map(const DecimalColumnConverter())();
  TextColumn get institutionPrice =>
      text().map(const DecimalColumnConverter())();
  TextColumn get institutionPriceAsOf =>
      text().map(const LocalDateColumnConverter()).nullable()();
  IntColumn get institutionValueMinor => integer()();
  IntColumn get costBasisMinor => integer().nullable()();
  TextColumn get currency => text()();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {accountId, securityId};

  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('plaid', 'demo'))",
  ];
}
