/// Which incoming rows are likely already on the account (`docs/reference/import.md`,
/// **Duplicates**). Pure Dart and deterministic.
///
/// Two checks, either of which marks an incoming row:
///
/// - **The duplicates detector** (`features/duplicates/`): a pair `findDuplicates` finds
///   among the existing and the incoming rows that joins an incoming row to an existing
///   one, which on one account means a bank row (`plaid`, `demo`) and an entered one.
/// - **A re-import**: the detector never pairs two entered rows of one account, so a file,
///   or an overlapping export, imported again into a manual account is caught here: an
///   incoming row repeats an existing `manual` or `import` row of its account with the
///   same date, the same amount and the same name (trimmed, case folded, whitespace
///   collapsed). A hidden existing row counts: it is still on the account.
///
/// Either way each existing row answers for one incoming row: the re-import matches are
/// taken first, then the detector's pairs nearest in date first (then by the incoming
/// row's place in the file, then by the existing row's id). So two identical coffees in
/// the file against one stored, or against one bank row, are one duplicate and one new
/// row. Two incoming rows never mark each other.
library;

import 'package:finance_tracker/core/util/binary_compare.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:shared_models/shared_models.dart';

/// The ids of [incoming] that are likely duplicates of [existing].
Set<String> likelyDuplicates(
  List<Transaction> incoming,
  List<Transaction> existing,
) {
  final Map<String, int> place = {
    for (int i = 0; i < incoming.length; i++) incoming[i].id: i,
  };
  final Set<String> marked = {};
  final Set<String> used = {};
  final Map<_Key, List<String>> stored = {};
  final List<Transaction> byId = [...existing]
    ..sort((a, b) => compareBinary(a.id, b.id));
  for (final Transaction t in byId) {
    if (t.deletedAt != null ||
        (t.source != DataSource.manual && t.source != DataSource.import)) {
      continue;
    }
    (stored[_Key.of(t)] ??= []).add(t.id);
  }
  for (final Transaction t in incoming) {
    final List<String>? same = stored[_Key.of(t)];
    if (same != null && same.isNotEmpty) {
      used.add(same.removeAt(0));
      marked.add(t.id);
    }
  }
  final List<({String incoming, String existing, int days})> pairs = [
    for (final DuplicateCandidate pair in findDuplicates([
      ...existing,
      ...incoming,
    ]))
      if (place.containsKey(pair.first.id) != place.containsKey(pair.second.id))
        place.containsKey(pair.first.id)
            ? (
                incoming: pair.first.id,
                existing: pair.second.id,
                days: pair.dayDistance,
              )
            : (
                incoming: pair.second.id,
                existing: pair.first.id,
                days: pair.dayDistance,
              ),
  ];
  pairs.sort((a, b) {
    final int byDays = a.days.compareTo(b.days);
    if (byDays != 0) return byDays;
    final int byPlace = place[a.incoming]!.compareTo(place[b.incoming]!);
    return byPlace != 0 ? byPlace : compareBinary(a.existing, b.existing);
  });
  for (final p in pairs) {
    if (marked.contains(p.incoming) || used.contains(p.existing)) continue;
    marked.add(p.incoming);
    used.add(p.existing);
  }
  return marked;
}

final RegExp _space = RegExp(r'\s+');

final class _Key {
  _Key.of(Transaction t)
    : account = t.accountId,
      date = t.date,
      amount = t.amount,
      name = t.name.trim().toLowerCase().replaceAll(_space, ' ');

  final String account;
  final LocalDate date;
  final Money amount;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.account == account &&
      other.date == date &&
      other.amount == amount &&
      other.name == name;

  @override
  int get hashCode => Object.hash(account, date, amount, name);
}
