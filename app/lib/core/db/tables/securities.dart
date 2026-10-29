/// The `securities` table: the securities the linked investment accounts hold, schema 11
/// (`docs/reference/investments.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// One row per security the server last listed with the holdings: server-authoritative,
/// replaced whole with the holdings by each Plaid pull, never recorded. `type` is Plaid's,
/// open (no CHECK); `close_price` is a `Decimal` per unit in `currency_code`.
@DataClassName('SecurityRow')
class Securities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get tickerSymbol => text().nullable()();
  TextColumn get type => text().nullable()();
  BoolColumn get isCashEquivalent => boolean().nullable()();
  TextColumn get closePrice =>
      text().map(const DecimalColumnConverter()).nullable()();
  TextColumn get closePriceAsOf =>
      text().map(const LocalDateColumnConverter()).nullable()();
  TextColumn get currencyCode => text()();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('plaid', 'demo'))",
  ];
}
