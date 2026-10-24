//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'apr.g.dart';

/// Apr
///
/// Properties:
/// * [aprPercentage] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [aprType] - Plaid's value, kept open (`balance_transfer_apr`, `cash_apr`, `purchase_apr`, `special`)
/// * [balanceSubjectToApr]
/// * [interestChargeAmount]
@BuiltValue()
abstract class Apr implements Built<Apr, AprBuilder> {
  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'apr_percentage')
  String get aprPercentage;

  /// Plaid's value, kept open (`balance_transfer_apr`, `cash_apr`, `purchase_apr`, `special`)
  @BuiltValueField(wireName: r'apr_type')
  String get aprType;

  @BuiltValueField(wireName: r'balance_subject_to_apr')
  Money? get balanceSubjectToApr;

  @BuiltValueField(wireName: r'interest_charge_amount')
  Money? get interestChargeAmount;

  Apr._();

  factory Apr([void updates(AprBuilder b)]) = _$Apr;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AprBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Apr> get serializer => _$AprSerializer();
}

class _$AprSerializer implements PrimitiveSerializer<Apr> {
  @override
  final Iterable<Type> types = const [Apr, _$Apr];

  @override
  final String wireName = r'Apr';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Apr object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'apr_percentage';
    yield serializers.serialize(
      object.aprPercentage,
      specifiedType: const FullType(String),
    );
    yield r'apr_type';
    yield serializers.serialize(
      object.aprType,
      specifiedType: const FullType(String),
    );
    yield r'balance_subject_to_apr';
    yield object.balanceSubjectToApr == null
        ? null
        : serializers.serialize(
            object.balanceSubjectToApr,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'interest_charge_amount';
    yield object.interestChargeAmount == null
        ? null
        : serializers.serialize(
            object.interestChargeAmount,
            specifiedType: const FullType.nullable(Money),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    Apr object, {
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
    required AprBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'apr_percentage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.aprPercentage = valueDes;
          break;
        case r'apr_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.aprType = valueDes;
          break;
        case r'balance_subject_to_apr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.balanceSubjectToApr.replace(valueDes);
          break;
        case r'interest_charge_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.interestChargeAmount.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Apr deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AprBuilder();
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
