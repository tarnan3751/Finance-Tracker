//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'holding.g.dart';

/// A position in one security. `quantity` and `institution_price` are `Decimal`; `institution_value` and `cost_basis` are totals in `currency_code`.
///
/// Properties:
/// * [accountId]
/// * [securityId]
/// * [quantity] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [institutionPrice] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [institutionPriceAsOf]
/// * [institutionValue]
/// * [costBasis]
/// * [currencyCode]
@BuiltValue()
abstract class Holding implements Built<Holding, HoldingBuilder> {
  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'security_id')
  String get securityId;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'quantity')
  String get quantity;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'institution_price')
  String get institutionPrice;

  @BuiltValueField(wireName: r'institution_price_as_of')
  Date? get institutionPriceAsOf;

  @BuiltValueField(wireName: r'institution_value')
  Money get institutionValue;

  @BuiltValueField(wireName: r'cost_basis')
  Money? get costBasis;

  @BuiltValueField(wireName: r'currency_code')
  String get currencyCode;

  Holding._();

  factory Holding([void updates(HoldingBuilder b)]) = _$Holding;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HoldingBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Holding> get serializer => _$HoldingSerializer();
}

class _$HoldingSerializer implements PrimitiveSerializer<Holding> {
  @override
  final Iterable<Type> types = const [Holding, _$Holding];

  @override
  final String wireName = r'Holding';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Holding object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'security_id';
    yield serializers.serialize(
      object.securityId,
      specifiedType: const FullType(String),
    );
    yield r'quantity';
    yield serializers.serialize(
      object.quantity,
      specifiedType: const FullType(String),
    );
    yield r'institution_price';
    yield serializers.serialize(
      object.institutionPrice,
      specifiedType: const FullType(String),
    );
    yield r'institution_price_as_of';
    yield object.institutionPriceAsOf == null
        ? null
        : serializers.serialize(
            object.institutionPriceAsOf,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'institution_value';
    yield serializers.serialize(
      object.institutionValue,
      specifiedType: const FullType(Money),
    );
    yield r'cost_basis';
    yield object.costBasis == null
        ? null
        : serializers.serialize(
            object.costBasis,
            specifiedType: const FullType.nullable(Money),
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
    Holding object, {
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
    required HoldingBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'account_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accountId = valueDes;
          break;
        case r'security_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.securityId = valueDes;
          break;
        case r'quantity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.quantity = valueDes;
          break;
        case r'institution_price':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.institutionPrice = valueDes;
          break;
        case r'institution_price_as_of':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.institutionPriceAsOf = valueDes;
          break;
        case r'institution_value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.institutionValue.replace(valueDes);
          break;
        case r'cost_basis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.costBasis.replace(valueDes);
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
  Holding deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HoldingBuilder();
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
