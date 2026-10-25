/// Which transactions to show: the filters, search and paging of the transaction list.
/// Pure Dart; an immutable value with equality, so it can key a provider family.
library;

import 'package:shared_models/shared_models.dart';

/// A query over transactions. Every filter is optional and the filters combine with AND:
///
/// - [accountIds]: on one of these accounts;
/// - [categoryIds] and [categoryPlaidCodes]: with one of [categoryIds] as user category,
///   or a split in one of them; or, when its user category is unset or names no live
///   category, whose Plaid code resolves to a category (`effective_category.dart`) whose
///   `plaidCategory` is one of [categoryPlaidCodes]: its detailed code when a live
///   category has that code, else its primary code;
/// - [range]: dated within the half-open range;
/// - [text]: every whitespace-separated term of [text] found in the name, the merchant
///   name, the notes or the tags, as words in a row with the last one a prefix, ignoring
///   case and Latin diacritics (the full-text index, `search_text.dart`); a term with no
///   letter or digit matches nothing. Only on a SQLite without FTS5, the Drift
///   repository falls back to [text] as one substring of the name, merchant name or
///   notes, ignoring case for ASCII letters only (`LIKE`);
/// - [pending]: pending or posted;
/// - [hidden]: hidden by the user or not (null: both; the list's default is false);
/// - [tags]: carrying at least one of these tags;
/// - [minAmount], [maxAmount]: whose absolute amount is at least or at most the bound,
///   among transactions in the bound's currency (the others do not match).
///
/// An empty set, a null, or a [text] with no term (empty or whitespace) means no filter. [limit] (all when null) and
/// [offset] page the result.
final class TransactionQuery {
  /// A query. A negative [limit] or [offset], or bounds in two currencies, is an
  /// [ArgumentError].
  TransactionQuery({
    Set<String> accountIds = const {},
    Set<String> categoryIds = const {},
    Set<String> categoryPlaidCodes = const {},
    this.range,
    this.text,
    this.pending,
    this.hidden,
    Set<String> tags = const {},
    this.minAmount,
    this.maxAmount,
    this.limit,
    this.offset = 0,
  }) : accountIds = Set.unmodifiable(accountIds),
       categoryIds = Set.unmodifiable(categoryIds),
       categoryPlaidCodes = Set.unmodifiable(categoryPlaidCodes),
       tags = Set.unmodifiable(tags) {
    if (limit != null && limit! < 0) {
      throw ArgumentError.value(limit, 'limit', 'must not be negative');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    final Money? min = minAmount;
    final Money? max = maxAmount;
    if (min != null && max != null && min.currencyCode != max.currencyCode) {
      throw ArgumentError('minAmount and maxAmount must share a currency');
    }
  }

  /// Every live transaction.
  static final TransactionQuery all = TransactionQuery();

  final Set<String> accountIds;
  final Set<String> categoryIds;
  final Set<String> categoryPlaidCodes;
  final LocalDateRange? range;
  final String? text;
  final bool? pending;
  final bool? hidden;
  final Set<String> tags;
  final Money? minAmount;
  final Money? maxAmount;
  final int? limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is TransactionQuery &&
      _sameSet(other.accountIds, accountIds) &&
      _sameSet(other.categoryIds, categoryIds) &&
      _sameSet(other.categoryPlaidCodes, categoryPlaidCodes) &&
      other.range == range &&
      other.text == text &&
      other.pending == pending &&
      other.hidden == hidden &&
      _sameSet(other.tags, tags) &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(accountIds),
    Object.hashAllUnordered(categoryIds),
    Object.hashAllUnordered(categoryPlaidCodes),
    range,
    text,
    pending,
    hidden,
    Object.hashAllUnordered(tags),
    minAmount,
    maxAmount,
    limit,
    offset,
  );

  @override
  String toString() =>
      'TransactionQuery(accounts: $accountIds, categories: $categoryIds, '
      'codes: $categoryPlaidCodes, range: $range, text: ${text == null ? null : '…'}, pending: $pending, hidden: $hidden, '
      'tags: $tags, amount: $minAmount..$maxAmount, limit: $limit, offset: $offset)';
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
