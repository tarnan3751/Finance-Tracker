//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/account_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'account.g.dart';

/// Mirrors `shared_models` `Account`. The balances are the institution's reported figures as of `balances_as_of`, null when not reported.
///
/// Properties:
/// * [id]
/// * [itemId]
/// * [type]
/// * [subtype] - Plaid's subtype, kept open
/// * [name]
/// * [officialName]
/// * [mask]
/// * [currencyCode]
/// * [currentBalance]
/// * [availableBalance]
/// * [creditLimit]
/// * [balancesAsOf]
/// * [isHidden]
/// * [displayOrder]
@BuiltValue()
abstract class Account implements Built<Account, AccountBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'item_id')
  String? get itemId;

  @BuiltValueField(wireName: r'type')
  AccountType get type;
  // enum typeEnum {  depository,  credit,  loan,  investment,  other,  };

  /// Plaid's subtype, kept open
  @BuiltValueField(wireName: r'subtype')
  String? get subtype;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'official_name')
  String? get officialName;

  @BuiltValueField(wireName: r'mask')
  String? get mask;

  @BuiltValueField(wireName: r'currency_code')
  String get currencyCode;

  @BuiltValueField(wireName: r'current_balance')
  Money? get currentBalance;

  @BuiltValueField(wireName: r'available_balance')
  Money? get availableBalance;

  @BuiltValueField(wireName: r'credit_limit')
  Money? get creditLimit;

  @BuiltValueField(wireName: r'balances_as_of')
  DateTime? get balancesAsOf;

  @BuiltValueField(wireName: r'is_hidden')
  bool get isHidden;

  @BuiltValueField(wireName: r'display_order')
  int get displayOrder;

  Account._();

  factory Account([void updates(AccountBuilder b)]) = _$Account;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AccountBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Account> get serializer => _$AccountSerializer();
}

class _$AccountSerializer implements PrimitiveSerializer<Account> {
  @override
  final Iterable<Type> types = const [Account, _$Account];

  @override
  final String wireName = r'Account';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Account object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'item_id';
    yield object.itemId == null
        ? null
        : serializers.serialize(
            object.itemId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(AccountType),
    );
    yield r'subtype';
    yield object.subtype == null
        ? null
        : serializers.serialize(
            object.subtype,
            specifiedType: const FullType.nullable(String),
          );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'official_name';
    yield object.officialName == null
        ? null
        : serializers.serialize(
            object.officialName,
            specifiedType: const FullType.nullable(String),
          );
    yield r'mask';
    yield object.mask == null
        ? null
        : serializers.serialize(
            object.mask,
            specifiedType: const FullType.nullable(String),
          );
    yield r'currency_code';
    yield serializers.serialize(
      object.currencyCode,
      specifiedType: const FullType(String),
    );
    yield r'current_balance';
    yield object.currentBalance == null
        ? null
        : serializers.serialize(
            object.currentBalance,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'available_balance';
    yield object.availableBalance == null
        ? null
        : serializers.serialize(
            object.availableBalance,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'credit_limit';
    yield object.creditLimit == null
        ? null
        : serializers.serialize(
            object.creditLimit,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'balances_as_of';
    yield object.balancesAsOf == null
        ? null
        : serializers.serialize(
            object.balancesAsOf,
            specifiedType: const FullType.nullable(DateTime),
          );
    yield r'is_hidden';
    yield serializers.serialize(
      object.isHidden,
      specifiedType: const FullType(bool),
    );
    yield r'display_order';
    yield serializers.serialize(
      object.displayOrder,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Account object, {
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
    required AccountBuilder result,
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
        case r'item_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.itemId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AccountType),
          ) as AccountType;
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'official_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.officialName = valueDes;
          break;
        case r'mask':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.mask = valueDes;
          break;
        case r'currency_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currencyCode = valueDes;
          break;
        case r'current_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.currentBalance.replace(valueDes);
          break;
        case r'available_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.availableBalance.replace(valueDes);
          break;
        case r'credit_limit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.creditLimit.replace(valueDes);
          break;
        case r'balances_as_of':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.balancesAsOf = valueDes;
          break;
        case r'is_hidden':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isHidden = valueDes;
          break;
        case r'display_order':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.displayOrder = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Account deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AccountBuilder();
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
