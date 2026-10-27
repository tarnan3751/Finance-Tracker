/// The enumerations of the domain model (`PLAN.md` §6.2).
///
/// Every enum serializes as its snake_case name. The ones that mirror a Plaid value set
/// ([AccountType], [ItemStatus], [RecurringCadence]) have a fallback the model fields
/// declare with `unknownEnumValue`, so a value Plaid adds later never throws at the
/// boundary.
library;

import 'package:json_annotation/json_annotation.dart';

/// The kind of an account; Plaid's `type`, and chosen by the user for a manual account.
/// An unrecognized Plaid type reads as [other].
@JsonEnum(fieldRename: FieldRename.snake)
enum AccountType { depository, credit, loan, investment, other }

/// The health of a Plaid Item; [removed] is an Item unlinked with its history kept.
@JsonEnum(fieldRename: FieldRename.snake)
enum ItemStatus {
  healthy,
  loginRequired,
  error,
  pendingExpiration,
  removed,
  unknown,
}

/// Where a transaction or a snapshot came from (`PLAN.md` §7.1). `derived` values are
/// reconstructed rather than reported and are labelled so in the UI; `demo` values exist
/// only in the demo flavor.
@JsonEnum(fieldRename: FieldRename.snake)
enum DataSource { plaid, manual, import, derived, demo }

/// Who found a recurring stream: Plaid, the app's own detector, or the user; [demo] for a
/// stream from the demo flavor or the dev server's fake Plaid client, which never wears
/// [plaid] (`PLAN.md` §7.1).
@JsonEnum(fieldRename: FieldRename.snake)
enum RecurringSource { plaid, detected, user, demo }

/// Whether a recurring stream is still expected to recur.
@JsonEnum(fieldRename: FieldRename.snake)
enum RecurringStatus { active, ended }

/// How often a recurring stream recurs; mirrors Plaid's `frequency`, plus [quarterly],
/// which Plaid never reports and the app's own detector does.
@JsonEnum(fieldRename: FieldRename.snake)
enum RecurringCadence {
  weekly,
  biweekly,
  semiMonthly,
  quarterly,
  monthly,
  annually,
  unknown,
}

/// The kind of a liability, as Plaid's Liabilities product groups them.
@JsonEnum(fieldRename: FieldRename.snake)
enum LiabilityKind { credit, mortgage, student }

/// What a rule condition tests.
@JsonEnum(fieldRename: FieldRename.snake)
enum RuleConditionKind {
  merchantContains,
  amountBetween,
  account,
  plaidCategory,
}

/// What a rule action does.
@JsonEnum(fieldRename: FieldRename.snake)
enum RuleActionKind { setCategory, addTag, rename, hide }

/// The operation a change-log entry records.
@JsonEnum(fieldRename: FieldRename.snake)
enum ChangeOperation { create, update, delete }

/// The period of a budget. Monthly, starting on the budget's `periodStartDay`.
@JsonEnum(fieldRename: FieldRename.snake)
enum BudgetPeriodKind { monthly }

/// The user-authored entities that sync through the change log (`PLAN.md` §6.4).
@JsonEnum(fieldRename: FieldRename.snake)
enum EntityType {
  account,
  transaction,
  category,
  rule,
  budget,
  recurringStream,
  billReminder,
  goal,
  settings,
}
