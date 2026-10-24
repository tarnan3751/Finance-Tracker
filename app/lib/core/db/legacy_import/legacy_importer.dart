/// The one-time import of the original app's data (`PLAN.md` §6.3, §12).
///
/// The original app (`git show fdf69c0:lib/main.dart`) kept everything in
/// shared_preferences: `transactions` (expenses) and `incomes`, each a JSON array of
/// `{"amount": <double>, "description": <String>}` written by `setString(jsonEncode(...))`
/// with the amount as the user typed it (positive), and `totalBalance` as a double. It
/// subtracted expenses and added incomes.
///
/// [LegacyImporter.runIfNeeded] reads both lists once, through the legacy
/// `SharedPreferences` API (the one the original app wrote with), into one manual
/// depository account named "Imported" in the device locale's currency: one transaction
/// per entry, dated to the import day, `source: DataSource.import`, the description as its
/// name, expenses negative and incomes positive. Ids are UUID v5 under a fixed namespace,
/// so a run interrupted before it recorded `legacy_import_done` writes the same records
/// again rather than duplicates, into the account it created (in that account's
/// currency); a record the user deleted meanwhile stays deleted and is not counted. If the
/// user has deleted that account, the legacy keys are removed, the import is marked done
/// and nothing is written. An entry it cannot read is skipped and counted; otherwise the
/// legacy keys are removed only when nothing was skipped.
///
/// Because the package id changed from `com.example.flutter_finance_tracker` to
/// `dev.tarnan.financetracker` (`PLAN.md` §12), an Android install of this app cannot see
/// the original app's data: the importer serves only an install that shares its data
/// directory.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final Logger _log = Logger('legacy_import');

/// The original app's shared_preferences keys.
const List<String> legacyKeys = ['transactions', 'incomes', 'totalBalance'];

const String _expensesKey = 'transactions';
const String _incomesKey = 'incomes';

/// The UUID v5 namespace of imported records.
const String legacyImportNamespace = '13c2a6bb-4e51-4ece-b75f-e4b750169fc1';

/// Imports the original app's data once.
final class LegacyImporter {
  /// An importer reading [preferences] into [accounts] and [transactions], recording that
  /// it ran in [meta], dating entries by [clock], and choosing the currency of [locale]
  /// (an intl locale such as `en_US`).
  LegacyImporter({
    required this._preferences,
    required this._accounts,
    required this._transactions,
    required this._meta,
    required this._clock,
    required this._locale,
  });

  final SharedPreferences _preferences;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final AppMetaStore _meta;
  final Clock _clock;
  final String _locale;

  static const Uuid _uuid = Uuid();

  /// The id of the imported account.
  static String get accountId =>
      _uuid.v5(legacyImportNamespace, 'legacy-import/account');

  /// Imports the legacy data unless it was imported before. Returns null when this was
  /// done before, there was nothing to import, or the user has deleted the Imported
  /// account (an earlier run was interrupted after creating it; the import is then marked
  /// done and nothing is written).
  Future<ImportSummary?> runIfNeeded() async {
    if (await _meta.read(AppMetaKeys.legacyImportDone) != null) return null;

    // An interrupted earlier run may have created the account: its currency wins over the
    // device locale's, which may have changed since.
    final List<Account> existing = await _accounts.watchAll().first;
    final Account? previous = existing
        .where((a) => a.id == accountId)
        .firstOrNull;
    final String currency = previous?.currencyCode ?? _currency();
    final (List<_Entry> expenses, int badExpenses) = _read(_expensesKey);
    final (List<_Entry> incomes, int badIncomes) = _read(_incomesKey);
    int skipped = badExpenses + badIncomes;

    final LocalDate today = _clock.today();
    final DateTime now = _clock.nowUtc();
    final List<Transaction> records = [];
    void convert(List<_Entry> entries, String kind, bool isIncome) {
      for (int i = 0; i < entries.length; i++) {
        final Money? amount = _money(entries[i].amount, currency);
        if (amount == null) {
          skipped++;
          continue;
        }
        records.add(
          Transaction(
            id: _uuid.v5(legacyImportNamespace, 'legacy-import/$kind/$i'),
            accountId: accountId,
            amount: isIncome ? amount : -amount,
            date: today,
            pending: false,
            name: entries[i].description,
            source: DataSource.import,
            createdAt: now,
            updatedAt: now,
            syncVersion: 0,
          ),
        );
      }
    }

    convert(expenses, 'expense', false);
    convert(incomes, 'income', true);

    if (records.isNotEmpty) {
      if (previous == null) {
        try {
          await _accounts.upsert(
            Account(
              id: accountId,
              type: AccountType.depository,
              name: 'Imported',
              currencyCode: currency,
              isHidden: false,
              displayOrder: existing.isEmpty
                  ? 0
                  : existing
                            .map((a) => a.displayOrder)
                            .reduce((a, b) => a > b ? a : b) +
                        1,
            ),
          );
        } on EntityDeletedException {
          // The user deleted the account an interrupted run created: they chose to drop
          // this data, so do not bring it back, remove the original app's plaintext copy,
          // and do not ask again.
          await _removeLegacyKeys();
          await _meta.write(AppMetaKeys.legacyImportDone, today.toIso());
          _log.info('legacy import: the Imported account was deleted; stopped');
          return null;
        }
      }
    }
    final List<Transaction> written = [];
    for (final Transaction t in records) {
      try {
        await _transactions.upsert(t);
        written.add(t);
      } on EntityDeletedException {
        // Deleted by the user after an interrupted run wrote it: it stays deleted, and
        // the summary leaves it out.
      }
    }
    await _meta.write(AppMetaKeys.legacyImportDone, today.toIso());
    if (skipped == 0) await _removeLegacyKeys();
    _log.info(
      'legacy import: ${written.length} transactions, $skipped skipped',
    );
    if (written.isEmpty && skipped == 0) return null;
    return ImportSummary(
      transactions: written.length,
      total: Money.sum(written.map((t) => t.amount), currencyCode: currency),
      skipped: skipped,
    );
  }

  Future<void> _removeLegacyKeys() async {
    for (final String key in legacyKeys) {
      await _preferences.remove(key);
    }
  }

  /// The entries under [key] and how many could not be read; a value that is not a JSON
  /// array counts as one.
  (List<_Entry>, int) _read(String key) {
    final Object? stored = _preferences.get(key);
    if (stored == null) return (const [], 0);
    final Object? decoded;
    try {
      decoded = stored is String ? jsonDecode(stored) : null;
    } on FormatException {
      return (const [], 1);
    }
    if (decoded is! List<Object?>) return (const [], 1);
    final List<_Entry> entries = [];
    int skipped = 0;
    for (final Object? item in decoded) {
      if (item is Map<String, Object?> &&
          item['amount'] is num &&
          item['description'] is String) {
        entries.add(
          _Entry(item['amount']! as num, item['description']! as String),
        );
      } else {
        skipped++;
      }
    }
    return (entries, skipped);
  }

  /// [amount] as `Money` in [currency], or null when it cannot be.
  ///
  /// The only place in the app a `double` is read: the original app stored amounts as
  /// doubles. They go through their fixed-point text at the currency's scale, which also
  /// rounds float error such as 0.1 + 0.2 to 0.30, and are parsed in a fixed locale
  /// because that text always uses `.` and `-`. Non-finite values, and values so large
  /// that the text is in exponent form or out of range, are refused.
  Money? _money(num amount, String currency) {
    final double value = amount.toDouble();
    if (!value.isFinite) return null;
    try {
      return Money.parse(
        value.toStringAsFixed(Currency.scaleOf(currency)),
        currency,
        locale: 'en_US',
      );
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  /// The currency of [_locale], or USD when intl does not know it.
  String _currency() {
    try {
      final String? name = NumberFormat.simpleCurrency(locale: _locale)
          .currencyName;
      return name != null && Money.isValidCurrencyCode(name) ? name : 'USD';
    } on ArgumentError {
      return 'USD';
    }
  }
}

final class _Entry {
  const _Entry(this.amount, this.description);

  final num amount;
  final String description;
}
