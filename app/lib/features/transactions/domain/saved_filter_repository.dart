/// The transaction list's saved filters, kept on this device only (`PLAN.md` §12: not
/// synced in Phase 4).
///
/// Implementations: Drift (dev and prod) and in memory (tests, and the demo flavor with
/// its two samples); both pass `test/contract/saved_filter_repository_contract.dart`.
library;

import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';

/// Reads and writes saved filters. The stream starts with the current value and emits
/// again only when it changes. Deletes are final: nothing syncs or restores them.
abstract interface class SavedFilterRepository {
  /// The saved filters, by `position`, then by id.
  Stream<List<SavedFilter>> watchAll();

  /// Saves [filters] under [name] after every saved filter, and returns it. A [name]
  /// that is empty once trimmed is an [ArgumentError].
  Future<SavedFilter> save(String name, Map<String, Object?> filters);

  /// Renames saved filter [id] to [name]; does nothing when there is no such filter. A
  /// [name] that is empty once trimmed is an [ArgumentError].
  Future<void> rename(String id, String name);

  /// Deletes saved filter [id]; does nothing when there is no such filter.
  Future<void> delete(String id);
}

/// [name] when it is not empty once trimmed; else an [ArgumentError].
String checkSavedFilterName(String name) {
  if (name.trim().isEmpty) {
    throw ArgumentError.value(name, 'name', 'must not be blank');
  }
  return name;
}
