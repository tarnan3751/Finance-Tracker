/// What the live transactions use: their distinct tags, and the categories and accounts
/// used most recently. Pure Dart; an immutable value with equality.
library;

/// The tags, recent categories and recent accounts of the live transactions
/// (`TransactionRepository.watchUsage`).
///
/// - [tags]: every tag on a live transaction, once, in BINARY order (UTF-8 bytes);
/// - [recentCategoryIds]: the user categories of live transactions, most recently used
///   first (by the newest `createdAt` among the transactions filed under each, ties by
///   id in BINARY order), at most the limit asked for; splits do not count;
/// - [recentAccountIds]: the accounts of live transactions, ordered and limited the same
///   way.
final class TransactionUsage {
  const TransactionUsage({
    required this.tags,
    required this.recentCategoryIds,
    required this.recentAccountIds,
  });

  /// No transactions.
  static const TransactionUsage empty = TransactionUsage(
    tags: [],
    recentCategoryIds: [],
    recentAccountIds: [],
  );

  final List<String> tags;
  final List<String> recentCategoryIds;
  final List<String> recentAccountIds;

  @override
  bool operator ==(Object other) =>
      other is TransactionUsage &&
      _same(other.tags, tags) &&
      _same(other.recentCategoryIds, recentCategoryIds) &&
      _same(other.recentAccountIds, recentAccountIds);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tags),
    Object.hashAll(recentCategoryIds),
    Object.hashAll(recentAccountIds),
  );

  @override
  String toString() =>
      'TransactionUsage(${tags.length} tags, categories: $recentCategoryIds, '
      'accounts: $recentAccountIds)';
}

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
