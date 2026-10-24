//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'money.g.dart';

/// An amount: integer minor units of an ISO 4217 currency. -1234 USD is -12.34 dollars. Negative is an outflow. -2^63 is excluded, so every amount has a negation.
///
/// Properties:
/// * [minorUnits]
/// * [currency]
@BuiltValue()
abstract class Money implements Built<Money, MoneyBuilder> {
  @BuiltValueField(wireName: r'minor_units')
  int get minorUnits;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  Money._();

  factory Money([void updates(MoneyBuilder b)]) = _$Money;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MoneyBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Money> get serializer => _$MoneySerializer();
}

class _$MoneySerializer implements PrimitiveSerializer<Money> {
  @override
  final Iterable<Type> types = const [Money, _$Money];

  @override
  final String wireName = r'Money';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Money object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'minor_units';
    yield serializers.serialize(
      object.minorUnits,
      specifiedType: const FullType(int),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Money object, {
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
    required MoneyBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'minor_units':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.minorUnits = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Money deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MoneyBuilder();
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
