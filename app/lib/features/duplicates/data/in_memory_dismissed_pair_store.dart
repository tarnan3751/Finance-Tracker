/// The [DismissedPairStore] of the tests and the demo flavor, in memory: it lives as long
/// as the in-memory store it sits beside, so the demo's persona switch starts it afresh.
library;

import 'dart:async';

import 'package:finance_tracker/features/duplicates/domain/dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';

/// Dismissed pairs held in memory.
final class InMemoryDismissedPairStore implements DismissedPairStore {
  final Set<PairKey> _pairs = {};
  final StreamController<Set<PairKey>> _changes =
      StreamController<Set<PairKey>>.broadcast();

  @override
  Stream<Set<PairKey>> watch() async* {
    yield Set.unmodifiable(_pairs);
    yield* _changes.stream;
  }

  @override
  Future<void> dismiss(PairKey pair) async {
    if (_pairs.add(pair)) _changes.add(Set.unmodifiable(_pairs));
  }

  @override
  Future<void> restore(PairKey pair) async {
    if (_pairs.remove(pair)) _changes.add(Set.unmodifiable(_pairs));
  }

  /// Closes the store's stream.
  Future<void> close() => _changes.close();
}
