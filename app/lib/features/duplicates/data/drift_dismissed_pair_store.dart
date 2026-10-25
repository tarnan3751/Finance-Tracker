/// The [DismissedPairStore] of the dev and prod flavors, over the `dismissed_pairs` table
/// (`docs/reference/data.md`, schema 7). Nothing here is recorded for sync.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/duplicates/domain/dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';

/// Dismissed pairs in [AppDatabase], stamped from the clock.
final class DriftDismissedPairStore implements DismissedPairStore {
  /// The store over [_database], stamping dismissals from [_clock].
  DriftDismissedPairStore(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  @override
  Stream<Set<PairKey>> watch() => _database
      .select(_database.dismissedPairs)
      .watch()
      .map((rows) => {for (final r in rows) PairKey(r.idA, r.idB)});

  @override
  Future<void> dismiss(PairKey pair) => _database
      .into(_database.dismissedPairs)
      .insert(
        DismissedPairsCompanion.insert(
          idA: pair.first,
          idB: pair.second,
          dismissedAt: _clock.nowUtc(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  Future<void> restore(PairKey pair) => (_database.delete(
    _database.dismissedPairs,
  )..where((p) => p.idA.equals(pair.first) & p.idB.equals(pair.second))).go();
}
