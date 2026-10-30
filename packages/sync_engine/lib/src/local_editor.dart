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
  /// In one store transaction: stamps a clock and persists it, diffs ([diff]), merges
  /// the entry into the stored record (so the local record is exactly what merging the
  /// entry anywhere gives), writes it and appends the entry to the outbox. Returns the
  /// entry, or null when nothing changed.
  ///
  /// The clock is [HlcClock.sendAfter] the greatest stored clock among the fields the
  /// entry writes, or [HlcClock.send] when none has one: an edit is causally after the
  /// values it changes, so it wins over them even when their clock is beyond the clock
  /// bound (this device received them without adopting their time), and it is visible
  /// as soon as it is recorded.
  Future<ChangeLogEntry?> recordChange(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
    int nowWallMillis,
  ) => store.transaction(() async {
    final stored = await store.read(type, id);
    // The fields the entry will write, from a diff stamped with the current clock.
    final fields = diff(type, id, before, after, clock.last)?.payload.keys;
    Hlc? seen;
    for (final f in fields ?? const <String>[]) {
      final c = stored?.fieldClocks[f];
      if (c != null && (seen == null || c.compareTo(seen) > 0)) seen = c;
    }
    final hlc = seen == null
        ? clock.send(nowWallMillis)
        : clock.sendAfter(seen, nowWallMillis);
    await store.saveClock(clock.last);
    final entry = diff(type, id, before, after, hlc);
    if (entry == null) return null;
    await store.write(merge(stored, entry).record);
    await store.append(entry);
    return entry;
  });
}
