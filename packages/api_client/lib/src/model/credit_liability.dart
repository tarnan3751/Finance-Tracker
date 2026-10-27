//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/data_source.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/apr.dart';
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'credit_liability.g.dart';

/// CreditLiability
///
/// Properties:
/// * [accountId]
/// * [source_]
/// * [aprs]
/// * [isOverdue]
/// * [lastPaymentAmount]
/// * [lastPaymentDate]
/// * [lastStatementIssueDate]
/// * [lastStatementBalance]
/// * [minimumPaymentAmount]
/// * [nextPaymentDueDate]
@BuiltValue()
abstract class CreditLiability
    implements Built<CreditLiability, CreditLiabilityBuilder> {
  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'source')
  DataSource get source_;
  // enum source_Enum {  plaid,  manual,  import,  derived,  demo,  };

  @BuiltValueField(wireName: r'aprs')
  BuiltList<Apr> get aprs;

  @BuiltValueField(wireName: r'is_overdue')
  bool? get isOverdue;

  @BuiltValueField(wireName: r'last_payment_amount')
  Money? get lastPaymentAmount;

  @BuiltValueField(wireName: r'last_payment_date')
  Date? get lastPaymentDate;

  @BuiltValueField(wireName: r'last_statement_issue_date')
  Date? get lastStatementIssueDate;

  @BuiltValueField(wireName: r'last_statement_balance')
  Money? get lastStatementBalance;

  @BuiltValueField(wireName: r'minimum_payment_amount')
  Money? get minimumPaymentAmount;

  @BuiltValueField(wireName: r'next_payment_due_date')
  Date? get nextPaymentDueDate;

  CreditLiability._();

  factory CreditLiability([void updates(CreditLiabilityBuilder b)]) =
      _$CreditLiability;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreditLiabilityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreditLiability> get serializer =>
      _$CreditLiabilitySerializer();
}

class _$CreditLiabilitySerializer
    implements PrimitiveSerializer<CreditLiability> {
  @override
  final Iterable<Type> types = const [CreditLiability, _$CreditLiability];

  @override
  final String wireName = r'CreditLiability';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreditLiability object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(DataSource),
    );
    yield r'aprs';
    yield serializers.serialize(
      object.aprs,
      specifiedType: const FullType(BuiltList, [FullType(Apr)]),
    );
    yield r'is_overdue';
    yield object.isOverdue == null
        ? null
        : serializers.serialize(
            object.isOverdue,
            specifiedType: const FullType.nullable(bool),
          );
    yield r'last_payment_amount';
    yield object.lastPaymentAmount == null
        ? null
        : serializers.serialize(
            object.lastPaymentAmount,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'last_payment_date';
    yield object.lastPaymentDate == null
        ? null
        : serializers.serialize(
            object.lastPaymentDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'last_statement_issue_date';
    yield object.lastStatementIssueDate == null
        ? null
        : serializers.serialize(
            object.lastStatementIssueDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'last_statement_balance';
    yield object.lastStatementBalance == null
        ? null
        : serializers.serialize(
            object.lastStatementBalance,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'minimum_payment_amount';
    yield object.minimumPaymentAmount == null
        ? null
        : serializers.serialize(
            object.minimumPaymentAmount,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'next_payment_due_date';
    yield object.nextPaymentDueDate == null
        ? null
        : serializers.serialize(
            object.nextPaymentDueDate,
            specifiedType: const FullType.nullable(Date),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreditLiability object, {
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
    required CreditLiabilityBuilder result,
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
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DataSource),
          ) as DataSource;
          result.source_ = valueDes;
          break;
        case r'aprs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Apr)]),
          ) as BuiltList<Apr>;
          result.aprs.replace(valueDes);
          break;
        case r'is_overdue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.isOverdue = valueDes;
          break;
        case r'last_payment_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.lastPaymentAmount.replace(valueDes);
          break;
        case r'last_payment_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.lastPaymentDate = valueDes;
          break;
        case r'last_statement_issue_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.lastStatementIssueDate = valueDes;
          break;
        case r'last_statement_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.lastStatementBalance.replace(valueDes);
          break;
        case r'minimum_payment_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.minimumPaymentAmount.replace(valueDes);
          break;
        case r'next_payment_due_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.nextPaymentDueDate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreditLiability deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreditLiabilityBuilder();
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
