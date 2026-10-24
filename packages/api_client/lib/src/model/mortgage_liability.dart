//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mortgage_liability.g.dart';

/// MortgageLiability
///
/// Properties:
/// * [accountId]
/// * [loanTypeDescription]
/// * [loanTerm]
/// * [interestRatePercentage] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [interestRateType] - Plaid's value, kept open (`fixed`, `variable`)
/// * [currentLateFee]
/// * [escrowBalance]
/// * [hasPmi]
/// * [hasPrepaymentPenalty]
/// * [lastPaymentAmount]
/// * [lastPaymentDate]
/// * [maturityDate]
/// * [nextMonthlyPayment]
/// * [nextPaymentDueDate]
/// * [originationDate]
/// * [originationPrincipalAmount]
/// * [pastDueAmount]
/// * [ytdInterestPaid]
/// * [ytdPrincipalPaid]
@BuiltValue()
abstract class MortgageLiability
    implements Built<MortgageLiability, MortgageLiabilityBuilder> {
  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'loan_type_description')
  String? get loanTypeDescription;

  @BuiltValueField(wireName: r'loan_term')
  String? get loanTerm;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'interest_rate_percentage')
  String? get interestRatePercentage;

  /// Plaid's value, kept open (`fixed`, `variable`)
  @BuiltValueField(wireName: r'interest_rate_type')
  String? get interestRateType;

  @BuiltValueField(wireName: r'current_late_fee')
  Money? get currentLateFee;

  @BuiltValueField(wireName: r'escrow_balance')
  Money? get escrowBalance;

  @BuiltValueField(wireName: r'has_pmi')
  bool? get hasPmi;

  @BuiltValueField(wireName: r'has_prepayment_penalty')
  bool? get hasPrepaymentPenalty;

  @BuiltValueField(wireName: r'last_payment_amount')
  Money? get lastPaymentAmount;

  @BuiltValueField(wireName: r'last_payment_date')
  Date? get lastPaymentDate;

  @BuiltValueField(wireName: r'maturity_date')
  Date? get maturityDate;

  @BuiltValueField(wireName: r'next_monthly_payment')
  Money? get nextMonthlyPayment;

  @BuiltValueField(wireName: r'next_payment_due_date')
  Date? get nextPaymentDueDate;

  @BuiltValueField(wireName: r'origination_date')
  Date? get originationDate;

  @BuiltValueField(wireName: r'origination_principal_amount')
  Money? get originationPrincipalAmount;

  @BuiltValueField(wireName: r'past_due_amount')
  Money? get pastDueAmount;

  @BuiltValueField(wireName: r'ytd_interest_paid')
  Money? get ytdInterestPaid;

  @BuiltValueField(wireName: r'ytd_principal_paid')
  Money? get ytdPrincipalPaid;

  MortgageLiability._();

  factory MortgageLiability([void updates(MortgageLiabilityBuilder b)]) =
      _$MortgageLiability;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MortgageLiabilityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MortgageLiability> get serializer =>
      _$MortgageLiabilitySerializer();
}

class _$MortgageLiabilitySerializer
    implements PrimitiveSerializer<MortgageLiability> {
  @override
  final Iterable<Type> types = const [MortgageLiability, _$MortgageLiability];

  @override
  final String wireName = r'MortgageLiability';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MortgageLiability object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'loan_type_description';
    yield object.loanTypeDescription == null
        ? null
        : serializers.serialize(
            object.loanTypeDescription,
            specifiedType: const FullType.nullable(String),
          );
    yield r'loan_term';
    yield object.loanTerm == null
        ? null
        : serializers.serialize(
            object.loanTerm,
            specifiedType: const FullType.nullable(String),
          );
    yield r'interest_rate_percentage';
    yield object.interestRatePercentage == null
        ? null
        : serializers.serialize(
            object.interestRatePercentage,
            specifiedType: const FullType.nullable(String),
          );
    yield r'interest_rate_type';
    yield object.interestRateType == null
        ? null
        : serializers.serialize(
            object.interestRateType,
            specifiedType: const FullType.nullable(String),
          );
    yield r'current_late_fee';
    yield object.currentLateFee == null
        ? null
        : serializers.serialize(
            object.currentLateFee,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'escrow_balance';
    yield object.escrowBalance == null
        ? null
        : serializers.serialize(
            object.escrowBalance,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'has_pmi';
    yield object.hasPmi == null
        ? null
        : serializers.serialize(
            object.hasPmi,
            specifiedType: const FullType.nullable(bool),
          );
    yield r'has_prepayment_penalty';
    yield object.hasPrepaymentPenalty == null
        ? null
        : serializers.serialize(
            object.hasPrepaymentPenalty,
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
    yield r'maturity_date';
    yield object.maturityDate == null
        ? null
        : serializers.serialize(
            object.maturityDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'next_monthly_payment';
    yield object.nextMonthlyPayment == null
        ? null
        : serializers.serialize(
            object.nextMonthlyPayment,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'next_payment_due_date';
    yield object.nextPaymentDueDate == null
        ? null
        : serializers.serialize(
            object.nextPaymentDueDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'origination_date';
    yield object.originationDate == null
        ? null
        : serializers.serialize(
            object.originationDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'origination_principal_amount';
    yield object.originationPrincipalAmount == null
        ? null
        : serializers.serialize(
            object.originationPrincipalAmount,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'past_due_amount';
    yield object.pastDueAmount == null
        ? null
        : serializers.serialize(
            object.pastDueAmount,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'ytd_interest_paid';
    yield object.ytdInterestPaid == null
        ? null
        : serializers.serialize(
            object.ytdInterestPaid,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'ytd_principal_paid';
    yield object.ytdPrincipalPaid == null
        ? null
        : serializers.serialize(
            object.ytdPrincipalPaid,
            specifiedType: const FullType.nullable(Money),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    MortgageLiability object, {
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
    required MortgageLiabilityBuilder result,
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
        case r'loan_type_description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.loanTypeDescription = valueDes;
          break;
        case r'loan_term':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.loanTerm = valueDes;
          break;
        case r'interest_rate_percentage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.interestRatePercentage = valueDes;
          break;
        case r'interest_rate_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.interestRateType = valueDes;
          break;
        case r'current_late_fee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.currentLateFee.replace(valueDes);
          break;
        case r'escrow_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.escrowBalance.replace(valueDes);
          break;
        case r'has_pmi':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.hasPmi = valueDes;
          break;
        case r'has_prepayment_penalty':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.hasPrepaymentPenalty = valueDes;
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
        case r'maturity_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.maturityDate = valueDes;
          break;
        case r'next_monthly_payment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.nextMonthlyPayment.replace(valueDes);
          break;
        case r'next_payment_due_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.nextPaymentDueDate = valueDes;
          break;
        case r'origination_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.originationDate = valueDes;
          break;
        case r'origination_principal_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.originationPrincipalAmount.replace(valueDes);
          break;
        case r'past_due_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.pastDueAmount.replace(valueDes);
          break;
        case r'ytd_interest_paid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.ytdInterestPaid.replace(valueDes);
          break;
        case r'ytd_principal_paid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.ytdPrincipalPaid.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MortgageLiability deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MortgageLiabilityBuilder();
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
