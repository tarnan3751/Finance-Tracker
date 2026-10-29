/// A period's report with its comparisons (`docs/reference/reports.md`, **Comparisons**,
/// **Top movers**, **Trends**; `PLAN.md` §12 "Reports and insights"). Pure Dart, integer
/// `Money` only.
///
/// - **Comparisons:** the period against the one before (month over month) and the one
///   twelve periods before (year over year). While the period is still running, both are
///   counted over the same number of days from their start (the same elapsed day),
///   clamped to their own length.
/// - **Top movers:** the categories (each its own rows, not rolled up) and the merchants
///   whose spending changed most against the period before, by the absolute change,
///   then by id; at most ten of each, none that did not change. The percent is the
///   change over the earlier amount; "new" when that was zero.
/// - **Trends:** the spending and income of the last twelve periods, ending with this
///   one (counted to today while it runs); the last six are the short trend.
library;

import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// How many movers of each kind a report lists.
const int topMoverLimit = 10;

/// How many periods the long trend covers; the short one covers [shortTrendPeriods].
const int longTrendPeriods = 12;

/// How many periods the short trend covers.
const int shortTrendPeriods = 6;

/// An amount against an earlier one.
final class Change {
  /// [current] against [previous], one currency.
  const Change(this.current, this.previous);

  /// The amount now.
  final Money current;

  /// The amount compared with.
  final Money previous;

  /// [current] less [previous].
  Money get change => current - previous;

  /// The change in basis points of [previous]'s magnitude, rounded half-even; null when
  /// [previous] is zero ("new").
  int? get percentBasisPoints => previous.isZero
      ? null
      : change.multipliedBy(10000, previous.abs().minorUnits).minorUnits;
}

/// A category or a merchant whose spending moved.
final class Mover {
  /// A mover.
  const Mover({
    required this.id,
    required this.displayName,
    required this.change,
  });

  /// The category id (null for the uncategorized rows), or the merchant key.
  final String? id;

  /// The merchant's name as the app shows it; null for a category.
  final String? displayName;

  /// The spending now against the period before.
  final Change change;
}

/// One period of a trend.
final class TrendPoint {
  /// A point.
  const TrendPoint({
    required this.range,
    required this.spend,
    required this.income,
  });

  /// The period.
  final LocalDateRange range;

  /// Its spending.
  final Money spend;

  /// Its income.
  final Money income;

  /// Income less spending.
  Money get net => income - spend;
}

/// A period's report: its totals, the comparisons, the movers and the trend.
final class Report {
  /// A report.
  const Report({
    required this.current,
    required this.previous,
    required this.yearAgo,
    required this.categoryMovers,
    required this.merchantMovers,
    required this.trend,
  });

  /// The period shown, counted to today while it runs.
  final ReportPeriod current;

  /// The period before, over the same elapsed days while [current] runs.
  final ReportPeriod previous;

  /// The period twelve before, likewise.
  final ReportPeriod yearAgo;

  /// The categories whose spending moved most.
  final List<Mover> categoryMovers;

  /// The merchants whose spending moved most.
  final List<Mover> merchantMovers;

  /// The last [longTrendPeriods] periods, oldest first, ending with [current].
  final List<TrendPoint> trend;

  /// The last [shortTrendPeriods] of [trend].
  List<TrendPoint> get shortTrend =>
      trend.sublist(trend.length - shortTrendPeriods);

  /// Spending against the period before.
  Change get spendMonthOverMonth => Change(current.spend, previous.spend);

  /// Income against the period before.
  Change get incomeMonthOverMonth => Change(current.income, previous.income);

  /// Spending against the period a year before.
  Change get spendYearOverYear => Change(current.spend, yearAgo.spend);

  /// Income against the period a year before.
  Change get incomeYearOverYear => Change(current.income, yearAgo.income);
}

/// The report of [period] (a period of [periodStartDay]) seen on [today], in
/// [currencyCode], from [entries] (`reportEntries`, which must cover the twelve periods
/// before it) with categories in [lookup].
Report buildReport({
  required LocalDateRange period,
  required int periodStartDay,
  required LocalDate today,
  required String currencyCode,
  required List<ReportEntry> entries,
  required CategoryLookup lookup,
}) {
  final bool running = period.contains(today);
  ReportPeriod periodAtOffset(int offset, {required bool sameElapsed}) {
    final LocalDateRange range = periodAt(period.start, periodStartDay, offset);
    final LocalDate? through = running && sameElapsed
        ? range.start.addDays(period.start.daysUntil(today))
        : running && offset == 0
        ? today
        : null;
    return ReportPeriod.of(
      range,
      entries,
      lookup,
      currencyCode: currencyCode,
      through: through,
    );
  }

  final ReportPeriod current = periodAtOffset(0, sameElapsed: false);
  final ReportPeriod previous = periodAtOffset(-1, sameElapsed: true);
  final ReportPeriod yearAgo = periodAtOffset(-12, sameElapsed: true);
  final Money zero = Money.zero(currencyCode);

  final Map<String?, Money> nowByCategory = {
    for (final CategoryTotal t in current.spendByCategory)
      if (!t.own.isZero) t.categoryId: t.own,
  };
  final Map<String?, Money> thenByCategory = {
    for (final CategoryTotal t in previous.spendByCategory)
      if (!t.own.isZero) t.categoryId: t.own,
  };
  final Map<String, MerchantTotal> nowByMerchant = {
    for (final MerchantTotal m in current.spendByMerchant) m.key: m,
  };
  final Map<String, MerchantTotal> thenByMerchant = {
    for (final MerchantTotal m in previous.spendByMerchant) m.key: m,
  };

  return Report(
    current: current,
    previous: previous,
    yearAgo: yearAgo,
    categoryMovers: _top([
      for (final String? id in {...nowByCategory.keys, ...thenByCategory.keys})
        Mover(
          id: id,
          displayName: null,
          change: Change(nowByCategory[id] ?? zero, thenByCategory[id] ?? zero),
        ),
    ]),
    merchantMovers: _top([
      for (final String key in {...nowByMerchant.keys, ...thenByMerchant.keys})
        Mover(
          id: key,
          displayName: (nowByMerchant[key] ?? thenByMerchant[key])!.displayName,
          change: Change(
            nowByMerchant[key]?.total ?? zero,
            thenByMerchant[key]?.total ?? zero,
          ),
        ),
    ]),
    trend: List.unmodifiable([
      for (int offset = 1 - longTrendPeriods; offset <= 0; offset++)
        () {
          final ReportPeriod p = offset == 0
              ? current
              : periodAtOffset(offset, sameElapsed: false);
          return TrendPoint(range: p.range, spend: p.spend, income: p.income);
        }(),
    ]),
  );
}

// The movers that changed, by the change's magnitude, largest first, then by id (null
// last), at most [topMoverLimit].
List<Mover> _top(List<Mover> movers) {
  final List<Mover> moved =
      [
        for (final Mover m in movers)
          if (!m.change.change.isZero) m,
      ]..sort((a, b) {
        final int bySize = b.change.change.abs().compareTo(
          a.change.change.abs(),
        );
        if (bySize != 0) return bySize;
        if (a.id == null) return 1;
        if (b.id == null) return -1;
        return a.id!.compareTo(b.id!);
      });
  return List.unmodifiable(moved.take(topMoverLimit));
}
