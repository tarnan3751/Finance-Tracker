/// Keeps the detected streams current (`docs/reference/recurring.md`, **The detector**):
/// whenever the transactions, the categories, the server's streams or today change, the
/// detector runs again [detectorDebounce] after the last change and its streams replace
/// the stored `detected` ones through `replaceDetected`. Each run detects, classifies
/// every detected stream and drops the ones the server's streams already cover
/// ([detectedStreamsFor]); on a ledger of more than [detectorIsolateThreshold] rows it
/// runs on a background isolate, so a large history never holds the UI isolate. One run
/// happens at a time: a change during a run starts one more run after it, on the latest
/// input. Nothing runs unless something listens: `bootstrap` does, for the life of the
/// app, in every flavor.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_merge.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscription_classifier.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'detector_runner.g.dart';

final Logger _log = Logger('recurring');

/// What one detector run reads: every live transaction, the live categories, the
/// server's streams (`plaid` and `demo`) and today.
typedef DetectorInput = ({
  List<Transaction> ledger,
  List<Category> categories,
  List<RecurringStream> pulled,
  LocalDate today,
});

/// The detected streams of [input], each classified, less those [DetectorInput.pulled]
/// covers (`mergeStreams`). Top level, so it can run on another isolate.
List<RecurringStream> detectedStreamsFor(DetectorInput input) {
  final CategoryLookup lookup = categoryLookup(input.categories);
  final Map<String, Transaction> byId = {
    for (final Transaction t in input.ledger) t.id: t,
  };
  final List<RecurringStream> detected = [
    for (final RecurringStream s in detectStreams(
      input.ledger,
      today: input.today,
      lookup: lookup,
      merchantKey: recurringMerchantKey,
    ))
      _classified(s, [
        for (final String id in s.transactionIds) byId[id]!,
      ], lookup),
  ];
  return [
    for (final RecurringStream s in mergeStreams(input.pulled, detected))
      if (s.source == RecurringSource.detected) s,
  ];
}

RecurringStream _classified(
  RecurringStream stream,
  List<Transaction> members,
  CategoryLookup lookup,
) => stream.copyWith(
  isSubscription: isSubscription(
    stream,
    effectiveCategory: streamCategory(members, lookup),
    band: StreamBand.of(members),
  ),
);

/// How long after the last change the detector runs.
@Riverpod(keepAlive: true)
Duration detectorDebounce(Ref ref) => const Duration(seconds: 2);

/// The ledger size above which the detector runs on a background isolate.
@Riverpod(keepAlive: true)
int detectorIsolateThreshold(Ref ref) => 2000;

/// Runs the detector [detectorDebounce] after its input last changed, while something
/// listens.
@riverpod
class DetectorRunner extends _$DetectorRunner {
  Timer? _timer;
  DetectorInput? _latest;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;

  @override
  void build() {
    final RecurringStreamRepository streams = ref.watch(
      recurringStreamRepositoryProvider,
    );
    final Duration debounce = ref.watch(detectorDebounceProvider);
    final int threshold = ref.watch(detectorIsolateThresholdProvider);
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });

    void changed() {
      final List<Transaction>? ledger = ref.read(recurringLedgerProvider).value;
      final List<Category>? categories = ref.read(categoriesProvider).value;
      final List<StreamView>? views = ref.read(recurringStreamsProvider).value;
      if (ledger == null || categories == null || views == null) return;
      final DetectorInput input = (
        ledger: ledger,
        categories: categories,
        pulled: [
          for (final StreamView v in views)
            if (v.stream.source != RecurringSource.detected) v.stream,
        ],
        today: ref.read(todayProvider),
      );
      // The run's own write changes the stored streams but not the server's: no rerun.
      final DetectorInput? latest = _latest;
      if (latest != null &&
          identical(latest.ledger, input.ledger) &&
          identical(latest.categories, input.categories) &&
          sameList(latest.pulled, input.pulled) &&
          latest.today == input.today) {
        return;
      }
      _latest = input;
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(_run(streams, threshold)));
    }

    ref.listen(recurringLedgerProvider, (_, _) => changed());
    ref.listen(categoriesProvider, (_, _) => changed());
    ref.listen(recurringStreamsProvider, (_, _) => changed());
    ref.listen(todayProvider, (_, _) => changed(), fireImmediately: true);
  }

  Future<void> _run(RecurringStreamRepository streams, int threshold) async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        final DetectorInput input = _latest!;
        final List<RecurringStream> detected = input.ledger.length > threshold
            ? await compute(detectedStreamsFor, input)
            : detectedStreamsFor(input);
        if (_disposed) return;
        await streams.replaceDetected(detected);
      } while (_again && !_disposed);
    } catch (e) {
      // Only the type: a message could carry a merchant or an amount.
      _log.warning('the recurring detector failed: ${e.runtimeType}');
    } finally {
      _running = false;
    }
  }
}
