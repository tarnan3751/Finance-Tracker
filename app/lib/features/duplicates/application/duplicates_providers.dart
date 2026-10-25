/// What the duplicate review shows and does (`docs/reference/duplicates.md`): the likely
/// duplicate pairs among the live transactions, without the ones the user dismissed, and
/// the review's writes. Nothing here merges or deletes a transaction.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/duplicates/domain/dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'duplicates_providers.g.dart';

/// The transactions the detector looks at: every live one.
@riverpod
Stream<List<Transaction>> duplicateSource(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watch(TransactionQuery());

/// The pairs the user dismissed.
@riverpod
Stream<Set<PairKey>> dismissedPairs(Ref ref) =>
    ref.watch(dismissedPairStoreProvider).watch();

/// The likely duplicate pairs, ranked (`findDuplicates`), recomputed when the
/// transactions or the dismissed pairs change.
@riverpod
Future<List<DuplicateCandidate>> duplicateCandidates(Ref ref) async =>
    findDuplicates(
      await ref.watch(duplicateSourceProvider.future),
      dismissed: await ref.watch(dismissedPairsProvider.future),
    );

/// The writes of the duplicate review.
@riverpod
DuplicateActions duplicateActions(Ref ref) =>
    DuplicateActions(ref.watch(dismissedPairStoreProvider));

/// Dismisses a pair as not duplicates, and brings it back.
final class DuplicateActions {
  DuplicateActions(this._dismissed);

  final DismissedPairStore _dismissed;

  /// Remembers [pair] as not duplicates, on this device.
  Future<void> dismiss(PairKey pair) => _dismissed.dismiss(pair);

  /// Forgets that [pair] was dismissed (the undo of [dismiss]).
  Future<void> restore(PairKey pair) => _dismissed.restore(pair);
}
