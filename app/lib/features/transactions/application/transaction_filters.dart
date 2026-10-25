/// The transaction list's search and filters as the user sets them, and the
/// `TransactionQuery` they make on a given day. Pure Dart.
///
/// A date preset is kept as a preset, not as dates, so "This month" still means this
/// month after midnight on the last day; it is resolved against "today" (the clock's, in
/// the device zone) each time the query is built, and kept as a preset in the JSON a
/// saved filter holds ([TransactionFilters.toJson]).
library;

import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:shared_models/shared_models.dart';

/// The date range choices of the filter sheet.
enum DatePreset {
  thisMonth('this_month'),
  lastMonth('last_month'),
  last90Days('last_90_days'),
  thisYear('this_year'),
  custom('custom');

  const DatePreset(this.jsonName);

  /// The name in a saved filter's JSON.
  final String jsonName;
}

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
/// no filter; the amount bounds share one currency. Hidden transactions are left out
/// unless [showHidden].
final class TransactionFilters {
  const TransactionFilters({
    this.text = '',
    this.accountIds = const {},
    this.categoryIds = const {},
    this.date,
    this.minAmount,
    this.maxAmount,
    this.tags = const {},
    this.showHidden = false,
  });

  /// No search and no filter.
  static const TransactionFilters none = TransactionFilters();

  /// The filters [json] holds ([toJson]'s form). Keys it does not know are ignored, so
  /// a later version's additions do not stop an older one reading the rest; a known key
  /// with a value of the wrong shape is a [FormatException].
  factory TransactionFilters.fromJson(Map<String, Object?> json) {
    T read<T>(String key, T fallback) {
      final Object? value = json[key];
      if (value == null) return fallback;
      if (value is T) return value as T;
      throw FormatException('saved filter: "$key" is not a $T', json);
    }

    Set<String> strings(String key) => {
      for (final Object? v in read<List<Object?>>(key, const []))
        if (v is String)
          v
        else
          throw FormatException(
            'saved filter: "$key" holds a non-string',
            json,
          ),
    };

    Money? money(String key) {
      final Map<String, Object?>? value = read<Map<String, Object?>?>(
        key,
        null,
      );
      try {
        return value == null ? null : Money.fromJson(value);
      } on Object catch (e) {
        throw FormatException('saved filter: "$key" is not money ($e)', json);
      }
    }

    DateFilter? date() {
      final Map<String, Object?>? value = read<Map<String, Object?>?>(
        'date',
        null,
      );
      if (value == null) return null;
      final DatePreset? preset = DatePreset.values
          .where((p) => p.jsonName == value['preset'])
          .firstOrNull;
      if (preset == null) {
        throw FormatException('saved filter: unknown date preset', json);
      }
      if (preset != DatePreset.custom) return DateFilter(preset);
      try {
        return DateFilter.custom(
          LocalDateRange(
            LocalDate.parse(value['start']! as String),
            LocalDate.parse(value['end']! as String),
          ),
        );
      } on Object catch (e) {
        throw FormatException('saved filter: a bad custom range ($e)', json);
      }
    }

    return TransactionFilters(
      text: read<String>('text', ''),
      accountIds: strings('account_ids'),
      categoryIds: strings('category_ids'),
      date: date(),
      minAmount: money('min_amount'),
      maxAmount: money('max_amount'),
      tags: strings('tags'),
      showHidden: read<bool>('show_hidden', false),
    );
  }

  final String text;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final DateFilter? date;
  final Money? minAmount;
  final Money? maxAmount;
  final Set<String> tags;

  /// Whether hidden transactions are listed too.
  final bool showHidden;

  /// Whether a filter other than the search text is set ("Show hidden" counts: the list
  /// then holds more than its default).
  bool get hasFilters =>
      accountIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      date != null ||
      minAmount != null ||
      maxAmount != null ||
      tags.isNotEmpty ||
      showHidden;

  /// The query of these filters on [today], returning at most [limit] transactions. Each
  /// chosen category brings the categories [childrenOf] it gives along, and every
  /// category included brings its Plaid code ([plaidCodeOf]), so a transaction matches
  /// on its effective category (`effective_category.dart`). Hidden transactions are
  /// left out unless [showHidden].
  TransactionQuery toQuery(
    LocalDate today, {
    int? limit,
    Iterable<String> Function(String id) childrenOf = _noChildren,
    String? Function(String id) plaidCodeOf = _noPlaidCode,
  }) {
    final Set<String> included = {
      for (final String id in categoryIds) ...[id, ...childrenOf(id)],
    };
    return TransactionQuery(
      accountIds: accountIds,
      categoryIds: included,
      categoryPlaidCodes: {
        for (final String id in included)
          if (plaidCodeOf(id) case final String code) code,
      },
      range: date?.rangeOn(today),
      text: text.trim().isEmpty ? null : text.trim(),
      hidden: showHidden ? null : false,
      tags: tags,
      minAmount: minAmount,
      maxAmount: maxAmount,
      limit: limit,
    );
  }

  /// These filters as JSON, for a saved filter: only what is set, ids and tags sorted,
  /// a date preset by name (resolved only when a query is built), a custom range as its
  /// ISO dates (end exclusive), amounts as `Money`'s JSON.
  Map<String, Object?> toJson() => {
    if (text.isNotEmpty) 'text': text,
    if (accountIds.isNotEmpty) 'account_ids': accountIds.toList()..sort(),
    if (categoryIds.isNotEmpty) 'category_ids': categoryIds.toList()..sort(),
    if (date case final DateFilter date)
      'date': {
        'preset': date.preset.jsonName,
        if (date.customRange case final LocalDateRange range) ...{
          'start': range.start.toIso(),
          'end': range.end.toIso(),
        },
      },
    if (minAmount case final Money min) 'min_amount': min.toJson(),
    if (maxAmount case final Money max) 'max_amount': max.toJson(),
    if (tags.isNotEmpty) 'tags': tags.toList()..sort(),
    if (showHidden) 'show_hidden': true,
  };

  /// A copy with the search text [text].
  TransactionFilters withText(String text) => TransactionFilters(
    text: text,
    accountIds: accountIds,
    categoryIds: categoryIds,
    date: date,
    minAmount: minAmount,
    maxAmount: maxAmount,
    tags: tags,
    showHidden: showHidden,
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

  /// A copy that leaves hidden transactions out.
  TransactionFilters withoutHidden() => _copy(hideHidden: true);

  TransactionFilters _copy({
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tags,
    bool clearDate = false,
    bool clearAmount = false,
    bool hideHidden = false,
  }) => TransactionFilters(
    text: text,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    date: clearDate ? null : date,
    minAmount: clearAmount ? null : minAmount,
    maxAmount: clearAmount ? null : maxAmount,
    tags: tags ?? this.tags,
    showHidden: !hideHidden && showHidden,
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
      _same(other.tags, tags) &&
      other.showHidden == showHidden;

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAllUnordered(accountIds),
    Object.hashAllUnordered(categoryIds),
    date,
    minAmount,
    maxAmount,
    Object.hashAllUnordered(tags),
    showHidden,
  );
}

Iterable<String> _noChildren(String id) => const [];

String? _noPlaidCode(String id) => null;

bool _same(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
