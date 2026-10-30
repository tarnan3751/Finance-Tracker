/// The [ConflictStore] of the tests and the demo flavor, in memory. The in-memory data
/// never syncs, so nothing adds a conflict here but [InMemoryConflictStore.add].
library;

import 'dart:async';

import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/conflicts/domain/conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';

/// Conflicts held in memory.
final class InMemoryConflictStore implements ConflictStore {
  final Map<ConflictKey, SyncConflict> _conflicts = {};
  final StreamController<List<SyncConflict>> _changes =
      StreamController<List<SyncConflict>>.broadcast();

  List<SyncConflict> _list() => [..._conflicts.values]
    ..sort((a, b) {
      final int seen = b.seenAt.compareTo(a.seenAt);
      if (seen != 0) return seen;
      final int type = snakeName(a.entityType)
          .compareTo(snakeName(b.entityType));
      if (type != 0) return type;
      final int id = a.entityId.compareTo(b.entityId);
      return id != 0 ? id : a.field.compareTo(b.field);
    });

  @override
  Stream<List<SyncConflict>> watch() async* {
    yield List.unmodifiable(_list());
    yield* _changes.stream;
  }

  /// Keeps [conflict], replacing the one with its key, as a session would.
  void add(SyncConflict conflict) {
    _conflicts[conflict.key] = conflict;
    _changes.add(List.unmodifiable(_list()));
  }

  @override
  Future<void> dismiss(SyncConflict conflict) async {
    if (_conflicts.remove(conflict.key) != null) {
      _changes.add(List.unmodifiable(_list()));
    }
  }

  /// Closes the store's stream.
  Future<void> close() => _changes.close();
}
