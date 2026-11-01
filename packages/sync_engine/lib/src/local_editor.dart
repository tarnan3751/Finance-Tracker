/// The local edit path: what the host's repositories call when the user changes a
/// user-authored entity (`docs/reference/sync.md`, **Local edits**).
library;

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/diff.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/hlc_clock.dart';
import 'package:sync_engine/src/merge.dart';
import 'package:sync_engine/src/sync_store.dart';

/// One local change to entity [id]: its record fields [before] (null for a new entity)
/// and [after], as [LocalEditor.recordChange] takes them.
typedef LocalChange = ({
  String id,
  Map<String, Object?>? before,
  Map<String, Object?> after,
});

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
    final (entry, record) = _stamp(
      type,
      id,
      stored,
      before,
      after,
      nowWallMillis,
    );
    await store.saveClock(clock.last);
    if (entry == null) return null;
    await store.write(record!);
    await store.append(entry);
    return entry;
  });

  /// Records [changes] to entities of [type], each as [recordChange] would, in order, in
  /// one store transaction; [nowWallMillis] is read once per change, as each
  /// [recordChange] call would be given it. Returns the entries, null where nothing
  /// changed, in the order of [changes].
  ///
  /// The stored records are read with one [SyncStore.readAll], the records written with
  /// one [SyncStore.writeAll] and the entries appended with one [SyncStore.appendAll],
  /// and the clock saved once, after the last stamp: in one transaction that leaves the
  /// store, the outbox and the clock exactly as the [recordChange] calls would. Throws
  /// [ArgumentError] when two changes name one entity, since each change is stamped
  /// against the record as stored before the batch.
  Future<List<ChangeLogEntry?>> recordChanges(
    EntityType type,
    List<LocalChange> changes,
    int Function() nowWallMillis,
  ) async {
    final ids = {for (final c in changes) c.id};
    if (ids.length != changes.length) {
      throw ArgumentError.value(changes, 'changes', 'names an entity twice');
    }
    if (changes.isEmpty) return const [];
    return store.transaction(() async {
      final stored = await store.readAll(type, ids);
      final entries = <ChangeLogEntry?>[];
      final records = <EntityRecord>[];
      for (final c in changes) {
        final (entry, record) = _stamp(
          type,
          c.id,
          stored[c.id],
          c.before,
          c.after,
          nowWallMillis(),
        );
        entries.add(entry);
        if (record != null) records.add(record);
      }
      await store.saveClock(clock.last);
      await store.writeAll(records);
      await store.appendAll([...entries.nonNulls]);
      return entries;
    });
  }

  // Stamps the change of [id] from [before] to [after] against [stored], advancing the
  // clock, and diffs it: the entry and the merged record, or nulls when nothing changed.
  (ChangeLogEntry?, EntityRecord?) _stamp(
    EntityType type,
    String id,
    EntityRecord? stored,
    Map<String, Object?>? before,
    Map<String, Object?> after,
    int nowWallMillis,
  ) {
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
    final entry = diff(type, id, before, after, hlc);
    if (entry == null) return (null, null);
    return (entry, merge(stored, entry).record);
  }
}
