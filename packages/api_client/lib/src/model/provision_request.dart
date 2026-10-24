//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/provision_persona.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provision_request.g.dart';

/// ProvisionRequest
///
/// Properties:
/// * [persona]
/// * [seed]
/// * [days]
@BuiltValue()
abstract class ProvisionRequest
    implements Built<ProvisionRequest, ProvisionRequestBuilder> {
  @BuiltValueField(wireName: r'persona')
  ProvisionPersona get persona;
  // enum personaEnum {  renter,  family,  student,  small_business,  };

  @BuiltValueField(wireName: r'seed')
  int? get seed;

  @BuiltValueField(wireName: r'days')
  int? get days;

  ProvisionRequest._();

  factory ProvisionRequest([void updates(ProvisionRequestBuilder b)]) =
      _$ProvisionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProvisionRequestBuilder b) => b
    ..seed = 1
    ..days = 730;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProvisionRequest> get serializer =>
      _$ProvisionRequestSerializer();
}

class _$ProvisionRequestSerializer
    implements PrimitiveSerializer<ProvisionRequest> {
  @override
  final Iterable<Type> types = const [ProvisionRequest, _$ProvisionRequest];

  @override
  final String wireName = r'ProvisionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProvisionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'persona';
    yield serializers.serialize(
      object.persona,
      specifiedType: const FullType(ProvisionPersona),
    );
    if (object.seed != null) {
      yield r'seed';
      yield serializers.serialize(
        object.seed,
        specifiedType: const FullType(int),
      );
    }
    if (object.days != null) {
      yield r'days';
      yield serializers.serialize(
        object.days,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProvisionRequest object, {
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
    required ProvisionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'persona':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProvisionPersona),
          ) as ProvisionPersona;
          result.persona = valueDes;
          break;
        case r'seed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.seed = valueDes;
          break;
        case r'days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.days = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProvisionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProvisionRequestBuilder();
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
