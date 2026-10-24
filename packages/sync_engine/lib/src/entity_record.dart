/// The engine's field-level state of one user-authored entity (`PLAN.md` §6.4).
library;

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';

/// Identifies an entity across types.
typedef EntityKey = ({EntityType type, String id});

/// One entity as the sync engine holds it: its snake_case JSON fields (as `shared_models`
/// writes them) and, per field, the clock of the change that last set it.
///
/// Every top-level field is a last-writer-wins register; a nested value (a list such as
/// `tags` or `splits`, a map such as a `Money`) is one value, replaced whole. `deleted_at`
/// is a register with its own clock, written only by updates and deletes (never by a
/// create, so it is absent until the first delete): the entity is deleted while it is
/// non-null. [createdAt] is the clock of the earliest `create` seen, null while only
/// updates have arrived (out-of-order delivery); the host does not materialize an
/// incomplete record.
///
/// The engine reads no field but `deleted_at`. It never reads `source`: keeping
/// Plaid-sourced rows out of the change log is the host's job (`docs/reference/sync.md`).
@immutable
final class EntityRecord {
  /// A record; [fields] and [fieldClocks] must have the same keys. Both are copied, deeply
  /// and unmodifiably, and every value must be JSON (null, bool, int, finite double,
  /// String, List, or Map with String keys).
  EntityRecord({
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

  /// An empty record for [type] and [id], before any change has been merged.
  EntityRecord.empty(this.type, this.id)
    : fields = const {},
      fieldClocks = const {},
      createdAt = null;

  /// The entity's type.
  final EntityType type;

  /// The entity's id.
  final String id;

  /// The entity's JSON fields.
  final Map<String, Object?> fields;

  /// The clock of the change that last set each field.
  final Map<String, Hlc> fieldClocks;

  /// The clock of the earliest `create` merged, or null.
  final Hlc? createdAt;

  /// The key of this entity.
  EntityKey get key => (type: type, id: id);

  /// Whether the entity is deleted: `deleted_at` is non-null.
  bool get isDeleted => fields[deletedAtField] != null;

  /// Whether the entity's `create` has been merged.
  bool get isComplete => createdAt != null;

  /// The canonical JSON form: keys sorted at every depth, clocks packed. Equal records
  /// have byte-identical canonical forms, with JSON number equality: `1` and `1.0` are
  /// equal values but encode differently, which never arises in practice because no
  /// user-authored field is a double.
  String toCanonicalJson() => jsonEncode(
    _sorted({
      'type': type.name,
      'id': id,
      'created_at': createdAt?.pack(),
      'fields': fields,
      'field_clocks': {
        for (final e in fieldClocks.entries) e.key: e.value.pack(),
      },
    }),
  );

  @override
  bool operator ==(Object other) =>
      other is EntityRecord &&
      other.type == type &&
      other.id == id &&
      other.createdAt == createdAt &&
      const MapEquality<String, Hlc>().equals(other.fieldClocks, fieldClocks) &&
      jsonEquality.equals(other.fields, fields);

  @override
  int get hashCode => Object.hash(
    type,
    id,
    createdAt,
    const MapEquality<String, Hlc>().hash(fieldClocks),
    jsonEquality.hash(fields),
  );

  @override
  String toString() => 'EntityRecord(${toCanonicalJson()})';
}

/// The tombstone field.
const String deletedAtField = 'deleted_at';

/// Deep equality on JSON values: lists in order, maps by key.
const DeepCollectionEquality jsonEquality = DeepCollectionEquality();

/// A deep, unmodifiable copy of the JSON object [map]; throws [ArgumentError] on a value
/// that is not JSON.
Map<String, Object?> freezeJsonMap(Map<String, Object?> map) =>
    Map.unmodifiable({for (final e in map.entries) e.key: _freeze(e.value)});

Object? _freeze(Object? value) => switch (value) {
  null || bool() || int() || String() => value,
  double() when value.isFinite => value,
  List<Object?>() => List<Object?>.unmodifiable(value.map(_freeze)),
  Map<String, Object?>() => freezeJsonMap(value),
  _ => throw ArgumentError.value(value, 'value', 'not a JSON value'),
};

Object? _sorted(Object? value) => switch (value) {
  Map<String, Object?>() => {
    for (final k in value.keys.toList()..sort()) k: _sorted(value[k]),
  },
  List<Object?>() => [for (final v in value) _sorted(v)],
  _ => value,
};
