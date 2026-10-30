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
/// - **Credit card payments** (`PLAN.md` §12 "Credit card payments in reports"): an
///   outflow without splits whose effective category's code is
///   `LOAN_PAYMENTS_CREDIT_CARD_PAYMENT` is a transfer when its other leg is in the
///   ledger, a counted inflow on a credit account of the same currency and amount dated
///   within [cardPaymentPairingDays] days either side; else it stays spending (an
///   unlinked card's payment is the only trace of that card's spending). The inflow
///   paired is a transfer too, whatever its code. One inflow pairs one payment, the
///   nearest dates first ([pairedCardPayments]).
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

/// The Plaid code of a credit card payment.
const String cardPaymentCode = 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT';

/// How many days either side of a credit card payment its card's inflow may be dated.
const int cardPaymentPairingDays = 5;

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

/// The kind [transaction] counts as whole, by its effective category in [lookup], on its
/// own: a credit card payment and its card's inflow, paired ([pairedCardPayments]), are
/// transfers only in [reportEntries].
TransactionKind transactionKind(
  Transaction transaction,
  CategoryLookup lookup,
) => kindOf(
  categoryCode(effectiveCategory(transaction, lookup), lookup),
  transaction.amount,
);

/// The ids of both legs of each credit card payment in [transactions] whose other leg
/// is in them: each live, not [excluded] outflow without splits whose effective
/// category's code is [cardPaymentCode], paired with a live, not [excluded] inflow
/// without splits on one of [creditAccountIds] of the same currency and amount dated
/// within
/// [cardPaymentPairingDays] days either side. The pairing is one-to-one: the pairs
/// closest in date are taken first, then the earlier payment (by date, then id), then
/// the earlier inflow.
Set<String> pairedCardPayments(
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  required Set<String> creditAccountIds,
  TransactionExclusion excluded = _excludeNone,
}) {
  final Map<Money, List<Transaction>> payments = {};
  final Map<Money, List<Transaction>> inflows = {};
  for (final Transaction t in transactions) {
    if (t.deletedAt != null || excluded(t)) continue;
    if (t.splits.isNotEmpty) continue;
    if (t.amount.isPositive && creditAccountIds.contains(t.accountId)) {
      (inflows[t.amount] ??= []).add(t);
    } else if (t.amount.isNegative &&
        categoryCode(effectiveCategory(t, lookup), lookup) == cardPaymentCode) {
      (payments[-t.amount] ??= []).add(t);
    }
  }
  final List<(int, Transaction, Transaction)> pairs =
      [
        for (final MapEntry(key: amount, value: outs) in payments.entries)
          for (final Transaction p in outs)
            for (final Transaction i
                in inflows[amount] ?? const <Transaction>[])
              if (p.date.daysUntil(i.date).abs() <= cardPaymentPairingDays)
                (p.date.daysUntil(i.date).abs(), p, i),
      ]..sort((a, b) {
        int c = a.$1.compareTo(b.$1);
        if (c == 0) c = a.$2.date.compareTo(b.$2.date);
        if (c == 0) c = a.$2.id.compareTo(b.$2.id);
        if (c == 0) c = a.$3.date.compareTo(b.$3.date);
        if (c == 0) c = a.$3.id.compareTo(b.$3.id);
        return c;
      });
  final Set<String> paired = {};
  for (final (_, Transaction p, Transaction i) in pairs) {
    if (!paired.contains(p.id) && !paired.contains(i.id)) {
      paired
        ..add(p.id)
        ..add(i.id);
    }
  }
  return paired;
}

/// The rows of [transactions] a report in [currencyCode] counts, in their order: each
/// live, not [excluded] transaction in the currency whole, or each of its splits in the
/// currency when it has splits. A credit card payment whose card's inflow is among
/// them, on one of [creditAccountIds], is a transfer, and so is that inflow
/// ([pairedCardPayments]).
Iterable<ReportEntry> reportEntries(
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  required String currencyCode,
  required Set<String> creditAccountIds,
  TransactionExclusion excluded = _excludeNone,
}) sync* {
  final Set<String> paired = pairedCardPayments(
    transactions,
    lookup,
    creditAccountIds: creditAccountIds,
    excluded: excluded,
  );
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
      kind: paired.contains(t.id)
          ? TransactionKind.transfer
          : kindOf(categoryCode(category, lookup), t.amount),
    );
  }
}
