/// Budget periods (`docs/reference/budgets.md`, **Periods**; `PLAN.md` §6.8): half-open
/// ranges of local dates, monthly from a start day of 1 to 28. Pure Dart.
///
/// The period containing a date `d` starts on the latest date on or before `d` whose day
/// of the month is the start day, and ends one month later. A start day of at most 28
/// exists in every month, so a period never clamps: consecutive periods tile the
/// calendar, each 28 to 31 days long. The dates are the device zone's local dates; the
/// caller's "today" comes from the clock, so no time zone or DST shift moves a period.
library;

import 'package:shared_models/shared_models.dart';

/// The budget period that contains [day], for periods starting on day [periodStartDay]
/// of the month. Throws [ArgumentError] unless [periodStartDay] is 1 to 28.
LocalDateRange periodContaining(LocalDate day, int periodStartDay) {
  _checkStartDay(periodStartDay);
  final LocalDate thisMonth = LocalDate(day.year, day.month, periodStartDay);
  final LocalDate start = day.day >= periodStartDay
      ? thisMonth
      : thisMonth.addMonths(-1);
  return LocalDateRange(start, start.addMonths(1));
}

/// The period [offset] periods after the one containing [day] (before it when [offset]
/// is negative), for periods starting on day [periodStartDay] of the month. Throws
/// [ArgumentError] unless [periodStartDay] is 1 to 28.
LocalDateRange periodAt(LocalDate day, int periodStartDay, int offset) {
  final LocalDate start = periodContaining(
    day,
    periodStartDay,
  ).start.addMonths(offset);
  return LocalDateRange(start, start.addMonths(1));
}

/// The periods from the one containing [startDate] through the one containing [through],
/// in order; empty when [through] is before the first of them. Throws [ArgumentError]
/// unless [periodStartDay] is 1 to 28.
List<LocalDateRange> periodsFrom(
  LocalDate startDate,
  int periodStartDay, {
  required LocalDate through,
}) {
  final List<LocalDateRange> periods = [];
  LocalDateRange period = periodContaining(startDate, periodStartDay);
  while (!through.isBefore(period.start)) {
    periods.add(period);
    period = LocalDateRange(period.end, period.end.addMonths(1));
  }
  return periods;
}

void _checkStartDay(int periodStartDay) {
  if (periodStartDay < 1 || periodStartDay > 28) {
    throw ArgumentError.value(
      periodStartDay,
      'periodStartDay',
      'must be 1 to 28',
    );
  }
}
