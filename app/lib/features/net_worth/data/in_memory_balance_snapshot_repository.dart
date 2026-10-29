/// A [BalanceSnapshotRepository] held in memory: what tests use, and the base of the
/// demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/converters.dart' show minorUnitsIn;
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Snapshots kept in memory for the life of the object.
base class InMemoryBalanceSnapshotRepository
    implements BalanceSnapshotRepository {
  final List<BalanceSnapshot> _snapshots = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<BalanceSnapshot> _sorted(bool Function(BalanceSnapshot) test) => [
    for (final BalanceSnapshot s in _snapshots)
      if (test(s)) s,
  ]..sort(compareSnapshots);

  Stream<List<BalanceSnapshot>> _watch(bool Function(BalanceSnapshot) test) =>
      Stream<List<BalanceSnapshot>>.multi((controller) {
        controller.add(_sorted(test));
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(_sorted(test)),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(sameList);

  @override
  Stream<List<BalanceSnapshot>> watchAll() => _watch((_) => true);

  @override
  Stream<List<BalanceSnapshot>> watchByAccount(String accountId) =>
      _watch((s) => s.accountId == accountId);

  @override
  Future<LocalDate?> latestDate() async {
    LocalDate? latest;
    for (final BalanceSnapshot s in _snapshots) {
      if (latest == null || s.date.isAfter(latest)) latest = s.date;
    }
    return latest;
  }

  @override
  Future<void> writeDay(LocalDate date, List<BalanceSnapshot> snapshots) async {
    checkSnapshotDay(date, snapshots);
    _snapshots
      ..removeWhere((s) => s.date == date)
      ..addAll(snapshots);
    _changes.add(null);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}

/// [BalanceSnapshotRepository.watchAll]'s order: date, then account id.
int compareSnapshots(BalanceSnapshot a, BalanceSnapshot b) {
  final int byDate = a.date.compareTo(b.date);
  return byDate != 0 ? byDate : compareBinary(a.accountId, b.accountId);
}

/// Throws when [snapshots] break [BalanceSnapshotRepository.writeDay]'s rules for
/// [date]: a snapshot of another date or a repeated account ([ArgumentError]), or an
/// available balance or limit in another currency than the current balance
/// (`CurrencyMismatchException`).
void checkSnapshotDay(LocalDate date, List<BalanceSnapshot> snapshots) {
  final Set<String> accounts = {};
  for (final BalanceSnapshot s in snapshots) {
    if (s.date != date) {
      throw ArgumentError.value(s.date, 'date', 'not the day written, $date');
    }
    if (!accounts.add(s.accountId)) {
      throw ArgumentError.value(s.accountId, 'accountId', 'twice on $date');
    }
    minorUnitsIn(s.available, s.current.currencyCode);
    minorUnitsIn(s.limit, s.current.currencyCode);
  }
}
