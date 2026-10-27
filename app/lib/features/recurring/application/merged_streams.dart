/// The recurring streams as the screens show them: the server's and the detector's merged,
/// every one classified (`docs/reference/recurring.md`, **Merging**, **Subscriptions**).
///
/// The detector's streams are stored already merged and classified
/// (`detector_runner.dart`); this list merges again when read, so a pull that lands
/// between two detector runs never shows a stream twice, and classifies the server's
/// streams, whose own flag Plaid never sets: a stream is a subscription when its source
/// flags it or the classifier says so, and the user's override wins over both
/// (`StreamView.isSubscription`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/recurring/domain/stream_merge.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscription_classifier.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'merged_streams.g.dart';

/// Every live transaction, which the detector and the classifier read.
@riverpod
Stream<List<Transaction>> recurringLedger(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watch(TransactionQuery.all);

/// The stored streams merged and classified ([mergedViews]), in the repository's order
/// (merchant name ignoring ASCII case, then id); muted ones included.
@riverpod
Stream<List<StreamView>> mergedStreams(Ref ref) async* {
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  final CategoryLookup lookup = categoryLookup(categories);
  yield* ref
      .watch(recurringStreamRepositoryProvider)
      .watchAll()
      .map((views) => mergedViews(views, ledger, lookup));
}

/// [views] in their order, less the detected streams the server's already cover
/// (`mergeStreams`), each server stream's flag set when the classifier counts it a
/// subscription over its members in [ledger]; the detected ones are kept as stored.
List<StreamView> mergedViews(
  List<StreamView> views,
  List<Transaction> ledger,
  CategoryLookup lookup,
) {
  final List<RecurringStream> pulled = [
    for (final StreamView v in views)
      if (v.stream.source != RecurringSource.detected) v.stream,
  ];
  final Set<String> kept = {
    for (final RecurringStream s in mergeStreams(pulled, [
      for (final StreamView v in views)
        if (v.stream.source == RecurringSource.detected) v.stream,
    ]))
      s.id,
  };
  final Map<String, Transaction> byId = {
    for (final Transaction t in ledger) t.id: t,
  };
  return [
    for (final StreamView v in views)
      if (kept.contains(v.stream.id))
        v.stream.source == RecurringSource.detected || v.stream.isSubscription
            ? v
            : StreamView(
                v.stream.copyWith(
                  isSubscription: _classify(v.stream, byId, lookup),
                ),
                v.userOverride,
              ),
  ];
}

/// The classifier's answer for [stream] over its members found in [byId].
bool _classify(
  RecurringStream stream,
  Map<String, Transaction> byId,
  CategoryLookup lookup,
) {
  final List<Transaction> members = [
    for (final String id in stream.transactionIds) ?byId[id],
  ];
  return isSubscription(
    stream,
    effectiveCategory: streamCategory(members, lookup),
    band: StreamBand.of(members),
  );
}
