/// The app's own recurring detector (`docs/reference/recurring.md`, **The detector**;
/// `PLAN.md` §12, "The detector"): transactions on any account grouped into recurring
/// streams with a cadence, an expected amount and the next date, `source: detected`. Pure
/// Dart and deterministic: the result depends only on the transactions, the categories
/// and `today`, never on their order; integer `Money` only.
///
/// - **Input**: live transactions that are not hidden, not pending, not `derived` and not
///   zero, except those whose effective category ([effectiveCategory]) is an internal
///   movement or an accrual ([detectorExcludedCodes], and any inflow under
///   `LOAN_PAYMENTS`, the receiving leg of a payment). A row the user recategorizes
///   becomes eligible.
/// - **Groups**: by account, currency, direction and merchant key
///   ([recurringMerchantKey]). The whole group is tried as one stream first; only when it
///   is not one is it split into amount clusters (sorted by magnitude, each amount linked
///   to the next when within 15 % of it or 100 minor units, whichever is larger; 25 % for
///   inflows), and each cluster tried.
/// - **Cadence**: the candidate's dates in order form maximal runs for each cadence, an
///   interval fitting once or, for one missed occurrence per run, twice: weekly 7±2 days,
///   biweekly 14±3, semimonthly 10..20 with every date within 3 days of one of two
///   day-of-month anchors at least 10 days apart, monthly 24..35 with every date within 4
///   days of its most common day of the month (clamped to short months), quarterly 91±7,
///   annual 365±10. A day of the month of 28 or more counts as one "last day" anchor
///   (`L`), so a bill on the month's end keeps one anchor through 28, 30 and 31-day
///   months, and its next date is the actual last day of the month; a stream truly on
///   the 28th is anchored to the last day too. A run is a stream when it has at least 4 occurrences (weekly,
///   biweekly), 3 (semimonthly, monthly, quarterly) or 2 (annual); when no row of its
///   candidate outside it shares its first or last date; when it holds at least two
///   thirds of its candidate's rows; when, quarterly or annual, its amounts are within
///   5 % of their median; and when, annual and seen only twice, it holds two thirds of
///   its group's rows. The longest run wins, then the one ending later, then the shorter
///   cadence (semimonthly before biweekly).
/// - **The stream**: its id is `detected-` and 16 hex digits of the SHA-1 of
///   `account|currency|direction|merchant key|cadence|anchor` (the anchor is the most
///   common weekday, fortnight phase, day pair, day of the month, or month and day, with
///   the last-day token `L`; ties to the smallest), so it stays the same as the stream's
///   occurrences accrue,
///   and of two streams with one id the one ending later is kept. `transactionIds` are the
///   run's members; `lastExpected` the last one's date; `nextExpected` the first anchored
///   date at least half a cadence after it; `status` active while `today` is at most two
///   cadence lengths after the last occurrence; `averageAmount` the median of the newest
///   price step ([StreamBand]); `merchantName` the newest member's display name.
///   `isSubscription` is false: the classifier (`subscription_classifier.dart`) decides.
///   The result is sorted by merchant name, then id.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:shared_models/shared_models.dart';

/// The effective-category codes whose rows are not detector input: transfers between the
/// user's own accounts, card payments, and the interest an institution posts.
const Set<String> detectorExcludedCodes = {
  'TRANSFER_IN_ACCOUNT_TRANSFER',
  'TRANSFER_OUT_ACCOUNT_TRANSFER',
  'TRANSFER_IN_SAVINGS',
  'TRANSFER_OUT_SAVINGS',
  'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT',
  'INCOME_INTEREST_EARNED',
  'BANK_FEES_INTEREST_CHARGE',
};

/// The key a transaction's merchant is grouped by: the enrichment fallback's display name
/// (Plaid's `merchantName`, else the dictionary's or the cleaned raw name), normalized.
String recurringMerchantKey(Transaction transaction) =>
    normalizeMerchantText(EnrichedMerchant.resolve(transaction).displayName);

/// The days a cadence lasts, for a stream's status: active while the last occurrence is
/// at most two of these before today.
int cadenceLengthDays(RecurringCadence cadence) => switch (cadence) {
  RecurringCadence.weekly => 7,
  RecurringCadence.biweekly => 14,
  RecurringCadence.semiMonthly => 16,
  RecurringCadence.monthly => 31,
  RecurringCadence.quarterly => 92,
  RecurringCadence.annually => 366,
  RecurringCadence.unknown => 0,
};

/// The expected amount and range of a stream with [members]: the median, the smallest
/// and the largest of its newest price step, signed (for an outflow [min] is the largest
/// outflow). A price step is one of the members' amount clusters (as the detector forms
/// them); when the clusters follow each other in time (a price change), the newest one is
/// the step; when they interleave (a seasonal bill) or there is one, every member is. The
/// median is the lower middle by magnitude.
final class StreamBand {
  const StreamBand({
    required this.median,
    required this.min,
    required this.max,
  });

  /// The band of [members], or null when there are none. They share one currency and
  /// one direction.
  static StreamBand? of(Iterable<Transaction> members) {
    final List<Transaction> byDate = members.toList()..sort(_byDateThenId);
    if (byDate.isEmpty) return null;
    final List<List<Transaction>> clusters = _amountClusters(byDate);
    List<Transaction> step = byDate;
    if (clusters.length > 1) {
      final Map<String, int> clusterOf = {
        for (int i = 0; i < clusters.length; i++)
          for (final Transaction t in clusters[i]) t.id: i,
      };
      final List<int> order = [];
      for (final Transaction t in byDate) {
        final int c = clusterOf[t.id]!;
        if (order.isEmpty || order.last != c) order.add(c);
      }
      if (order.length == clusters.length) {
        step = clusters[order.last];
      }
    }
    final List<Transaction> byMagnitude = [...step]..sort(_byMagnitude);
    final Money median = byMagnitude[(byMagnitude.length - 1) ~/ 2].amount;
    Money min = step.first.amount;
    Money max = step.first.amount;
    for (final Transaction t in step) {
      min = Money.min(min, t.amount);
      max = Money.max(max, t.amount);
    }
    return StreamBand(median: median, min: min, max: max);
  }

  /// The expected amount.
  final Money median;

  /// The smallest amount, signed.
  final Money min;

  /// The largest amount, signed.
  final Money max;

  /// Whether every amount is within [basisPoints] of the median's magnitude.
  bool isWithin(int basisPoints) {
    final int m = median.minorUnits.abs();
    return (max - median).minorUnits.abs() * 10000 <= m * basisPoints &&
        (median - min).minorUnits.abs() * 10000 <= m * basisPoints;
  }

  @override
  bool operator ==(Object other) =>
      other is StreamBand &&
      other.median == median &&
      other.min == min &&
      other.max == max;

  @override
  int get hashCode => Object.hash(median, min, max);

  @override
  String toString() => 'StreamBand($median, $min..$max)';
}

/// The recurring streams in [transactions] as of [today], [lookup] giving the effective
/// categories and [merchantKey] the grouping key (the app passes
/// [recurringMerchantKey]). See the library comment for the rules.
List<RecurringStream> detectStreams(
  List<Transaction> transactions, {
  required LocalDate today,
  required CategoryLookup lookup,
  required String Function(Transaction) merchantKey,
}) {
  final Map<String, List<Transaction>> groups = {};
  final Map<String, String> keyOfGroup = {};
  for (final Transaction t in transactions) {
    if (!_isInput(t, lookup)) continue;
    final String key = merchantKey(t);
    final String group =
        '${t.accountId}\u0000${t.amount.currencyCode}\u0000'
        '${t.amount.isPositive}\u0000$key';
    (groups[group] ??= []).add(t);
    keyOfGroup[group] = key;
  }
  final Map<String, RecurringStream> byId = {};
  for (final String group in groups.keys.toList()..sort()) {
    final List<Transaction> rows = groups[group]!..sort(_byDateThenId);
    final String key = keyOfGroup[group]!;
    final _Run? whole = _bestRun(rows, rows.length);
    final List<_Run> runs = whole != null
        ? [whole]
        : [
            for (final List<Transaction> cluster in _amountClusters(rows))
              ?_bestRun(cluster..sort(_byDateThenId), rows.length),
          ];
    for (final _Run run in runs) {
      final RecurringStream stream = _stream(run, key, today);
      final RecurringStream? previous = byId[stream.id];
      if (previous == null || _endsLater(stream, previous)) {
        byId[stream.id] = stream;
      }
    }
  }
  return byId.values.toList()..sort(_byMerchantThenId);
}

/// [a] and [b] by merchant name, then id: the order every stream list is shown in.
int compareStreams(RecurringStream a, RecurringStream b) =>
    _byMerchantThenId(a, b);

bool _isInput(Transaction t, CategoryLookup lookup) {
  if (t.deletedAt != null ||
      t.hidden ||
      t.pending ||
      t.source == DataSource.derived ||
      t.amount.isZero) {
    return false;
  }
  final String? code = effectiveCategory(t, lookup)?.plaidCategory;
  if (code == null) return true;
  if (detectorExcludedCodes.contains(code)) return false;
  return !(t.amount.isPositive &&
      (code == 'LOAN_PAYMENTS' || code.startsWith('LOAN_PAYMENTS_')));
}

/// The cadences in the order a tie between equally long runs is settled: semimonthly
/// before biweekly, since its anchors are the stricter test.
const List<RecurringCadence> _cadences = [
  RecurringCadence.weekly,
  RecurringCadence.semiMonthly,
  RecurringCadence.biweekly,
  RecurringCadence.monthly,
  RecurringCadence.quarterly,
  RecurringCadence.annually,
];

/// Whether [days] between two occurrences fits [cadence] with [missed] occurrences
/// between them (0 or 1).
bool _fits(RecurringCadence cadence, int days, int missed) {
  final int k = missed + 1;
  return switch (cadence) {
    RecurringCadence.weekly => (days - 7 * k).abs() <= 2,
    RecurringCadence.biweekly => (days - 14 * k).abs() <= 3,
    RecurringCadence.semiMonthly =>
      k == 1 ? days >= 10 && days <= 20 : days >= 25 && days <= 35,
    RecurringCadence.monthly =>
      k == 1 ? days >= 24 && days <= 35 : days >= 55 && days <= 66,
    RecurringCadence.quarterly => (days - 91 * k).abs() <= 7 * k,
    RecurringCadence.annually => (days - 365 * k).abs() <= 10 * k,
    RecurringCadence.unknown => false,
  };
}

int _minimumOccurrences(RecurringCadence cadence) => switch (cadence) {
  RecurringCadence.weekly || RecurringCadence.biweekly => 4,
  RecurringCadence.annually => 2,
  _ => 3,
};

/// A run: [members] in date order at [cadence].
typedef _Run = ({RecurringCadence cadence, List<Transaction> members});

/// The best run of [rows] (in date order), [groupSize] being the number of rows in their
/// merchant group; null when none is a stream.
_Run? _bestRun(List<Transaction> rows, int groupSize) {
  _Run? best;
  void consider(RecurringCadence cadence, int start, int end) {
    final List<Transaction> members = rows.sublist(start, end);
    if (!_isStream(cadence, members, rows, start, end, groupSize)) return;
    final _Run? b = best;
    if (b == null ||
        members.length > b.members.length ||
        (members.length == b.members.length &&
            members.last.date.isAfter(b.members.last.date))) {
      best = (cadence: cadence, members: members);
    }
  }

  for (final RecurringCadence cadence in _cadences) {
    int start = 0;
    int missed = 0;
    for (int i = 1; i < rows.length; i++) {
      final int days = rows[i - 1].date.daysUntil(rows[i].date);
      if (_fits(cadence, days, 0)) continue;
      if (_fits(cadence, days, 1)) {
        if (missed == 0) {
          missed = 1;
          continue;
        }
        // A second miss: the run ends before it and the next one starts with it.
        consider(cadence, start, i);
        start = i - 1;
        missed = 1;
        continue;
      }
      consider(cadence, start, i);
      start = i;
      missed = 0;
    }
    consider(cadence, start, rows.length);
  }
  return best;
}

bool _isStream(
  RecurringCadence cadence,
  List<Transaction> members,
  List<Transaction> rows,
  int start,
  int end,
  int groupSize,
) {
  if (members.length < _minimumOccurrences(cadence)) return false;
  if (members.length * 3 < rows.length * 2) return false;
  if (start > 0 && rows[start - 1].date == members.first.date) return false;
  if (end < rows.length && rows[end].date == members.last.date) return false;
  switch (cadence) {
    case RecurringCadence.monthly:
      final int anchor = _mode([
        for (final t in members) _dayToken(t.date.day),
      ]);
      if (!members.every((t) => _daysFromAnchor(t.date, anchor) <= 4)) {
        return false;
      }
    case RecurringCadence.semiMonthly:
      final (int, int)? anchors = _semiMonthlyAnchors(members);
      if (anchors == null) return false;
      if (!members.every(
        (t) =>
            _daysFromAnchor(t.date, anchors.$1) <= 3 ||
            _daysFromAnchor(t.date, anchors.$2) <= 3,
      )) {
        return false;
      }
    case RecurringCadence.quarterly || RecurringCadence.annually:
      if (!StreamBand.of(members)!.isWithin(500)) return false;
      if (cadence == RecurringCadence.annually &&
          members.length < 3 &&
          members.length * 3 < groupSize * 2) {
        return false;
      }
    case _:
  }
  return true;
}

/// The most common of [values], ties to the smallest.
int _mode(Iterable<int> values) {
  final Map<int, int> counts = {};
  for (final int v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  int? best;
  for (final MapEntry<int, int> e in counts.entries) {
    final int? b = best;
    if (b == null ||
        e.value > counts[b]! ||
        (e.value == counts[b]! && e.key < b)) {
      best = e.key;
    }
  }
  return best!;
}

/// The anchor a day of the month counts toward: itself, or [_lastDay] from the 28th on,
/// so the end of a month is one anchor whatever the month's length.
int _dayToken(int day) => day >= 28 ? _lastDay : day;

/// The last-day anchor: day 31, which [_anchored] clamps to every month's last day.
const int _lastDay = 31;

/// [token] as the id hashes it: `L` for the last day.
String _dayName(int token) => token == _lastDay ? 'L' : '$token';

/// [day] in the month of [year] and [month], clamped to its length.
LocalDate _anchored(int year, int month, int day) {
  final int last = LocalDate.daysInMonth(year, month);
  return LocalDate(year, month, day < last ? day : last);
}

/// The days between [date] and the nearest date on day [anchor] (clamped) of its month or
/// the months either side.
int _daysFromAnchor(LocalDate date, int anchor) {
  final LocalDate first = date.firstOfMonth;
  int nearest = 1 << 30;
  for (int m = -1; m <= 1; m++) {
    final LocalDate month = first.addMonths(m);
    final int d = date
        .daysUntil(_anchored(month.year, month.month, anchor))
        .abs();
    if (d < nearest) nearest = d;
  }
  return nearest;
}

/// The two days of the month a semimonthly run is on ([_dayToken]): the most common
/// day, and the most common of the days at least 10 days from it; null when there is no
/// second.
(int, int)? _semiMonthlyAnchors(List<Transaction> members) {
  final List<int> days = [for (final t in members) _dayToken(t.date.day)];
  final int first = _mode(days);
  final List<int> others = [
    for (final int day in days)
      if (_dayDistance(day, first) >= 10) day,
  ];
  if (others.isEmpty) return null;
  final int second = _mode(others);
  return first < second ? (first, second) : (second, first);
}

/// The distance between two days of the month, around the month's end.
int _dayDistance(int a, int b) {
  final int d = (a - b).abs();
  return d < 31 - d ? d : 31 - d;
}

final LocalDate _epoch = LocalDate(1970, 1, 1);

/// The anchor of a run at its cadence, as the id hashes it, and whether a date is on it.
({String anchor, bool Function(LocalDate) on}) _anchorOf(_Run run) {
  final List<LocalDate> dates = [for (final t in run.members) t.date];
  switch (run.cadence) {
    case RecurringCadence.weekly:
      final int weekday = _mode(dates.map((d) => d.weekday));
      return (anchor: '$weekday', on: (d) => d.weekday == weekday);
    case RecurringCadence.biweekly:
      final int phase = _mode(dates.map((d) => _epoch.daysUntil(d) % 14));
      return (anchor: '$phase', on: (d) => _epoch.daysUntil(d) % 14 == phase);
    case RecurringCadence.semiMonthly:
      final (int a, int b) = _semiMonthlyAnchors(run.members)!;
      return (
        anchor: '${_dayName(a)}-${_dayName(b)}',
        on: (d) =>
            d == _anchored(d.year, d.month, a) ||
            d == _anchored(d.year, d.month, b),
      );
    case RecurringCadence.monthly:
      final int day = _mode(dates.map((d) => _dayToken(d.day)));
      return (
        anchor: _dayName(day),
        on: (d) => d == _anchored(d.year, d.month, day),
      );
    case RecurringCadence.quarterly:
      final int at = _mode(
        dates.map((d) => (d.month - 1) % 3 * 100 + _dayToken(d.day)),
      );
      return (
        anchor: '${at ~/ 100}-${_dayName(at % 100)}',
        on: (d) =>
            (d.month - 1) % 3 == at ~/ 100 &&
            d == _anchored(d.year, d.month, at % 100),
      );
    case RecurringCadence.annually || RecurringCadence.unknown:
      final int at = _mode(dates.map((d) => d.month * 100 + _dayToken(d.day)));
      return (
        anchor: '${at ~/ 100}-${_dayName(at % 100)}',
        on: (d) =>
            d.month == at ~/ 100 && d == _anchored(d.year, d.month, at % 100),
      );
  }
}

RecurringStream _stream(_Run run, String key, LocalDate today) {
  final Transaction newest = run.members.last;
  final (:String anchor, :bool Function(LocalDate) on) = _anchorOf(run);
  final int length = cadenceLengthDays(run.cadence);
  final LocalDate last = newest.date;
  LocalDate next = last.addDays(length ~/ 2);
  while (!on(next)) {
    next = next.addDays(1);
  }
  final String digest = sha1
      .convert(
        utf8.encode(
          '${newest.accountId}|${newest.amount.currencyCode}|'
          '${newest.amount.isPositive ? 'in' : 'out'}|$key|'
          '${run.cadence.name}|$anchor',
        ),
      )
      .toString();
  return RecurringStream(
    id: 'detected-${digest.substring(0, 16)}',
    accountId: newest.accountId,
    merchantName: EnrichedMerchant.resolve(newest).displayName,
    cadence: run.cadence,
    averageAmount: StreamBand.of(run.members)!.median,
    lastExpected: last,
    nextExpected: next,
    status: last.daysUntil(today) <= 2 * length
        ? RecurringStatus.active
        : RecurringStatus.ended,
    isSubscription: false,
    source: RecurringSource.detected,
    transactionIds: [for (final t in run.members) t.id],
  );
}

bool _endsLater(RecurringStream a, RecurringStream b) {
  final int byLast = a.lastExpected!.compareTo(b.lastExpected!);
  if (byLast != 0) return byLast > 0;
  if (a.transactionIds.length != b.transactionIds.length) {
    return a.transactionIds.length > b.transactionIds.length;
  }
  return a.transactionIds.first.compareTo(b.transactionIds.first) < 0;
}

/// [rows] (one currency and direction) as amount clusters: sorted by magnitude, each
/// amount joining the previous one's cluster when within 15 % of it or 100 minor units,
/// whichever is larger (25 % for inflows).
List<List<Transaction>> _amountClusters(List<Transaction> rows) {
  final List<Transaction> sorted = [...rows]..sort(_byMagnitude);
  final List<List<Transaction>> clusters = [];
  for (final Transaction t in sorted) {
    if (clusters.isEmpty) {
      clusters.add([t]);
      continue;
    }
    final int previous = clusters.last.last.amount.minorUnits.abs();
    final int percent = t.amount.isPositive ? 25 : 15;
    final int share = previous * percent ~/ 100;
    final int tolerance = share > 100 ? share : 100;
    if (t.amount.minorUnits.abs() - previous <= tolerance) {
      clusters.last.add(t);
    } else {
      clusters.add([t]);
    }
  }
  return clusters;
}

int _byDateThenId(Transaction a, Transaction b) {
  final int byDate = a.date.compareTo(b.date);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

int _byMagnitude(Transaction a, Transaction b) {
  final int byAmount = a.amount.minorUnits.abs().compareTo(
    b.amount.minorUnits.abs(),
  );
  return byAmount != 0 ? byAmount : _byDateThenId(a, b);
}

int _byMerchantThenId(RecurringStream a, RecurringStream b) {
  final int byName = a.merchantName.compareTo(b.merchantName);
  return byName != 0 ? byName : a.id.compareTo(b.id);
}
