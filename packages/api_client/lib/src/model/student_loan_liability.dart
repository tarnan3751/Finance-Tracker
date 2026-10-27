//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/data_source.dart';
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'student_loan_liability.g.dart';

/// StudentLoanLiability
///
/// Properties:
/// * [accountId]
/// * [source_]
/// * [loanName]
/// * [guarantor]
/// * [interestRatePercentage] - An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
/// * [isOverdue]
/// * [expectedPayoffDate]
/// * [lastPaymentAmount]
/// * [lastPaymentDate]
/// * [lastStatementBalance]
/// * [lastStatementIssueDate]
/// * [minimumPaymentAmount]
/// * [nextPaymentDueDate]
/// * [originationDate]
/// * [originationPrincipalAmount]
/// * [outstandingInterestAmount]
/// * [loanStatusType] - Plaid's loan status type, kept open (`repayment`, `deferment`, ...)
/// * [repaymentPlanType] - Plaid's repayment plan type, kept open (`standard`, `income-based`, ...)
/// * [ytdInterestPaid]
/// * [ytdPrincipalPaid]
@BuiltValue()
abstract class StudentLoanLiability
    implements Built<StudentLoanLiability, StudentLoanLiabilityBuilder> {
  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'source')
  DataSource get source_;
  // enum source_Enum {  plaid,  manual,  import,  derived,  demo,  };

  @BuiltValueField(wireName: r'loan_name')
  String? get loanName;

  @BuiltValueField(wireName: r'guarantor')
  String? get guarantor;

  /// An exact decimal number as a string, for per-unit prices, share quantities and rates, which need more precision than minor units. Never an amount of money: totals are `Money`.
  @BuiltValueField(wireName: r'interest_rate_percentage')
  String get interestRatePercentage;

  @BuiltValueField(wireName: r'is_overdue')
  bool? get isOverdue;

  @BuiltValueField(wireName: r'expected_payoff_date')
  Date? get expectedPayoffDate;

  @BuiltValueField(wireName: r'last_payment_amount')
  Money? get lastPaymentAmount;

  @BuiltValueField(wireName: r'last_payment_date')
  Date? get lastPaymentDate;

  @BuiltValueField(wireName: r'last_statement_balance')
  Money? get lastStatementBalance;

  @BuiltValueField(wireName: r'last_statement_issue_date')
  Date? get lastStatementIssueDate;

  @BuiltValueField(wireName: r'minimum_payment_amount')
  Money? get minimumPaymentAmount;

  @BuiltValueField(wireName: r'next_payment_due_date')
  Date? get nextPaymentDueDate;

  @BuiltValueField(wireName: r'origination_date')
  Date? get originationDate;

  @BuiltValueField(wireName: r'origination_principal_amount')
  Money? get originationPrincipalAmount;

  @BuiltValueField(wireName: r'outstanding_interest_amount')
  Money? get outstandingInterestAmount;

  /// Plaid's loan status type, kept open (`repayment`, `deferment`, ...)
  @BuiltValueField(wireName: r'loan_status_type')
  String? get loanStatusType;

  /// Plaid's repayment plan type, kept open (`standard`, `income-based`, ...)
  @BuiltValueField(wireName: r'repayment_plan_type')
  String? get repaymentPlanType;

  @BuiltValueField(wireName: r'ytd_interest_paid')
  Money? get ytdInterestPaid;

  @BuiltValueField(wireName: r'ytd_principal_paid')
  Money? get ytdPrincipalPaid;

  StudentLoanLiability._();

  factory StudentLoanLiability([void updates(StudentLoanLiabilityBuilder b)]) =
      _$StudentLoanLiability;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StudentLoanLiabilityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StudentLoanLiability> get serializer =>
      _$StudentLoanLiabilitySerializer();
}

class _$StudentLoanLiabilitySerializer
    implements PrimitiveSerializer<StudentLoanLiability> {
  @override
  final Iterable<Type> types = const [
    StudentLoanLiability,
    _$StudentLoanLiability,
  ];

  @override
  final String wireName = r'StudentLoanLiability';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StudentLoanLiability object, {
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
    yield r'loan_name';
    yield object.loanName == null
        ? null
        : serializers.serialize(
            object.loanName,
            specifiedType: const FullType.nullable(String),
          );
    yield r'guarantor';
    yield object.guarantor == null
        ? null
        : serializers.serialize(
            object.guarantor,
            specifiedType: const FullType.nullable(String),
          );
    yield r'interest_rate_percentage';
    yield serializers.serialize(
      object.interestRatePercentage,
      specifiedType: const FullType(String),
    );
    yield r'is_overdue';
    yield object.isOverdue == null
        ? null
        : serializers.serialize(
            object.isOverdue,
            specifiedType: const FullType.nullable(bool),
          );
    yield r'expected_payoff_date';
    yield object.expectedPayoffDate == null
        ? null
        : serializers.serialize(
            object.expectedPayoffDate,
            specifiedType: const FullType.nullable(Date),
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
    yield r'last_statement_balance';
    yield object.lastStatementBalance == null
        ? null
        : serializers.serialize(
            object.lastStatementBalance,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'last_statement_issue_date';
    yield object.lastStatementIssueDate == null
        ? null
        : serializers.serialize(
            object.lastStatementIssueDate,
            specifiedType: const FullType.nullable(Date),
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
    yield r'outstanding_interest_amount';
    yield object.outstandingInterestAmount == null
        ? null
        : serializers.serialize(
            object.outstandingInterestAmount,
            specifiedType: const FullType.nullable(Money),
          );
    yield r'loan_status_type';
    yield object.loanStatusType == null
        ? null
        : serializers.serialize(
            object.loanStatusType,
            specifiedType: const FullType.nullable(String),
          );
    yield r'repayment_plan_type';
    yield object.repaymentPlanType == null
        ? null
        : serializers.serialize(
            object.repaymentPlanType,
            specifiedType: const FullType.nullable(String),
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
    StudentLoanLiability object, {
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
    required StudentLoanLiabilityBuilder result,
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
        case r'loan_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.loanName = valueDes;
          break;
        case r'guarantor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.guarantor = valueDes;
          break;
        case r'interest_rate_percentage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.interestRatePercentage = valueDes;
          break;
        case r'is_overdue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.isOverdue = valueDes;
          break;
        case r'expected_payoff_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.expectedPayoffDate = valueDes;
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
        case r'last_statement_balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.lastStatementBalance.replace(valueDes);
          break;
        case r'last_statement_issue_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.lastStatementIssueDate = valueDes;
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
        case r'outstanding_interest_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Money),
          ) as Money?;
          if (valueDes == null) continue;
          result.outstandingInterestAmount.replace(valueDes);
          break;
        case r'loan_status_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.loanStatusType = valueDes;
          break;
        case r'repayment_plan_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repaymentPlanType = valueDes;
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
  StudentLoanLiability deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StudentLoanLiabilityBuilder();
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
