/// The generator's book of entries. Every money movement in a household goes through
/// [Ledger.post] (one account) or [Ledger.transfer] (two of the household's accounts), so
/// balances can only change by an entry and a transfer's legs are one value, negated.
library;

import 'package:persona_engine/src/model/anomaly.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:shared_models/shared_models.dart';

final Map<String, String> _primaryOf = {
  for (final c in plaidCategories) c.detailed: c.primary,
};

/// The primary category of the Plaid v2 detailed code [detailed]; throws an
/// [ArgumentError] for a code that is not in the taxonomy.
String primaryCategoryOf(String detailed) =>
    _primaryOf[detailed] ??
    (throw ArgumentError.value(
      detailed,
      'detailed',
      'not a Plaid v2 category',
    ));

/// Which side of a transfer an entry is.
enum TransferLeg { out, into }

/// One entry: a future transaction.
final class LedgerEntry {
  LedgerEntry._({
    required this.seq,
    required this.account,
    required this.amount,
    required this.transacted,
    required this.posted,
    required this.raw,
    required this.merchant,
    required this.detailed,
    this.pairId,
    this.leg,
    this.isInterest = false,
    this.anomaly,
  });

  /// The emission order; unique, so it breaks every sort tie.
  final int seq;

  /// The account key.
  final String account;

  /// The amount, negative for an outflow.
  final Money amount;

  /// The day it happened.
  final LocalDate transacted;

  /// The day it posted, on or after [transacted] and never after the as-of date.
  final LocalDate posted;

  /// The raw description.
  final String raw;

  /// The normalized merchant.
  final String? merchant;

  /// The Plaid detailed category.
  final String detailed;

  /// The transfer it belongs to.
  final int? pairId;

  /// Its side of that transfer.
  final TransferLeg? leg;

  /// Whether it is a card or loan interest charge.
  final bool isInterest;

  /// The anomaly it was planted as.
  final AnomalyKind? anomaly;
}

/// The running book of one household.
final class Ledger {
  /// A ledger opened at [openings], each non-investment account's balance on the
  /// window's eve.
  Ledger(this.persona, this.asOf, Map<String, Money> openings)
    : _balances = {...openings};

  /// The household.
  final Persona persona;

  /// The last day; later posting dates are clamped to it.
  final LocalDate asOf;

  final Map<String, Money> _balances;
  final List<LedgerEntry> _entries = [];
  int _pairs = 0;

  /// The entries, in emission order.
  List<LedgerEntry> get entries => List.unmodifiable(_entries);

  /// The balance of [account] after every entry so far.
  Money balance(String account) =>
      _balances[account] ??
      (throw ArgumentError.value(account, 'account', 'no ledger account'));

  /// Records [amount] (negative for an outflow) on [account].
  LedgerEntry post({
    required String account,
    required Money amount,
    required LocalDate date,
    LocalDate? posted,
    required String raw,
    required String? merchant,
    required String detailed,
    bool isInterest = false,
    AnomalyKind? anomaly,
  }) => _add(
    account: account,
    amount: amount,
    date: date,
    posted: posted,
    raw: raw,
    merchant: merchant,
    detailed: detailed,
    isInterest: isInterest,
    anomaly: anomaly,
  );

  /// [post] with a [Payee]'s description.
  LedgerEntry postPayee(
    String account,
    Money amount,
    LocalDate date,
    Payee payee,
  ) => post(
    account: account,
    amount: amount,
    date: date,
    raw: payee.raw,
    merchant: payee.merchant,
    detailed: payee.detailed,
  );

  /// Moves [amount] (positive) from [from] to [to] on [date]: an outflow leg described
  /// by [outPayee] and an inflow leg by [inPayee], both from the one value.
  void transfer({
    required String from,
    required String to,
    required Money amount,
    required LocalDate date,
    required Payee outPayee,
    required Payee inPayee,
  }) {
    if (!amount.isPositive) {
      throw ArgumentError.value(amount, 'amount', 'a transfer is positive');
    }
    final pair = _pairs++;
    _add(
      account: from,
      amount: -amount,
      date: date,
      raw: outPayee.raw,
      merchant: outPayee.merchant,
      detailed: outPayee.detailed,
      pairId: pair,
      leg: TransferLeg.out,
    );
    _add(
      account: to,
      amount: amount,
      date: date,
      raw: inPayee.raw,
      merchant: inPayee.merchant,
      detailed: inPayee.detailed,
      pairId: pair,
      leg: TransferLeg.into,
    );
  }

  LedgerEntry _add({
    required String account,
    required Money amount,
    required LocalDate date,
    LocalDate? posted,
    required String raw,
    required String? merchant,
    required String detailed,
    int? pairId,
    TransferLeg? leg,
    bool isInterest = false,
    AnomalyKind? anomaly,
  }) {
    if (amount.isZero) throw ArgumentError('a zero entry on $account on $date');
    if (date.isAfter(asOf)) throw ArgumentError('$date is after $asOf');
    primaryCategoryOf(detailed);
    final p = posted == null ? date : (posted.isAfter(asOf) ? asOf : posted);
    final entry = LedgerEntry._(
      seq: _entries.length,
      account: account,
      amount: amount,
      transacted: date,
      posted: p,
      raw: raw,
      merchant: merchant,
      detailed: detailed,
      pairId: pairId,
      leg: leg,
      isInterest: isInterest,
      anomaly: anomaly,
    );
    _balances[account] = balance(account) + amount;
    _entries.add(entry);
    return entry;
  }
}
