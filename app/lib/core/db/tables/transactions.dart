/// The `transactions` table (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// Transactions. `amount_minor` is in `currency`, which always equals the account's
/// currency (the repositories check it on write). There is no foreign key to `accounts`:
/// Phase 2's sync may apply a transaction before its account, so the repositories enforce
/// that the account exists.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_account_date', columns: {#accountId, #date})
@TableIndex(name: 'transactions_user_category', columns: {#userCategoryId})
@TableIndex(
  name: 'transactions_pending_transaction',
  columns: {#pendingTransactionId},
)
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get date => text().map(const LocalDateColumnConverter())();
  TextColumn get authorizedDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  BoolColumn get pending => boolean()();
  TextColumn get pendingTransactionId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get merchantLogoUrl =>
      text().map(const UriColumnConverter()).nullable()();
  TextColumn get plaidPrimaryCategory => text().nullable()();
  TextColumn get plaidDetailedCategory => text().nullable()();
  TextColumn get userCategoryId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();

  /// The SHA-256 of the receipt photo's bytes (schema 13), by which a device without the
  /// file fetches it.
  TextColumn get receiptSha256 => text().nullable()();

  /// The user's hidden override (schema 5): the row still counts toward its account's
  /// balance and leaves the default list, budgets and reports.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  /// Whether this row was deleted by its account's delete, so the account's restore brings
  /// back exactly these rows (and not one deleted on its own, whatever its instant).
  BoolColumn get deletedWithAccount =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // The provenance values of PLAN.md §7.1; a test checks they match DataSource.
  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('plaid', 'manual', 'import', 'derived', 'demo'))",
  ];
}
