/// The `balance_snapshots` table: each account's balances as observed on each local day,
/// schema 11 (`docs/reference/net-worth.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// One row per account and local date, written by the snapshot writer on this device and
/// never recorded or synced: the day's row is replaced while the day lasts, earlier days
/// are never written. The balances are `*_minor` in the row's `currency`, in the app's
/// sign; `source` is where the balance came from (`PLAN.md` §7.1); `written_at` is when
/// the row was last written, UTC. No foreign key to `accounts`: the history of an
/// account that goes stays.
@DataClassName('BalanceSnapshotRow')
@TableIndex(name: 'balance_snapshots_date', columns: {#date})
class BalanceSnapshots extends Table {
  TextColumn get accountId => text()();
  TextColumn get date => text().map(const LocalDateColumnConverter())();
  IntColumn get currentMinor => integer()();
  IntColumn get availableMinor => integer().nullable()();
  IntColumn get limitMinor => integer().nullable()();
  TextColumn get currency => text()();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get writtenAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {accountId, date};

  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('plaid', 'manual', 'import', 'derived', 'demo'))",
  ];
}
