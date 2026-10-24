/// The local edit path: what the host's repositories call when the user changes a
/// user-authored entity (`docs/reference/sync.md`, **Local edits**).
library;

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/diff.dart';
import 'package:sync_engine/src/hlc_clock.dart';
import 'package:sync_engine/src/merge.dart';
import 'package:sync_engine/src/sync_store.dart';

/// Records local changes: diff, stamp, store, outbox, in one transaction.
///
/// Only user-authored data comes through here. The engine never reads `source`; keeping
/// Plaid-sourced rows (server-authoritative, pulled by version) out of the change log is
/// the host's filter, in the app's repositories, before they call [recordChange].
final class LocalEditor {
  /// An editor over [store], stamping with [clock], the same clock instance the device's
  /// `SyncSession` uses.
  LocalEditor(this.store, this.clock);

  /// The device's store.
  final SyncStore store;

  /// The device's clock.
  final HlcClock clock;

  /// Records the change of entity [type] [id] from [before] (the snapshot the edit
  /// started from; null for a new entity) to [after], at physical time [nowWallMillis].
  ///
  /// In one store transaction: stamps a clock with [HlcClock.send] and persists the
  /// clock, diffs ([diff]), merges the entry into the stored record (so the local record
  /// is exactly what merging the entry anywhere gives), writes it and appends the entry
  /// to the outbox. Returns the entry, or null when nothing changed.
  Future<ChangeLogEntry?> recordChange(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
    int nowWallMillis,
  ) => store.transaction(() async {
    final hlc = clock.send(nowWallMillis);
    await store.saveClock(clock.last);
    final entry = diff(type, id, before, after, hlc);
    if (entry == null) return null;
    await store.write(merge(await store.read(type, id), entry).record);
    await store.append(entry);
    return entry;
  });
}
