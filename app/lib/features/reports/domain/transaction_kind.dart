/// What a report counts a transaction as (`docs/reference/reports.md`, **Classification**;
/// `PLAN.md` §12 "Reports and insights", "6c plan rulings"): spending, income or a
/// transfer, from its effective category. Pure Dart.
///
/// - **Which rows:** live (not deleted), not excluded (the app leaves out the hidden
///   ones), in the report's currency; pending rows count.
/// - **The unit:** a transaction without splits counts whole under its effective category
///   (`effective_category.dart`); one with splits counts each split in the currency
///   under the split's own category, as the budgets do.
/// - **The code:** the category's Plaid code, else its nearest ancestor's, so a user
///   category under "Income" is income.
/// - **The kind:** `TRANSFER_IN*` and `TRANSFER_OUT*` are transfers, and so are inflows
///   under `LOAN_PAYMENTS*` (the receiving leg of a payment) and `LOAN_DISBURSEMENTS*`
///   (borrowed money); `INCOME*` is income whatever its sign; any other code is spending,
///   so a refund under a spending category nets against it. With no code at all, an
///   inflow is income and an outflow spending.
library;

import 'package:finance_tracker/features/budgets/domain/budget_math.dart'
    show TransactionExclusion;
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// What a report counts a row as.
enum TransactionKind { spend, income, transfer }

/// One row a report counts: [transaction] whole when [split] is null, else that split.
final class ReportEntry {
  /// An entry.
  const ReportEntry({
    required this.transaction,
    required this.split,
    required this.amount,
    required this.categoryId,
    required this.kind,
  });

  /// The transaction.
  final Transaction transaction;

  /// The split counted, or null for the whole transaction.
  final TransactionSplit? split;

  /// The amount in the app's sign (an outflow negative).
  final Money amount;

  /// The live category it counts under, or null ("Uncategorized").
  final String? categoryId;

  /// What it counts as.
  final TransactionKind kind;

  /// The transaction's date.
  LocalDate get date => transaction.date;
}

bool _excludeNone(Transaction _) => false;

/// The Plaid code [category] stands for: its own, else its nearest ancestor's in
/// [lookup]; null when none has one.
String? categoryCode(Category? category, CategoryLookup lookup) {
  final Set<String> seen = {};
  Category? c = category;
  while (c != null && seen.add(c.id)) {
    if (c.plaidCategory case final String code) return code;
    c = lookup.byId[c.parentId];
  }
  return null;
}

/// The kind of a row of [amount] under Plaid code [code] (null when it has none).
TransactionKind kindOf(String? code, Money amount) {
  if (code == null) {
    return amount.isPositive ? TransactionKind.income : TransactionKind.spend;
  }
  if (code.startsWith('TRANSFER_IN') || code.startsWith('TRANSFER_OUT')) {
    return TransactionKind.transfer;
  }
  if (amount.isPositive &&
      (code.startsWith('LOAN_PAYMENTS') ||
          code.startsWith('LOAN_DISBURSEMENTS'))) {
    return TransactionKind.transfer;
  }
  if (code.startsWith('INCOME')) return TransactionKind.income;
  return TransactionKind.spend;
}

/// The kind [transaction] counts as whole, by its effective category in [lookup].
TransactionKind transactionKind(
  Transaction transaction,
  CategoryLookup lookup,
) => kindOf(
  categoryCode(effectiveCategory(transaction, lookup), lookup),
  transaction.amount,
);

/// The rows of [transactions] a report in [currencyCode] counts, in their order: each
/// live, not [excluded] transaction in the currency whole, or each of its splits in the
/// currency when it has splits.
Iterable<ReportEntry> reportEntries(
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  required String currencyCode,
  TransactionExclusion excluded = _excludeNone,
}) sync* {
  for (final Transaction t in transactions) {
    if (t.deletedAt != null ||
        t.amount.currencyCode != currencyCode ||
        excluded(t)) {
      continue;
    }
    if (t.splits.isNotEmpty) {
      for (final TransactionSplit split in t.splits) {
        if (split.amount.currencyCode != currencyCode) continue;
        final Category? category = lookup.byId[split.categoryId];
        yield ReportEntry(
          transaction: t,
          split: split,
          amount: split.amount,
          categoryId: category?.id,
          kind: kindOf(categoryCode(category, lookup), split.amount),
        );
      }
      continue;
    }
    final Category? category = effectiveCategory(t, lookup);
    yield ReportEntry(
      transaction: t,
      split: null,
      amount: t.amount,
      categoryId: category?.id,
      kind: kindOf(categoryCode(category, lookup), t.amount),
    );
  }
}
