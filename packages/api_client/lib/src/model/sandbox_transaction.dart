//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sandbox_transaction.g.dart';

/// A transaction to inject. `amount` is in Plaid's convention, the opposite of this API's: positive is money out of the account. Without `account_id`, Plaid picks the Item's checking account.
///
/// Properties:
/// * [dateTransacted]
/// * [datePosted]
/// * [amount]
/// * [description]
/// * [accountId] - One of the Item's accounts (this API's account id)
@BuiltValue()
abstract class SandboxTransaction
    implements Built<SandboxTransaction, SandboxTransactionBuilder> {
  @BuiltValueField(wireName: r'date_transacted')
  Date get dateTransacted;

  @BuiltValueField(wireName: r'date_posted')
  Date get datePosted;

  @BuiltValueField(wireName: r'amount')
  Money get amount;

  @BuiltValueField(wireName: r'description')
  String get description;

  /// One of the Item's accounts (this API's account id)
  @BuiltValueField(wireName: r'account_id')
  String? get accountId;

  SandboxTransaction._();

  factory SandboxTransaction([void updates(SandboxTransactionBuilder b)]) =
      _$SandboxTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SandboxTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SandboxTransaction> get serializer =>
      _$SandboxTransactionSerializer();
}

class _$SandboxTransactionSerializer
    implements PrimitiveSerializer<SandboxTransaction> {
  @override
  final Iterable<Type> types = const [SandboxTransaction, _$SandboxTransaction];

  @override
  final String wireName = r'SandboxTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SandboxTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'date_transacted';
    yield serializers.serialize(
      object.dateTransacted,
      specifiedType: const FullType(Date),
    );
    yield r'date_posted';
    yield serializers.serialize(
      object.datePosted,
      specifiedType: const FullType(Date),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(Money),
    );
    yield r'description';
    yield serializers.serialize(
      object.description,
      specifiedType: const FullType(String),
    );
    if (object.accountId != null) {
      yield r'account_id';
      yield serializers.serialize(
        object.accountId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SandboxTransaction object, {
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
    required SandboxTransactionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'date_transacted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.dateTransacted = valueDes;
          break;
        case r'date_posted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.datePosted = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.amount.replace(valueDes);
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'account_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.accountId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SandboxTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SandboxTransactionBuilder();
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
