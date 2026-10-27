// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(Account.serializer)
          ..add(AccountType.serializer)
          ..add(Apr.serializer)
          ..add(AuthTokens.serializer)
          ..add(ChangeLogEntry.serializer)
          ..add(ChangeOperation.serializer)
          ..add(CreateSandboxTransactionsRequest.serializer)
          ..add(CreditLiability.serializer)
          ..add(DataSource.serializer)
          ..add(Device.serializer)
          ..add(EntityType.serializer)
          ..add(ExchangeRequest.serializer)
          ..add(FieldError.serializer)
          ..add(FireWebhookRequest.serializer)
          ..add(Health.serializer)
          ..add(HealthStatusEnum.serializer)
          ..add(Holding.serializer)
          ..add(HoldingsResponse.serializer)
          ..add(Institution.serializer)
          ..add(InvestmentTransaction.serializer)
          ..add(InvestmentTransactionPage.serializer)
          ..add(Item.serializer)
          ..add(ItemStatus.serializer)
          ..add(Liabilities.serializer)
          ..add(LinkToken.serializer)
          ..add(LinkTokenRequest.serializer)
          ..add(LoginRequest.serializer)
          ..add(Money.serializer)
          ..add(MortgageLiability.serializer)
          ..add(Problem.serializer)
          ..add(ProblemCode.serializer)
          ..add(ProvisionJob.serializer)
          ..add(ProvisionJobStatus.serializer)
          ..add(ProvisionPersona.serializer)
          ..add(ProvisionProgress.serializer)
          ..add(ProvisionRequest.serializer)
          ..add(PullPage.serializer)
          ..add(PulledChangeLogEntry.serializer)
          ..add(PushRejectionCode.serializer)
          ..add(PushRequest.serializer)
          ..add(PushResult.serializer)
          ..add(RecurringCadence.serializer)
          ..add(RecurringSource.serializer)
          ..add(RecurringStatus.serializer)
          ..add(RecurringStream.serializer)
          ..add(RefreshRequest.serializer)
          ..add(RegisterRequest.serializer)
          ..add(RejectedEntry.serializer)
          ..add(SandboxTransaction.serializer)
          ..add(Security.serializer)
          ..add(StudentLoanLiability.serializer)
          ..add(SyncRun.serializer)
          ..add(SyncRunStatus.serializer)
          ..add(Transaction.serializer)
          ..add(TransactionPage.serializer)
          ..add(TransactionSplit.serializer)
          ..add(UpdateLinkTokenRequest.serializer)
          ..add(User.serializer)
          ..add(ValidationProblem.serializer)
          ..add(ValidationProblemCodeEnum.serializer)
          ..add(ValidationProblemStatusEnum.serializer)
          ..add(WebhookCode.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Apr)]),
            () => ListBuilder<Apr>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ChangeLogEntry)]),
            () => ListBuilder<ChangeLogEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(CreditLiability)]),
            () => ListBuilder<CreditLiability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(MortgageLiability),
            ]),
            () => ListBuilder<MortgageLiability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(StudentLoanLiability),
            ]),
            () => ListBuilder<StudentLoanLiability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(FieldError)]),
            () => ListBuilder<FieldError>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Holding)]),
            () => ListBuilder<Holding>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Security)]),
            () => ListBuilder<Security>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(InvestmentTransaction),
            ]),
            () => ListBuilder<InvestmentTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(PulledChangeLogEntry),
            ]),
            () => ListBuilder<PulledChangeLogEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(SandboxTransaction),
            ]),
            () => ListBuilder<SandboxTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(RejectedEntry)]),
            () => ListBuilder<RejectedEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(TransactionSplit)]),
            () => ListBuilder<TransactionSplit>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Transaction)]),
            () => ListBuilder<Transaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType.nullable(JsonObject),
            ]),
            () => MapBuilder<String, JsonObject?>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType.nullable(JsonObject),
            ]),
            () => MapBuilder<String, JsonObject?>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
