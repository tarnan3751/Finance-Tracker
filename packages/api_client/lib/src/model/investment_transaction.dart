//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'investment_transaction.g.dart';

/// A buy, sell, dividend, fee or transfer in an investment account. `amount` follows our sign (negative is an outflow from the account); `quantity` and `price` are `Decimal`. `deleted_at` is the tombstone.
///
/// Properties:
/// * [id]
/// * [accountId]
/// * [securityId]
/// * [date]
/// * [name]
/// * [type] - Plaid's type, kept open (`buy`, `sell`, `cancel`, `cash`, `fee`, `transfer`)
/// * [subtype]
/// * [quantity] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [price] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [amount]
/// * [fees]
/// * [deletedAt]
/// * [syncVersion]
@BuiltValue()
abstract class InvestmentTransaction
    implements Built<InvestmentTransaction, InvestmentTransactionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'security_id')
  String? get securityId;

  @BuiltValueField(wireName: r'date')
  Date get date;

  @BuiltValueField(wireName: r'name')
  String get name;

  /// Plaid's type, kept open (`buy`, `sell`, `cancel`, `cash`, `fee`, `transfer`)
  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'subtype')
  String? get subtype;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'quantity')
  String get quantity;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'price')
  String get price;

  @BuiltValueField(wireName: r'amount')
  Money get amount;

  @BuiltValueField(wireName: r'fees')
  Money? get fees;

  @BuiltValueField(wireName: r'deleted_at')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'sync_version')
  int get syncVersion;

  InvestmentTransaction._();

  factory InvestmentTransaction([
    void updates(InvestmentTransactionBuilder b),
  ]) = _$InvestmentTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InvestmentTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InvestmentTransaction> get serializer =>
      _$InvestmentTransactionSerializer();
}

class _$InvestmentTransactionSerializer
    implements PrimitiveSerializer<InvestmentTransaction> {
  @override
  final Iterable<Type> types = const [
    InvestmentTransaction,
    _$InvestmentTransaction,
  ];

  @override
  final String wireName = r'InvestmentTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InvestmentTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'security_id';
    yield object.securityId == null
        ? null
        : serializers.serialize(
            object.securityId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'date';
    yield serializers.serialize(
      object.date,
      specifiedType: const FullType(Date),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'subtype';
    yield object.subtype == null
        ? null
        : serializers.serialize(
            object.subtype,
            specifiedType: const FullType.nullable(String),
          );
    yield r'quantity';
    yield serializers.serialize(
      object.quantity,
      specifiedType: const FullType(String),
    );
    yield r'price';
    yield serializers.serialize(
      object.price,
      specifiedType: const FullType(String),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(Money),
    );
    yield r'fees';
    yield object.fees == null
        ? null
        : serializers.serialize(
            object.fees,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'deleted_at';
    yield object.deletedAt == null
        ? null
        : serializers.serialize(
            object.deletedAt,
            specifiedType: const FullType.nullable(DateTime),
          );
    yield r'sync_version';
    yield serializers.serialize(
      object.syncVersion,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    InvestmentTransaction object, {
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
    required InvestmentTransactionBuilder result,
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
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.securityId = valueDes;
          break;
        case r'date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.date = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'subtype':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.subtype = valueDes;
          break;
        case r'quantity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.quantity = valueDes;
          break;
        case r'price':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.price = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.amount.replace(valueDes);
          break;
        case r'fees':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.fees.replace(valueDes);
          break;
        case r'deleted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.deletedAt = valueDes;
          break;
        case r'sync_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.syncVersion = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  InvestmentTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InvestmentTransactionBuilder();
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
