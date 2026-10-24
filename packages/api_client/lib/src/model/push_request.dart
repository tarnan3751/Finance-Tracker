//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/change_log_entry.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'push_request.g.dart';

/// PushRequest
///
/// Properties:
/// * [entries]
@BuiltValue()
abstract class PushRequest implements Built<PushRequest, PushRequestBuilder> {
  @BuiltValueField(wireName: r'entries')
  BuiltList<ChangeLogEntry> get entries;

  PushRequest._();

  factory PushRequest([void updates(PushRequestBuilder b)]) = _$PushRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PushRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PushRequest> get serializer => _$PushRequestSerializer();
}

class _$PushRequestSerializer implements PrimitiveSerializer<PushRequest> {
  @override
  final Iterable<Type> types = const [PushRequest, _$PushRequest];

  @override
  final String wireName = r'PushRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PushRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(ChangeLogEntry)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PushRequest object, {
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
    required PushRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(ChangeLogEntry),
            ]),
          ) as BuiltList<ChangeLogEntry>;
          result.entries.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PushRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PushRequestBuilder();
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
