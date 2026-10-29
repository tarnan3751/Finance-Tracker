/// The `investment_transactions` table: the buys, sells, contributions and fees of the
/// linked investment accounts, schema 11 (`docs/reference/investments.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// One row per investment transaction the server sent, by its id: server-authoritative,
/// upserted page by page from the server's versions, never recorded. `type` and `subtype`
/// are Plaid's, open (no CHECK); `quantity` and `price` are `Decimal`s; the amount (in the
/// app's sign) and the fees are `*_minor` in the row's `currency`. `deleted_at` is the
/// server's tombstone and `sync_version` its version of the row. No foreign key to
/// `accounts` or `securities` (a sold security is no longer listed).
@DataClassName('InvestmentTransactionRow')
@TableIndex(
  name: 'investment_transactions_account_date',
  columns: {#accountId, #date},
)
class InvestmentTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get securityId => text().nullable()();
  TextColumn get date => text().map(const LocalDateColumnConverter())();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subtype => text().nullable()();
  TextColumn get quantity => text().map(const DecimalColumnConverter())();
  TextColumn get price => text().map(const DecimalColumnConverter())();
  IntColumn get amountMinor => integer()();
  IntColumn get feesMinor => integer().nullable()();
  TextColumn get currency => text()();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get syncVersion => integer()();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('plaid', 'demo'))",
  ];
}
