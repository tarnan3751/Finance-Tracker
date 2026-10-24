//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/holding.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/security.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'holdings_response.g.dart';

/// HoldingsResponse
///
/// Properties:
/// * [holdings]
/// * [securities]
@BuiltValue()
abstract class HoldingsResponse
    implements Built<HoldingsResponse, HoldingsResponseBuilder> {
  @BuiltValueField(wireName: r'holdings')
  BuiltList<Holding> get holdings;

  @BuiltValueField(wireName: r'securities')
  BuiltList<Security> get securities;

  HoldingsResponse._();

  factory HoldingsResponse([void updates(HoldingsResponseBuilder b)]) =
      _$HoldingsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HoldingsResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HoldingsResponse> get serializer =>
      _$HoldingsResponseSerializer();
}

class _$HoldingsResponseSerializer
    implements PrimitiveSerializer<HoldingsResponse> {
  @override
  final Iterable<Type> types = const [HoldingsResponse, _$HoldingsResponse];

  @override
  final String wireName = r'HoldingsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HoldingsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'holdings';
    yield serializers.serialize(
      object.holdings,
      specifiedType: const FullType(BuiltList, [FullType(Holding)]),
    );
    yield r'securities';
    yield serializers.serialize(
      object.securities,
      specifiedType: const FullType(BuiltList, [FullType(Security)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HoldingsResponse object, {
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
    required HoldingsResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'holdings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Holding)]),
          ) as BuiltList<Holding>;
          result.holdings.replace(valueDes);
          break;
        case r'securities':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Security)]),
          ) as BuiltList<Security>;
          result.securities.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HoldingsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HoldingsResponseBuilder();
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
