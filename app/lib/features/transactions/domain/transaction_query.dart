/// Which transactions to show: the filters, search and paging of the transaction list.
/// Pure Dart; an immutable value with equality, so it can key a provider family.
library;

import 'package:shared_models/shared_models.dart';

/// A query over transactions. Every filter is optional and the filters combine with AND:
///
/// - [accountIds]: on one of these accounts;
/// - [categoryIds]: with one of these as user category, or a split in one of them;
/// - [range]: dated within the half-open range;
/// - [text]: containing [text] in the name, the merchant name or the notes, ignoring
///   case for ASCII letters only (SQLite's `LIKE`; `%`, `_` and `\` match themselves);
/// - [pending]: pending or posted;
/// - [tags]: carrying at least one of these tags;
/// - [minAmount], [maxAmount]: whose absolute amount is at least or at most the bound,
///   among transactions in the bound's currency (the others do not match).
///
/// An empty set, a null or an empty [text] means no filter. [limit] (all when null) and
/// [offset] page the result.
final class TransactionQuery {
  /// A query. A negative [limit] or [offset], or bounds in two currencies, is an
  /// [ArgumentError].
  TransactionQuery({
    Set<String> accountIds = const {},
    Set<String> categoryIds = const {},
    this.range,
    this.text,
    this.pending,
    Set<String> tags = const {},
    this.minAmount,
    this.maxAmount,
    this.limit,
    this.offset = 0,
  }) : accountIds = Set.unmodifiable(accountIds),
       categoryIds = Set.unmodifiable(categoryIds),
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
  final LocalDateRange? range;
  final String? text;
  final bool? pending;
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
      other.range == range &&
      other.text == text &&
      other.pending == pending &&
      _sameSet(other.tags, tags) &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(accountIds),
    Object.hashAllUnordered(categoryIds),
    range,
    text,
    pending,
    Object.hashAllUnordered(tags),
    minAmount,
    maxAmount,
    limit,
    offset,
  );

  @override
  String toString() =>
      'TransactionQuery(accounts: $accountIds, categories: $categoryIds, '
      'range: $range, text: ${text == null ? null : '…'}, pending: $pending, '
      'tags: $tags, amount: $minAmount..$maxAmount, limit: $limit, offset: $offset)';
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
