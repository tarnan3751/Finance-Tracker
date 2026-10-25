/// Likely duplicate transactions, for the user to review (`docs/reference/duplicates.md`).
/// Pure Dart and deterministic: the result depends only on the transactions and the pairs
/// the user dismissed, never on their order. Nothing here merges or deletes anything
/// (`PLAN.md` §12: a heuristic never destroys user-authored data).
///
/// Two transactions are a candidate pair when:
///
/// - both are live, neither is hidden (the user has already set one aside) and neither is
///   `derived` (a value the app computed, not a record);
/// - their dates are at most [duplicateWindowDays] calendar days apart;
/// - their amounts are equal, sign and currency included (an outflow's duplicate is an
///   outflow; the two legs of a transfer are not duplicates);
/// - they are on different accounts, whatever their sources; or, on one account, one is
///   bank data (`plaid`, or `demo` in the demo flavor) and the other was entered
///   (`manual` or `import`). Two bank rows of one account never pair: the bank already
///   deduplicates its own feed.
///
/// Each pair is reported once, its ids in SQLite's `BINARY` order ([PairKey]), and a pair
/// the user dismissed is left out. The pairs are ranked by the days between them, then by
/// how alike their names are ([nameSimilarity]), then the newer pair first, then by key.
/// The work is a sort by amount and date and a scan of each amount's rows within the
/// window: O(n log n), plus the pairs found.
library;

import 'package:finance_tracker/core/util/binary_compare.dart';
import 'package:shared_models/shared_models.dart';

/// How many calendar days apart two duplicates' dates may be, inclusive.
const int duplicateWindowDays = 3;

/// A pair of transaction ids in SQLite's `BINARY` order, whichever way round it was
/// found: how a dismissed pair is remembered.
final class PairKey {
  /// The pair of [a] and [b], in order.
  factory PairKey(String a, String b) =>
      compareBinary(a, b) <= 0 ? PairKey._(a, b) : PairKey._(b, a);

  const PairKey._(this.first, this.second);

  /// The id that sorts first.
  final String first;

  /// The id that sorts second.
  final String second;

  @override
  bool operator ==(Object other) =>
      other is PairKey && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => 'PairKey($first, $second)';
}

/// How alike two names are: the words they share over the words either has, as a
/// fraction of integers (no `double`, so the ranking is the same on every device).
typedef NameSimilarity = ({int shared, int total});

/// Two transactions that may be one.
final class DuplicateCandidate {
  /// The pair of [first] and [second], whose ids are in `BINARY` order.
  const DuplicateCandidate({
    required this.first,
    required this.second,
    required this.dayDistance,
    required this.similarity,
  });

  /// The transaction whose id sorts first.
  final Transaction first;

  /// The other.
  final Transaction second;

  /// The calendar days between their dates.
  final int dayDistance;

  /// How alike their names are.
  final NameSimilarity similarity;

  /// The pair's key.
  PairKey get key => PairKey._(first.id, second.id);
}

/// The candidate pairs among [transactions], ranked, without the [dismissed] ones.
List<DuplicateCandidate> findDuplicates(
  List<Transaction> transactions, {
  Set<PairKey> dismissed = const {},
}) {
  final List<Transaction> rows = [
    for (final Transaction t in transactions)
      if (t.deletedAt == null && !t.hidden && t.source != DataSource.derived) t,
  ]..sort(_byAmountThenDate);
  final List<DuplicateCandidate> found = [];
  for (int i = 0; i < rows.length; i++) {
    final Transaction a = rows[i];
    for (int j = i + 1; j < rows.length; j++) {
      final Transaction b = rows[j];
      if (b.amount != a.amount) break;
      final int days = a.date.daysUntil(b.date);
      if (days > duplicateWindowDays) break;
      if (a.id == b.id || !_mayPair(a, b)) continue;
      final PairKey key = PairKey(a.id, b.id);
      if (dismissed.contains(key)) continue;
      final bool inOrder = key.first == a.id;
      found.add(
        DuplicateCandidate(
          first: inOrder ? a : b,
          second: inOrder ? b : a,
          dayDistance: days,
          similarity: nameSimilarity(a, b),
        ),
      );
    }
  }
  return found..sort(_byRank);
}

/// How alike the names of [a] and [b] are: their name and merchant name taken as
/// lowercase words of letters and digits, the words both have over the words either has.
NameSimilarity nameSimilarity(Transaction a, Transaction b) {
  final Set<String> x = _words(a);
  final Set<String> y = _words(b);
  return (shared: x.intersection(y).length, total: x.union(y).length);
}

final RegExp _separators = RegExp('[^a-z0-9]+');

Set<String> _words(Transaction t) => {
  for (final String text in [t.name, ?t.merchantName])
    for (final String word in text.toLowerCase().split(_separators))
      if (word.isNotEmpty) word,
};

bool _isBank(DataSource s) => s == DataSource.plaid || s == DataSource.demo;

bool _isEntered(DataSource s) =>
    s == DataSource.manual || s == DataSource.import;

bool _mayPair(Transaction a, Transaction b) =>
    a.accountId != b.accountId ||
    (_isBank(a.source) && _isEntered(b.source)) ||
    (_isEntered(a.source) && _isBank(b.source));

int _byAmountThenDate(Transaction a, Transaction b) {
  final int byCurrency = compareBinary(
    a.amount.currencyCode,
    b.amount.currencyCode,
  );
  if (byCurrency != 0) return byCurrency;
  final int byAmount = a.amount.minorUnits.compareTo(b.amount.minorUnits);
  if (byAmount != 0) return byAmount;
  final int byDate = a.date.compareTo(b.date);
  return byDate != 0 ? byDate : compareBinary(a.id, b.id);
}

int _byRank(DuplicateCandidate a, DuplicateCandidate b) {
  final int byDays = a.dayDistance.compareTo(b.dayDistance);
  if (byDays != 0) return byDays;
  // More alike first: b's fraction against a's, cross-multiplied (an empty union is 0).
  final int bySimilarity = (b.similarity.shared * _atLeastOne(a.similarity))
      .compareTo(a.similarity.shared * _atLeastOne(b.similarity));
  if (bySimilarity != 0) return bySimilarity;
  final int byDate = _later(b).compareTo(_later(a));
  if (byDate != 0) return byDate;
  final int byFirst = compareBinary(a.first.id, b.first.id);
  return byFirst != 0 ? byFirst : compareBinary(a.second.id, b.second.id);
}

int _atLeastOne(NameSimilarity s) => s.total == 0 ? 1 : s.total;

LocalDate _later(DuplicateCandidate c) =>
    c.first.date.isAfter(c.second.date) ? c.first.date : c.second.date;
