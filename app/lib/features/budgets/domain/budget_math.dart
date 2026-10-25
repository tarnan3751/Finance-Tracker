/// What a budget stands at (`docs/reference/budgets.md`; `PLAN.md` §12, "Budget semantics
/// (4a)"): what was spent in a period, what carries over, how far along it is, where it
/// is heading and which alert thresholds it has reached. Pure Dart, integer `Money`
/// arithmetic only.
///
/// - **Spending** in a period is the net of the live transactions dated in it, in the
///   budget's currency, that the caller does not exclude (the hidden ones): a transaction
///   with splits contributes each split whose category is the budget's category or one of
///   its descendants; one without contributes its whole amount when its effective
///   category (`effective_category.dart`) is. Amounts are negated, so outflows count
///   positive and refunds negative; pending transactions count.
/// - **Rollover**: with `rollover`, every period since the one containing `startDate` and
///   before the current one carries its signed remainder (amount minus spent) forward.
/// - **Available** is the amount plus the carry; **remaining** is available minus spent;
///   **progress** is spent over available.
/// - **Projection** is linear on the elapsed days of the period: spent times the period's
///   length over the days from its start through today, rounded half-even. "Projected
///   overspend" means the projection is above available.
/// - **Thresholds**: 80 % and 100 % of available, each reached when spent is at least
///   that fraction; none when available is zero or less.
library;

import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// The alert thresholds, in basis points of what is available, ascending.
const List<int> budgetAlertThresholds = [8000, 10000];

/// Which transactions a budget leaves out besides deleted ones and other currencies (the
/// hidden ones, once transactions can be hidden).
typedef TransactionExclusion = bool Function(Transaction transaction);

bool _excludeNone(Transaction _) => false;

/// A fraction of two amounts' minor units: [numerator] over [denominator], never a
/// `double`.
final class Ratio {
  /// [spent] over [available], in one currency.
  Ratio.of(Money spent, Money available)
    : numerator = spent.minorUnits,
      denominator = available.minorUnits,
      percentBasisPoints = available.isPositive
          ? spent
                .multipliedBy(
                  10000,
                  available.minorUnits,
                  mode: RoundingMode.floor,
                )
                .minorUnits
          : null;

  /// The numerator, minor units.
  final int numerator;

  /// The denominator, minor units.
  final int denominator;

  /// The ratio in basis points (10000 is 100 %), rounded down so it never shows a
  /// threshold before it is reached; null when [denominator] is zero or less.
  final int? percentBasisPoints;

  @override
  bool operator ==(Object other) =>
      other is Ratio &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}

/// Where [budget] stands in [period], the period containing the day it was computed for.
final class BudgetStatus {
  /// A status; see [budgetStatus].
  const BudgetStatus({
    required this.budget,
    required this.period,
    required this.spent,
    required this.carried,
    required this.available,
    required this.remaining,
    required this.progress,
    required this.elapsedDays,
    required this.projected,
    required this.projectedOverspend,
    required this.thresholdsCrossed,
  });

  /// The budget.
  final Budget budget;

  /// The current period.
  final LocalDateRange period;

  /// What was spent in [period] (outflows positive, refunds negative).
  final Money spent;

  /// What the earlier periods carry into this one: zero without rollover.
  final Money carried;

  /// The amount plus [carried].
  final Money available;

  /// [available] minus [spent].
  final Money remaining;

  /// [spent] over [available].
  final Ratio progress;

  /// The days from the period's start through today, at least 1.
  final int elapsedDays;

  /// [spent] projected linearly to the end of the period.
  final Money projected;

  /// Whether [projected] is above [available].
  final bool projectedOverspend;

  /// The [budgetAlertThresholds] [spent] has reached, ascending.
  final List<int> thresholdsCrossed;
}

/// What was spent against [budget] in [period], in the budget's currency, from
/// [transactions] looked up in [lookup] (the live categories); [excluded] rows are left
/// out.
Money spentIn(
  LocalDateRange period,
  Budget budget,
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  TransactionExclusion excluded = _excludeNone,
}) {
  final Set<String> ids = budgetCategoryIds(budget.categoryId, lookup);
  Money spent = Money.zero(budget.amount.currencyCode);
  for (final Transaction t in transactions) {
    if (!period.contains(t.date)) continue;
    spent += _contribution(t, budget, ids, lookup, excluded);
  }
  return spent;
}

/// One row a budget counts: [transaction] whole when [split] is null, else that one
/// split of it.
typedef BudgetEntry = ({Transaction transaction, TransactionSplit? split});

/// The rows [spentIn] counts against [budget] in [period], in [transactions]' order: a
/// transaction whole, or each of its splits that qualifies.
List<BudgetEntry> entriesIn(
  LocalDateRange period,
  Budget budget,
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  TransactionExclusion excluded = _excludeNone,
}) {
  final Set<String> ids = budgetCategoryIds(budget.categoryId, lookup);
  return [
    for (final Transaction t in transactions)
      if (period.contains(t.date))
        ..._entries(t, budget, ids, lookup, excluded),
  ];
}

/// Where [budget] stands on [today] (the device zone's local date), from [transactions]
/// looked up in [lookup] (the live categories); [excluded] rows are left out.
/// [transactions] must hold every transaction dated from the first period's start through
/// the current period's end; others are ignored. A budget whose first period is after
/// today's still has a status for today's period, with nothing carried.
BudgetStatus budgetStatus(
  Budget budget,
  LocalDate today,
  Iterable<Transaction> transactions,
  CategoryLookup lookup, {
  TransactionExclusion excluded = _excludeNone,
}) {
  final int startDay = budget.periodStartDay;
  final LocalDateRange current = periodContaining(today, startDay);
  final Set<String> ids = budgetCategoryIds(budget.categoryId, lookup);
  final Money zero = Money.zero(budget.amount.currencyCode);

  // One pass: what each period spent, by its start.
  final Map<LocalDate, Money> spentByStart = {};
  for (final Transaction t in transactions) {
    if (!t.date.isBefore(current.end)) continue;
    final Money c = _contribution(t, budget, ids, lookup, excluded);
    if (c.isZero) continue;
    final LocalDate start = periodContaining(t.date, startDay).start;
    spentByStart[start] = (spentByStart[start] ?? zero) + c;
  }

  final Money spent = spentByStart[current.start] ?? zero;
  Money carried = zero;
  if (budget.rollover) {
    for (final LocalDateRange p in periodsFrom(
      budget.startDate,
      startDay,
      through: today,
    )) {
      if (!p.start.isBefore(current.start)) break;
      carried += budget.amount - (spentByStart[p.start] ?? zero);
    }
  }
  final Money available = budget.amount + carried;
  final int elapsedDays = current.start.daysUntil(today) + 1;
  final Money projected = spent.multipliedBy(current.length, elapsedDays);
  return BudgetStatus(
    budget: budget,
    period: current,
    spent: spent,
    carried: carried,
    available: available,
    remaining: available - spent,
    progress: Ratio.of(spent, available),
    elapsedDays: elapsedDays,
    projected: projected,
    projectedOverspend: projected > available,
    thresholdsCrossed: List.unmodifiable([
      if (available.isPositive)
        for (final int bp in budgetAlertThresholds)
          if (spent >= available.percent(bp, mode: RoundingMode.ceiling)) bp,
    ]),
  );
}

/// [categoryId] and the ids of every category in [lookup] below it: those whose parent
/// chain reaches it (a parent category budgets its group).
Set<String> budgetCategoryIds(String categoryId, CategoryLookup lookup) {
  final Set<String> ids = {categoryId};
  for (final Category category in lookup.byId.values) {
    final Set<String> seen = {};
    String? parent = category.parentId;
    while (parent != null && seen.add(parent)) {
      if (parent == categoryId) {
        ids.add(category.id);
        break;
      }
      parent = lookup.byId[parent]?.parentId;
    }
  }
  return ids;
}

// What [t] adds to [budget]'s spending: its entries' amounts, negated.
Money _contribution(
  Transaction t,
  Budget budget,
  Set<String> ids,
  CategoryLookup lookup,
  TransactionExclusion excluded,
) {
  Money spent = Money.zero(budget.amount.currencyCode);
  for (final BudgetEntry e in _entries(t, budget, ids, lookup, excluded)) {
    spent -= e.split?.amount ?? e.transaction.amount;
  }
  return spent;
}

// What of [t] counts against [budget]: nothing unless it is live, not excluded, in the
// budget's currency and in one of [ids]; then each split in [ids] when it has splits,
// else the whole transaction.
Iterable<BudgetEntry> _entries(
  Transaction t,
  Budget budget,
  Set<String> ids,
  CategoryLookup lookup,
  TransactionExclusion excluded,
) sync* {
  final String currency = budget.amount.currencyCode;
  if (t.deletedAt != null || t.amount.currencyCode != currency || excluded(t)) {
    return;
  }
  if (t.splits.isNotEmpty) {
    for (final TransactionSplit split in t.splits) {
      if (ids.contains(split.categoryId) &&
          split.amount.currencyCode == currency) {
        yield (transaction: t, split: split);
      }
    }
    return;
  }
  final Category? category = effectiveCategory(t, lookup);
  if (category != null && ids.contains(category.id)) {
    yield (transaction: t, split: null);
  }
}
