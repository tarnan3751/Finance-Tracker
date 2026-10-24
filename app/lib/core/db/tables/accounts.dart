/// The `accounts` table: one row per manual or linked account (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// Accounts. The three balances share the row's `currency`; they are null for a manual
/// account, whose balance is derived from its transactions.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().nullable()();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get subtype => text().nullable()();
  TextColumn get name => text()();
  TextColumn get officialName => text().nullable()();
  TextColumn get mask => text().nullable()();
  TextColumn get currency => text()();
  IntColumn get currentBalanceMinor => integer().nullable()();
  IntColumn get availableBalanceMinor => integer().nullable()();
  IntColumn get creditLimitMinor => integer().nullable()();
  IntColumn get balancesAsOf =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  BoolColumn get isHidden => boolean()();
  IntColumn get displayOrder => integer()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (type IN ('depository', 'credit', 'loan', 'investment', 'other'))",
  ];
}
