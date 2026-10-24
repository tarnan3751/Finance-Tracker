/// Turns a local edit into a change-log entry (`docs/reference/sync.md`, **Diff**).
library;

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';

/// The change from [before] to [after] of the entity [type] [id], stamped [hlc], or null
/// when nothing changed.
///
/// [before] is the host's snapshot the edit started from (null for a new entity), not
/// necessarily the stored record: a field the user did not touch is not in the entry, so
/// a remote change merged meanwhile is not reverted. Fields are top-level keys; a nested
/// value is compared deeply and carried whole when it differs. A key absent from one map
/// counts as null there.
///
/// The operation is `create` when [before] is null, `delete` when `deleted_at` goes from
/// null to non-null, and `update` otherwise (a restore is an update setting `deleted_at`
/// to null). A create's payload is all of [after] except `deleted_at`: only updates and
/// deletes write the tombstone, so a create concurrent with a delete never undoes it. A
/// delete's `deleted_at` is the entry's wall instant, `hlc.wall` written by
/// [UtcInstantConverter], whatever the host put there.
///
/// Throws [ArgumentError] on a value that is not JSON, on a create with an empty [after]
/// (the relay would refuse it forever) and on a create with a non-null `deleted_at` (a
/// new entity is not born deleted).
ChangeLogEntry? diff(
  EntityType type,
  String id,
  Map<String, Object?>? before,
  Map<String, Object?> after,
  Hlc hlc,
) {
  final payload = <String, Object?>{};
  final ChangeOperation operation;
  if (before == null) {
    if (after[deletedAtField] != null) {
      throw ArgumentError.value(after, 'after', 'a create cannot be deleted');
    }
    operation = ChangeOperation.create;
    payload
      ..addAll(after)
      ..remove(deletedAtField);
    if (payload.isEmpty) {
      throw ArgumentError.value(after, 'after', 'a create needs fields');
    }
  } else {
    for (final key in {...before.keys, ...after.keys}) {
      if (!jsonEquality.equals(before[key], after[key])) {
        payload[key] = after[key];
      }
    }
    if (payload.isEmpty) return null;
    operation = before['deleted_at'] == null && after['deleted_at'] != null
        ? ChangeOperation.delete
        : ChangeOperation.update;
  }
  if (operation == ChangeOperation.delete) {
    payload['deleted_at'] = const UtcInstantConverter().toJson(hlc.wall);
  }
  return ChangeLogEntry(
    entityType: type,
    entityId: id,
    operation: operation,
    payload: freezeJsonMap(payload),
    hlc: hlc,
    deviceId: hlc.nodeId,
    synced: false,
  );
}
