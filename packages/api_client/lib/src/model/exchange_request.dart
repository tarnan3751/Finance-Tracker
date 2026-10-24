//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'exchange_request.g.dart';

/// ExchangeRequest
///
/// Properties:
/// * [publicToken]
@BuiltValue()
abstract class ExchangeRequest
    implements Built<ExchangeRequest, ExchangeRequestBuilder> {
  @BuiltValueField(wireName: r'public_token')
  String get publicToken;

  ExchangeRequest._();

  factory ExchangeRequest([void updates(ExchangeRequestBuilder b)]) =
      _$ExchangeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExchangeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExchangeRequest> get serializer =>
      _$ExchangeRequestSerializer();
}

class _$ExchangeRequestSerializer
    implements PrimitiveSerializer<ExchangeRequest> {
  @override
  final Iterable<Type> types = const [ExchangeRequest, _$ExchangeRequest];

  @override
  final String wireName = r'ExchangeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExchangeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'public_token';
    yield serializers.serialize(
      object.publicToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExchangeRequest object, {
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
    required ExchangeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'public_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.publicToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExchangeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExchangeRequestBuilder();
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
