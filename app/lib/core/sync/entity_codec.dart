/// How the app's entities appear as sync records (`docs/reference/sync-app.md`).
///
/// A record's fields are the entity's `shared_models` JSON, plus what the app keeps beside
/// it: `deleted_at` for accounts and categories (whose entities carry no tombstone), and
/// `deleted_with_account` for transactions (the cascade flag, synced so a restore on any
/// device brings back the same rows). Settings are the one record `settings/local`, with
/// `theme_mode` and `use_dynamic_color`. Nested values (tags, splits, amounts) are whole
/// field values.
///
/// Pure Dart, no Flutter import: the database migration uses it.
library;

import 'dart:convert';

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

/// The record fields of [settings].
Map<String, Object?> settingsRecordJson(Settings settings) => {
  'theme_mode': settings.themeMode.name,
  'use_dynamic_color': settings.useDynamicColor,
};

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
