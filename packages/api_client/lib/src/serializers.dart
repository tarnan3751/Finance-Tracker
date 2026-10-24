//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:api_client/src/date_serializer.dart';
import 'package:api_client/src/model/date.dart';

import 'package:api_client/src/model/account.dart';
import 'package:api_client/src/model/account_type.dart';
import 'package:api_client/src/model/apr.dart';
import 'package:api_client/src/model/auth_tokens.dart';
import 'package:api_client/src/model/change_log_entry.dart';
import 'package:api_client/src/model/change_operation.dart';
import 'package:api_client/src/model/create_sandbox_transactions_request.dart';
import 'package:api_client/src/model/credit_liability.dart';
import 'package:api_client/src/model/data_source.dart';
import 'package:api_client/src/model/device.dart';
import 'package:api_client/src/model/entity_type.dart';
import 'package:api_client/src/model/exchange_request.dart';
import 'package:api_client/src/model/field_error.dart';
import 'package:api_client/src/model/fire_webhook_request.dart';
import 'package:api_client/src/model/health.dart';
import 'package:api_client/src/model/holding.dart';
import 'package:api_client/src/model/holdings_response.dart';
import 'package:api_client/src/model/institution.dart';
import 'package:api_client/src/model/investment_transaction.dart';
import 'package:api_client/src/model/investment_transaction_page.dart';
import 'package:api_client/src/model/item.dart';
import 'package:api_client/src/model/item_status.dart';
import 'package:api_client/src/model/liabilities.dart';
import 'package:api_client/src/model/link_token.dart';
import 'package:api_client/src/model/link_token_request.dart';
import 'package:api_client/src/model/login_request.dart';
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/mortgage_liability.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/problem_code.dart';
import 'package:api_client/src/model/pull_page.dart';
import 'package:api_client/src/model/pulled_change_log_entry.dart';
import 'package:api_client/src/model/push_rejection_code.dart';
import 'package:api_client/src/model/push_request.dart';
import 'package:api_client/src/model/push_result.dart';
import 'package:api_client/src/model/recurring_cadence.dart';
import 'package:api_client/src/model/recurring_source.dart';
import 'package:api_client/src/model/recurring_status.dart';
import 'package:api_client/src/model/recurring_stream.dart';
import 'package:api_client/src/model/refresh_request.dart';
import 'package:api_client/src/model/register_request.dart';
import 'package:api_client/src/model/rejected_entry.dart';
import 'package:api_client/src/model/sandbox_transaction.dart';
import 'package:api_client/src/model/security.dart';
import 'package:api_client/src/model/student_loan_liability.dart';
import 'package:api_client/src/model/sync_run.dart';
import 'package:api_client/src/model/sync_run_status.dart';
import 'package:api_client/src/model/transaction.dart';
import 'package:api_client/src/model/transaction_page.dart';
import 'package:api_client/src/model/transaction_split.dart';
import 'package:api_client/src/model/update_link_token_request.dart';
import 'package:api_client/src/model/user.dart';
import 'package:api_client/src/model/validation_problem.dart';
import 'package:api_client/src/model/webhook_code.dart';

part 'serializers.g.dart';

@SerializersFor([
  Account,
  AccountType,
  Apr,
  AuthTokens,
  ChangeLogEntry,
  ChangeOperation,
  CreateSandboxTransactionsRequest,
  CreditLiability,
  DataSource,
  Device,
  EntityType,
  ExchangeRequest,
  FieldError,
  FireWebhookRequest,
  Health,
  Holding,
  HoldingsResponse,
  Institution,
  InvestmentTransaction,
  InvestmentTransactionPage,
  Item,
  ItemStatus,
  Liabilities,
  LinkToken,
  LinkTokenRequest,
  LoginRequest,
  Money,
  MortgageLiability,
  Problem,
  ProblemCode,
  PullPage,
  PulledChangeLogEntry,
  PushRejectionCode,
  PushRequest,
  PushResult,
  RecurringCadence,
  RecurringSource,
  RecurringStatus,
  RecurringStream,
  RefreshRequest,
  RegisterRequest,
  RejectedEntry,
  SandboxTransaction,
  Security,
  StudentLoanLiability,
  SyncRun,
  SyncRunStatus,
  Transaction,
  TransactionPage,
  TransactionSplit,
  UpdateLinkTokenRequest,
  User,
  ValidationProblem,
  WebhookCode,
])
Serializers serializers =
    (_$serializers.toBuilder()
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(SandboxTransaction)]),
            () => ListBuilder<SandboxTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(MortgageLiability)]),
            () => ListBuilder<MortgageLiability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Apr)]),
            () => ListBuilder<Apr>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(InvestmentTransaction)]),
            () => ListBuilder<InvestmentTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(ChangeLogEntry)]),
            () => ListBuilder<ChangeLogEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Device)]),
            () => ListBuilder<Device>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(FieldError)]),
            () => ListBuilder<FieldError>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(PulledChangeLogEntry)]),
            () => ListBuilder<PulledChangeLogEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(RecurringStream)]),
            () => ListBuilder<RecurringStream>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Account)]),
            () => ListBuilder<Account>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Transaction)]),
            () => ListBuilder<Transaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Security)]),
            () => ListBuilder<Security>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Item)]),
            () => ListBuilder<Item>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Holding)]),
            () => ListBuilder<Holding>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(TransactionSplit)]),
            () => ListBuilder<TransactionSplit>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, [
              FullType(String),
              FullType.nullable(JsonObject),
            ]),
            () => MapBuilder<String, JsonObject?>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(CreditLiability)]),
            () => ListBuilder<CreditLiability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(RejectedEntry)]),
            () => ListBuilder<RejectedEntry>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(StudentLoanLiability)]),
            () => ListBuilder<StudentLoanLiability>(),
          )
          ..add(const OneOfSerializer())
          ..add(const AnyOfSerializer())
          ..add(const DateSerializer())
          ..add(Iso8601DateTimeSerializer()))
        .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
