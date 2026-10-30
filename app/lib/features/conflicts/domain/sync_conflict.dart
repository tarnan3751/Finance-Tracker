/// A sync conflict as the Conflicts screen shows it (`docs/reference/sync-app.md`,
/// **Conflicts**): one of this device's own values that a change pulled from another
/// device overwrote within ten minutes. Pure Dart, no Flutter import.
library;

import 'package:shared_models/shared_models.dart';

/// Identifies a conflict: one per entity and field.
typedef ConflictKey = ({EntityType type, String id, String field});

/// A field whose value this device wrote ([localValue] under [localClock]) and another
/// device replaced ([remoteValue] under [remoteClock]). The values are the record's JSON
/// values; each clock's node is the device that wrote it. [entityLabel] is the entity's
/// name when it has one; [seenAt] is when this device saw the conflict (UTC).
final class SyncConflict {
  /// A conflict.
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.localValue,
    required this.localClock,
    required this.remoteValue,
    required this.remoteClock,
    required this.entityLabel,
    required this.seenAt,
  });

  final EntityType entityType;
  final String entityId;
  final String field;
  final Object? localValue;
  final Hlc localClock;
  final Object? remoteValue;
  final Hlc remoteClock;
  final String? entityLabel;
  final DateTime seenAt;

  /// The conflict's key.
  ConflictKey get key => (type: entityType, id: entityId, field: field);

  @override
  bool operator ==(Object other) =>
      other is SyncConflict &&
      other.key == key &&
      other.localClock == localClock &&
      other.remoteClock == remoteClock;

  @override
  int get hashCode => Object.hash(key, localClock, remoteClock);

  @override
  String toString() =>
      'SyncConflict(${entityType.name}/$entityId.$field, $localClock lost to '
      '$remoteClock)';
}
