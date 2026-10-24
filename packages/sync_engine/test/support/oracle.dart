// The brute-force reference for merge, written without merge: for every entity and field,
// the value of the entry with the greatest clock that wrote the field (a create never
// writes `deleted_at`), and the least `create` clock; and, separately, which entities are
// deleted, straight from the tombstone rule. The property test and the simulation check
// merge against both.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// The records [entries] determine, by entity.
Map<EntityKey, EntityRecord> oracleFold(Iterable<ChangeLogEntry> entries) {
  final byKey = <EntityKey, List<ChangeLogEntry>>{};
  for (final e in entries) {
    (byKey[(type: e.entityType, id: e.entityId)] ??= []).add(e);
  }
  return {
    for (final MapEntry(:key, value: list) in byKey.entries)
      key: _record(key, list),
  };
}

EntityRecord _record(EntityKey key, List<ChangeLogEntry> list) {
  final winners = <String, ChangeLogEntry>{};
  Hlc? createdAt;
  for (final e in list) {
    for (final field in e.payload.keys) {
      if (e.operation == ChangeOperation.create && field == 'deleted_at') {
        continue;
      }
      final best = winners[field];
      if (best == null || e.hlc.compareTo(best.hlc) > 0) winners[field] = e;
    }
    if (e.operation == ChangeOperation.create &&
        (createdAt == null || e.hlc.compareTo(createdAt) < 0)) {
      createdAt = e.hlc;
    }
  }
  return EntityRecord(
    type: key.type,
    id: key.id,
    fields: {
      for (final MapEntry(key: f, value: e) in winners.entries)
        f: e.payload[f] as Object?,
    },
    fieldClocks: {
      for (final MapEntry(key: f, value: e) in winners.entries) f: e.hlc,
    },
    createdAt: createdAt,
  );
}

/// Folds [entries] through merge, in order.
Map<EntityKey, EntityRecord> mergeFold(
  Iterable<ChangeLogEntry> entries, [
  Map<EntityKey, EntityRecord>? start,
]) {
  final state = {...?start};
  for (final e in entries) {
    final key = (type: e.entityType, id: e.entityId);
    state[key] = merge(state[key], e).record;
  }
  return state;
}

/// The canonical form of a set of records, sorted by key.
String canonical(Map<EntityKey, EntityRecord> state) {
  final records = state.values.map((r) => r.toCanonicalJson()).toList()..sort();
  return records.join('\n');
}

/// Whether each entity is deleted, by the tombstone rule alone: the non-create entry with
/// the greatest clock that writes `deleted_at` has a non-null value. Entities no such
/// entry touches are absent (not deleted).
Map<EntityKey, bool> oracleDeleted(Iterable<ChangeLogEntry> entries) {
  final latest = <EntityKey, ChangeLogEntry>{};
  for (final e in entries) {
    if (e.operation == ChangeOperation.create) continue;
    if (!e.payload.containsKey('deleted_at')) continue;
    final key = (type: e.entityType, id: e.entityId);
    final best = latest[key];
    if (best == null || e.hlc.compareTo(best.hlc) > 0) latest[key] = e;
  }
  return {
    for (final MapEntry(:key, value: e) in latest.entries)
      key: e.payload['deleted_at'] != null,
  };
}

/// Null when every record's `isDeleted` agrees with [oracleDeleted], else the first
/// disagreement.
String? tombstoneMismatch(
  Map<EntityKey, EntityRecord> state,
  Iterable<ChangeLogEntry> entries,
) {
  final deleted = oracleDeleted(entries);
  for (final MapEntry(:key, value: record) in state.entries) {
    final expected = deleted[key] ?? false;
    if (record.isDeleted != expected) {
      return '$key isDeleted ${record.isDeleted}, the tombstone rule says $expected';
    }
  }
  return null;
}
