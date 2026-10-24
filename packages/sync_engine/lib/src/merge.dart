/// Field-level last-writer-wins merge (`docs/reference/sync.md`, **Merge**).
///
/// The state of an entity is one register per field, holding the value with the greatest
/// clock, plus [EntityRecord.createdAt], the least `create` clock. Merging an entry joins
/// each register it touches with the entry's value, so folding any multiset of entries in
/// any order and grouping gives the same record: merge is commutative, associative and
/// idempotent, given that one clock identifies one payload (clocks are unique per node and
/// carry the node id; the relay refuses a resent clock with another payload).
///
/// Tombstones win over concurrent edits. `deleted_at` is a register written only by
/// `update` and `delete` entries: an edit concurrent with a delete does not write it
/// (its diff has no change there), and a `create` never does (merge ignores `deleted_at`
/// in a create, whoever produced it), so the entity stays deleted whatever those
/// entries' clocks; their other fields still apply, so a later restore shows them. Only
/// an update writing `deleted_at: null` with a greater clock than the tombstone's
/// restores the entity. Ignoring one field of an entry keeps the join argument: the
/// create simply does not touch that register.
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';

/// The result of [merge].
@immutable
final class MergeOutcome {
  /// An outcome.
  const MergeOutcome(this.record, this.changedFields, this.applied);

  /// The merged record.
  final EntityRecord record;

  /// The fields the entry set: those whose clock was absent or older.
  final Set<String> changedFields;

  /// Whether the entry changed the record (a field, or [EntityRecord.createdAt]).
  final bool applied;
}

/// Merges [remote] into [local] (null when the entity is unknown here).
///
/// Each payload field is taken when its clock in [local] is absent or less than
/// `remote.hlc`; an equal clock is the same change again and is left alone. A `create`
/// for an entity that exists is an update of every field it carries except
/// `deleted_at`, which a create never writes, and lowers `createdAt` to its clock if
/// that is earlier. Throws [ArgumentError] when [local] is
/// another entity.
MergeOutcome merge(EntityRecord? local, ChangeLogEntry remote) {
  final base = local ?? EntityRecord.empty(remote.entityType, remote.entityId);
  if (base.type != remote.entityType || base.id != remote.entityId) {
    throw ArgumentError.value(
      remote,
      'remote',
      'is not a change to ${base.key}',
    );
  }
  final hlc = remote.hlc;
  final changed = <String>{};
  final isCreate = remote.operation == ChangeOperation.create;
  for (final field in remote.payload.keys) {
    if (isCreate && field == deletedAtField) continue;
    final clock = base.fieldClocks[field];
    if (clock == null || clock.compareTo(hlc) < 0) changed.add(field);
  }
  var createdAt = base.createdAt;
  if (isCreate && (createdAt == null || hlc.compareTo(createdAt) < 0)) {
    createdAt = hlc;
  }
  if (changed.isEmpty && createdAt == base.createdAt) {
    return MergeOutcome(base, const {}, false);
  }
  final record = EntityRecord(
    type: base.type,
    id: base.id,
    fields: {
      ...base.fields,
      for (final f in changed) f: remote.payload[f] as Object?,
    },
    fieldClocks: {...base.fieldClocks, for (final f in changed) f: hlc},
    createdAt: createdAt,
  );
  return MergeOutcome(record, changed, true);
}
