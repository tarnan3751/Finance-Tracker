/// Pulled changes to entities of a type this build does not know: a newer version's
/// (`docs/reference/sync.md`, **Unknown types**).
///
/// A device on an older build keeps syncing when another device pushes a type added
/// after its build: the relay adapter keeps such an entry's raw type name instead of
/// failing the page, the session hands it to [SyncStore.holdUnknownType] inside the
/// page's transaction (its clock received like any other), and the store keeps the
/// entity's fields and clocks under the raw name, folded by [mergeUnknownType] exactly
/// as [merge] would fold them. The rest of the page applies and the cursor advances. A
/// later version that knows the type finds the record under its JSON name and stores it.
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/merge.dart';
import 'package:sync_engine/src/sync_store.dart';

/// A pulled change-log entry whose `entity_type`, [entityType], this build does not know.
@immutable
final class UnknownTypeEntry {
  /// An entry.
  const UnknownTypeEntry({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.hlc,
    required this.deviceId,
  });

  /// The type's JSON name, as the relay sent it.
  final String entityType;

  /// The entity's id.
  final String entityId;

  /// The operation.
  final ChangeOperation operation;

  /// The changed fields as JSON.
  final Map<String, dynamic> payload;

  /// The entry's clock.
  final Hlc hlc;

  /// The device that recorded it.
  final String deviceId;
}

/// The fields and field clocks of an entity of a type this build does not know, as
/// merged so far; [createdAt] is the earliest `create` merged, as in [EntityRecord].
@immutable
final class UnknownTypeRecord {
  /// A record; [fields] and [fieldClocks] have the same keys.
  UnknownTypeRecord({
    required this.type,
    required this.id,
    Map<String, Object?> fields = const {},
    Map<String, Hlc> fieldClocks = const {},
    this.createdAt,
  }) : fields = freezeJsonMap(fields),
       fieldClocks = Map.unmodifiable(fieldClocks) {
    if (fields.length != fieldClocks.length ||
        !fields.keys.every(fieldClocks.containsKey)) {
      throw ArgumentError('fields and fieldClocks must have the same keys');
    }
  }

  /// The type's JSON name.
  final String type;

  /// The entity's id.
  final String id;

  /// The entity's JSON fields.
  final Map<String, Object?> fields;

  /// The clock of the change that last set each field.
  final Map<String, Hlc> fieldClocks;

  /// The clock of the earliest `create` merged, or null.
  final Hlc? createdAt;
}

/// [remote] merged into [local] (null when the entity is unknown here), by the rules of
/// [merge]. Throws [ArgumentError] when [local] is another entity.
UnknownTypeRecord mergeUnknownType(
  UnknownTypeRecord? local,
  UnknownTypeEntry remote,
) {
  if (local != null &&
      (local.type != remote.entityType || local.id != remote.entityId)) {
    throw ArgumentError.value(
      remote,
      'remote',
      'is not a change to ${local.type}/${local.id}',
    );
  }
  final base =
      local ?? UnknownTypeRecord(type: remote.entityType, id: remote.entityId);
  final joined = joinChange(
    fields: base.fields,
    fieldClocks: base.fieldClocks,
    createdAt: base.createdAt,
    operation: remote.operation,
    payload: remote.payload,
    hlc: remote.hlc,
  );
  if (joined == null) return base;
  return UnknownTypeRecord(
    type: base.type,
    id: base.id,
    fields: joined.fields,
    fieldClocks: joined.fieldClocks,
    createdAt: joined.createdAt,
  );
}
