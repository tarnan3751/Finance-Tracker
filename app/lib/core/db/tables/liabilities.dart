/// The `liabilities` table: the liability detail of the user's linked card and loan
/// accounts, schema 9 (`docs/reference/liabilities.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// One row per account and kind, as the server last listed them: server-authoritative,
/// replaced whole by each Plaid pull, never recorded. Every amount is a `*_minor` in the
/// row's `currency` (null when the row has no amount at all); rates are basis points;
/// `aprs` is a JSON array of `{apr_type, percentage_basis_points,
/// balance_subject_to_apr}`; `payload` is the server's object as it came, the exact rate
/// strings included. No foreign key to `accounts`.
@DataClassName('LiabilityRow')
class Liabilities extends Table {
  TextColumn get accountId => text()();
  TextColumn get kind => textEnum<LiabilityKind>()();
  TextColumn get currency => text().nullable()();
  TextColumn get nextPaymentDueDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  IntColumn get minimumPaymentMinor => integer().nullable()();
  IntColumn get lastStatementBalanceMinor => integer().nullable()();
  TextColumn get lastStatementIssueDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  IntColumn get lastPaymentMinor => integer().nullable()();
  TextColumn get lastPaymentDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  BoolColumn get isOverdue => boolean().nullable()();
  TextColumn get aprs => text()();
  IntColumn get interestRateBp => integer().nullable()();
  TextColumn get originationDate =>
      text().map(const LocalDateColumnConverter()).nullable()();
  IntColumn get originationPrincipalMinor => integer().nullable()();
  TextColumn get loanTerm => text().nullable()();
  IntColumn get nextMonthlyPaymentMinor => integer().nullable()();
  IntColumn get ytdInterestPaidMinor => integer().nullable()();
  IntColumn get ytdPrincipalPaidMinor => integer().nullable()();
  TextColumn get payload => text()();
  TextColumn get source => textEnum<DataSource>()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {accountId, kind};

  @override
  List<String> get customConstraints => const [
    "CHECK (kind IN ('credit', 'mortgage', 'student'))",
    "CHECK (source IN ('plaid', 'demo'))",
  ];
}
