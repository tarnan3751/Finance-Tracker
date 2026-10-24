/// The transaction list's search and filters as the user sets them, and the
/// `TransactionQuery` they make on a given day. Pure Dart.
///
/// A date preset is kept as a preset, not as dates, so "This month" still means this
/// month after midnight on the last day; it is resolved against "today" (the clock's, in
/// the device zone) each time the query is built.
library;

import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:shared_models/shared_models.dart';

/// The date range choices of the filter sheet.
enum DatePreset { thisMonth, lastMonth, last90Days, thisYear, custom }

/// A date filter: a preset, or [DatePreset.custom] with its [customRange].
final class DateFilter {
  /// A preset other than [DatePreset.custom].
  const DateFilter(this.preset) : customRange = null;

  /// The custom range [range], half-open.
  const DateFilter.custom(LocalDateRange range)
    : preset = DatePreset.custom,
      customRange = range;

  final DatePreset preset;
  final LocalDateRange? customRange;

  /// The half-open range this filter means when today is [today].
  LocalDateRange rangeOn(LocalDate today) => switch (preset) {
    DatePreset.thisMonth => LocalDateRange(
      today.firstOfMonth,
      today.firstOfMonth.addMonths(1),
    ),
    DatePreset.lastMonth => LocalDateRange(
      today.firstOfMonth.addMonths(-1),
      today.firstOfMonth,
    ),
    DatePreset.last90Days => LocalDateRange(
      today.addDays(-89),
      today.addDays(1),
    ),
    DatePreset.thisYear => LocalDateRange(
      LocalDate(today.year, 1, 1),
      LocalDate(today.year, 1, 1).addMonths(12),
    ),
    DatePreset.custom => customRange!,
  };

  @override
  bool operator ==(Object other) =>
      other is DateFilter &&
      other.preset == preset &&
      other.customRange == customRange;

  @override
  int get hashCode => Object.hash(preset, customRange);
}

/// The search text and the filters of the transaction list. Empty sets and nulls mean
/// no filter; the amount bounds share one currency.
final class TransactionFilters {
  const TransactionFilters({
    this.text = '',
    this.accountIds = const {},
    this.categoryIds = const {},
    this.date,
    this.minAmount,
    this.maxAmount,
    this.tags = const {},
  });

  /// No search and no filter.
  static const TransactionFilters none = TransactionFilters();

  final String text;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final DateFilter? date;
  final Money? minAmount;
  final Money? maxAmount;
  final Set<String> tags;

  /// Whether a filter other than the search text is set.
  bool get hasFilters =>
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      date != null ||
      minAmount != null ||
      maxAmount != null ||
      tags.isNotEmpty;

  /// The query of these filters on [today], returning at most [limit] transactions. Each
  /// chosen category brings the categories [childrenOf] it gives along.
  TransactionQuery toQuery(
    LocalDate today, {
    int? limit,
    Iterable<String> Function(String id) childrenOf = _noChildren,
  }) => TransactionQuery(
    accountIds: accountIds,
    categoryIds: {
      for (final String id in categoryIds) ...[id, ...childrenOf(id)],
    },
    range: date?.rangeOn(today),
    text: text.trim().isEmpty ? null : text.trim(),
    tags: tags,
    minAmount: minAmount,
    maxAmount: maxAmount,
    limit: limit,
  );

  /// A copy with the search text [text].
  TransactionFilters withText(String text) => TransactionFilters(
    text: text,
    accountIds: accountIds,
    categoryIds: categoryIds,
    date: date,
    minAmount: minAmount,
    maxAmount: maxAmount,
    tags: tags,
  );

  /// A copy without account [id].
  TransactionFilters withoutAccount(String id) =>
      _copy(accountIds: {...accountIds}..remove(id));

  /// A copy without category [id].
  TransactionFilters withoutCategory(String id) =>
      _copy(categoryIds: {...categoryIds}..remove(id));

  /// A copy without tag [tag].
  TransactionFilters withoutTag(String tag) =>
      _copy(tags: {...tags}..remove(tag));

  /// A copy without the date filter.
  TransactionFilters withoutDate() => _copy(clearDate: true);

  /// A copy without the amount bounds.
  TransactionFilters withoutAmount() => _copy(clearAmount: true);

  TransactionFilters _copy({
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tags,
    bool clearDate = false,
    bool clearAmount = false,
  }) => TransactionFilters(
    text: text,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    date: clearDate ? null : date,
    minAmount: clearAmount ? null : minAmount,
    maxAmount: clearAmount ? null : maxAmount,
    tags: tags ?? this.tags,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilters &&
      other.text == text &&
      _same(other.accountIds, accountIds) &&
      _same(other.categoryIds, categoryIds) &&
      other.date == date &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      _same(other.tags, tags);

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAllUnordered(accountIds),
    Object.hashAllUnordered(categoryIds),
    date,
    minAmount,
    maxAmount,
    Object.hashAllUnordered(tags),
  );
}

Iterable<String> _noChildren(String id) => const [];

bool _same(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
