/// When a recurring stream is next expected, for the forecast (`docs/reference/forecast.md`,
/// **Stream dates**): the dates a stream's series takes from its `nextExpected` by its
/// cadence. Pure Dart.
///
/// - weekly and biweekly: every 7 or 14 days;
/// - monthly, quarterly and annually: the anchor's day of the month every 1, 3 or 12
///   months, clamped to short months from the anchor each time; when the anchor is a
///   month's last day the series is on every month's last day (the detector's `L`
///   anchor), which for a stream the app did not detect also needs `lastExpected` to be
///   a last day, so a bank's stream on the 28th or the 30th stays there;
/// - semimonthly, whatever the stream's source: the days of the month of `lastExpected`
///   and `nextExpected` when they are at least 10 apart, else the anchor's day `d` and
///   `d + 15` (`d - 15` past the 15th); a day of 28 or more is the month's last day (the
///   detector's `L` token), so a payroll on the 15th and the month end lands on every
///   month's true last day whichever of its two dates is the next;
/// - unknown: `nextExpected` alone.
///
/// The anchor is `nextExpected`; with none, the series steps from `lastExpected` by the
/// cadence (that date itself is past); with neither, or for an `ended` stream, there are
/// no dates.
library;

import 'package:shared_models/shared_models.dart';

/// The dates of [stream]'s series from [from] to [to], both inclusive, ascending.
List<LocalDate> streamDates(
  RecurringStream stream,
  LocalDate from,
  LocalDate to,
) {
  if (stream.status == RecurringStatus.ended || to.isBefore(from)) {
    return const [];
  }
  final LocalDate? next = stream.nextExpected;
  final LocalDate? last = stream.lastExpected;
  final LocalDate? anchor = next ?? last;
  if (anchor == null) return const [];
  // The anchor counts only when it is the predicted date, not the last one seen.
  bool counts(LocalDate d) =>
      (next != null ? !d.isBefore(anchor) : d.isAfter(anchor)) &&
      !d.isBefore(from) &&
      !d.isAfter(to);
  switch (stream.cadence) {
    case RecurringCadence.unknown:
      return next != null && counts(next) ? [next] : const [];
    case RecurringCadence.weekly || RecurringCadence.biweekly:
      final int step = stream.cadence == RecurringCadence.weekly ? 7 : 14;
      final List<LocalDate> dates = [];
      final int skip = anchor.daysUntil(from);
      for (int k = skip > 0 ? skip ~/ step : 0; ; k++) {
        final LocalDate d = anchor.addDays(k * step);
        if (d.isAfter(to)) break;
        if (counts(d)) dates.add(d);
      }
      return dates;
    case RecurringCadence.monthly ||
        RecurringCadence.quarterly ||
        RecurringCadence.annually:
      final int months = switch (stream.cadence) {
        RecurringCadence.quarterly => 3,
        RecurringCadence.annually => 12,
        _ => 1,
      };
      final bool lastDay =
          _isLastDay(anchor) &&
          (stream.source == RecurringSource.detected ||
              (next != null && last != null && _isLastDay(last)));
      final List<LocalDate> dates = [];
      final int skip = _monthIndex(from) - _monthIndex(anchor);
      for (int k = skip > months ? skip ~/ months - 1 : 0; ; k++) {
        final LocalDate month = anchor.addMonths(k * months);
        final LocalDate d = lastDay ? month.lastOfMonth : month;
        if (d.isAfter(to)) break;
        if (counts(d)) dates.add(d);
      }
      return dates;
    case RecurringCadence.semiMonthly:
      final (int a, int b) = switch ((next, last)) {
        (final LocalDate n, final LocalDate l)
            when (n.day - l.day).abs() >= 10 =>
          n.day < l.day ? (n.day, l.day) : (l.day, n.day),
        _ =>
          anchor.day <= 15
              ? (anchor.day, anchor.day + 15)
              : (anchor.day - 15, anchor.day),
      };
      final List<LocalDate> dates = [];
      final int skip = _monthIndex(from) - _monthIndex(anchor);
      for (int k = skip > 1 ? skip - 1 : 0; ; k++) {
        final LocalDate month = anchor.firstOfMonth.addMonths(k);
        final int length = LocalDate.daysInMonth(month.year, month.month);
        // A day of 28 or more is the month's last day.
        int on(int day) => day >= 28 ? length : day;
        final LocalDate first = LocalDate(month.year, month.month, on(a));
        if (first.isAfter(to)) break;
        final LocalDate second = LocalDate(month.year, month.month, on(b));
        for (final LocalDate d in [first, second]) {
          if (counts(d)) dates.add(d);
        }
      }
      return dates;
  }
}

bool _isLastDay(LocalDate d) => d.day == LocalDate.daysInMonth(d.year, d.month);

int _monthIndex(LocalDate d) => d.year * 12 + d.month - 1;
