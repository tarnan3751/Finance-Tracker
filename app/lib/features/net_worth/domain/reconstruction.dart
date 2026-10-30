/// Net worth before the first stored snapshot, reconstructed from transactions
/// (`docs/reference/net-worth.md`, **The reconstruction**; `PLAN.md` §7.1 tier C, §12
/// "Balance snapshots and net worth", "6b plan rulings"). Pure Dart, integer `Money` only;
/// computed on read and never stored.
///
/// For each currency, with S the series' first day (the first date a snapshot in it is
/// stored for):
///
/// - a depository or credit account with a snapshot on S is walked back from it:
///   balance(d − 1) = balance(d) − the sum of its transactions dated d, counting posted
///   ones only (pending ones are left out), hidden ones (the money moved), both legs of a
///   transfer, and none in another currency; the transactions given are the live ones.
///   Before its earliest such transaction E the account holds flat at B(E − 1), the
///   balance before its history starts (zero for a manual account whose first row is its
///   opening balance, the balance before the bank's horizon for a linked one); an
///   account with no such transaction holds flat at its snapshot. So every walked account
///   is present on every day of the prefix, and none appears with a jump;
/// - a loan, investment or other account with a snapshot on S is held flat at it, since
///   its transactions do not tell its balance (interest, prices);
/// - an account whose first snapshot is after S has no derived history.
///
/// The prefix runs from the earliest walked transaction across the accounts to S − 1,
/// every point `derived`; it joins the observed series at S, whose point is the snapshots' own, so the two meet
/// exactly. With no walked transaction before S there is no prefix.
library;

import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:shared_models/shared_models.dart';

/// Whether an account of [type] is walked back through its transactions rather than
/// held flat.
bool isWalked(AccountType? type) =>
    type == AccountType.depository || type == AccountType.credit;

/// The balances of an account on each day before [anchor]'s date, walked back from
/// [anchor] through [transactions] (any account's; the account's live ones are used, see
/// the library comment), by date, from its earliest counted transaction's date to the day
/// before [anchor]'s. Empty when it has no counted transaction dated before [anchor]'s
/// date.
List<(LocalDate, Money)> walkedBalances(
  BalanceSnapshot anchor,
  Iterable<Transaction> transactions,
) {
  final String currency = anchor.current.currencyCode;
  final Map<LocalDate, Money> byDate = {};
  LocalDate? earliest;
  for (final Transaction t in transactions) {
    if (!_counts(t, anchor)) continue;
    byDate[t.date] = (byDate[t.date] ?? Money.zero(currency)) + t.amount;
    if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
  }
  if (earliest == null || !earliest.isBefore(anchor.date)) return const [];
  final List<(LocalDate, Money)> walked = [];
  Money balance = anchor.current;
  for (
    LocalDate d = anchor.date.addDays(-1);
    !d.isBefore(earliest);
    d = d.addDays(-1)
  ) {
    balance -= byDate[d.addDays(1)] ?? Money.zero(currency);
    walked.add((d, balance));
  }
  return walked.reversed.toList();
}

/// The balance of [anchor]'s account before its history in [transactions] starts: the
/// anchor less every counted transaction dated on or before its date, B(E − 1) for its
/// earliest counted transaction E; the anchor itself when it has none.
Money balanceBefore(
  BalanceSnapshot anchor,
  Iterable<Transaction> transactions,
) =>
    anchor.current -
    Money.sum([
      for (final Transaction t in transactions)
        if (_counts(t, anchor)) t.amount,
    ], currencyCode: anchor.current.currencyCode);

// Whether [t] moves [anchor]'s account's balance up to the anchor's date: on the account,
// posted, live, in its currency, dated on or before the anchor.
bool _counts(Transaction t, BalanceSnapshot anchor) =>
    t.accountId == anchor.accountId &&
    !t.pending &&
    t.deletedAt == null &&
    t.amount.currencyCode == anchor.current.currencyCode &&
    !t.date.isAfter(anchor.date);

/// The derived prefix (see the library comment) of the series in [currencyCode] from
/// [snapshots], the live accounts' types [typeOf] and the live [transactions], by date.
List<NetWorthPoint> reconstructedPrefix(
  Iterable<BalanceSnapshot> snapshots,
  Map<String, AccountType> typeOf,
  Iterable<Transaction> transactions,
  String currencyCode,
) {
  final List<BalanceSnapshot> inCurrency = [
    for (final BalanceSnapshot s in snapshots)
      if (s.current.currencyCode == currencyCode) s,
  ];
  if (inCurrency.isEmpty) return const [];
  final LocalDate start = inCurrency
      .map((s) => s.date)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final List<BalanceSnapshot> first = [
    for (final BalanceSnapshot s in inCurrency)
      if (s.date == start) s,
  ];
  final List<BalanceSnapshot> flat = [];
  // Each walked account's balances from its earliest transaction, and the balance it
  // holds before it.
  final Map<String, (Map<LocalDate, Money>, Money)> walked = {};
  LocalDate? from;
  for (final BalanceSnapshot s in first) {
    if (!isWalked(typeOf[s.accountId])) {
      flat.add(s);
      continue;
    }
    final List<(LocalDate, Money)> days = walkedBalances(s, transactions);
    walked[s.accountId] = (
      {for (final (LocalDate d, Money m) in days) d: m},
      balanceBefore(s, transactions),
    );
    if (days.isNotEmpty && (from == null || days.first.$1.isBefore(from))) {
      from = days.first.$1;
    }
  }
  if (from == null) return const [];
  return [
    for (LocalDate d = from; d.isBefore(start); d = d.addDays(1))
      pointOf(
        d,
        [
          for (final BalanceSnapshot s in flat)
            (typeOf[s.accountId], s.current),
          for (final MapEntry(
                key: String id,
                value: (Map<LocalDate, Money> days, Money before),
              )
              in walked.entries)
            (typeOf[id], days[d] ?? before),
        ],
        currencyCode,
        derived: true,
      ),
  ];
}

/// The whole series per currency code: [reconstructedPrefix] followed by
/// [observedNetWorth], by date.
Map<String, List<NetWorthPoint>> netWorthHistory(
  List<BalanceSnapshot> snapshots,
  Map<String, AccountType> typeOf,
  List<Transaction> transactions,
) => {
  for (final MapEntry<String, List<NetWorthPoint>> e in observedNetWorth(
    snapshots,
    typeOf,
  ).entries)
    e.key: [
      ...reconstructedPrefix(snapshots, typeOf, transactions, e.key),
      ...e.value,
    ],
};
