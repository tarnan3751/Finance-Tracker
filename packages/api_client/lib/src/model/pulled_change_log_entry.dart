//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/entity_type.dart';
import 'package:api_client/src/model/change_operation.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pulled_change_log_entry.g.dart';

/// A `ChangeLogEntry` as pulled, with the server's `seq`.
///
/// Properties:
/// * [entityType]
/// * [entityId]
/// * [operation]
/// * [payload]
/// * [hlc] - A hybrid logical clock timestamp in its packed form `<wall>-<counter>-<node>`: wall milliseconds zero-padded to 15 digits, the counter to 5, then the node id. Packed strings sort in logical order.
/// * [deviceId]
/// * [seq] - The server's per-user order of arrival
@BuiltValue()
abstract class PulledChangeLogEntry
    implements Built<PulledChangeLogEntry, PulledChangeLogEntryBuilder> {
  @BuiltValueField(wireName: r'entity_type')
  EntityType get entityType;
  // enum entityTypeEnum {  account,  transaction,  category,  rule,  budget,  recurring_stream,  bill_reminder,  goal,  settings,  };

  @BuiltValueField(wireName: r'entity_id')
  String get entityId;

  @BuiltValueField(wireName: r'operation')
  ChangeOperation get operation;
  // enum operationEnum {  create,  update,  delete,  };

  @BuiltValueField(wireName: r'payload')
  BuiltMap<String, JsonObject?> get payload;

  /// A hybrid logical clock timestamp in its packed form `<wall>-<counter>-<node>`: wall milliseconds zero-padded to 15 digits, the counter to 5, then the node id. Packed strings sort in logical order.
  @BuiltValueField(wireName: r'hlc')
  String get hlc;

  @BuiltValueField(wireName: r'device_id')
  String get deviceId;

  /// The server's per-user order of arrival
  @BuiltValueField(wireName: r'seq')
  int get seq;

  PulledChangeLogEntry._();

  factory PulledChangeLogEntry([void updates(PulledChangeLogEntryBuilder b)]) =
      _$PulledChangeLogEntry;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PulledChangeLogEntryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PulledChangeLogEntry> get serializer =>
      _$PulledChangeLogEntrySerializer();
}

class _$PulledChangeLogEntrySerializer
    implements PrimitiveSerializer<PulledChangeLogEntry> {
  @override
  final Iterable<Type> types = const [
    PulledChangeLogEntry,
    _$PulledChangeLogEntry,
  ];

  @override
  final String wireName = r'PulledChangeLogEntry';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PulledChangeLogEntry object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entity_type';
    yield serializers.serialize(
      object.entityType,
      specifiedType: const FullType(EntityType),
    );
    yield r'entity_id';
    yield serializers.serialize(
      object.entityId,
      specifiedType: const FullType(String),
    );
    yield r'operation';
    yield serializers.serialize(
      object.operation,
      specifiedType: const FullType(ChangeOperation),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(BuiltMap, [
        FullType(String),
        FullType.nullable(JsonObject),
      ]),
    );
    yield r'hlc';
    yield serializers.serialize(
      object.hlc,
      specifiedType: const FullType(String),
    );
    yield r'device_id';
    yield serializers.serialize(
      object.deviceId,
      specifiedType: const FullType(String),
    );
    yield r'seq';
    yield serializers.serialize(object.seq, specifiedType: const FullType(int));
  }

  @override
  Object serialize(
    Serializers serializers,
    PulledChangeLogEntry object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PulledChangeLogEntryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entity_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EntityType),
          ) as EntityType;
          result.entityType = valueDes;
          break;
        case r'entity_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.entityId = valueDes;
          break;
        case r'operation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ChangeOperation),
          ) as ChangeOperation;
          result.operation = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [
              FullType(String),
              FullType.nullable(JsonObject),
            ]),
          ) as BuiltMap<String, JsonObject?>;
          result.payload.replace(valueDes);
          break;
        case r'hlc':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.hlc = valueDes;
          break;
        case r'device_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceId = valueDes;
          break;
        case r'seq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seq = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PulledChangeLogEntry deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PulledChangeLogEntryBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
