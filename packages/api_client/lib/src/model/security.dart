//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'security.g.dart';

/// Security
///
/// Properties:
/// * [id]
/// * [name]
/// * [tickerSymbol]
/// * [type] - Plaid's security type, kept open (`equity`, `etf`, `mutual fund`, `cash`, ...)
/// * [isCashEquivalent]
/// * [closePrice] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [closePriceAsOf]
/// * [currencyCode]
@BuiltValue()
abstract class Security implements Built<Security, SecurityBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'ticker_symbol')
  String? get tickerSymbol;

  /// Plaid's security type, kept open (`equity`, `etf`, `mutual fund`, `cash`, ...)
  @BuiltValueField(wireName: r'type')
  String? get type;

  @BuiltValueField(wireName: r'is_cash_equivalent')
  bool? get isCashEquivalent;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'close_price')
  String? get closePrice;

  @BuiltValueField(wireName: r'close_price_as_of')
  Date? get closePriceAsOf;

  @BuiltValueField(wireName: r'currency_code')
  String get currencyCode;

  Security._();

  factory Security([void updates(SecurityBuilder b)]) = _$Security;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SecurityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Security> get serializer => _$SecuritySerializer();
}

class _$SecuritySerializer implements PrimitiveSerializer<Security> {
  @override
  final Iterable<Type> types = const [Security, _$Security];

  @override
  final String wireName = r'Security';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Security object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield object.name == null
        ? null
        : serializers.serialize(
            object.name,
            specifiedType: const FullType.nullable(String),
          );
    yield r'ticker_symbol';
    yield object.tickerSymbol == null
        ? null
        : serializers.serialize(
            object.tickerSymbol,
            specifiedType: const FullType.nullable(String),
          );
    yield r'type';
    yield object.type == null
        ? null
        : serializers.serialize(
            object.type,
            specifiedType: const FullType.nullable(String),
          );
    yield r'is_cash_equivalent';
    yield object.isCashEquivalent == null
        ? null
        : serializers.serialize(
            object.isCashEquivalent,
            specifiedType: const FullType.nullable(bool),
          );
    yield r'close_price';
    yield object.closePrice == null
        ? null
        : serializers.serialize(
            object.closePrice,
            specifiedType: const FullType.nullable(String),
          );
    yield r'close_price_as_of';
    yield object.closePriceAsOf == null
        ? null
        : serializers.serialize(
            object.closePriceAsOf,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'currency_code';
    yield serializers.serialize(
      object.currencyCode,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Security object, {
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
    required SecurityBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'ticker_symbol':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tickerSymbol = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.type = valueDes;
          break;
        case r'is_cash_equivalent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.isCashEquivalent = valueDes;
          break;
        case r'close_price':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.closePrice = valueDes;
          break;
        case r'close_price_as_of':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.closePriceAsOf = valueDes;
          break;
        case r'currency_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currencyCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Security deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SecurityBuilder();
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
