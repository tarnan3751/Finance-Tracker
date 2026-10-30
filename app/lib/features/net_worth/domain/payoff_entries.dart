/// What the user entered for a liability's payoff projection (`docs/reference/
/// net-worth.md`, **Payoff**): a payment or a rate the bank does not report, and an
/// extra payment a month. Kept on the device under `app_meta` `payoff_entries` as JSON
/// keyed by account id; never synced. Pure Dart.
library;

import 'package:shared_models/shared_models.dart';

/// The highest rate an entry may hold: 100 % a year.
const int maxEnteredRateBasisPoints = 10000;

/// One account's entries. A [payment] is positive, a [rateBasisPoints] from 0 to
/// [maxEnteredRateBasisPoints], an [extra] not negative; [PayoffEntry.new] refuses
/// anything else with an [ArgumentError].
final class PayoffEntry {
  /// An entry.
  PayoffEntry({this.payment, this.rateBasisPoints, this.extra}) {
    if (payment != null && !payment!.isPositive) {
      throw ArgumentError.value(payment, 'payment', 'must be positive');
    }
    final int? rate = rateBasisPoints;
    if (rate != null && (rate < 0 || rate > maxEnteredRateBasisPoints)) {
      throw ArgumentError.value(rate, 'rateBasisPoints', 'must be 0 to 10000');
    }
    if (extra != null && extra!.isNegative) {
      throw ArgumentError.value(extra, 'extra', 'must not be negative');
    }
  }

  final Money? payment;
  final int? rateBasisPoints;
  final Money? extra;

  /// Whether it holds nothing.
  bool get isEmpty =>
      payment == null &&
      rateBasisPoints == null &&
      (extra == null || extra!.isZero);

  /// This entry with [payment] (null clears it).
  PayoffEntry withPayment(Money? payment) => PayoffEntry(
    payment: payment,
    rateBasisPoints: rateBasisPoints,
    extra: extra,
  );

  /// This entry with [rateBasisPoints] (null clears it).
  PayoffEntry withRate(int? rateBasisPoints) => PayoffEntry(
    payment: payment,
    rateBasisPoints: rateBasisPoints,
    extra: extra,
  );

  /// This entry with [extra] (null clears it).
  PayoffEntry withExtra(Money? extra) => PayoffEntry(
    payment: payment,
    rateBasisPoints: rateBasisPoints,
    extra: extra,
  );

  /// The JSON form: `{"payment": Money, "rate_bp": int, "extra": Money}`, each when set.
  Map<String, Object?> toJson() => {
    if (payment != null) 'payment': payment!.toJson(),
    if (rateBasisPoints != null) 'rate_bp': rateBasisPoints,
    if (extra != null) 'extra': extra!.toJson(),
  };

  /// Reads the JSON form; a malformed or invalid value is a [FormatException].
  factory PayoffEntry.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('a payoff entry is an object');
    }
    try {
      Money? money(Object? v) =>
          v == null ? null : Money.fromJson(v as Map<String, dynamic>);
      return PayoffEntry(
        payment: money(json['payment']),
        rateBasisPoints: json['rate_bp'] as int?,
        extra: money(json['extra']),
      );
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('a malformed payoff entry: ${e.runtimeType}');
    }
  }
}

/// Reads the stored entries (account id to entry); an entry that does not read is
/// dropped, and a value that is not an object reads as none.
Map<String, PayoffEntry> payoffEntriesFromJson(Object? json) {
  if (json is! Map<String, Object?>) return const {};
  final Map<String, PayoffEntry> entries = {};
  for (final MapEntry<String, Object?> e in json.entries) {
    try {
      entries[e.key] = PayoffEntry.fromJson(e.value);
    } on FormatException {
      // Dropped: an invalid entry is as if never made.
    }
  }
  return entries;
}

/// The JSON form of [entries], the empty ones left out.
Map<String, Object?> payoffEntriesToJson(Map<String, PayoffEntry> entries) => {
  for (final MapEntry<String, PayoffEntry> e in entries.entries)
    if (!e.value.isEmpty) e.key: e.value.toJson(),
};

/// The basis points of [text], a rate in percent with at most two decimal places
/// (`4.89`, `12`, `0.5`; a `.` or a `,` before the decimals), or null when it is not one
/// or is over [maxEnteredRateBasisPoints].
int? parseRateBasisPoints(String text) {
  final RegExpMatch? m = RegExp(r'^\s*(\d{1,3})(?:[.,](\d{1,2}))?\s*%?\s*$')
      .firstMatch(text);
  if (m == null) return null;
  final int bp =
      int.parse(m[1]!) * 100 + int.parse((m[2] ?? '0').padRight(2, '0'));
  return bp > maxEnteredRateBasisPoints ? null : bp;
}

/// [basisPoints] as a percentage with two decimals, `4.89`.
String rateText(int basisPoints) =>
    '${basisPoints ~/ 100}.${(basisPoints % 100).toString().padLeft(2, '0')}';
