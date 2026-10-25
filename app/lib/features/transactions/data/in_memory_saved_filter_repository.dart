/// A [SavedFilterRepository] held in memory: what tests use, and the demo flavor's, with
/// its two samples (`demo_saved_filters.dart`).
library;

import 'dart:async';

import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter_repository.dart';
import 'package:uuid/uuid.dart';

/// Saved filters kept in memory for the life of the object.
final class InMemorySavedFilterRepository implements SavedFilterRepository {
  /// A repository holding [initial].
  InMemorySavedFilterRepository({List<SavedFilter> initial = const []}) {
    for (final SavedFilter f in initial) {
      _filters[f.id] = f;
    }
  }

  final Map<String, SavedFilter> _filters = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<SavedFilter> _all() => _filters.values.toList()
    ..sort((a, b) {
      final int byPosition = a.position.compareTo(b.position);
      return byPosition != 0 ? byPosition : compareBinary(a.id, b.id);
    });

  @override
  Stream<List<SavedFilter>> watchAll() =>
      Stream<List<SavedFilter>>.multi((controller) {
        controller.add(_all());
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(_all()),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(sameList);

  @override
  Future<SavedFilter> save(String name, Map<String, Object?> filters) async {
    checkSavedFilterName(name);
    final SavedFilter saved = SavedFilter(
      id: const Uuid().v4(),
      name: name,
      position: _filters.isEmpty
          ? 0
          : _filters.values
                    .map((f) => f.position)
                    .reduce((a, b) => a > b ? a : b) +
                1,
      filters: filters,
    );
    _filters[saved.id] = saved;
    _changes.add(null);
    return saved;
  }

  @override
  Future<void> rename(String id, String name) async {
    checkSavedFilterName(name);
    final SavedFilter? f = _filters[id];
    if (f == null) return;
    _filters[id] = SavedFilter(
      id: id,
      name: name,
      position: f.position,
      filters: f.filters,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    if (_filters.remove(id) != null) _changes.add(null);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
