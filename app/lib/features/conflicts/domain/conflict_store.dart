/// Where this device's sync conflicts are kept: on the device only, never synced
/// (`docs/reference/sync-app.md`, **Conflicts**). Sessions add them through the sync
/// store (`DriftSyncStore.recordConflicts`), which also drops the ones a later write
/// settles; this is the screen's side.
///
/// Implementations: Drift (dev and prod, the `conflicts` table) and in memory (the tests
/// and the demo flavor, which never syncs); both pass
/// `test/contract/conflict_store_contract.dart`.
library;

import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';

/// The conflicts.
abstract interface class ConflictStore {
  /// The conflicts, the most recently seen first (then by entity and field), starting
  /// with the current list and emitting again when it changes.
  Stream<List<SyncConflict>> watch();

  /// Forgets [conflict] ("Keep the other"); does nothing when it is gone.
  Future<void> dismiss(SyncConflict conflict);
}
