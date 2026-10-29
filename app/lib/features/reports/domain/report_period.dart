/// What a period's transactions add up to (`docs/reference/reports.md`, **Periods**):
/// spending, income and transfers, by category with the parent roll-up and by merchant,
/// and the savings rate. Pure Dart, integer `Money` only.
///
/// Spending is counted positive (an outflow adds to it, a refund takes from it), income
/// positive (an inflow adds to it), transfers in the app's sign. So
/// `income − spend + transferNet` is the sum of every counted amount.
library;

import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:shared_models/shared_models.dart';

/// A category's part of a period: its [own] rows and its [total], which adds its
/// children's totals. [categoryId] null is "Uncategorized".
final class CategoryTotal {
  /// A total.
  const CategoryTotal({
    required this.categoryId,
    required this.parentId,
    required this.own,
    required this.total,
  });

  /// The category, or null for the uncategorized rows.
  final String? categoryId;

  /// The live parent it rolls up into, or null at the top level.
  final String? parentId;

  /// What the rows under this category itself add up to.
  final Money own;

  /// [own] plus every child's total.
  final Money total;
}

/// What the spending at one merchant adds up to in a period.
final class MerchantTotal {
  /// A total.
  const MerchantTotal({
    required this.key,
    required this.displayName,
    required this.total,
    required this.count,
  });

  /// The merchant key (`recurringMerchantKey`).
  final String key;

  /// The name of the newest row's merchant, as the app shows it.
  final String displayName;

  /// The spending, positive.
  final Money total;

  /// The rows counted.
  final int count;
}

/// What the rows dated in [range] up to [through] add up to, in [currencyCode].
final class ReportPeriod {
  ReportPeriod._({
    required this.range,
    required this.through,
    required this.currencyCode,
    required this.spend,
    required this.income,
    required this.transferNet,
    required this.counts,
    required this.spendByCategory,
    required this.incomeByCategory,
    required this.spendByMerchant,
  });

  /// The totals of [entries] (`reportEntries`) dated in [range] on or before [through]
  /// (the range's last day when null), categories looked up in [lookup].
  factory ReportPeriod.of(
    LocalDateRange range,
    Iterable<ReportEntry> entries,
    CategoryLookup lookup, {
    required String currencyCode,
    LocalDate? through,
  }) {
    final LocalDate last = range.isEmpty ? range.start : range.end.addDays(-1);
    final LocalDate counted = through == null || through.isAfter(last)
        ? last
        : through;
    final Money zero = Money.zero(currencyCode);
    Money spend = zero;
    Money income = zero;
    Money transfers = zero;
    final Map<TransactionKind, int> counts = {
      for (final TransactionKind k in TransactionKind.values) k: 0,
    };
    final Map<String?, Money> spendOwn = {};
    final Map<String?, Money> incomeOwn = {};
    final Map<String, ({Money total, int count, Transaction newest})>
    merchants = {};
    for (final ReportEntry e in entries) {
      if (!range.contains(e.date) || e.date.isAfter(counted)) continue;
      counts[e.kind] = counts[e.kind]! + 1;
      switch (e.kind) {
        case TransactionKind.spend:
          spend -= e.amount;
          spendOwn[e.categoryId] = (spendOwn[e.categoryId] ?? zero) - e.amount;
          final String key = recurringMerchantKey(e.transaction);
          final m = merchants[key];
          merchants[key] = (
            total: (m?.total ?? zero) - e.amount,
            count: (m?.count ?? 0) + 1,
            newest: m == null || _newer(e.transaction, m.newest)
                ? e.transaction
                : m.newest,
          );
        case TransactionKind.income:
          income += e.amount;
          incomeOwn[e.categoryId] =
              (incomeOwn[e.categoryId] ?? zero) + e.amount;
        case TransactionKind.transfer:
          transfers += e.amount;
      }
    }
    return ReportPeriod._(
      range: range,
      through: counted,
      currencyCode: currencyCode,
      spend: spend,
      income: income,
      transferNet: transfers,
      counts: Map.unmodifiable(counts),
      spendByCategory: _rollUp(spendOwn, lookup, zero),
      incomeByCategory: _rollUp(incomeOwn, lookup, zero),
      spendByMerchant: List.unmodifiable(
        <MerchantTotal>[
          for (final MapEntry(:key, :value) in merchants.entries)
            MerchantTotal(
              key: key,
              displayName: EnrichedMerchant.resolve(value.newest).displayName,
              total: value.total,
              count: value.count,
            ),
        ]..sort((a, b) {
          final int byTotal = b.total.compareTo(a.total);
          return byTotal != 0 ? byTotal : a.key.compareTo(b.key);
        }),
      ),
    );
  }

  /// The period.
  final LocalDateRange range;

  /// The last day counted: the range's last day, or today in a period still running.
  final LocalDate through;

  /// The currency of every amount.
  final String currencyCode;

  /// The spending, outflows positive and refunds negative.
  final Money spend;

  /// The income, inflows positive.
  final Money income;

  /// The transfers' sum, in the app's sign.
  final Money transferNet;

  /// The rows counted, by kind.
  final Map<TransactionKind, int> counts;

  /// Every category with spending in the period or below it, by total, largest first,
  /// then by id (the uncategorized rows last on a tie).
  final List<CategoryTotal> spendByCategory;

  /// The same for income.
  final List<CategoryTotal> incomeByCategory;

  /// The spending by merchant, largest first, then by key.
  final List<MerchantTotal> spendByMerchant;

  /// Whether the period was counted only up to [through], before its last day.
  bool get partial => through.isBefore(range.end.addDays(-1));

  /// The days counted, from the start through [through].
  int get elapsedDays => range.start.daysUntil(through) + 1;

  /// Income less spending.
  Money get net => income - spend;

  /// What was kept of the income, in basis points of it ((income − spend) × 10000 ÷
  /// income, rounded down); null when there was no income.
  int? get savingsRateBasisPoints => income.isPositive
      ? net
            .multipliedBy(10000, income.minorUnits, mode: RoundingMode.floor)
            .minorUnits
      : null;

  /// The top-level categories (no live parent) of [totals], in its order.
  static List<CategoryTotal> topLevel(List<CategoryTotal> totals) => [
    for (final CategoryTotal t in totals)
      if (t.parentId == null) t,
  ];

  /// The children of [parentId] in [totals], in its order.
  static List<CategoryTotal> childrenOf(
    List<CategoryTotal> totals,
    String parentId,
  ) => [
    for (final CategoryTotal t in totals)
      if (t.parentId == parentId) t,
  ];
}

// Whether [a] is newer than [b]: a later date, then a greater id.
bool _newer(Transaction a, Transaction b) {
  final int byDate = a.date.compareTo(b.date);
  return byDate != 0 ? byDate > 0 : a.id.compareTo(b.id) > 0;
}

// The live parent of [id] in [lookup], or null.
String? _parentOf(String? id, CategoryLookup lookup) {
  final String? parent = lookup.byId[id]?.parentId;
  return lookup.byId.containsKey(parent) ? parent : null;
}

// [own] rolled up: each amount added to its category and every live ancestor, so a
// category's total is its own rows plus its children's totals.
List<CategoryTotal> _rollUp(
  Map<String?, Money> own,
  CategoryLookup lookup,
  Money zero,
) {
  final Map<String?, Money> totals = {};
  for (final MapEntry(:key, :value) in own.entries) {
    final Set<String?> seen = {key};
    String? id = key;
    totals[id] = (totals[id] ?? zero) + value;
    while ((id = _parentOf(id, lookup)) != null && seen.add(id)) {
      totals[id] = (totals[id] ?? zero) + value;
    }
  }
  return List.unmodifiable(
    <CategoryTotal>[
      for (final MapEntry(:key, :value) in totals.entries)
        CategoryTotal(
          categoryId: key,
          parentId: _parentOf(key, lookup),
          own: own[key] ?? zero,
          total: value,
        ),
    ]..sort((a, b) {
      final int byTotal = b.total.compareTo(a.total);
      if (byTotal != 0) return byTotal;
      if (a.categoryId == null) return 1;
      if (b.categoryId == null) return -1;
      return a.categoryId!.compareTo(b.categoryId!);
    }),
  );
}
