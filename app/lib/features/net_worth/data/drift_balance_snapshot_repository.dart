/// The [BalanceSnapshotRepository] of the dev and prod flavors, over the
/// `balance_snapshots` table (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart'
    show checkSnapshotDay;
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Snapshots in [AppDatabase], stamped `written_at` from the clock; nothing recorded.
final class DriftBalanceSnapshotRepository
    implements BalanceSnapshotRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftBalanceSnapshotRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  $BalanceSnapshotsTable get _table => _database.balanceSnapshots;

  Stream<List<BalanceSnapshot>> _watch(
    Expression<bool> Function($BalanceSnapshotsTable) w,
  ) =>
      (_database.select(_table)
            ..where(w)
            ..orderBy([
              (s) => OrderingTerm.asc(s.date),
              (s) => OrderingTerm.asc(s.accountId),
            ]))
          .watch()
          .map((rows) => rows.map(balanceSnapshotFromRow).toList())
          .distinct(sameList);

  @override
  Stream<List<BalanceSnapshot>> watchAll() =>
      _watch((_) => const Constant(true));

  @override
  Stream<List<BalanceSnapshot>> watchByAccount(String accountId) =>
      _watch((s) => s.accountId.equals(accountId));

  @override
  Future<LocalDate?> latestDate() async {
    final Expression<String> latest = _table.date.max();
    final String? date = await (_database.selectOnly(
      _table,
    )..addColumns([latest])).map((row) => row.read(latest)).getSingle();
    return date == null ? null : LocalDate.parse(date);
  }

  @override
  Future<void> writeDay(LocalDate date, List<BalanceSnapshot> snapshots) async {
    checkSnapshotDay(date, snapshots);
    final DateTime now = _clock.nowUtc();
    await _database.transaction(() async {
      await (_database.delete(
        _table,
      )..where((s) => s.date.equalsValue(date))).go();
      await _database.batch(
        (batch) => batch.insertAll(_table, [
          for (final BalanceSnapshot s in snapshots)
            BalanceSnapshotsCompanion.insert(
              accountId: s.accountId,
              date: s.date,
              currentMinor: s.current.minorUnits,
              availableMinor: Value(
                minorUnitsIn(s.available, s.current.currencyCode),
              ),
              limitMinor: Value(minorUnitsIn(s.limit, s.current.currencyCode)),
              currency: s.current.currencyCode,
              source: s.source,
              writtenAt: now,
            ),
        ]),
      );
    });
  }
}

/// The [BalanceSnapshot] a row holds.
BalanceSnapshot balanceSnapshotFromRow(BalanceSnapshotRow row) =>
    BalanceSnapshot(
      accountId: row.accountId,
      date: row.date,
      current: Money(row.currentMinor, row.currency),
      available: moneyOrNull(row.availableMinor, row.currency),
      limit: moneyOrNull(row.limitMinor, row.currency),
      source: row.source,
    );
