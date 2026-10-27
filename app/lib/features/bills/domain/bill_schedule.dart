/// When a bill is due (`docs/reference/bills.md`, **Occurrences**): the occurrences of a
/// bill from its first due date by its cadence. Pure Dart.
///
/// - one-off (no cadence, or `unknown`): the anchor alone;
/// - weekly and biweekly: every 7 or 14 days from the anchor;
/// - monthly, quarterly and annually: the anchor's day of the month, every 1, 3 or 12
///   months, clamped to short months from the anchor each time (January 31 gives February
///   28, then March 31);
/// - semimonthly: two days a month from the anchor's day `d`: `d` and `d + 15` when `d` is
///   15 or less, else `d - 15` and `d`, each clamped to the month.
///
/// The anchor is the bill's `dueDate`, and no occurrence falls before it. A bill that
/// follows a liability with a next payment due date is anchored on that date instead,
/// which is always an occurrence: the institution's date is authoritative, so the series
/// runs both ways from it with no floor. The next and previous occurrences are found
/// however far they are (a one-off years past, an annual bill whose first date is more
/// than a year ahead).
library;

import 'package:shared_models/shared_models.dart';

/// The due dates of one bill.
final class BillSchedule {
  /// The schedule repeating [anchor] by [cadence], never before [first] (the anchor
  /// when null).
  BillSchedule(this.anchor, this.cadence, {LocalDate? first})
    : first = first ?? anchor;

  /// The schedule repeating [anchor] by [cadence] in both directions, with no first
  /// date: a followed liability's.
  BillSchedule.unbounded(this.anchor, this.cadence) : first = null;

  /// The schedule of [bill]; [liabilityDue] is the next payment due date of the
  /// liability it follows, when there is one, and then the series' anchor.
  factory BillSchedule.of(BillReminder bill, {LocalDate? liabilityDue}) =>
      liabilityDue == null
      ? BillSchedule(bill.dueDate, bill.cadence)
      : BillSchedule.unbounded(liabilityDue, bill.cadence);

  /// The date the series is counted from.
  final LocalDate anchor;

  /// How often it repeats; null (or `unknown`) for once.
  final RecurringCadence? cadence;

  /// No occurrence is earlier than this; null for none.
  final LocalDate? first;

  /// The occurrences from [from] (inclusive) to [to] (exclusive), ascending.
  List<LocalDate> between(LocalDate from, LocalDate to) {
    if (!from.isBefore(to)) return const [];
    final LocalDate? floor = first;
    final LocalDate start = floor != null && from.isBefore(floor)
        ? floor
        : from;
    if (!start.isBefore(to)) return const [];
    bool inRange(LocalDate d) => !d.isBefore(start) && d.isBefore(to);
    switch (cadence) {
      case null || RecurringCadence.unknown:
        return inRange(anchor) ? [anchor] : const [];
      case RecurringCadence.weekly || RecurringCadence.biweekly:
        final int step = cadence == RecurringCadence.weekly ? 7 : 14;
        final List<LocalDate> dates = [];
        for (int k = _floorDiv(anchor.daysUntil(start), step); ; k++) {
          final LocalDate d = anchor.addDays(k * step);
          if (!d.isBefore(to)) break;
          if (inRange(d)) dates.add(d);
        }
        return dates;
      case RecurringCadence.monthly ||
          RecurringCadence.quarterly ||
          RecurringCadence.annually ||
          RecurringCadence.semiMonthly:
        final int months = switch (cadence) {
          RecurringCadence.quarterly => 3,
          RecurringCadence.annually => 12,
          _ => 1,
        };
        final List<LocalDate> dates = [];
        for (
          int k =
              _floorDiv(_monthIndex(start) - _monthIndex(anchor), months) - 1;
          ;
          k++
        ) {
          final List<LocalDate> period = _period(k * months);
          if (!period.first.isBefore(to)) break;
          dates.addAll(period.where(inRange));
        }
        return dates;
    }
  }

  /// The first occurrence on or after [today], or null when there is none (a one-off
  /// already past).
  LocalDate? nextOnOrAfter(LocalDate today) {
    if (_once) return anchor.isBefore(today) ? null : anchor;
    // From the first date when it is ahead: within a longest gap of it there is one.
    final LocalDate? floor = first;
    final LocalDate start = floor != null && floor.isAfter(today)
        ? floor
        : today;
    return between(start, start.addDays(_longestGap)).firstOrNull;
  }

  /// The last occurrence before [today], or null when there is none.
  LocalDate? previousBefore(LocalDate today) {
    if (_once) return anchor.isBefore(today) ? anchor : null;
    final LocalDate? floor = first;
    if (floor != null && !floor.isBefore(today)) return null;
    // Some occurrence is before today, so the last is within a longest gap of it.
    return between(today.addDays(-_longestGap), today).lastOrNull;
  }

  bool get _once => cadence == null || cadence == RecurringCadence.unknown;

  // The anchor's dates in the month [months] after its own, ascending.
  List<LocalDate> _period(int months) {
    final LocalDate month = anchor.addMonths(months);
    if (cadence != RecurringCadence.semiMonthly) return [month];
    final int d = anchor.day;
    final (int a, int b) = d <= 15 ? (d, d + 15) : (d - 15, d);
    final int last = LocalDate.daysInMonth(month.year, month.month);
    return [
      LocalDate(month.year, month.month, a > last ? last : a),
      LocalDate(month.year, month.month, b > last ? last : b),
    ];
  }

  // More than the longest gap between two occurrences (a year with February 29), so
  // a search that wide finds the neighbour when there is one.
  static const int _longestGap = 367;
}

int _monthIndex(LocalDate d) => d.year * 12 + d.month - 1;

int _floorDiv(int a, int b) => a >= 0 ? a ~/ b : -((-a + b - 1) ~/ b);
