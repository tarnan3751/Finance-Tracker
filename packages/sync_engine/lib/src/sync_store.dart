/// The storage the engine needs from its host (`docs/reference/sync.md`, **The store**).
library;

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/sync_relay.dart';

/// Where one device keeps its records, its outbox, its pull cursor and its clock. The app
/// implements it over Drift and the server over SQLite; [InMemorySyncStore] is the
/// reference implementation.
///
/// [transaction] is all-or-nothing and serialized: when `body` throws, every write made
/// inside it is discarded and the error is rethrown; no other transaction's reads or
/// writes interleave with it; a call made inside `body` (a nested [transaction] included)
/// joins it. Each call outside a transaction is atomic on its own.
abstract interface class SyncStore {
  /// Runs [body] as one transaction.
  Future<T> transaction<T>(Future<T> Function() body);

  /// The record of entity [type] [id], or null when the device has none.
  Future<EntityRecord?> read(EntityType type, String id);

  /// Stores [record], replacing the one with its key.
  Future<void> write(EntityRecord record);

  /// Up to [limit] outbox entries not yet accepted by the relay, in clock order.
  Future<List<ChangeLogEntry>> unsynced({int limit = 200});

  /// Marks the outbox entries with these clocks as accepted by the relay.
  Future<void> markSynced(Iterable<Hlc> hlcs);

  /// Takes the outbox entries with these clocks out of the outbox for good: the relay
  /// refused them for [reason], which is permanent (`invalid` or
  /// `conflictingDuplicate`). The store keeps them, with the reason, for the host to
  /// inspect; [unsynced] never returns them again.
  Future<void> markRejected(Iterable<Hlc> hlcs, PushRejectionReason reason);

  /// Adds a local change to the outbox, unsynced.
  Future<void> append(ChangeLogEntry entry);

  /// The relay `seq` pulled up to, or null before the first pull.
  Future<int?> pullCursor();

  /// Saves the relay `seq` pulled up to.
  Future<void> savePullCursor(int seq);

  /// The persisted clock state ([HlcClock.last]), or null on a new device.
  Future<Hlc?> lastClock();

  /// Persists the clock state.
  Future<void> saveClock(Hlc clock);
}
