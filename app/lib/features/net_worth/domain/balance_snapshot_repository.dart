/// The balance snapshots this device has observed: one per account per local day
/// (`docs/reference/net-worth.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor); all
/// pass `test/contract/balance_snapshot_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads the snapshots and writes one day of them. Local to the device: nothing here is
/// recorded for sync. Every stream starts with the current value and emits again only
/// when that value changes.
abstract interface class BalanceSnapshotRepository {
  /// Every snapshot, by date, then account id.
  Stream<List<BalanceSnapshot>> watchAll();

  /// The snapshots of account [accountId], by date.
  Stream<List<BalanceSnapshot>> watchByAccount(String accountId);

  /// The latest date any snapshot is stored for, or null when there is none.
  Future<LocalDate?> latestDate();

  /// Replaces every snapshot of [date] with [snapshots] in one write; other dates are
  /// never touched. A snapshot of another date, or two of one account, is an
  /// [ArgumentError], and one whose available balance or limit is in another currency
  /// than its current balance a `CurrencyMismatchException`, before anything is written.
  Future<void> writeDay(LocalDate date, List<BalanceSnapshot> snapshots);
}
