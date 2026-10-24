//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/sync_run_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sync_run.g.dart';

/// The outcome of a sync request. `added`, `modified` and `removed` count the transactions applied, 0 unless `completed`.
///
/// Properties:
/// * [status]
/// * [added]
/// * [modified]
/// * [removed]
/// * [nextCursorSaved] - Whether the run finished every page and stored the new cursor
@BuiltValue()
abstract class SyncRun implements Built<SyncRun, SyncRunBuilder> {
  @BuiltValueField(wireName: r'status')
  SyncRunStatus get status;
  // enum statusEnum {  started,  not_ready,  completed,  };

  @BuiltValueField(wireName: r'added')
  int get added;

  @BuiltValueField(wireName: r'modified')
  int get modified;

  @BuiltValueField(wireName: r'removed')
  int get removed;

  /// Whether the run finished every page and stored the new cursor
  @BuiltValueField(wireName: r'next_cursor_saved')
  bool get nextCursorSaved;

  SyncRun._();

  factory SyncRun([void updates(SyncRunBuilder b)]) = _$SyncRun;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SyncRunBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SyncRun> get serializer => _$SyncRunSerializer();
}

class _$SyncRunSerializer implements PrimitiveSerializer<SyncRun> {
  @override
  final Iterable<Type> types = const [SyncRun, _$SyncRun];

  @override
  final String wireName = r'SyncRun';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SyncRun object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(SyncRunStatus),
    );
    yield r'added';
    yield serializers.serialize(
      object.added,
      specifiedType: const FullType(int),
    );
    yield r'modified';
    yield serializers.serialize(
      object.modified,
      specifiedType: const FullType(int),
    );
    yield r'removed';
    yield serializers.serialize(
      object.removed,
      specifiedType: const FullType(int),
    );
    yield r'next_cursor_saved';
    yield serializers.serialize(
      object.nextCursorSaved,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SyncRun object, {
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
    required SyncRunBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SyncRunStatus),
          ) as SyncRunStatus;
          result.status = valueDes;
          break;
        case r'added':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.added = valueDes;
          break;
        case r'modified':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.modified = valueDes;
          break;
        case r'removed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.removed = valueDes;
          break;
        case r'next_cursor_saved':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.nextCursorSaved = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SyncRun deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SyncRunBuilder();
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
