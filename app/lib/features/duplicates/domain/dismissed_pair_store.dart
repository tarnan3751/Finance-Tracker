/// Where the duplicate pairs the user dismissed are kept: on the device only, never
/// synced (`docs/reference/duplicates.md`).
///
/// Implementations: Drift (dev and prod, the `dismissed_pairs` table) and in memory (the
/// tests and the demo flavor); both pass `test/contract/dismissed_pair_store_contract.dart`.
library;

import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';

/// The dismissed pairs.
abstract interface class DismissedPairStore {
  /// The dismissed pairs, starting with the current set and emitting again when it
  /// changes.
  Stream<Set<PairKey>> watch();

  /// Remembers [pair] as not duplicates; dismissing it again keeps the first time.
  Future<void> dismiss(PairKey pair);

  /// Forgets [pair] (the undo of [dismiss]); does nothing when it is not dismissed.
  Future<void> restore(PairKey pair);
}
