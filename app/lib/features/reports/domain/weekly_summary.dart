/// The weekly summary (`docs/reference/reports.md`, **The weekly summary**): a week from
/// Monday to Sunday, its spending, income and net, its three biggest categories and its
/// biggest merchant. Pure Dart, integer `Money` only.
library;

import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// How many categories a weekly summary names.
const int weeklyTopCategories = 3;

/// The week, Monday to Sunday, that contains [day].
LocalDateRange weekContaining(LocalDate day) {
  final LocalDate monday = day.addDays(1 - day.weekday);
  return LocalDateRange(monday, monday.addDays(7));
}

/// A week's totals.
final class WeeklySummary {
  /// The summary of [week] from [entries] (`reportEntries`) dated on or before
  /// [through] (the week's Sunday when null), categories looked up in [lookup].
  WeeklySummary.of(
    LocalDateRange week,
    Iterable<ReportEntry> entries,
    CategoryLookup lookup, {
    required String currencyCode,
    LocalDate? through,
  }) : period = ReportPeriod.of(
         week,
         entries,
         lookup,
         currencyCode: currencyCode,
         through: through,
       );

  /// The week's totals.
  final ReportPeriod period;

  /// The week.
  LocalDateRange get week => period.range;

  /// The top-level categories spent most in, at most [weeklyTopCategories], none with
  /// nothing spent.
  List<CategoryTotal> get topCategories => [
    for (final CategoryTotal t in ReportPeriod.topLevel(period.spendByCategory))
      if (t.total.isPositive) t,
  ].take(weeklyTopCategories).toList();

  /// The merchant spent most at, or null.
  MerchantTotal? get topMerchant => switch (period.spendByMerchant) {
    [final MerchantTotal first, ...] when first.total.isPositive => first,
    _ => null,
  };
}
