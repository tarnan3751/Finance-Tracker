/// How the app's entities appear as sync records (`docs/reference/sync-app.md`).
///
/// A record's fields are the entity's `shared_models` JSON, plus what the app keeps beside
/// it: `deleted_at` for accounts, categories, rules, budgets and bills (whose entities
/// carry no tombstone), and `deleted_with_account` for transactions (the cascade flag, synced so a
/// restore on any device brings back the same rows). Settings are the one record `settings/local`, with
/// `theme_mode` and `use_dynamic_color`. A `recurring_stream` record is the user's
/// override of one stream (keyed by the stream's id): `muted`, `is_subscription`,
/// `display_name` and `deleted_at`, never the stream itself, which is the server's or
/// the detector's. A `goal` and a `goal_contribution` are their entities' JSON, each
/// with its own `deleted_at`; a goal's contributions are records of their own, never a
/// field of it. Nested values (tags, splits, amounts, linked accounts) are whole field
/// values.
///
/// Pure Dart, no Flutter import: the database migration uses it.
library;

import 'dart:convert';

import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:shared_models/shared_models.dart';

/// The tombstone field of every record (the engine's register for deletes).
const String deletedAtField = 'deleted_at';

/// The cascade flag of a transaction record.
const String deletedWithAccountField = 'deleted_with_account';

/// The id of the settings record.
const String settingsRecordId = 'local';

/// The fields of a Plaid transaction the user owns, the only ones recorded for one
/// (`PLAN.md` §7.1; the rest is server-authoritative).
const Set<String> plaidOverrideFields = {
  'user_category_id',
  'notes',
  'tags',
  'splits',
  'receipt_path',
  'receipt_sha256',
  'hidden',
};

/// The record fields of [account], deleted at [deletedAt] (null while live).
Map<String, Object?> accountRecordJson(
  Account account, {
  DateTime? deletedAt,
}) => {..._plain(account.toJson()), deletedAtField: _instant(deletedAt)};

/// The record fields of [transaction] (its own `deletedAt` included).
Map<String, Object?> transactionRecordJson(
  Transaction transaction, {
  bool deletedWithAccount = false,
}) => {
  ..._plain(transaction.toJson()),
  deletedWithAccountField: deletedWithAccount,
};

/// The record fields of [category], deleted at [deletedAt] (null while live).
Map<String, Object?> categoryRecordJson(
  Category category, {
  DateTime? deletedAt,
}) => {..._plain(category.toJson()), deletedAtField: _instant(deletedAt)};

/// The record fields of [rule], deleted at [deletedAt] (null while live). Its conditions
/// and actions are whole field values.
Map<String, Object?> ruleRecordJson(Rule rule, {DateTime? deletedAt}) => {
  ..._plain(rule.toJson()),
  deletedAtField: _instant(deletedAt),
};

/// The record fields of [budget], deleted at [deletedAt] (null while live). Its amount is
/// one whole field value.
Map<String, Object?> budgetRecordJson(Budget budget, {DateTime? deletedAt}) => {
  ..._plain(budget.toJson()),
  deletedAtField: _instant(deletedAt),
};

/// The record fields of [bill], deleted at [deletedAt] (null while live). Its amount,
/// reminder offsets and paid occurrences are whole field values.
Map<String, Object?> billRecordJson(BillReminder bill, {DateTime? deletedAt}) =>
    {..._plain(bill.toJson()), deletedAtField: _instant(deletedAt)};

/// The record fields of [goal] (its own `deletedAt` included). Its target and linked
/// accounts are whole field values.
Map<String, Object?> goalRecordJson(Goal goal) => _plain(goal.toJson());

/// The record fields of [contribution] (its own `deletedAt` included).
Map<String, Object?> goalContributionRecordJson(
  GoalContribution contribution,
) => _plain(contribution.toJson());

/// The record fields of [settings].
Map<String, Object?> settingsRecordJson(Settings settings) => {
  'theme_mode': settings.themeMode.name,
  'use_dynamic_color': settings.useDynamicColor,
};

/// The record fields of the override of a stream, cleared at [deletedAt] (null while
/// live).
Map<String, Object?> streamOverrideRecordJson(
  StreamOverride override, {
  DateTime? deletedAt,
}) => {
  'muted': override.muted,
  'is_subscription': override.isSubscription,
  'display_name': override.displayName,
  deletedAtField: _instant(deletedAt),
};

/// The override record [fields] hold; a missing field is its default. Throws
/// [FormatException] on a value of the wrong type.
StreamOverride streamOverrideOf(Map<String, Object?> fields) => StreamOverride(
  muted: switch (fields['muted']) {
    null => false,
    final bool muted => muted,
    final Object other => throw FormatException('muted', '$other'),
  },
  isSubscription: switch (fields['is_subscription']) {
    null => null,
    final bool value => value,
    final Object other => throw FormatException('is_subscription', '$other'),
  },
  displayName: switch (fields['display_name']) {
    null => null,
    final String name => name,
    final Object other => throw FormatException('display_name', '$other'),
  },
);

/// The `deleted_at` of record [fields] (absent or null: live). Throws [FormatException]
/// on a value that is not an instant.
DateTime? deletedAtOf(Map<String, Object?> fields) =>
    switch (fields[deletedAtField]) {
      null => null,
      final String instant => const UtcInstantConverter().fromJson(instant),
      final Object other => throw FormatException('not an instant', '$other'),
    };

/// The cascade flag of transaction record [fields] (absent: false).
bool deletedWithAccountOf(Map<String, Object?> fields) =>
    fields[deletedWithAccountField] == true;

/// The record fields this version knows for [type].
Set<String> knownRecordFields(EntityType type) => switch (type) {
  EntityType.account => _accountFields,
  EntityType.transaction => _transactionFields,
  EntityType.category => _categoryFields,
  EntityType.rule => _ruleFields,
  EntityType.budget => _budgetFields,
  EntityType.billReminder => _billFields,
  EntityType.goal => _goalFields,
  EntityType.goalContribution => _goalContributionFields,
  EntityType.settings => const {'theme_mode', 'use_dynamic_color'},
  EntityType.recurringStream => const {
    'muted',
    'is_subscription',
    'display_name',
    deletedAtField,
  },
};

final Set<String> _accountFields = accountRecordJson(
  const Account(
    id: '',
    type: AccountType.other,
    name: '',
    currencyCode: 'USD',
    isHidden: false,
    displayOrder: 0,
  ),
).keys.toSet();

final Set<String> _transactionFields = transactionRecordJson(
  Transaction(
    id: '',
    accountId: '',
    amount: Money(0, 'USD'),
    date: LocalDate(2026, 1, 1),
    pending: false,
    name: '',
    source: DataSource.manual,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    syncVersion: 0,
  ),
).keys.toSet();

final Set<String> _categoryFields = categoryRecordJson(
  const Category(id: '', name: '', isSystem: false, icon: '', color: 0),
).keys.toSet();

final Set<String> _ruleFields = ruleRecordJson(
  const Rule(id: '', name: '', position: 0, conditions: [], actions: []),
).keys.toSet();

final Set<String> _budgetFields = budgetRecordJson(
  Budget(
    id: '',
    categoryId: '',
    period: BudgetPeriodKind.monthly,
    periodStartDay: 1,
    amount: Money(0, 'USD'),
    rollover: false,
    startDate: LocalDate(2026, 1, 1),
  ),
).keys.toSet();

final Set<String> _billFields = billRecordJson(
  BillReminder(id: '', dueDate: LocalDate(2026, 1, 1)),
).keys.toSet();

final Set<String> _goalFields = goalRecordJson(
  Goal(
    id: '',
    name: '',
    target: Money(0, 'USD'),
    kind: GoalKind.balance,
    createdOn: LocalDate(2026, 1, 1),
  ),
).keys.toSet();

final Set<String> _goalContributionFields = goalContributionRecordJson(
  GoalContribution(
    id: '',
    goalId: '',
    date: LocalDate(2026, 1, 1),
    amount: Money(0, 'USD'),
  ),
).keys.toSet();

/// The JSON name of [value]: its Dart name in snake case (`recurring_stream`,
/// `conflicting_duplicate`), as `shared_models` writes enums.
String snakeName(Enum value) => value.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '_${m[0]!.toLowerCase()}',
);

/// The value of [values] whose [snakeName] is [name]; [FormatException] when none is.
T enumFromSnakeName<T extends Enum>(List<T> values, String name) =>
    values.firstWhere(
      (v) => snakeName(v) == name,
      orElse: () => throw FormatException('unknown value', name),
    );

String? _instant(DateTime? instant) =>
    instant == null ? null : const UtcInstantConverter().toJson(instant);

// A copy that holds only JSON values (maps, lists, strings, numbers, booleans).
Map<String, Object?> _plain(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;
