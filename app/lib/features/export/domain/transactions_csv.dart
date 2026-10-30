/// The transactions as CSV (`docs/reference/export.md`, **The CSV**; `PLAN.md` §12
/// "Export" and "6f plan rulings"). Pure Dart.
///
/// RFC 4180: one record per live transaction, fields separated by commas, every record
/// (the last one too) ended by CRLF, a field quoted only when it holds a comma, a double
/// quote, a CR or an LF, with its double quotes doubled. The caller encodes the text as
/// UTF-8 with no byte order mark.
///
/// The fields are the data as stored, never localized or mangled: ISO dates, amounts in
/// the app's sign as `Money.toDecimalString()` with the currency beside them, the
/// account's name, the stored merchant name and name, the effective category's name and
/// its live parent's (empty when uncategorized), the flags as `true`/`false`, the tags
/// joined by `;` (a tag that itself holds `;` reads back as two: a known limit, which
/// the Phase 9 import's escaping settles), the notes, the source and the id. A field
/// that starts with `=`, `+`, `-` or `@` is written as it is (a spreadsheet may read it
/// as a formula). A transaction with splits is one record under its own effective
/// category. Deleted rows are left out; hidden and pending rows are written, with their
/// flags.
library;

import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// The header record's fields, in order.
const List<String> transactionsCsvHeader = [
  'date',
  'account',
  'merchant',
  'name',
  'amount',
  'currency',
  'category',
  'parent_category',
  'pending',
  'hidden',
  'tags',
  'notes',
  'source',
  'id',
];

/// The live [transactions] dated in [range] (every date when null) on the accounts in
/// [accountIds] (every account when null), sorted by date then id, as CSV text with the
/// header first. Accounts are named from [accounts] (empty for one not there),
/// categories looked up in [lookup].
String transactionsCsv(
  Iterable<Transaction> transactions, {
  required Map<String, Account> accounts,
  required CategoryLookup lookup,
  LocalDateRange? range,
  Set<String>? accountIds,
}) {
  final List<Transaction> rows =
      [
        for (final Transaction t in transactions)
          if (t.deletedAt == null &&
              (range == null || range.contains(t.date)) &&
              (accountIds == null || accountIds.contains(t.accountId)))
            t,
      ]..sort((a, b) {
        final int byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
  final StringBuffer out = StringBuffer();
  void record(List<String> fields) {
    out
      ..writeAll(fields.map(csvField), ',')
      ..write('\r\n');
  }

  record(transactionsCsvHeader);
  for (final Transaction t in rows) {
    final Category? category = effectiveCategory(t, lookup);
    record([
      t.date.toIso(),
      accounts[t.accountId]?.name ?? '',
      t.merchantName ?? '',
      t.name,
      t.amount.toDecimalString(),
      t.amount.currencyCode,
      category?.name ?? '',
      lookup.byId[category?.parentId]?.name ?? '',
      '${t.pending}',
      '${t.hidden}',
      // Not escaped: a tag holding `;` does not round-trip (a known limit).
      t.tags.join(';'),
      t.notes ?? '',
      t.source.name,
      t.id,
    ]);
  }
  return out.toString();
}

/// [value] as an RFC 4180 field: quoted, its double quotes doubled, when it holds a
/// comma, a double quote, a CR or an LF; else as it is.
String csvField(String value) => value.contains(RegExp('[",\r\n]'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;
