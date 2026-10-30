/// Rules and helpers the Drift and in-memory repositories share, so the two cannot drift
/// apart: the category edit rule, the audit-instant rule, the transaction order, SQLite's
/// text comparisons (ASCII case folding as `LIKE` and `NOCASE` do, UTF-8 byte order as
/// `BINARY` does, re-exported from `core/util/binary_compare.dart`), the equality the
/// repositories' `distinct` streams use, what a Plaid transaction keeps from the stored
/// row when the server's arrives, and what a batch write may change on one.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/util/binary_compare.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

export 'package:finance_tracker/core/util/binary_compare.dart'
    show compareBinary;

/// Throws [CategoryNotEditableException] when writing [next] over [existing] (null for a
/// new category) is not allowed: creating a system category, changing more than the icon
/// and color of one, or making a user category a system one.
void checkCategoryEdit(Category? existing, Category next) {
  final bool allowed = existing == null
      ? !next.isSystem
      : existing.isSystem
      ? next.isSystem &&
            next.name == existing.name &&
            next.parentId == existing.parentId &&
            next.plaidCategory == existing.plaidCategory
      : !next.isSystem;
  if (!allowed) throw CategoryNotEditableException(next.id);
}

/// Throws [AuditInstantError] (an [ArgumentError]) unless [transaction]'s `createdAt` and
/// `updatedAt` are UTC
/// instants with millisecond precision, the only audit instants stored (`PLAN.md` §12).
/// Its `deletedAt` is not stored from an upsert, so it is not checked.
void checkAuditInstants(Transaction transaction) {
  for (final (String name, DateTime instant) in [
    ('createdAt', transaction.createdAt),
    ('updatedAt', transaction.updatedAt),
  ]) {
    if (!instant.isUtc) {
      throw AuditInstantError(instant, name, 'audit instants must be UTC');
    }
    if (instant.microsecond != 0) {
      throw AuditInstantError(
        instant,
        name,
        'audit instants have millisecond precision',
      );
    }
  }
}

/// The transaction order of the repositories: date, then `createdAt`, then id (in
/// SQLite's `BINARY` order), all descending.
int compareTransactionsNewestFirst(Transaction a, Transaction b) {
  final int byDate = b.date.compareTo(a.date);
  if (byDate != 0) return byDate;
  final int byCreated = b.createdAt.compareTo(a.createdAt);
  return byCreated != 0 ? byCreated : compareBinary(b.id, a.id);
}

/// [a] against [b] as SQLite's `NOCASE` collation compares text: ASCII letters folded,
/// then [compareBinary].
int compareNoCase(String a, String b) =>
    compareBinary(asciiLowerCase(a), asciiLowerCase(b));

/// [text] with the ASCII letters A to Z lowered and every other character kept, as
/// SQLite's `LIKE` and `NOCASE` compare.
String asciiLowerCase(String text) {
  final List<int> units = text.codeUnits.toList();
  for (int i = 0; i < units.length; i++) {
    final int c = units[i];
    if (c >= 0x41 && c <= 0x5A) units[i] = c + 0x20;
  }
  return String.fromCharCodes(units);
}

/// Whether [a] and [b] hold equal elements in the same order.
bool sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Whether [a] and [b] hold equal values under the same keys.
bool sameMap<K, V>(Map<K, V> a, Map<K, V> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);

/// `TransactionRepository.watchUsage`'s argument check: [recentLimit] must be at least 1.
void checkRecentLimit(int recentLimit) {
  if (recentLimit < 1) {
    throw ArgumentError.value(recentLimit, 'recentLimit', 'must be at least 1');
  }
}

final Logger _log = Logger('db');

/// [server], a transaction as the server sent it, carrying the seven fields the user owns
/// from [stored], the row already on the device (`PLAN.md` §6.4: Plaid's fields are the
/// server's, the overrides the user's). Kept splits in another currency than the
/// server's amount cannot be stored and are dropped; only their count is logged.
Transaction withPlaidOverrides(Transaction server, Transaction stored) {
  List<TransactionSplit> splits = stored.splits;
  if (splits.any((s) => s.amount.currencyCode != server.amount.currencyCode)) {
    _log.warning('dropped ${splits.length} splits in another currency');
    splits = const [];
  }
  return server.copyWith(
    userCategoryId: stored.userCategoryId,
    notes: stored.notes,
    tags: stored.tags,
    splits: splits,
    receiptPath: stored.receiptPath,
    receiptSha256: stored.receiptSha256,
    hidden: stored.hidden,
  );
}

// The record fields a batch write may change on a `plaid` row besides the overrides: its
// audit stamp, and what only delete and restore set (deletedAt is ignored on write).
const Set<String> _batchWritable = {
  'updated_at',
  deletedAtField,
  deletedWithAccountField,
};

/// `TransactionRepository.upsertAll`'s rule for Plaid rows: when [next] or [stored] (the
/// row on the device, null when there is none) is `plaid`, [next] may differ from
/// [stored] only in the fields the user owns ([plaidOverrideFields]) and `updatedAt`.
/// Throws [PlaidOverridesOnlyError] naming the first other field that differs, or when
/// there is no stored row: only the Plaid pull creates a `plaid` transaction.
void checkPlaidOverridesOnly(Transaction next, Transaction? stored) {
  if (next.source != DataSource.plaid && stored?.source != DataSource.plaid) {
    return;
  }
  if (stored == null) {
    throw PlaidOverridesOnlyError(next.id);
  }
  final Map<String, Object?> before = transactionRecordJson(stored);
  final Map<String, Object?> after = transactionRecordJson(next);
  for (final String field in after.keys) {
    if (plaidOverrideFields.contains(field) || _batchWritable.contains(field)) {
      continue;
    }
    if (jsonEncode(before[field]) != jsonEncode(after[field])) {
      throw PlaidOverridesOnlyError(next.id, field: field);
    }
  }
}

/// Throws [ArgumentError] naming the first id [ids] repeats: a batch writes each
/// transaction once.
void checkDistinctIds(Iterable<String> ids) {
  final Set<String> seen = {};
  for (final String id in ids) {
    if (!seen.add(id)) {
      throw ArgumentError.value(id, 'ids', 'is repeated in the batch');
    }
  }
}

/// Whether [error] is a refusal of one transaction, which a batch reports as a
/// [TransactionBatchException], rather than a failure of the database itself.
bool isBatchRefusal(Object error) =>
    error is AccountNotFoundException ||
    error is CurrencyMismatchException ||
    error is EntityDeletedException ||
    error is BankDataNotDeletableException ||
    error is AuditInstantError ||
    error is PlaidOverridesOnlyError;
