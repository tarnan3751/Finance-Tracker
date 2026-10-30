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
  final joined = joinChange(
    fields: base.fields,
    fieldClocks: base.fieldClocks,
    createdAt: base.createdAt,
    operation: remote.operation,
    payload: remote.payload,
    hlc: remote.hlc,
  );
  if (joined == null) return MergeOutcome(base, const {}, false);
  final record = EntityRecord(
    type: base.type,
    id: base.id,
    fields: joined.fields,
    fieldClocks: joined.fieldClocks,
    createdAt: joined.createdAt,
  );
  return MergeOutcome(record, joined.changed, true);
}

/// The registers of one entity after a change ([operation] of [payload] at [hlc]) is
/// joined into [fields], [fieldClocks] and [createdAt], as [merge] joins it; null when
/// the change sets nothing. [merge] and `mergeUnknownType` share it, so a record held
/// under a type this build does not know folds exactly as it will once the type is
/// known.
({
  Map<String, Object?> fields,
  Map<String, Hlc> fieldClocks,
  Hlc? createdAt,
  Set<String> changed,
})?
joinChange({
  required Map<String, Object?> fields,
  required Map<String, Hlc> fieldClocks,
  required Hlc? createdAt,
  required ChangeOperation operation,
  required Map<String, dynamic> payload,
  required Hlc hlc,
}) {
  final changed = <String>{};
  final isCreate = operation == ChangeOperation.create;
  for (final field in payload.keys) {
    if (isCreate && field == deletedAtField) continue;
    final clock = fieldClocks[field];
    if (clock == null || clock.compareTo(hlc) < 0) changed.add(field);
  }
  var created = createdAt;
  if (isCreate && (created == null || hlc.compareTo(created) < 0)) {
    created = hlc;
  }
  if (changed.isEmpty && created == createdAt) return null;
  return (
    fields: {...fields, for (final f in changed) f: payload[f] as Object?},
    fieldClocks: {...fieldClocks, for (final f in changed) f: hlc},
    createdAt: created,
    changed: changed,
  );
}
