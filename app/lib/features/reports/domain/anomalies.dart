/// Anomaly flags (`docs/reference/reports.md`, **Anomalies**; `PLAN.md` §12 "Reports and
/// insights", "6c plan rulings"): outflows worth a second look, either an unusual amount
/// at a merchant or a merchant new to the household. A hint list, not a verdict. Pure
/// Dart; every comparison is in integer minor units, never a `double`.
///
/// - **Rows considered:** live, not excluded (the hidden ones), outflows counted as
///   spending (`transaction_kind.dart`), less the scheduled payments: the members of a
///   recurring stream, the rows under `detectorExcludedCodes` and every outflow under
///   `LOAN_PAYMENTS*` or `LOAN_DISBURSEMENTS*` (a loan paid out to a school or a seller);
///   and less the rows a rule's merchant condition matches (a merchant
///   the user has a rule for is known to them).
/// - **Legs.** A transaction without splits is one leg under its effective category; one
///   with splits has a leg per split in its currency under the split's own category (as
///   the reports classify it). Only considered legs count; the transaction's outflow at
///   its merchant is the sum of its considered legs.
/// - **Unusual amount.** On the merchant basis, the priors are the earlier transactions'
///   outflows at the same merchant key in the same currency (one per transaction, its
///   legs summed), dated in the twelve months before the row (from the same day twelve
///   months earlier up to the day before), and the row's own outflow is judged. When
///   there are fewer than six, the category basis judges each leg against the earlier
///   legs in its category instead. With at least six priors, `m` is their lower median
///   magnitude and `MAD` the lower median of their distances from `m`; a magnitude `v` is
///   flagged when `d = v − m` is above the median and `v ≥ 2m`, and then, with
///   `MAD > 0`, when `6745 × d > 35000 × MAD` (the modified z-score 0.6745 × d ÷ MAD
///   above 3.5), or, with `MAD = 0`, when `100 × d > 20 × m` and `d` is at least 5 major
///   units of the currency.
/// - **New merchant.** No live row at the merchant key, of any kind or account, in the
///   six months before the row (nor earlier the same day with a smaller id, so two first
///   visits on one day flag once), while the row's account has rows from at least six
///   months before it.
/// - **One flag per row.** Every leg (or the merchant outflow) is checked for an unusual
///   amount first; only when none is unusual can the row be a new merchant. A flag
///   carries the amount judged (`AnomalyFlag.amount`). The flags are sorted by date, then
///   transaction id, and depend only on the inputs.
library;

import 'package:finance_tracker/features/budgets/domain/budget_math.dart'
    show TransactionExclusion;
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// The fewest priors an unusual amount is judged on.
const int anomalyMinimumPriors = 6;

/// What a flag says about a transaction.
enum AnomalyKind { unusualAmount, newMerchant }

/// What an unusual amount was compared with.
enum AnomalyBasis { merchant, category }

/// A transaction worth a look, with the evidence.
final class AnomalyFlag {
  /// A flag.
  const AnomalyFlag({
    required this.kind,
    required this.transaction,
    required this.amount,
    this.basis,
    this.median,
    this.mad,
    this.since,
  });

  /// What the flag says.
  final AnomalyKind kind;

  /// The transaction flagged.
  final Transaction transaction;

  /// The outflow judged, in the app's sign: the transaction's outflow at its merchant
  /// (its considered legs summed), or the leg's when a leg was judged on its category.
  final Money amount;

  /// For an unusual amount: whether the merchant's or the category's history was used.
  final AnomalyBasis? basis;

  /// For an unusual amount: the priors' lower median, positive.
  final Money? median;

  /// For an unusual amount: the median absolute deviation of the priors.
  final Money? mad;

  /// For a new merchant: the start of the six months with no row at the merchant.
  final LocalDate? since;

  /// The transaction's id.
  String get transactionId => transaction.id;
}

bool _excludeNone(Transaction _) => false;

// One considered outflow of a transaction under [categoryId].
typedef _Leg = ({Money amount, String? categoryId});

// An earlier outflow a judgment compares with: its date and magnitude in minor units.
typedef _Prior = ({LocalDate date, int magnitude});

// What a judgment found: the median and the median absolute deviation of the priors.
typedef _Evidence = ({Money median, Money mad});

/// The flags on the rows of [transactions] dated in [window], judged against every row of
/// [transactions] (which must hold the year before the window and each account's first
/// row). [scheduledIds] are the recurring streams' members, [rules] the live rules,
/// [lookup] the live categories; [excluded] rows (the hidden ones) are neither flagged
/// nor counted as priors. See the library comment for the rule.
List<AnomalyFlag> detectAnomalies(
  Iterable<Transaction> transactions, {
  required LocalDateRange window,
  required CategoryLookup lookup,
  required Set<String> scheduledIds,
  required List<Rule> rules,
  TransactionExclusion excluded = _excludeNone,
  String Function(Transaction) merchantKey = recurringMerchantKey,
}) {
  final List<RuleCondition> merchantConditions = [
    for (final Rule r in rules)
      for (final RuleCondition c in r.conditions)
        if (c.kind == RuleConditionKind.merchantContains) c,
  ];
  final Map<String, String> keyOf = {};
  final Map<String, LocalDate> firstByAccount = {};
  // Every live row by merchant key, for "new merchant".
  final Map<String, List<Transaction>> rowsByKey = {};
  // The priors: one per transaction by currency and merchant key, one per leg by
  // currency and category.
  final Map<(String, String), List<_Prior>> byMerchant = {};
  final Map<(String, String), List<_Prior>> byCategory = {};
  final List<(Transaction, List<_Leg>, Money)> candidates = [];

  bool considered(Money amount, Category? category) {
    if (!amount.isNegative) return false;
    final String? code = categoryCode(category, lookup);
    return kindOf(code, amount) == TransactionKind.spend &&
        !(code != null &&
            (detectorExcludedCodes.contains(code) ||
                code.startsWith('LOAN_PAYMENTS') ||
                code.startsWith('LOAN_DISBURSEMENTS')));
  }

  for (final Transaction t in transactions) {
    if (t.deletedAt != null) continue;
    final String key = keyOf[t.id] = merchantKey(t);
    (rowsByKey[key] ??= []).add(t);
    final LocalDate? first = firstByAccount[t.accountId];
    if (first == null || t.date.isBefore(first)) {
      firstByAccount[t.accountId] = t.date;
    }
    if (excluded(t) ||
        scheduledIds.contains(t.id) ||
        merchantConditions.any((c) => conditionMatches(c, t))) {
      continue;
    }
    final String currency = t.amount.currencyCode;
    final List<_Leg> legs = t.splits.isEmpty
        ? [
            if (effectiveCategory(t, lookup) case final Category? c
                when considered(t.amount, c))
              (amount: t.amount, categoryId: c?.id),
          ]
        : [
            for (final TransactionSplit s in t.splits)
              if (s.amount.currencyCode == currency &&
                  considered(s.amount, lookup.byId[s.categoryId]))
                (amount: s.amount, categoryId: lookup.byId[s.categoryId]?.id),
          ];
    if (legs.isEmpty) continue;
    final Money outflow = Money.sum([
      for (final _Leg l in legs) l.amount,
    ], currencyCode: currency);
    (byMerchant[(currency, key)] ??= []).add((
      date: t.date,
      magnitude: -outflow.minorUnits,
    ));
    for (final _Leg l in legs) {
      if (l.categoryId case final String id) {
        (byCategory[(currency, id)] ??= []).add((
          date: t.date,
          magnitude: -l.amount.minorUnits,
        ));
      }
    }
    if (window.contains(t.date)) candidates.add((t, legs, outflow));
  }

  final List<AnomalyFlag> flags = [];
  for (final (Transaction t, List<_Leg> legs, Money outflow) in candidates) {
    final String currency = t.amount.currencyCode;
    final String key = keyOf[t.id]!;
    AnomalyFlag unusual(Money amount, AnomalyBasis basis, _Evidence e) =>
        AnomalyFlag(
          kind: AnomalyKind.unusualAmount,
          transaction: t,
          amount: amount,
          basis: basis,
          median: e.median,
          mad: e.mad,
        );

    final List<_Prior> merchantPriors = _priorsBefore(
      byMerchant[(currency, key)]!,
      t.date,
    );
    AnomalyFlag? flag;
    if (merchantPriors.length >= anomalyMinimumPriors) {
      if (_judge(outflow, merchantPriors) case final _Evidence e) {
        flag = unusual(outflow, AnomalyBasis.merchant, e);
      }
    } else {
      for (final _Leg l in legs) {
        final String? id = l.categoryId;
        if (id == null) continue;
        final List<_Prior> priors = _priorsBefore(
          byCategory[(currency, id)]!,
          t.date,
        );
        if (priors.length < anomalyMinimumPriors) continue;
        if (_judge(l.amount, priors) case final _Evidence e) {
          flag = unusual(l.amount, AnomalyBasis.category, e);
          break;
        }
      }
    }
    if (flag == null) {
      final LocalDate since = t.date.addMonths(-6);
      final bool history = !firstByAccount[t.accountId]!.isAfter(since);
      final bool seen = rowsByKey[key]!.any(
        (r) =>
            !r.date.isBefore(since) &&
            (r.date.isBefore(t.date) ||
                (r.date == t.date && r.id.compareTo(t.id) < 0)),
      );
      if (history && !seen) {
        flag = AnomalyFlag(
          kind: AnomalyKind.newMerchant,
          transaction: t,
          amount: outflow,
          since: since,
        );
      }
    }
    if (flag != null) flags.add(flag);
  }
  flags.sort((a, b) {
    final int byDate = a.transaction.date.compareTo(b.transaction.date);
    return byDate != 0 ? byDate : a.transactionId.compareTo(b.transactionId);
  });
  return List.unmodifiable(flags);
}

// The magnitudes of [priors] dated in the twelve months before [date].
List<_Prior> _priorsBefore(List<_Prior> priors, LocalDate date) {
  final LocalDate from = date.addMonths(-12);
  return [
    for (final _Prior p in priors)
      if (p.date.isBefore(date) && !p.date.isBefore(from)) p,
  ];
}

// The evidence when outflow [amount] is unusual against [priors] (at least
// [anomalyMinimumPriors] of them), else null.
_Evidence? _judge(Money amount, List<_Prior> priors) {
  final String currency = amount.currencyCode;
  final List<int> magnitudes = [for (final _Prior p in priors) p.magnitude];
  final int m = lowerMedian(magnitudes);
  final Money median = Money(m, currency);
  final Money mad = Money(
    lowerMedian([for (final int v in magnitudes) (v - m).abs()]),
    currency,
  );
  return isUnusualAmount(-amount, median, mad)
      ? (median: median, mad: mad)
      : null;
}

/// The lower middle of [values] once sorted (the middle one of an odd count, the lower
/// of the two middle ones of an even count). [values] must not be empty.
int lowerMedian(List<int> values) {
  final List<int> sorted = [...values]..sort();
  return sorted[(sorted.length - 1) ~/ 2];
}

/// Whether magnitude [v] is unusual against priors with lower median [m] and median
/// absolute deviation [mad], one currency: above the median and at least twice it, then
/// a modified z-score above 3.5 (`6745 × (v − m) > 35000 × mad`) when [mad] is
/// positive, else more than 20 % above the median and by at least 5 major units. `Money`
/// arithmetic, which throws rather than overflow.
bool isUnusualAmount(Money v, Money m, Money mad) {
  final Money d = v - m;
  if (!d.isPositive || v < m * 2) return false;
  if (mad.isPositive) return d * 6745 > mad * 35000;
  Money fiveMajor = Money(5, v.currencyCode);
  for (int i = 0; i < v.scale; i++) {
    fiveMajor = fiveMajor * 10;
  }
  return d * 100 > m * 20 && d >= fiveMajor;
}
